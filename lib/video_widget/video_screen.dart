import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as https;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobi_tv_entertainment/video_widget/network_reconnection_screen.dart';
import 'package:video_player/video_player.dart'; // Changed from VLC to video_player
import 'package:keep_screen_on/keep_screen_on.dart';
import 'package:mobi_tv_entertainment/main.dart';
import 'package:mobi_tv_entertainment/menu_screens/home_sub_screen/home_category.dart';
import 'package:mobi_tv_entertainment/video_widget/socket_service.dart';
import 'package:mobi_tv_entertainment/widgets/small_widgets/loading_indicator.dart';
import 'package:mobi_tv_entertainment/widgets/small_widgets/rainbow_page.dart';
import 'package:mobi_tv_entertainment/widgets/small_widgets/rainbow_spinner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../menu_screens/home_sub_screen/sub_vod.dart';
import '../menu_screens/home_sub_screen/banner_slider_screen.dart';
import '../menu_screens/search_screen.dart';
import '../widgets/models/news_item_model.dart';
// First create an EventBus class (create a new file event_bus.dart)
import 'package:event_bus/event_bus.dart';

class GlobalEventBus {
  static final EventBus eventBus = EventBus();
}

class GlobalVariables {
  static String unUpdatedUrl = '';
  static String UpdatedUrl = '';
  static Duration position = Duration.zero;
  static Duration duration = Duration.zero;
  static String banner = '';
  static String name = '';
  static bool liveStatus = false;
  static String slectedId = '';
}

// Create an event class
class RefreshPageEvent {
  final String pageId; // To identify which page to refresh
  RefreshPageEvent(this.pageId);
}

class VideoScreen extends StatefulWidget {
  final String videoUrl;
  final String name;
  final bool liveStatus;
  final String unUpdatedUrl;
  final List<dynamic> channelList;
  final String bannerImageUrl;
  final Duration startAtPosition;
  final bool isLive;
  final bool isVOD;
  final bool isSearch;
  final bool? isHomeCategory;
  final bool isBannerSlider;
  final String videoType;
  final int? videoId;
  final String source;
  final Duration? totalDuration;

  VideoScreen(
      {required this.videoUrl,
      required this.unUpdatedUrl,
      required this.channelList,
      required this.bannerImageUrl,
      required this.startAtPosition,
      required this.videoType,
      required this.isLive,
      required this.isVOD,
      required this.isSearch,
      this.isHomeCategory,
      required this.isBannerSlider,
      required this.videoId,
      required this.source,
      required this.name,
      required this.liveStatus,
      this.totalDuration});

  @override
  _VideoScreenState createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> with WidgetsBindingObserver {
  final SocketService _socketService = SocketService();

  // Changed from VlcPlayerController to VideoPlayerController
  VideoPlayerController? _controller;
  bool _controlsVisible = true;
  late Timer _hideControlsTimer;
  Duration _totalDuration = Duration.zero;
  Duration _currentPosition = Duration.zero;
  bool _isBuffering = false;
  bool _isConnected = true;
  bool _isVideoInitialized = false;
  Timer? _connectivityCheckTimer;
  int _focusedIndex = 0;
  bool _isFocused = false;
  List<FocusNode> focusNodes = [];
  late ScrollController _scrollController;
  final FocusNode _channelListFocusNode = FocusNode();
  final FocusNode screenFocusNode = FocusNode();
  final FocusNode playPauseButtonFocusNode = FocusNode();
  final FocusNode progressIndicatorFocusNode = FocusNode();
  final FocusNode forwardButtonFocusNode = FocusNode();
  final FocusNode backwardButtonFocusNode = FocusNode();
  final FocusNode nextButtonFocusNode = FocusNode();
  final FocusNode prevButtonFocusNode = FocusNode();
  double _progress = 0.0;
  double _currentVolume = 0.00; // Initialize with default volume (50%)
  double _bufferedProgress = 0.0;
  bool _isVolumeIndicatorVisible = false;
  Timer? _volumeIndicatorTimer;
  static const platform = MethodChannel('com.example.volume');
  bool _loadingVisible = false;
  Duration _lastKnownPosition = Duration.zero;
  Duration _resumePositionOnNetDisconnection = Duration.zero;
  bool _wasPlayingBeforeDisconnection = false;
  int _maxRetries = 3;
  int _retryDelay = 5; // seconds
  Timer? _networkCheckTimer;
  bool _wasDisconnected = false;
  String? _currentModifiedUrl; // To store the current modified URL

  Map<String, Uint8List> _imageCache = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);

    _previewPosition = _controller?.value.position ?? Duration.zero;
    Timer.periodic(Duration(minutes: 5), (timer) {
      if (mounted) {
        // Speed control is different in video_player
        _controller?.setPlaybackSpeed(1.0);
      } else {
        timer.cancel();
      }
    });
    KeepScreenOn.turnOn();
    _initializeVolume();
    _listenToVolumeChanges();
    // Initialize banner cache
    _loadStoredBanners().then((_) {
      // Store current banners after loading cached ones
      _storeBannersLocally();
    });
    // Match channel by ID as strings
    if (widget.isBannerSlider || widget.source == 'isLastPlayedVideos') {
      _focusedIndex = widget.channelList.indexWhere(
        (channel) =>
            channel.contentId.toString() ==
            (isOnItemTapUsed ? GlobalVariables.slectedId : widget.videoId)
                .toString(),
      );
    } 
    else if (widget.isVOD || widget.source == 'isLiveScreen'  ) {
      _focusedIndex = widget.channelList.indexWhere(
        (channel) =>
            channel.id.toString() ==
            (isOnItemTapUsed ? GlobalVariables.slectedId : widget.videoId)
                .toString(),
      );
    } 
    else if ( widget.source == 'webseries_details_page' ) {
      
      _focusedIndex = widget.channelList.indexWhere(
        (channel) =>
            channel.id.toString() ==
            (isOnItemTapUsed ? GlobalVariables.slectedId : widget.videoId)
                .toString(),
      );
    // } 

// // Update the initState focus index detection:
//     if (widget.source == 'webseries_details_page') {
//       _focusedIndex = widget.channelList.indexWhere(
//         (channel) => channel.id.toString() == widget.videoId.toString(),
//       );
//       // if (_focusedIndex == -1) {
//       //   _focusedIndex = widget.channelList.indexWhere(
//       //     (channel) =>
//       //         channel.contentId.toString() == widget.videoId.toString(),
//       //   );
//       // }
    }
     else {
      _focusedIndex = widget.channelList.indexWhere(
        (channel) => channel.url == widget.videoUrl,
      );
    }

    // Default to 0 if no match is found
    _focusedIndex = (_focusedIndex >= 0) ? _focusedIndex : 0;

    // Initialize focus nodes
    focusNodes = List.generate(
      widget.channelList.length,
      (index) => FocusNode(),
    );
    // Set initial focus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setInitialFocus();
    });
    _initializeVideoController(_focusedIndex);
    _startHideControlsTimer();
    _startNetworkMonitor();
    _startPositionUpdater();
  }

  @override
  void dispose() {
    _saveLastPlayedVideoBeforeDispose();

    _controller?.pause();
    _controller?.dispose();
    _scrollController.dispose();

    _controller?.removeListener(() {});

    _connectivityCheckTimer?.cancel();
    _hideControlsTimer.cancel();
    _volumeIndicatorTimer?.cancel(); // Cancel the volume timer if running
    // Clean up FocusNodes
    screenFocusNode.dispose();
    _channelListFocusNode.dispose();
    _scrollController.dispose();
    focusNodes.forEach((node) => node.dispose());
    progressIndicatorFocusNode.dispose();
    playPauseButtonFocusNode.dispose();
    backwardButtonFocusNode.dispose();
    forwardButtonFocusNode.dispose();
    nextButtonFocusNode.dispose();
    prevButtonFocusNode.dispose();

    // Dispose of socket service if necessary
    try {
      _socketService.dispose();
    } catch (e) {
      print("Error disposing socket service: $e");
    }

    // Ensure screen-on feature is turned off
    KeepScreenOn.turnOff();

    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  bool get isControllerReady {
    return _controller != null && _controller!.value.isInitialized;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller != null && _controller!.value.isInitialized) {
      if (state == AppLifecycleState.paused ||
          state == AppLifecycleState.inactive) {
        _controller!.pause(); // 🔹 App background mein jaane par pause
        print("✅ App background mein gaya, video paused.");
      } else if (state == AppLifecycleState.resumed) {
        _controller!.play(); // 🔹 App wapas foreground mein aane par resume
        print("✅ App foreground mein aaya, video resumed.");
      }
    }
  }

  bool isSave = false;
  Future<void> _saveLastPlayedVideoBeforeDispose() async {
    try {
      if (_controller != null && _controller!.value.isInitialized) {
        final position = _controller!.value.position;
        final duration = _controller!.value.duration;

        // Ensure valid position and duration
        if (isOnItemTapUsed) {
          await _saveLastPlayedVideo(
            GlobalVariables.unUpdatedUrl,
            GlobalVariables.position,
            GlobalVariables.duration,
            GlobalVariables.banner,
            GlobalVariables.name,
            GlobalVariables.liveStatus,
          );
          print("Video saved successfully before dispose");
        } else if (!isOnItemTapUsed) {
          await _saveLastPlayedVideo(
            widget.unUpdatedUrl,
            position,
            duration,
            widget.bannerImageUrl,
            widget.name,
            widget.liveStatus,
          );
        }
      }
      setState(() {});
    } catch (e) {
      print("Error saving video before dispose: $e");
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      // _fetchData();
    }
  }

  void _scrollToFocusedItem() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients || _focusedIndex < 0) {
        print('ScrollController not ready or invalid index.');
        return;
      }

      double itemHeight = screenhgt * 0.18; // Change if needed
      const double viewportPadding = 16.0; // Adjust scrolling behavior

      final double targetOffset =
          _focusedIndex * (itemHeight + viewportPadding);
      final double maxScroll = _scrollController.position.maxScrollExtent;
      final double safeOffset = targetOffset.clamp(0, maxScroll);

      print("Scrolling to offset: $safeOffset");

      _scrollController.animateTo(
        safeOffset,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
      );
    });
    setState(() {});
  }

  // Add this to your existing Map
  Map<String, Uint8List> _bannerCache = {};

  // Add this method to store banners in SharedPreferences
  Future<void> _storeBannersLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String storageKey =
          'channel_banners_${widget.videoId ?? ''}_${widget.source}';

      Map<String, String> bannerMap = {};

      // Store each banner
      for (var channel in widget.channelList) {
        if (channel.banner != null && channel.banner!.isNotEmpty) {
          String bannerId =
              channel.id?.toString() ?? channel.contentId?.toString() ?? '';
          if (bannerId.isNotEmpty) {
            // If it's already a base64 string
            if (channel.banner!.startsWith('data:image')) {
              bannerMap[bannerId] = channel.banner!;
            } else {
              // If it's a URL, we'll store it as is
              bannerMap[bannerId] = channel.banner!;
            }
          }
        }
      }

      // Store the banner map as JSON
      await prefs.setString(storageKey, jsonEncode(bannerMap));

      // Store timestamp
      await prefs.setInt(
          '${storageKey}_timestamp', DateTime.now().millisecondsSinceEpoch);

      print('Banners stored successfully');
    } catch (e) {
      print('Error storing banners: $e');
    }
  }

  // Add this method to load banners from SharedPreferences
  Future<void> _loadStoredBanners() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String storageKey =
          'channel_banners_${widget.videoId ?? ''}_${widget.source}';

      // Check cache age
      final timestamp = prefs.getInt('${storageKey}_timestamp');
      if (timestamp != null) {
        // Cache expires after 24 hours
        if (DateTime.now().millisecondsSinceEpoch - timestamp > 86400000) {
          await prefs.remove(storageKey);
          await prefs.remove('${storageKey}_timestamp');
          return;
        }
      }

      String? storedData = prefs.getString(storageKey);
      if (storedData != null) {
        Map<String, dynamic> bannerMap = jsonDecode(storedData);

        // Load into memory cache
        bannerMap.forEach((id, bannerData) {
          if (bannerData.startsWith('data:image')) {
            _bannerCache[id] = _getCachedImage(bannerData);
          }
        });

        print('Banners loaded successfully');
      }
    } catch (e) {
      print('Error loading banners: $e');
    }
  }

  // Modify your existing _getCachedImage method
  Uint8List _getCachedImage(String base64String) {
    try {
      if (!_bannerCache.containsKey(base64String)) {
        _bannerCache[base64String] = base64Decode(base64String.split(',').last);
      }
      return _bannerCache[base64String]!;
    } catch (e) {
      print('Error processing image: $e');
      // Return a 1x1 transparent pixel as fallback
      return Uint8List.fromList([0, 0, 0, 0]);
    }
  }

  // void _setInitialFocus() {
  //   if (widget.channelList.isEmpty) {
  //     print('Channel list is empty, focusing on Play/Pause button');
  //     _safelyRequestFocus(playPauseButtonFocusNode);
  //     return;
  //   }

  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     print('Setting initial focus to index: $_focusedIndex');
  //     _safelyRequestFocus(focusNodes[_focusedIndex]);
  //     _scrollToFocusedItem();
  //   });
  // }

  void _setInitialFocus() {
    if (widget.channelList.isEmpty || _focusedIndex < 0) {
      _safelyRequestFocus(playPauseButtonFocusNode);
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🔰 Setting focus to index $_focusedIndex');
      if (_focusedIndex < focusNodes.length) {
        _safelyRequestFocus(focusNodes[_focusedIndex]);
        _scrollToFocusedItem();
      } else {
        print(
            "⚠️ _focusedIndex out of bounds: $_focusedIndex vs ${focusNodes.length}");
      }
    });
  }

  bool _isReconnecting = false;
  bool _shouldDisposeController = false;

  // Future<void> _onNetworkReconnected() async {
  //   if (_isReconnecting) return;
  //   _isReconnecting = true;

  //   try {
  //     print("🌐 Network reconnected, resuming playback...");

  //     bool isConnected = await _isInternetAvailable();
  //     if (!isConnected) {
  //       print("⚠️ Network not stable yet. Retrying...");
  //       return;
  //     }

  //     String url =
  //         isOnItemTapUsed ? GlobalVariables.UpdatedUrl : widget.videoUrl;

  //     await _controller?.pause();
  //     await _controller?.dispose();
  //     _controller = null;

  //     if (_controller == null) {
  //       if (GlobalVariables.liveStatus == true) {
  //         _controller = VideoPlayerController.networkUrl(Uri.parse(url));
  //       } else {
  //         _controller = VideoPlayerController.networkUrl(Uri.parse(url)); // VOD
  //         await _seekToPositionOnNetReconnect(
  //             _resumePositionOnNetDisconnection);
  //       }

  //       await _controller!.initialize();

  //       _controller!.play();
  //     }
  //   } catch (e) {
  //     print("❌ Error during reconnection: $e");
  //   } finally {
  //     _isReconnecting = false;
  //   }
  // }

// Helper method to set up all the listeners
  // void _setupVideoPlayerListeners() {
  //   _controller!.addListener(() {
  //     // Copy your entire existing listener code here
  //     if (!mounted) return;

  //     // Update buffering state
  //     if (_controller!.value.isBuffering) {
  //       _isBuffering = true;
  //     } else {
  //       _isBuffering = false;
  //     }

  //     // Update progress values
  //     if (_controller!.value.duration.inMilliseconds > 0) {
  //       _progress = _controller!.value.position.inMilliseconds /
  //           _controller!.value.duration.inMilliseconds;
  //     }

  //     // Handle errors
  //     if (_controller!.value.hasError) {
  //       print("⚠️ VideoPlayer error: ${_controller!.value.errorDescription}");
  //       // Error handling code
  //     }

  //     // Rest of your existing listener code
  //   });
  // }

// Improved internet connectivity check
  Future<bool> _isInternetAvailable() async {
    try {
      final List<InternetAddress> result =
          await InternetAddress.lookup('google.com')
              .timeout(Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } on TimeoutException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

// Add this variable to track reconnection attempts
  int _reconnectionAttempts = 0;
  final int _maxReconnectionAttempts = 3;

// Replace your existing _startNetworkMonitor method with this improved version
  void _startNetworkMonitor() {
    _networkCheckTimer = Timer.periodic(Duration(seconds: 5), (_) async {
      if (!mounted) return;

      bool isConnected = await _isInternetAvailable();

      if (!isConnected && !_wasDisconnected) {
        // Just disconnected
        setState(() {
          _wasDisconnected = true;
          _lastDisconnectTime = DateTime.now();
        });

        // Save current position for later
        _resumePositionOnNetDisconnection =
            _controller?.value.position ?? Duration.zero;
        _wasPlayingBeforeDisconnection = _controller?.value.isPlaying ?? false;

        print(
            "📡 Network disconnected at ${_lastDisconnectTime}. Position: ${_formatDuration(_resumePositionOnNetDisconnection)}");

        // Pause video on disconnect
        if (_controller != null && _controller!.value.isInitialized) {
          _controller?.pause();
        }

        // Show user feedback about disconnection
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Network disconnected. Waiting to reconnect..."),
              backgroundColor: Colors.red,
              duration:
                  Duration(seconds: -1), // Infinite duration until dismissed
            ),
          );
        }
      } else if (isConnected && _wasDisconnected) {
        // Just reconnected
        print(
            "🌐 Network reconnected. Preparing to navigate to reconnection screen...");

        // Clear any existing snackbar
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        }

        setState(() {
          _wasDisconnected = false;
        });

        // Add a delay to ensure network stability before attempting reconnection
        if (!_isReconnecting && mounted) {
          _isReconnecting = true;

          // Add a bit more delay to ensure stability
          await Future.delayed(Duration(seconds: 3));

          if (mounted) {
            // Force navigation to the reconnection animation
            // _handleNetworkReconnection();
            _controller!.play();
          }

          _isReconnecting = false;
        }
      }
    });
  }

// Add this variable to track disconnect time
  DateTime _lastDisconnectTime = DateTime.now();

  void _startPositionUpdater() {
    Timer.periodic(Duration(seconds: 3), (_) {
      if (mounted && _controller?.value.isInitialized == true) {
        setState(() {
          _lastKnownPosition = _controller!.value.position;
          if (_controller!.value.duration > Duration.zero) {
            _progress = _lastKnownPosition.inMilliseconds /
                _controller!.value.duration.inMilliseconds;
          }
        });
      }
    });
  }

  bool urlUpdating = false;

  String extractApiEndpoint(String url) {
    try {
      Uri uri = Uri.parse(url);
      // Get the scheme, host, and path to form the API endpoint
      String apiEndpoint = '${uri.scheme}://${uri.host}${uri.path}';
      return apiEndpoint;
    } catch (e) {
      print("Error parsing URL: $e");
      return '';
    }
  }

  bool _isSeekingOnNetReconnect = false; // Flag to track seek state

  Future<void> _seekToPositionOnNetReconnect(Duration position) async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (_isSeekingOnNetReconnect) return; // Prevent multiple seek calls

    _isSeekingOnNetReconnect = true;
    try {
      print("⏩ Seeking to position after reconnection: $position");

      if (_controller!.value.position != position) {
        bool wasPlaying = _controller!.value.isPlaying;
        if (wasPlaying) await _controller!.pause();

        await _controller!.seekTo(position);

        if (wasPlaying) await _controller!.play();
      }
    } catch (e) {
      print("❌ Error during seek after reconnection: $e");
    } finally {
      await Future.delayed(Duration(milliseconds: 100));
      _isSeekingOnNetReconnect = false;
    }
  }

  bool _isSeeking = false; // Flag to track seek state

  Future<void> _seekToPosition(Duration position) async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (_isSeeking) return; // Prevent multiple seek calls

    _isSeeking = true;
    try {
      print("Seeking to position: $position");

      if (_controller!.value.position != position) {
        // Pehle pause karein taaki seek fast ho
        bool wasPlaying = _controller!.value.isPlaying;
        if (wasPlaying) await _controller!.pause();

        // Seek karein
        await _controller!.seekTo(position);

        // Agar pehle playing tha to dobara play karein
        if (wasPlaying) await _controller!.play();
      }
    } catch (e) {
      print("Error during seek: $e");
    } finally {
      await Future.delayed(Duration(milliseconds: 100));
      _isSeeking = false;
    }
  }

  // for ontap
  bool _isSeekingOntap = false; // Flag to track seek state

  Future<void> _seekToPositionOntap(Duration position) async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (_isSeekingOntap) return; // Prevent multiple seek calls

    _isSeekingOntap = true;
    try {
      print("Seeking to position: $position");

      if (_controller!.value.position != position) {
        // Pehle pause karein taaki seek fast ho
        bool wasPlaying = _controller!.value.isPlaying;
        if (wasPlaying) await _controller!.pause();

        // Seek karein
        await _controller!.seekTo(position);

        // Agar pehle playing tha to dobara play karein
        if (wasPlaying) await _controller!.play();
      }
    } catch (e) {
      print("Error during seek: $e");
    } finally {
      await Future.delayed(Duration(milliseconds: 100));
      _isSeekingOntap = false;
    }
  }

  // Add these variables to class
  int _bufferingRetryCount = 0;
  DateTime? _bufferingStartTime;
  Timer? _bufferingTimer;

  bool _hasSeeked = false;

  Future<void> _initializeVideoController(int index) async {
    if (_controller != null) {
      await _controller!.dispose();
      _controller = null;
    }

    setState(() {
      _hasSeeked = false;
    });

    // VideoPlayerController does not need the caching parameters that VLC used
    String videoUrl = widget.videoUrl;

    // Initialize the controller
    if (_controller == null) {
      _controller = VideoPlayerController.network(
        videoUrl,
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: false,
        ),
        httpHeaders: {
          'Range': 'bytes=0-8000000', // लगभग 8MB का initial chunk मांगें
          'Connection': 'keep-alive', // Connection को open रखें
        },
      );

      try {
        try {
          await _controller!.initialize();
          print("✅ Video initialized successfully");
        } catch (initError) {
          print("❌ Video initialization error: $initError");
          print("❌ URL that failed: $videoUrl");
          // Try to provide more context about the error
          if (initError.toString().contains("404")) {
            print("❌ The video URL returned a 404 Not Found error");
          } else if (initError.toString().contains("403")) {
            print("❌ The video URL returned a 403 Forbidden error");
          }
          // Rethrow to be caught by the outer try-catch
          rethrow;
        }

        await _controller!.play();

        _controller!.addListener(() async {
          // Handle position seeking for non-live videos
          if (_controller!.value.isInitialized &&
              _controller!.value.duration > Duration.zero &&
              !_isSeeking &&
              !_hasSeeked &&
              !widget.liveStatus &&
              widget.source == 'isLastPlayedVideos') {
            if (widget.startAtPosition > Duration.zero &&
                widget.startAtPosition > _controller!.value.position) {
              if (widget.startAtPosition <= _controller!.value.position) {
                print("Video already at the desired position, skipping seek.");
                _isSeeking = true;
                _hasSeeked = true;
                return;
              }
              await _seekToPosition(widget.startAtPosition);
              _isSeeking = true;
              _hasSeeked = true;
            }
          }
          _isSeeking = false;

          // Update loading indicators
          if (_controller!.value.position <= Duration.zero) {
            _loadingVisible = true;
          } else if (_controller!.value.position > Duration.zero) {
            _loadingVisible = false;
          }
          if (_controller!.value.isBuffering) {
            _isBuffering = true;
          } else {
            _isBuffering = false;
          }

          // Auto-play next for VOD content
          if (widget.isVOD &&
              (_controller!.value.position > Duration.zero) &&
              (_controller!.value.duration > Duration.zero) &&
              (_controller!.value.duration - _controller!.value.position <=
                  Duration(seconds: 5)) &&
              (!widget.channelList.isEmpty || widget.channelList.length != 1)) {
            print("Video is about to end. Playing next...");
            _playNext(); // Automatically play next video
          }
        });

        setState(() {
          _isVideoInitialized = true;
          _currentModifiedUrl = videoUrl;
        });
      } catch (initError) {
        print("❌ Video initialization error: $initError");
        print("❌ URL that failed: $videoUrl");

        // Important: Don't rethrow the error - handle it gracefully
        // Instead of crashing, attempt to play the next video
        if (widget.channelList.length > 1) {
          print(
              "🔄 Initialization error detected, attempting to play next video...");

          // We need to set _controller to null so that we can reinitialize it
          _controller = null;

          // Use Future.delayed to ensure this happens after the current method completes
          Future.delayed(Duration(milliseconds: 5), () {
            if (mounted && !widget.channelList.isEmpty ||
                widget.channelList.length != 1) {
              _playNext();
            }
          });
        } else {
          print(
              "⚠️ Cannot play next video - this is the only video in the list");
          // Show error message to user
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Something went wrong."),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      }
    }
  }

  Future<void> _retryPlayback(String url, int retries) async {
    for (int i = 0; i < retries; i++) {
      if (!mounted || _controller == null || !_controller!.value.isInitialized)
        return;

      try {
        // We need to create a new controller for retry
        await _controller!.dispose();
        _controller = VideoPlayerController.network(url);
        await _controller!.initialize();
        await _controller!.play();
        return; // Exit on success
      } catch (e) {
        print("Retry ${i + 1} failed: $e");
        await Future.delayed(Duration(seconds: 1));
      }
    }
    print("All retries failed for URL: $url");
  }

  bool isYoutubeUrl(String? url) {
    if (url == null || url.isEmpty) {
      return false;
    }

    url = url.toLowerCase().trim();

    // First check if it's a YouTube ID (exactly 11 characters)
    bool isYoutubeId = RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(url);
    if (isYoutubeId) {
      print("Matched YouTube ID pattern: $url");
      return true;
    }

    // Then check for regular YouTube URLs
    bool isYoutubeUrl = url.contains('youtube.com') ||
        url.contains('youtu.be') ||
        url.contains('youtube.com/shorts/');
    if (isYoutubeUrl) {
      print("Matched YouTube URL pattern: $url");
      return true;
    }

    print("Not a YouTube URL/ID: $url");
    return false;
  }

  String formatUrl(String url, {Map<String, String>? params}) {
    if (url.isEmpty) {
      print("Warning: Empty URL provided");
      throw Exception("Empty URL provided");
    }

    // Handle YouTube ID by converting to full URL if needed
    if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(url)) {
      print("Converting YouTube ID to full URL");
      url = "https://www.youtube.com/watch?v=$url";
    }

    // Remove any existing query parameters
    url = url.split('?')[0];

    // Add new query parameters
    if (params != null && params.isNotEmpty) {
      url += '?' + params.entries.map((e) => '${e.key}=${e.value}').join('&');
    }

    print("Formatted URL: $url");
    return url;
  }

  bool isOnItemTapUsed = false;
  bool _hasSeekedOntap = false;

  // Future<void> _onItemTap(int index) async {
  //   setState(() {
  //     isOnItemTapUsed = true;
  //     _hasSeekedOntap = false;
  //   });
  //   var selectedChannel = widget.channelList[index];
  //   String updatedUrl = selectedChannel.url;

  //   try {
  //     if (widget.source == 'isLastPlayedVideos') {
  //       // For last played videos, just use the URL from the channel list directly
  //       updatedUrl = widget.channelList[index].url;

  //       // Check if it's a YouTube URL
  //       if (isYoutubeUrl(updatedUrl)) {
  //         print("Processing YouTube URL from last played videos");
  //         updatedUrl = await _socketService.getUpdatedUrl(updatedUrl);
  //       }
  //     } else {
  //       final int contentId = int.tryParse(selectedChannel.id) ?? 0;

  //       String apiEndpoint = extractApiEndpoint(updatedUrl);
  //       print("API Endpoint onitemtap: $updatedUrl");

  //       // if (widget.source == 'isHomeCategory') {
  //       //   final playLink = await fetchLiveFeaturedTVById(selecte

  //       // Continuing from previous part
  //       if (widget.source == 'isHomeCategory') {
  //         final playLink = await fetchLiveFeaturedTVById(selectedChannel.id);
  //         if (playLink['url'] != null && playLink['url']!.isNotEmpty) {
  //           updatedUrl = playLink['url']!;
  //         }
  //       }

  //       if (widget.isBannerSlider) {
  //         final playLink =
  //             await fetchLiveFeaturedTVById(selectedChannel.contentId);
  //         if (playLink['url'] != null && playLink['url']!.isNotEmpty) {
  //           updatedUrl = playLink['url']!;
  //         }
  //       }

  //       if (selectedChannel.contentType == '1' ||
  //           selectedChannel.contentType == 1 &&
  //               widget.source == 'isSearchScreen') {
  //         final playLink = await fetchMoviePlayLink(contentId);
  //         print('hello isSearchScreen$playLink');
  //         if (playLink['url'] != null && playLink['url']!.isNotEmpty) {
  //           updatedUrl = playLink['url']!;
  //         }
  //       }

  //       if (widget.isVOD ||
  //           widget.source == 'isSearchScreenViaDetailsPageChannelList') {
  //         print('hello isVOD');
  //         if (selectedChannel.contentType == '1' ||
  //             selectedChannel.contentType == 1) {
  //           final playLink = await fetchMoviePlayLink(contentId);
  //           print('hello isVOD$playLink');
  //           if (playLink['url'] != null && playLink['url']!.isNotEmpty) {
  //             updatedUrl = playLink['url']!;
  //           }
  //         }
  //       }
  //     }

  //     GlobalVariables.unUpdatedUrl = updatedUrl;
  //     GlobalVariables.position = _controller!.value.position;
  //     GlobalVariables.duration = _controller!.value.duration;
  //     GlobalVariables.banner = selectedChannel.banner ?? '';
  //     GlobalVariables.name = selectedChannel.name ?? '';
  //     GlobalVariables.slectedId = selectedChannel.id ?? '';

  //     if (selectedChannel.streamType == 'YoutubeLive' ||
  //         selectedChannel.contentType == '1' ||
  //         selectedChannel.contentType == 1) {
  //       setState(() {
  //         GlobalVariables.liveStatus = false;
  //       });
  //     } else {
  //       setState(() {
  //         GlobalVariables.liveStatus = true;
  //       });
  //     }

  //     // Now process YouTube URL if needed
  //     if (isYoutubeUrl(updatedUrl)) {
  //       print("Processing as YouTube content");
  //       updatedUrl = await _socketService.getUpdatedUrl(updatedUrl);
  //       print("Socket service returned URL: $updatedUrl");
  //     }

  //     String apiEndpoint1 = extractApiEndpoint(updatedUrl);
  //     print("API Endpoint onitemtap1: $apiEndpoint1");

  //     // video_player doesn't need the caching parameters
  //     GlobalVariables.UpdatedUrl = updatedUrl;

  //     if (_controller != null && _controller!.value.isInitialized) {
  //       // For video_player, we need to dispose and create a new controller
  //       await _controller!.dispose();
  //       _controller = VideoPlayerController.network(updatedUrl);

  //       await _controller!.initialize();

  //       await _controller!.play();

  //       _controller!.addListener(() async {
  //         if (_controller!.value.isInitialized &&
  //             _controller!.value.duration > Duration.zero &&
  //             !_isSeekingOntap &&
  //             !_hasSeekedOntap &&
  //             !selectedChannel.liveStatus &&
  //             widget.source == 'isLastPlayedVideos') {
  //           if (selectedChannel.position > Duration.zero &&
  //               selectedChannel.position > _controller!.value.position &&
  //               _controller!.value.position > Duration.zero) {
  //             if (selectedChannel.position <= _controller!.value.position) {
  //               print("Video already at the desired position, skipping seek.");
  //               _isSeekingOntap = true;
  //               _hasSeekedOntap = true;
  //               return;
  //             }

  //             print("🔹 Channel liveStatus: ${selectedChannel.liveStatus}");
  //             await _seekToPositionOntap(selectedChannel.position);
  //             _isSeekingOntap = true;
  //             _hasSeekedOntap = true;
  //           }
  //         }
  //         _isSeekingOntap = false;
  //         if (_controller!.value.position <= Duration.zero) {
  //           _loadingVisible = true;
  //         } else if (_controller!.value.position > Duration.zero) {
  //           _loadingVisible = false;
  //         }

  //         // Auto-play next for VOD content
  //         if (widget.isVOD &&
  //             (_controller!.value.position > Duration.zero) &&
  //             (_controller!.value.duration > Duration.zero) &&
  //             (_controller!.value.duration - _controller!.value.position <=
  //                 Duration(seconds: 5))) {
  //           print("Video is about to end. Playing next...");
  //           _playNext();
  //         }
  //       });

  //       setState(() {
  //         _focusedIndex = index;
  //       });
  //     } else {
  //       throw Exception("Video Controller is not initialized");
  //     }

  //     setState(() {
  //       _focusedIndex = index;
  //       _currentModifiedUrl = updatedUrl;
  //     });

  //     _scrollToFocusedItem();
  //     _resetHideControlsTimer();
  //   } catch (e) {
  //     print("Error switching channel: $e");
  //   } finally {
  //     setState(() {
  //       // Loading handling done through controller listener
  //     });
  //   }
  // }

  // Update your _onItemTap method to handle potential null values:

  Future<void> _onItemTap(int index) async {
    if (index < 0 || index >= widget.channelList.length) {
      print("⚠️ अमान्य इंडेक्स: $index");
      return;
    }

    setState(() {
      isOnItemTapUsed = true;
      _hasSeekedOntap = false;
      _isVideoInitialized = false; // रिसेट करें ताकि लोडिंग इंडिकेटर दिखे
      _loadingVisible = true; // लोडिंग इंडिकेटर को सक्रिय करें
    });

    var selectedChannel = widget.channelList[index];
    String updatedUrl = selectedChannel.url ?? '';

    try {
      if (widget.source == 'isLastPlayedVideos') {
        // For last played videos, just use the URL from the channel list directly
        updatedUrl = widget.channelList[index].url;

        // Check if it's a YouTube URL
        if (isYoutubeUrl(updatedUrl)) {
          print("Processing YouTube URL from last played videos");
          updatedUrl = await _socketService.getUpdatedUrl(updatedUrl);
        }
      } else {
        final int contentId = int.tryParse(selectedChannel.id) ?? 0;

        String apiEndpoint = extractApiEndpoint(updatedUrl);
        print("API Endpoint onitemtap: $updatedUrl");

        // if (widget.source == 'isHomeCategory') {
        //   final playLink = await fetchLiveFeaturedTVById(selecte

        // Continuing from previous part
        if (widget.source == 'isHomeCategory') {
          final playLink = await fetchLiveFeaturedTVById(selectedChannel.id);
          if (playLink['url'] != null && playLink['url']!.isNotEmpty) {
            updatedUrl = playLink['url']!;
          }
        }

        if (widget.isBannerSlider) {
          final playLink =
              await fetchLiveFeaturedTVById(selectedChannel.contentId);
          if (playLink['url'] != null && playLink['url']!.isNotEmpty) {
            updatedUrl = playLink['url']!;
          }
        }

        if (selectedChannel.contentType == '1' ||
            selectedChannel.contentType == 1 &&
                widget.source == 'isSearchScreen') {
          final playLink = await fetchMoviePlayLink(contentId);
          print('hello isSearchScreen$playLink');
          if (playLink['url'] != null && playLink['url']!.isNotEmpty) {
            updatedUrl = playLink['url']!;
          }
        }

        if (
            // selectedChannel.contentType == '1' ||
            // selectedChannel.contentType == 1 &&
            widget.source == 'manage_movies') {
          final playLink = await fetchMoviePlayLink(contentId);
          print('hello isSearchScreen$playLink');
          if (playLink['url'] != null && playLink['url']!.isNotEmpty) {
            updatedUrl = playLink['url']!;
          }
        }

        if (widget.isVOD ||
            widget.source == 'isSearchScreenViaDetailsPageChannelList') {
          print('hello isVOD');
          if (selectedChannel.contentType == '1' ||
              selectedChannel.contentType == 1) {
            final playLink = await fetchMoviePlayLink(contentId);
            print('hello isVOD$playLink');
            if (playLink['url'] != null && playLink['url']!.isNotEmpty) {
              updatedUrl = playLink['url']!;
            }
          }
        }
        if (widget.source == 'webseries_details_page') {
          final playLink =
              await fetchEpisodeUrlById(selectedChannel.contentId.toString());

          if (playLink != null && playLink.isNotEmpty) {
            updatedUrl = playLink;
          } else {
            return;
          }
        }
      }

      // GlobalVariables अपडेट करें
      GlobalVariables.unUpdatedUrl = updatedUrl;
      GlobalVariables.position = _controller?.value.position ?? Duration.zero;
      GlobalVariables.duration = _controller?.value.duration ?? Duration.zero;
      GlobalVariables.banner = selectedChannel.banner ?? '';
      GlobalVariables.name = selectedChannel.name ?? '';
      GlobalVariables.slectedId = selectedChannel.id ?? '';

      // Live स्टेटस अपडेट करें
      if (selectedChannel.streamType == 'YoutubeLive' ||
          selectedChannel.contentType == '1' ||
          selectedChannel.contentType == 1) {
        setState(() {
          GlobalVariables.liveStatus = false;
        });
      } else {
        setState(() {
          GlobalVariables.liveStatus = true;
        });
      }

      // YouTube URL प्रोसेसिंग
      if (isYoutubeUrl(updatedUrl)) {
        print("YT url processing");
        try {
          updatedUrl = await _socketService.getUpdatedUrl(updatedUrl);
        } catch (e) {
          print("YT URL processing errror: $e");
        }
      }

      GlobalVariables.UpdatedUrl = updatedUrl;

      // पुराने कंट्रोलर को सही से डिस्पोज़ करें
      if (_controller != null) {
        try {
          await _controller!.pause();
          await _controller!.dispose();
          _controller = null;
        } catch (e) {
          print("old contoller disposed error: $e");
          _controller = null;
        }
      }

      // बेहतर एरर हैंडलिंग के साथ नया कंट्रोलर बनाएं
      bool videoInitialized = false;
      int retryCount = 0;
      const maxRetries = 2;

      while (!videoInitialized && retryCount < maxRetries) {
        try {
          _controller = VideoPlayerController.network(
            updatedUrl,
            videoPlayerOptions: VideoPlayerOptions(
              mixWithOthers: false,
            ),
            httpHeaders: {
              'Range': 'bytes=0-8000000',
              'Connection': 'keep-alive',
            },
          );

          // वीडियो इनिशियलाइज़ करने का टाइमआउट सेट करें
          await _controller!.initialize().timeout(Duration(seconds: 10),
              onTimeout: () {
            throw TimeoutException("video initialization timed out");
          });

          // वीडियो आकार की जांच करें
          if (_controller!.value.size.width <= 0 ||
              _controller!.value.size.height <= 0) {
            throw Exception("video size is invalid");
          }

          await _controller!.play();

          videoInitialized = true;

          _setupVideoPlayerListeners();

          setState(() {
            _isVideoInitialized = true;
            _loadingVisible = false;
            _focusedIndex = index;
            _currentModifiedUrl = updatedUrl;
          });

          break;
        } catch (e) {
          retryCount++;

          if (_controller != null) {
            await _controller!.dispose();
            _controller = null;
          }

          if (retryCount >= maxRetries) {
            if (index < widget.channelList.length - 1) {
              Future.delayed(Duration(milliseconds: 5), () {
                if (mounted && !widget.channelList.isEmpty ||
                    widget.channelList.length != 1) {
                  _onItemTap(index + 1);
                }
              });
              return;
            } else {
              // अगर यह आखिरी वीडियो है तो यूजर को बताएं
              // if (mounted) {
              //   ScaffoldMessenger.of(context).showSnackBar(
              //     SnackBar(
              //       content: Text("वीडियो चलाने में समस्या आई। बाद में पुनः प्रयास करें।"),
              //       backgroundColor: Colors.red,
              //       duration: Duration(seconds: 3),
              //     ),
              //   );
              // }
              return;
            }
          }

          // रीट्राई से पहले थोड़ा इंतज़ार करें
          await Future.delayed(Duration(milliseconds: 10));
        }
      }

      // UI अपडेट करें
      _scrollToFocusedItem();
      _resetHideControlsTimer();
    } catch (e) {
      print("चैनल स्विच करने में त्रुटि: $e");
      if (mounted) {
        setState(() {
          _loadingVisible = false;
        });
      }

      // अगले वीडियो पर जाने की कोशिश करें
      if (index < widget.channelList.length - 1) {
        Future.delayed(Duration(milliseconds: 500), () {
          if (mounted && !widget.channelList.isEmpty ||
              widget.channelList.length != 1) {
            _onItemTap(index + 1);
          }
        });
      }
    }
  }

  Future<String?> fetchEpisodeUrlById(String episodeId) async {
    const apiUrl = 'https://mobifreetv.com/android/getEpisodes/id/0';

    try {
      final response = await https.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        // Search for the matching episode by id
        final matchedEpisode = data.firstWhere(
          (item) => item['id'] == episodeId,
          orElse: () => null,
        );

        if (matchedEpisode != null && matchedEpisode['url'] != null) {
          return matchedEpisode['url'];
        }
      }
    } catch (e) {
      print('Error fetching episode URL: $e');
    }

    return null;
  }

// वीडियो प्लेयर लिसनर सेटअप के लिए एक अलग मेथड बनाएं
  void _setupVideoPlayerListeners() {
    if (_controller == null) return;

    _controller!.addListener(() {
      if (!mounted) return;

      // Error handling first
      if (_controller!.value.hasError) {
        print("⚠️ Video player error: ${_controller!.value.errorDescription}");
        _playNext(); // Try next video on error
        return;
      }

      // Update buffering state
      if (mounted) {
        setState(() {
          _isBuffering = _controller!.value.isBuffering;

          // If video is playing and position > 0, hide loading indicator
          if (_controller!.value.position > Duration.zero &&
              _controller!.value.isPlaying) {
            _loadingVisible = false;
          }

          // Update progress values
          if (_controller!.value.duration.inMilliseconds > 0) {
            _progress = _controller!.value.position.inMilliseconds /
                _controller!.value.duration.inMilliseconds;
          }
        });
      }
      // VOD कंटेंट के लिए ऑटो-प्ले नेक्स्ट
      if (widget.isVOD &&
          (_controller!.value.position > Duration.zero) &&
          (_controller!.value.duration > Duration.zero) &&
          (_controller!.value.duration - _controller!.value.position <=
              Duration(seconds: 5))) {
        print("वीडियो खत्म होने वाला है। अगला प्ले कर रहे हैं...");
        _playNext();
      }
    });
  }

  // Add this new method to safely handle focus changes
  void _safelyRequestFocus(FocusNode node) {
    if (!mounted || node == null || !node.canRequestFocus) return;

    try {
      // Delay focus slightly to allow UI to update first
      Future.delayed(Duration(milliseconds: 50), () {
        if (mounted && node.canRequestFocus) {
          FocusScope.of(context).requestFocus(node);
        }
      });
    } catch (e) {
      print("Error requesting focus: $e");
    }
  }

// Then replace direct focus calls with this method
// For example:
// Instead of: FocusScope.of(context).requestFocus(nextButtonFocusNode);
// Use: _safelyRequestFocus(nextButtonFocusNode);

// Also update your _playNext method to be more robust:

  // void _playNext() {
  //   if (widget.channelList.isEmpty || widget.channelList.length == 1) {
  //     print("⚠️ Channel list is empty, cannot play next");
  //     return;
  //   }

  //   if (_focusedIndex < widget.channelList.length - 1) {
  //     try {
  //       print("🔁 Playing next video at index: ${_focusedIndex + 1}");
  //       _onItemTap(_focusedIndex + 1);

  //       Future.delayed(Duration(milliseconds: 50), () {
  //         if (mounted) {
  //           _safelyRequestFocus(nextButtonFocusNode);
  //         }
  //       });
  //     } catch (e) {
  //       print("❌ Error in _playNext: $e");
  //       // If there's an error with this video too, try to move to the next one
  //       if (_focusedIndex + 2 < widget.channelList.length) {
  //         print("🔄 Attempting to skip to next+1 video");
  //         Future.delayed(Duration(milliseconds: 500), () {
  //           if (mounted ) {
  //             _onItemTap(_focusedIndex + 1);
  //           }
  //         });
  //       }
  //     }
  //   } else {
  //     print("⚠️ Already at the last video in the playlist");
  //     // Optional: loop back to the first video
  //     // _onItemTap(0);
  //   }
  // }

  void _playNext() async {
    if (widget.channelList.isEmpty || widget.channelList.length <= 1) {
      print("⚠️ Channel list is empty or has only one video, cannot play next");
      return;
    }

    int nextIndex = _focusedIndex + 1;

    if (nextIndex >= widget.channelList.length) {
      print("🔄 Last video reached, looping back to the first video");
      nextIndex = 0;
    }

    try {
      print("▶️ Playing next video at index: $nextIndex");

      // Ensure previous controller is safely disposed
      if (_controller != null) {
        await _controller!.pause();
        await _controller!.dispose();
        _controller = null;
        await Future.delayed(Duration(milliseconds: 100)); // give slight delay
      }

      // Reset necessary state before calling _onItemTap
      setState(() {
        _isVideoInitialized = false;
        _loadingVisible = true;
        _focusedIndex = nextIndex;
      });

      _onItemTap(nextIndex);

      Future.delayed(Duration(milliseconds: 50), () {
        if (mounted) {
          _safelyRequestFocus(nextButtonFocusNode);
        }
      });
    } catch (e) {
      print("❌ Error in _playNext: $e");
      // If there's an error, try the next video again after a slight delay
      if (nextIndex + 1 < widget.channelList.length) {
        Future.delayed(Duration(milliseconds: 500), () {
          if (mounted) {
            _playNext();
          }
        });
      }
    }
  }

//   void _playNext() {
//   if (widget.channelList.isEmpty) {
//     print("⚠️ Channel list is empty, cannot play next");
//     return;
//   }

//   // If there's only one video, don't call playNext
//   if (widget.channelList.length == 1) {
//     print("ℹ️ Only one video in the list, playNext will not be called.");
//     return;
//   }

//   int nextIndex = _focusedIndex + 1;

//   // Loop back if last video
//   if (nextIndex >= widget.channelList.length) {
//     print("🔄 Last video reached, looping back to the first video");
//     nextIndex = 0;
//   }

//   try {
//     print("▶️ Playing next video at index: $nextIndex");
//     _onItemTap(nextIndex);

//     Future.delayed(Duration(milliseconds: 50), () {
//       if (mounted) {
//         _safelyRequestFocus(nextButtonFocusNode);
//       }
//     });
//   } catch (e) {
//     print("❌ Error in _playNext: $e");
//     if (nextIndex + 1 < widget.channelList.length) {
//       Future.delayed(Duration(milliseconds: 500), () {
//         if (mounted) {
//           _onItemTap(nextIndex + 1);
//         }
//       });
//     }
//   }
// }

  Future<void> _initializeVolume() async {
    try {
      // Fetch volume from the platform
      final double volume = await platform.invokeMethod('getVolume');
      setState(() {
        _currentVolume = volume.clamp(0.0, 1.0); // Normalize and update volume
      });
      print("Initial Volume: $volume");
    } catch (e) {
      print("Error fetching initial volume: $e");
      setState(() {
        _currentVolume = 0.0; // Default to 50% in case of an error
      });
    }
  }

  void _listenToVolumeChanges() {
    platform.setMethodCallHandler((call) async {
      if (call.method == "volumeChanged") {
        double newVolume = call.arguments as double;
        setState(() {
          _currentVolume = newVolume.clamp(0.0, 1.0); // Normalize volume
          _isVolumeIndicatorVisible = true; // Show volume indicator
        });

        // Hide the volume indicator after 3 seconds
        _volumeIndicatorTimer?.cancel();
        _volumeIndicatorTimer = Timer(Duration(seconds: 3), () {
          setState(() {
            _isVolumeIndicatorVisible = false;
          });
        });
      }
    });
  }

  Future<double> getVolumeLevel() async {
    try {
      final double volume = await platform.invokeMethod('getVolume');
      return volume;
    } catch (e) {
      print("Error getting volume: $e");
      return 0.0; // Default to 50% if there's an error
    }
  }

  void _updateVolume() async {
    try {
      double newVolume = await platform.invokeMethod('getVolume');
      setState(() {
        _currentVolume = newVolume.clamp(0.0, 1.0); // Normalize the volume
        _isVolumeIndicatorVisible = true; // Show volume indicator
      });

      // Hide the volume indicator after 3 seconds
      _volumeIndicatorTimer?.cancel();
      _volumeIndicatorTimer = Timer(Duration(seconds: 3), () {
        setState(() {
          _isVolumeIndicatorVisible = false;
        });
      });
    } catch (e) {
      print("Error fetching volume: $e");
    }
  }

  // void _playNext() {
  //   if (_focusedIndex < widget.channelList.length - 1) {
  //     _onItemTap(_focusedIndex + 1);
  //     Future.delayed(Duration(milliseconds: 50), () {
  //       _safelyRequestFocus(nextButtonFocusNode);
  //     });
  //   }
  // }

  void _playPrevious() {
    if (_focusedIndex > 0) {
      _onItemTap(_focusedIndex - 1);
      Future.delayed(Duration(milliseconds: 50), () {
        _safelyRequestFocus(prevButtonFocusNode);
      });
    }
  }

  void _togglePlayPause() {
    if (isControllerReady) {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
    }

    Future.delayed(Duration(milliseconds: 50), () {
      _safelyRequestFocus(playPauseButtonFocusNode);
    });
    _resetHideControlsTimer();
  }

  void _resetHideControlsTimer() {
    // Set initial focus and scroll
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.channelList.isEmpty) {
        _safelyRequestFocus(playPauseButtonFocusNode);
      } else {
        _safelyRequestFocus(focusNodes[_focusedIndex]);
        _scrollToFocusedItem();
      }
    });
    _hideControlsTimer.cancel();
    setState(() {
      _controlsVisible = true;
    });
    _startHideControlsTimer();
  }

  void _startHideControlsTimer() {
    _hideControlsTimer = Timer(Duration(seconds: 10), () {
      setState(() {
        _controlsVisible = false;
      });
    });
  }

  Future<void> _saveLastPlayedVideo(
    String unUpdatedUrl,
    Duration position,
    Duration duration,
    String bannerImageUrl,
    String name,
    bool liveStatus,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> lastPlayedVideos =
          prefs.getStringList('last_played_videos') ?? [];

      // 🔹 Debugging: Print existing list before modification
      print("Existing lastPlayedVideos: $lastPlayedVideos");

      if (duration <= Duration(seconds: 5) &&
          position <= Duration(seconds: 5)) {
        print("Invalid duration or position. Skipping save.");
        return;
      }

      // 🔹 Check if video ID is valid
      String videoId = widget.videoId?.toString() ?? '';

      if (widget.channelList.isNotEmpty) {
        int index = widget.channelList.indexWhere((channel) =>
            channel.url == unUpdatedUrl ||
            channel.id == widget.videoId.toString());
        if (index != -1) {
          videoId = widget.channelList[index].id ?? '';
        }
      }

      // 🔹 Debugging: Check if video ID exists
      print("Video ID for saving: $videoId");

      // 🔹 Video entry format
      String newVideoEntry =
          "$unUpdatedUrl|${position.inMilliseconds}|${duration.inMilliseconds}|$liveStatus|$bannerImageUrl|$videoId|$name";

      print("Saving video: $newVideoEntry");

      // 🔹 Remove duplicate entries safely
      lastPlayedVideos.removeWhere((entry) {
        List<String> parts = entry.split('|');
        return parts.isNotEmpty &&
            (parts[0] == unUpdatedUrl ||
                parts.length > 4 && parts[4] == videoId);
      });

      // 🔹 Ensure list has elements before accessing indices
      if (lastPlayedVideos.isEmpty) {
        print("List was empty, adding first video.");
      }

      lastPlayedVideos.insert(0, newVideoEntry);

      // 🔹 Avoid RangeError by limiting size safely
      if (lastPlayedVideos.length > 25) {
        lastPlayedVideos =
            lastPlayedVideos.sublist(0, lastPlayedVideos.length.clamp(0, 25));
      }

      // 🔹 Save to SharedPreferences
      await prefs.setStringList('last_played_videos', lastPlayedVideos);
      await prefs.setInt('last_video_duration', duration.inMilliseconds);
      await prefs.setInt('last_video_position', position.inMilliseconds);

      print("Saved successfully: $lastPlayedVideos");
    } catch (e) {
      print("Error saving last played video: $e");
    }
  }

  int _accumulatedSeekForward = 0;
  int _accumulatedSeekBackward = 0;
  Timer? _seekTimer;
  Duration _previewPosition = Duration.zero;
  final _seekDuration = 10; // seconds
  final _seekDelay = 3000; // milliseconds

  // void _seekForward() {
  //   if (_controller == null || !_controller!.value.isInitialized) return;

  //   setState(() {
  //     // Accumulate seek duration
  //     _accumulatedSeekForward += _seekDuration;
  //     // Update preview position instantly
  //     _previewPosition = _controller!.value.position +
  //         Duration(seconds: _accumulatedSeekForward);
  //     // Ensure preview position does not exceed video duration
  //     if (_previewPosition > _controller!.value.duration) {
  //       _previewPosition = _controller!.value.duration;
  //     }
  //   });

  //   // Reset and start timer to execute seek after delay
  //   _seekTimer?.cancel();
  //   _seekTimer = Timer(Duration(milliseconds: _seekDelay), () {
  //     if (_controller != null) {
  //       _controller!.seekTo(_previewPosition);
  //       setState(() {
  //         _accumulatedSeekForward = 0; // Reset accumulator after seek
  //       });
  //     }

  //     // Update focus to forward button
  //     Future.delayed(Duration(milliseconds: 50), () {
  //       _safelyRequestFocus(forwardButtonFocusNode);
  //     });
  //   });
  // }

  // void _seekBackward() {
  //   if (_controller == null || !_controller!.value.isInitialized) return;

  //   setState(() {
  //     // Accumulate seek duration
  //     _accumulatedSeekBackward += _seekDuration;
  //     // Update preview position instantly
  //     final newPosition = _controller!.value.position -
  //         Duration(seconds: _accumulatedSeekBackward);
  //     // Ensure preview position does not go below zero
  //     _previewPosition =
  //         newPosition > Duration.zero ? newPosition : Duration.zero;
  //   });

  //   // Reset and start timer to execute seek after delay
  //   _seekTimer?.cancel();
  //   _seekTimer = Timer(Duration(milliseconds: _seekDelay), () {
  //     if (_controller != null) {
  //       _controller!.seekTo(_previewPosition);
  //       setState(() {
  //         _accumulatedSeekBackward = 0; // Reset accumulator after seek
  //       });
  //     }

  //     // Update focus to backward button
  //     Future.delayed(Duration(milliseconds: 50), () {
  //       _safelyRequestFocus(backwardButtonFocusNode);
  //     });
  //   });
  // }

  void _seekForward() {
    if (_controller == null || !_controller!.value.isInitialized) return;

    setState(() {
      // Accumulate seek duration
      _accumulatedSeekForward += _seekDuration;
      // Instantly update preview position for UI
      final newPreviewPosition = _controller!.value.position +
          Duration(seconds: _accumulatedSeekForward);
      _previewPosition = newPreviewPosition <= _controller!.value.duration
          ? newPreviewPosition
          : _controller!.value.duration;

      // Instantly reflect progress change
      _progress = _previewPosition.inMilliseconds /
          _controller!.value.duration.inMilliseconds;
    });

    // Reset and start timer to execute seek after delay
    _seekTimer?.cancel();
    _seekTimer = Timer(Duration(milliseconds: _seekDelay), () async {
      if (_controller != null) {
        await _controller!.seekTo(_previewPosition);
        setState(() {
          _accumulatedSeekForward = 0; // Reset accumulator
        });
      }
      _safelyRequestFocus(forwardButtonFocusNode);
    });
  }

  void _seekBackward() {
    if (_controller == null || !_controller!.value.isInitialized) return;

    setState(() {
      // Accumulate seek duration
      _accumulatedSeekBackward += _seekDuration;
      // Instantly update preview position for UI
      final newPreviewPosition = _controller!.value.position -
          Duration(seconds: _accumulatedSeekBackward);
      _previewPosition = newPreviewPosition >= Duration.zero
          ? newPreviewPosition
          : Duration.zero;

      // Instantly reflect progress change
      _progress = _previewPosition.inMilliseconds /
          _controller!.value.duration.inMilliseconds;
    });

    // Reset and start timer to execute seek after delay
    _seekTimer?.cancel();
    _seekTimer = Timer(Duration(milliseconds: _seekDelay), () async {
      if (_controller != null) {
        await _controller!.seekTo(_previewPosition);
        setState(() {
          _accumulatedSeekBackward = 0; // Reset accumulator
        });
      }
      _safelyRequestFocus(backwardButtonFocusNode);
    });
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      _resetHideControlsTimer();

      if (event.logicalKey.keyId == 0x100700E9) {
        // Volume Up
        _updateVolume();
      } else if (event.logicalKey.keyId == 0x100700EA) {
        // Volume Down
        _updateVolume();
      }

      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowUp:
          print("Focused Index: $_focusedIndex, Source: ${widget.source}");

          _resetHideControlsTimer();
          if (playPauseButtonFocusNode.hasFocus ||
              backwardButtonFocusNode.hasFocus ||
              forwardButtonFocusNode.hasFocus ||
              prevButtonFocusNode.hasFocus ||
              nextButtonFocusNode.hasFocus ||
              progressIndicatorFocusNode.hasFocus) {
            Future.delayed(Duration(milliseconds: 100), () {
              if (!widget.isLive) {
                _safelyRequestFocus(focusNodes[_focusedIndex]);
                _scrollListener();
              }
            });
          } else if (focusNodes[_focusedIndex].hasFocus && _focusedIndex > 0) {
            Future.delayed(Duration(milliseconds: 100), () {
              setState(() {
                _focusedIndex--;
                _safelyRequestFocus(focusNodes[_focusedIndex]);
                _scrollToFocusedItem();
              });
            });
          }

          // else if (_focusedIndex > 0) {

          //   if (widget.channelList.isEmpty) return;

          //   setState(() {
          //     _focusedIndex--;
          //     _safelyRequestFocus(focusNodes[_focusedIndex]);
          //     _scrollListener();
          //   });
          // }
          break;

        case LogicalKeyboardKey.arrowDown:
          print("Focused Index: $_focusedIndex, Sourcesss: ${widget.source}");

          _resetHideControlsTimer();
          if (progressIndicatorFocusNode.hasFocus) {
            _safelyRequestFocus(focusNodes[_focusedIndex]);
            _scrollListener();
          }
          // else if (_focusedIndex < widget.channelList.length - 1) {

          //   setState(() {
          //     _focusedIndex++;
          //     _safelyRequestFocus(focusNodes[_focusedIndex]);
          //     _scrollListener();
          //   });
          // }

          else if (focusNodes[_focusedIndex].hasFocus &&
              _focusedIndex < widget.channelList.length - 1) {
            Future.delayed(Duration(milliseconds: 100), () {
              setState(() {
                _focusedIndex++;
                _safelyRequestFocus(focusNodes[_focusedIndex]);
                _scrollToFocusedItem();
              });
            });
          } else if (_focusedIndex < widget.channelList.length) {
            Future.delayed(Duration(milliseconds: 100), () {
              _safelyRequestFocus(playPauseButtonFocusNode);
            });
          }
          break;

        case LogicalKeyboardKey.arrowRight:
          _resetHideControlsTimer();
          if (progressIndicatorFocusNode.hasFocus) {
            if (!widget.isLive) {
              _seekForward();
            }
            Future.delayed(Duration(milliseconds: 100), () {
              _safelyRequestFocus(progressIndicatorFocusNode);
            });
          } else if (focusNodes.any((node) => node.hasFocus)) {
            Future.delayed(Duration(milliseconds: 100), () {
              _safelyRequestFocus(playPauseButtonFocusNode);
            });
          } else if (playPauseButtonFocusNode.hasFocus) {
            Future.delayed(Duration(milliseconds: 100), () {
              if (widget.channelList.isEmpty && widget.isLive) {
                _safelyRequestFocus(progressIndicatorFocusNode);
              } else if (widget.isLive && !widget.channelList.isEmpty) {
                _safelyRequestFocus(prevButtonFocusNode);
              } else {
                _safelyRequestFocus(backwardButtonFocusNode);
              }
            });
          } else if (backwardButtonFocusNode.hasFocus) {
            Future.delayed(Duration(milliseconds: 100), () {
              _safelyRequestFocus(forwardButtonFocusNode);
            });
          } else if (forwardButtonFocusNode.hasFocus) {
            Future.delayed(Duration(milliseconds: 100), () {
              if (widget.channelList.isEmpty) {
                _safelyRequestFocus(progressIndicatorFocusNode);
              } else {
                _safelyRequestFocus(prevButtonFocusNode);
              }
            });
          } else if (prevButtonFocusNode.hasFocus) {
            Future.delayed(Duration(milliseconds: 100), () {
              _safelyRequestFocus(nextButtonFocusNode);
            });
          } else if (nextButtonFocusNode.hasFocus) {
            Future.delayed(Duration(milliseconds: 100), () {
              _safelyRequestFocus(progressIndicatorFocusNode);
            });
          }
          break;

        case LogicalKeyboardKey.arrowLeft:
          _resetHideControlsTimer();
          if (progressIndicatorFocusNode.hasFocus) {
            if (!widget.isLive) {
              _seekBackward();
            }
            Future.delayed(Duration(milliseconds: 100), () {
              _safelyRequestFocus(progressIndicatorFocusNode);
            });
          } else if (nextButtonFocusNode.hasFocus) {
            Future.delayed(Duration(milliseconds: 100), () {
              _safelyRequestFocus(prevButtonFocusNode);
            });
          } else if (prevButtonFocusNode.hasFocus) {
            Future.delayed(Duration(milliseconds: 100), () {
              if (widget.isLive) {
                _safelyRequestFocus(playPauseButtonFocusNode);
              } else {
                _safelyRequestFocus(forwardButtonFocusNode);
              }
            });
          } else if (forwardButtonFocusNode.hasFocus) {
            Future.delayed(Duration(milliseconds: 100), () {
              _safelyRequestFocus(backwardButtonFocusNode);
            });
          } else if (backwardButtonFocusNode.hasFocus) {
            Future.delayed(Duration(milliseconds: 100), () {
              _safelyRequestFocus(playPauseButtonFocusNode);
            });
          } else if (playPauseButtonFocusNode.hasFocus) {
            Future.delayed(Duration(milliseconds: 100), () {
              _safelyRequestFocus(focusNodes[_focusedIndex]);
              _scrollToFocusedItem();
            });
          } else if (focusNodes.any((node) => node.hasFocus)) {
            Future.delayed(Duration(milliseconds: 100), () {
              _safelyRequestFocus(playPauseButtonFocusNode);
            });
          }
          break;

        case LogicalKeyboardKey.select:
        case LogicalKeyboardKey.enter:
          _resetHideControlsTimer();
          if (nextButtonFocusNode.hasFocus) {
            _playNext();
            _safelyRequestFocus(nextButtonFocusNode);
          } else if (prevButtonFocusNode.hasFocus) {
            _playPrevious();
            _safelyRequestFocus(prevButtonFocusNode);
          } else if (forwardButtonFocusNode.hasFocus) {
            _seekForward();
            _safelyRequestFocus(forwardButtonFocusNode);
          } else if (backwardButtonFocusNode.hasFocus) {
            _seekBackward();
            _safelyRequestFocus(backwardButtonFocusNode);
          } else if (playPauseButtonFocusNode.hasFocus) {
            _togglePlayPause();
            _safelyRequestFocus(playPauseButtonFocusNode);
          } else {
            _onItemTap(_focusedIndex);
          }
          break;
      }
    }
  }

  String _formatDuration(Duration duration) {
    // Function to convert single digit to double digit string (e.g., 5 -> "05")
    String twoDigits(int n) => n.toString().padLeft(2, '0');

    // Get hours string only if hours > 0
    String hours =
        duration.inHours > 0 ? '${twoDigits(duration.inHours)}:' : '';

    // Get minutes (00-59)
    String minutes = twoDigits(duration.inMinutes.remainder(60));

    // Get seconds (00-59)
    String seconds = twoDigits(duration.inSeconds.remainder(60));

    // Combine everything into final time string
    return '$hours$minutes:$seconds';
  }

  Widget _buildVideoPlayer() {
    if (!_isVideoInitialized || _controller == null) {
      return Center(child: CircularProgressIndicator());
    }

    // video_player needs a different approach to aspect ratio handling
    return LayoutBuilder(
      builder: (context, constraints) {
        // Get screen dimensions
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;

        // Calculate aspect ratio from the controller
        // final videoAspectRatio = _controller!.value.aspectRatio;

        // Use AspectRatio widget to maintain correct proportions
        return Container(
          width: screenWidth,
          height: screenHeight,
          color: Colors.black,
          child: Center(
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: VideoPlayer(_controller!),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Safely pause the controller before popping
        if (isControllerReady) {
          _controller!.pause();
        }
        await Future.delayed(Duration(milliseconds: 500));
        GlobalEventBus.eventBus.fire(RefreshPageEvent('uniquePageId'));
        Navigator.of(context).pop(true);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SizedBox(
          width: screenwdt,
          height: screenhgt,
          child: Focus(
            focusNode: screenFocusNode,
            onKey: (node, event) {
              if (event is RawKeyDownEvent) {
                _handleKeyEvent(event);
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: GestureDetector(
              onTap: _resetHideControlsTimer,
              child: Stack(
                children: [
                  // Video Player - using the new implementation for video_player
                  if (_isVideoInitialized && _controller != null)
                    _buildVideoPlayer(),

                  // // Loading Indicator
                  // if (_loadingVisible || !_isVideoInitialized)
                  //   Container(
                  //     color: Colors.black54,
                  //     child: Center(
                  //         child: RainbowPage(
                  //       backgroundColor: Colors.black,
                  //     )),
                  //   ),
                  // if (_isBuffering) LoadingIndicator(),
                  // Replace the existing loading indicator section
// Loading Indicator
                  if (!_isVideoInitialized) // Only show rainbow on initial load
                    Container(
                      color: Colors.black54,
                      child: Center(
                          child: RainbowPage(
                        backgroundColor: Colors.black,
                      )),
                    ),
                  if (_isBuffering && _loadingVisible)
                    LoadingIndicator(), // Only show if both conditions are true
                  // Channel List
                  if (_controlsVisible && !widget.channelList.isEmpty)
                    _buildChannelList(),

                  // Controls
                  if (_controlsVisible) _buildControls(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVolumeIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Image.asset('assets/volume.png', width: 24, height: 24),
          Expanded(
            child: LinearProgressIndicator(
              value: _currentVolume, // Dynamic value from _currentVolume
              color: const Color.fromARGB(211, 155, 40, 248),
              backgroundColor: Colors.grey,
            ),
          ),
          SizedBox(width: 8),
          Text(
            '${(_currentVolume * 100).toInt()}%', // Show percentage
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelList() {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.02,
      bottom: MediaQuery.of(context).size.height * 0.1,
      left: MediaQuery.of(context).size.width * 0.0,
      right: MediaQuery.of(context).size.width * 0.78,
      child: Container(
        child: ListView.builder(
          controller: _scrollController,
          itemCount: widget.channelList.length,
          itemBuilder: (context, index) {
            final channel = widget.channelList[index];
            final String channelId = widget.isBannerSlider
                ? (channel.contentId?.toString() ??
                    channel.contentId?.toString() ??
                    '')
                : (channel.id?.toString() ?? channel.id?.toString() ?? '');

            final String? banner = channel is Map
                ? channel['banner']?.toString()
                : channel.banner?.toString();
            final bool isBase64 =
                channel.banner?.startsWith('data:image') ?? false;

            return Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Focus(
                focusNode: focusNodes[index],
                onFocusChange: (hasFocus) {
                  if (hasFocus) {
                    setState(() {
                      _focusedIndex = index;
                    });
                  }
                },
                child: GestureDetector(
                  onTap: () {
                    _onItemTap(index);
                    _resetHideControlsTimer();
                  },
                  child: Container(
                    width: screenwdt * 0.3,
                    height: screenhgt * 0.18,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: playPauseButtonFocusNode.hasFocus ||
                                backwardButtonFocusNode.hasFocus ||
                                forwardButtonFocusNode.hasFocus ||
                                prevButtonFocusNode.hasFocus ||
                                nextButtonFocusNode.hasFocus ||
                                progressIndicatorFocusNode.hasFocus
                            ? Colors.transparent
                            : _focusedIndex == index
                                ? const Color.fromARGB(211, 155, 40, 248)
                                : Colors.transparent,
                        width: 5.0,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      color: _focusedIndex == index
                          ? Colors.black26
                          : Colors.transparent,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Opacity(
                              opacity: 0.6,
                              child: isBase64
                                  ? Image.memory(
                                      _bannerCache[channelId] ??
                                          _getCachedImage(
                                              channel.banner ?? localImage),
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error,
                                              stackTrace) =>
                                          Image.asset('assets/placeholder.png'),
                                    )
                                  : CachedNetworkImage(
                                      imageUrl: channel.banner ?? localImage,
                                      fit: BoxFit.cover,
                                      errorWidget: (context, url, error) =>
                                          localImage,
                                    ),
                            ),
                          ),
                          if (_focusedIndex == index)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.9),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          if (_focusedIndex == index)
                            Positioned(
                              left: 8,
                              bottom: 8,
                              child: Text(
                                channel.name ?? '',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Widget _buildCustomProgressIndicator() {

  //     if (!isControllerReady) {
  //   return Container(
  //     height: 6,
  //     color: Colors.grey,
  //   );
  // }
  //   // Calculate played progress from the controller
  //   double playedProgress =
  //       (_controller?.value.position.inMilliseconds.toDouble() ?? 0.0) /
  //           (_controller?.value.duration.inMilliseconds.toDouble() ?? 1.0);

  //   // For video_player, buffered progress is available from the controller
  //   double bufferedProgress = _controller?.value.buffered.isNotEmpty ?? false
  //       ? _controller!.value.buffered.last.end.inMilliseconds.toDouble() /
  //           _controller!.value.duration.inMilliseconds.toDouble()
  //       : (playedProgress + 0.02).clamp(0.0, 1.0); // Fallback

  //   return Container(
  //       // Add padding to make the indicator more visible when focused
  //       padding: EdgeInsets.all(screenhgt * 0.03),
  //       // Change background color based on focus state
  //       decoration: BoxDecoration(
  //         color: progressIndicatorFocusNode.hasFocus
  //             ? const Color.fromARGB(
  //                 200, 16, 62, 99) // Blue background when focused
  //             : Colors.transparent,
  //         // Optional: Add rounded corners when focused
  //         borderRadius: progressIndicatorFocusNode.hasFocus
  //             ? BorderRadius.circular(4.0)
  //             : null,
  //       ),
  //       child: Stack(
  //         children: [
  //           // Buffered progress
  //           LinearProgressIndicator(
  //             minHeight: 6,
  //             value: bufferedProgress.isNaN ? 0.0 : bufferedProgress,
  //             color: Colors.green, // Buffered color
  //             backgroundColor: Colors.grey, // Background
  //           ),
  //           // Played progress
  //           LinearProgressIndicator(
  //             minHeight: 6,
  //             value: playedProgress.isNaN ? 0.0 : playedProgress,
  //             valueColor: AlwaysStoppedAnimation<Color>(
  //               _previewPosition != _controller!.value.position
  //                   ? Colors.red.withOpacity(0.5) // Preview seeking
  //                   : Colors.red, // Normal playback
  //             ),
  //             color: const Color.fromARGB(211, 155, 40, 248), // Played color
  //             backgroundColor: Colors.transparent, // Transparent to overlay
  //           ),
  //         ],
  //       ));
  // }

  Widget _buildCustomProgressIndicator() {
    if (!isControllerReady) {
      return Container(height: 6, color: Colors.grey);
    }

    double bufferedProgress = _controller?.value.buffered.isNotEmpty ?? false
        ? _controller!.value.buffered.last.end.inMilliseconds.toDouble() /
            _controller!.value.duration.inMilliseconds.toDouble()
        : (_progress + 0.02).clamp(0.0, 1.0);

    return Container(
      padding: EdgeInsets.all(screenhgt * 0.03),
      decoration: BoxDecoration(
        color: progressIndicatorFocusNode.hasFocus
            ? const Color.fromARGB(200, 16, 62, 99)
            : Colors.transparent,
        borderRadius: progressIndicatorFocusNode.hasFocus
            ? BorderRadius.circular(4.0)
            : null,
      ),
      child: Stack(
        children: [
          LinearProgressIndicator(
            minHeight: 6,
            value: bufferedProgress.isNaN ? 0.0 : bufferedProgress,
            color: Colors.green,
            backgroundColor: Colors.grey,
          ),
          LinearProgressIndicator(
            minHeight: 6,
            value: _progress.isNaN ? 0.0 : _progress,
            valueColor: AlwaysStoppedAnimation<Color>(
              const Color.fromARGB(255, 174, 54, 244),
            ),
            backgroundColor: Colors.transparent,
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
// Safe flag for play/pause icon
    bool isPlaying = false;
    if (isControllerReady) {
      isPlaying = _controller!.value.isPlaying;
    }

// Safe duration and position
    Duration position = Duration.zero;
    Duration duration = Duration.zero;
    if (isControllerReady) {
      position = _controller!.value.position;
      duration = _controller!.value.duration;
    }

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            color: Colors.black54,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(flex: 1, child: Container()),
                Expanded(
                  flex: 4,
                  child: Container(
                    color: playPauseButtonFocusNode.hasFocus
                        ? const Color.fromARGB(200, 16, 62, 99)
                        : Colors.transparent,
                    child: Center(
                      child: Focus(
                        focusNode: playPauseButtonFocusNode,
                        onFocusChange: (hasFocus) {
                          if (mounted) {
                            setState(() {});
                          }
                        },
                        child: IconButton(
                          icon: Image.asset(
                            isPlaying ? 'assets/pause.png' : 'assets/play.png',
                            width: 35,
                            height: 35,
                          ),
                          onPressed: _togglePlayPause,
                        ),
                      ),
                    ),
                  ),
                ),
                if (!widget.isLive)
                  Expanded(
                    flex: 2,
                    child: Container(
                      color: backwardButtonFocusNode.hasFocus
                          ? const Color.fromARGB(200, 16, 62, 99)
                          : Colors.transparent,
                      child: Center(
                        child: Focus(
                          focusNode: backwardButtonFocusNode,
                          onFocusChange: (hasFocus) {
                            if (mounted) {
                              setState(() {
// Change color based on focus state
                              });
                            }
                          },
                          child: IconButton(
                            icon: Transform(
                              transform:
                                  Matrix4.rotationY(pi), // pi from dart:math
                              alignment: Alignment.center,
                              child: Image.asset('assets/seek.png',
                                  width: 24, height: 24),
                            ),
                            onPressed: _seekForward,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (!widget.isLive)
                  Expanded(
                    flex: 2,
                    child: Container(
                      color: forwardButtonFocusNode.hasFocus
                          ? const Color.fromARGB(200, 16, 62, 99)
                          : Colors.transparent,
                      child: Center(
                        child: Focus(
                          focusNode: forwardButtonFocusNode,
                          onFocusChange: (hasFocus) {
                            if (mounted) {
                              setState(() {
// Change color based on focus state
                              });
                            }
                          },
                          child: IconButton(
                            icon: Image.asset('assets/seek.png',
                                width: 24, height: 24),
                            onPressed: _seekForward,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (!widget.channelList.isEmpty)
                  Expanded(
                    flex: 2,
                    child: Container(
                      color: prevButtonFocusNode.hasFocus
                          ? const Color.fromARGB(200, 16, 62, 99)
                          : Colors.transparent,
                      child: Center(
                        child: Focus(
                          focusNode: prevButtonFocusNode,
                          onFocusChange: (hasFocus) {
                            if (mounted) {
                              setState(() {
// Change color based on focus state
                              });
                            }
                          },
                          child: IconButton(
                            icon: Transform(
                              transform:
                                  Matrix4.rotationY(pi), // pi from dart:math
                              alignment: Alignment.center,
                              child: Image.asset('assets/next.png',
                                  width: 35, height: 35),
                            ),
                            onPressed: _playPrevious,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (!widget.channelList.isEmpty)
                  Expanded(
                    flex: 2,
                    child: Container(
                      color: nextButtonFocusNode.hasFocus
                          ? const Color.fromARGB(200, 16, 62, 99)
                          : Colors.transparent,
                      child: Center(
                        child: Focus(
                          focusNode: nextButtonFocusNode,
                          onFocusChange: (hasFocus) {
                            if (mounted) {
                              setState(() {
// Change color based on focus state
                              });
                            }
                          },
                          child: IconButton(
                            icon: Image.asset('assets/next.png',
                                width: 35, height: 35),
                            onPressed: _playNext,
                          ),
                        ),
                      ),
                    ),
                  ),
                Expanded(flex: 8, child: _buildVolumeIndicator()),
                if (!widget.isLive)
                Expanded(
                  flex: 3,
                  child: Center(
                    child: Text(
                      _formatDuration(
                          _controller?.value.position ?? Duration.zero),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 15,
                  child: Center(
                    child: Focus(
                      focusNode: progressIndicatorFocusNode,
                      onFocusChange: (hasFocus) {
                        if (mounted) {
                          setState(() {
// Handle focus changes if needed
                          });
                        }
                      },
                      child: Container(
                          color: progressIndicatorFocusNode.hasFocus
                              ? const Color.fromARGB(200, 16, 62,
                                  99) // Blue background when focused
                              : Colors.transparent,
                          child: _buildCustomProgressIndicator()),
                    ),
                  ),
                ),
                if (!widget.isLive)
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: Text(
                        _formatDuration(
                            _controller?.value.duration ?? Duration.zero),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  flex: widget.isLive ? 3 : 1,
                  child: Center(
                    child: widget.isLive
                        ? 
                        // Row(
                        //     mainAxisAlignment: MainAxisAlignment.center,
                        //     children: [
                        //       Icon(Icons.circle, color: Colors.red, size: 15),
                        //       SizedBox(width: 5),
                        //       Text(
                        //         'Live',
                        //         style: TextStyle(
                        //           color: Colors.red,
                        //           fontSize: 20,
                        //           fontWeight: FontWeight.bold,
                        //         ),
                        //       ),
                        //     ],
                        //   )
                        Image.asset('assets/live.png')
                        : Container(),
                  ),
                ),
                Expanded(flex: 1, child: Container()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
