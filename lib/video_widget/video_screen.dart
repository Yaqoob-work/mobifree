import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as https;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:keep_screen_on/keep_screen_on.dart';
import 'package:mobi_tv_entertainment/main.dart';
import 'package:mobi_tv_entertainment/menu_screens/home_sub_screen/home_category.dart';
import 'package:mobi_tv_entertainment/video_widget/socket_service.dart';
import 'package:mobi_tv_entertainment/widgets/small_widgets/loading_indicator.dart';
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

// Create an event class
class RefreshPageEvent {
  final String pageId; // To identify which page to refresh
  RefreshPageEvent(this.pageId);
}

class VideoScreen extends StatefulWidget {
  final String videoUrl;
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

  VideoScreen({
    required this.videoUrl,
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
  });

  @override
  _VideoScreenState createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> with WidgetsBindingObserver {
  final SocketService _socketService = SocketService();
  VlcPlayerController? _controller;
  bool _controlsVisible = true;
  late Timer _hideControlsTimer;
  Duration _totalDuration = Duration.zero;
  Duration _currentPosition = Duration.zero;
  bool _isBuffering = false;
  bool _isConnected = true;
  bool _isVideoInitialized = false;
  Timer? _connectivityCheckTimer;
  int _focusedIndex = 0;
  // bool _isPlayPauseFocused = false;
  bool _isFocused = false;
  List<FocusNode> focusNodes = [];
  final ScrollController _scrollController = ScrollController();
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
  bool _wasPlayingBeforeDisconnection = false;
  int _maxRetries = 3;
  int _retryDelay = 5; // seconds
  Timer? _networkCheckTimer;
  bool _wasDisconnected = false;
  String? _currentModifiedUrl; // To store the current modified URL

  // Uint8List _getImageFromBase64String(String base64String) {
  //   // Split the base64 string to remove metadata if present
  //   return base64Decode(base64String.split(',').last);
  // }

  Map<String, Uint8List> _imageCache = {};

  Uint8List _getCachedImage(String base64String) {
    if (!_imageCache.containsKey(base64String)) {
      _imageCache[base64String] = base64Decode(base64String.split(',').last);
    }
    return _imageCache[base64String]!;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    KeepScreenOn.turnOn();
    _initializeVolume();
    _listenToVolumeChanges();
    // Match channel by ID as strings
    if (widget.isBannerSlider) {
      _focusedIndex = widget.channelList.indexWhere(
        (channel) => channel.contentId.toString() == widget.videoId.toString(),
      );
    } else if (widget.isVOD || widget.source == 'isLiveScreen') {
      _focusedIndex = widget.channelList.indexWhere(
        (channel) => channel.id.toString() == widget.videoId.toString(),
      );
    } else {
      _focusedIndex = widget.channelList.indexWhere(
        (channel) => channel.url == widget.videoUrl,
      );
    }
    // Default to 0 if no match is found
    _focusedIndex = (_focusedIndex >= 0) ? _focusedIndex : 0;
    // print('Initial focused index: $_focusedIndex');
    // Initialize focus nodes
    focusNodes = List.generate(
      widget.channelList.length,
      (index) => FocusNode(),
    );
    // Set initial focus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setInitialFocus();
    });
    _differentActionOnDifferentSourceOfChannelList();
    _initializeVLCController(_focusedIndex);
    _startHideControlsTimer();
    _startNetworkMonitor();
    _startPositionUpdater();
  }

  // @override
  // void dispose() {
  //   try {
  //     _controller?.stop();
  //     Future.delayed(Duration(milliseconds: 100), () {
  //       _controller?.dispose();
  //     });
  //   } catch (e) {
  //     print("Error in dispose: $e");
  //   }
  //   _connectivityCheckTimer?.cancel();
  // _saveLastPlayedVideo(widget.videoUrl,
  //     _controller?.value.position ?? Duration.zero, widget.bannerImageUrl);
  //   // _socketService.dispose();
  // WidgetsBinding.instance.removeObserver(this);
  //   _connectivityCheckTimer?.cancel();
  //   _hideControlsTimer.cancel();
  //   screenFocusNode.dispose();
  //   _channelListFocusNode.dispose();
  //   _scrollController.dispose();
  //   focusNodes.forEach((node) => node.dispose());
  //   progressIndicatorFocusNode.dispose();
  //   playPauseButtonFocusNode.dispose();
  //   backwardButtonFocusNode.dispose();
  //   forwardButtonFocusNode.dispose();
  //   nextButtonFocusNode.dispose();
  //   prevButtonFocusNode.dispose();
  //   KeepScreenOn.turnOff();
  //   super.dispose();
  // }

  @override
  void dispose() {
    try {
      _controller?.stop();
      _controller?.dispose();
    } catch (e) {
      print("Error disposing controller: $e");
    }
    _controller?.removeListener(() {});
    _saveLastPlayedVideo(widget.videoUrl,
        _controller?.value.position ?? Duration.zero, widget.bannerImageUrl);
    _connectivityCheckTimer?.cancel();
    _hideControlsTimer?.cancel();
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

  void _differentActionOnDifferentSourceOfChannelList() {
    if (widget.source == 'isSearchScreenFromDetailsPageChannelList') {
    } else if (widget.source == 'isContentScreenFromDetailsPageChannelLIst') {
      // print('Channel list is coming from ContentScreen');
    } else {
      // print('Channel list source is unknown');
    }
  }

  void _setInitialFocus() {
    if (widget.channelList.isEmpty) {
      print('Channel list is empty, focusing on Play/Pause button');
      FocusScope.of(context).requestFocus(playPauseButtonFocusNode);
      return;
    }

    print('Setting initial focus to index: $_focusedIndex');
    FocusScope.of(context).requestFocus(focusNodes[_focusedIndex]);
    _scrollToFocusedItem();
  }

  Future<void> _onNetworkReconnected() async {
    if (_controller != null) {
      try {
        print("Attempting to resume playback...");

        // Check if the network is stable
        bool isConnected = await _isInternetAvailable();
        if (!isConnected) {
          print("Network is not stable yet. Delaying reconnection attempt.");
          return;
        }

        // Fallback: Ensure modifiedUrl is available
        if (_currentModifiedUrl == null || _currentModifiedUrl!.isEmpty) {
          var selectedChannel = widget.channelList[_focusedIndex];
          _currentModifiedUrl =
              '${selectedChannel.url}?network-caching=2000&live-caching=1000&rtsp-tcp';
        }

        // Log the URL for debugging
        print("Resuming playback with URL: $_currentModifiedUrl");
        // Handle playback based on content type (Live or VOD)
        if (_controller!.value.isInitialized) {
          if (widget.isLive) {
            // Restart live playback
            await _retryPlayback(_currentModifiedUrl!, 3);
            // await _controller!.setMediaFromNetwork(_currentModifiedUrl!);
            // await _controller!.play();
          } else {
            // Resume VOD playback from the last known position
            // await _controller!.setMediaFromNetwork(_currentModifiedUrl!);
            await _retryPlayback(_currentModifiedUrl!, 3);
            if (_lastKnownPosition != Duration.zero) {
              await _controller!.seekTo(_lastKnownPosition);
            }
            await _controller!.play();
          }
        }
      } catch (e) {
        print("Error during reconnection: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error resuming playback: ${e.toString()}")),
        );
      }
    } else {
      print("Controller is null, cannot reconnect.");
    }
  }

  // void _startNetworkMonitor() {
  //   _networkCheckTimer = Timer.periodic(Duration(seconds: 5), (_) async {
  //     bool isConnected = await _isInternetAvailable();
  //     if (!isConnected && !_wasDisconnected) {
  //       _wasDisconnected = true;
  //       print("Network disconnected");
  //     } else if (isConnected && _wasDisconnected) {
  //       _wasDisconnected = false;
  //       print("Network reconnected. Attempting to resume video...");

  //       // Attempt reconnection only once
  //       if (_controller?.value.isInitialized ?? false) {
  //         _onNetworkReconnected();
  //       }
  //     }
  //   });
  // }

  void _startNetworkMonitor() {
    _networkCheckTimer = Timer.periodic(Duration(seconds: 5), (_) async {
      bool isConnected = await _isInternetAvailable();
      if (!isConnected && !_wasDisconnected) {
        _wasDisconnected = true;
        print("Network disconnected");
      } else if (isConnected && _wasDisconnected) {
        _wasDisconnected = false;
        print("Network reconnected. Attempting to resume video...");

        // Attempt reconnection only once
        if (_controller?.value.isInitialized ?? false) {
          _onNetworkReconnected();
        }
      }
    });
  }

  Future<bool> _isInternetAvailable() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void _startPositionUpdater() {
    Timer.periodic(Duration(seconds: 1), (_) {
      if (mounted && _controller?.value.isInitialized == true) {
        setState(() {
          _lastKnownPosition = _controller!.value.position;
        });
      }
    });
  }

  // void _startPositionUpdater() {
  //   Timer.periodic(Duration(seconds: 1), (_) {
  //     if (_controller?.value.isInitialized ?? false) {
  //       setState(() {
  //         _lastKnownPosition = _controller!.value.position;
  //       });
  //     }
  //   });
  // }

//   // First, update the VlcPlayer initialization in _initializeVLCController:
// Future<void> _initializeVLCController() async {
//   setState(() {
//     _loadingVisible = true;
//   });

//   try {
//     String modifiedUrl = '${widget.videoUrl}?network-caching=10000&live-caching=1000&rtsp-tcp';

//     if (_controller != null) {
//       await _controller!.dispose();
//     }

//     _controller = VlcPlayerController.network(
//       modifiedUrl,
//       hwAcc: HwAcc.auto,
//       autoPlay: false,  // Changed to false to handle initialization properly
//       options: VlcPlayerOptions(
//         advanced: VlcAdvancedOptions([
//           VlcAdvancedOptions.networkCaching(10000),
//           VlcAdvancedOptions.liveCaching(1000),
//         ]),
//         http: VlcHttpOptions([
//           VlcHttpOptions.httpReconnect(true),
//         ]),
//         video: VlcVideoOptions([
//           VlcVideoOptions.dropLateFrames(true),
//           VlcVideoOptions.skipFrames(true),
//         ]),
//       ),
//     );

//      _controller!.initialize();

//     setState(() {
//       _isVideoInitialized = true;
//     });

//     // Only start playing after successful initialization
//     if (_isVideoInitialized) {
//       await _controller!.play();
//     }

//   } catch (e) {
//     print("Error initializing video: $e");
//     setState(() {
//       _isVideoInitialized = false;
//       _loadingVisible = false;
//     });
//   }

//   // Hide loading after a delay
//   Future.delayed(Duration(seconds: widget.isVOD ? 9 : 3), () {
//     if (mounted) {
//       setState(() {
//         _loadingVisible = false;
//       });
//     }
//   });
// }
  bool urlUpdating = false;
  Future<void> _initializeVLCController(int index) async {
    // try {
    setState(() {
      _loadingVisible = true; // Show loading initially
    });

    String modifiedUrl =
        '${widget.videoUrl}?network-caching=5000&live-caching=500&rtsp-tcp';
    // var selectedChannel = widget.channelList[index];
    // String updatedUrl = selectedChannel.url;
    // final int contentId = int.tryParse(selectedChannel.id) ?? 0;

    // if (widget.source == 'isHomeCategory') {
    //   print('asd : ${selectedChannel.id}');

    //   final playLink = await fetchLiveFeaturedTVById(selectedChannel.contentId);
    //   if (playLink['url'] != null && playLink['url']!.isNotEmpty) {
    //     updatedUrl = playLink['url']!;
    //     if (playLink['stream_type'] == 'YoutubeLive') {
    //       updatedUrl = await _socketService.getUpdatedUrl(updatedUrl);
    //       setState(() {
    //         setState(() {
    //           urlUpdating = true;
    //         });
    //       });
    //     }
    //   } else {
    //     throw Exception("Invalid play link for VOD");
    //   }
    // } else if (selectedChannel.streamType == 'YoutubeLive' ||
    //     selectedChannel.streamType == 'Youtube') {
    //   updatedUrl = await _fetchUpdatedUrl(selectedChannel.url);
    //   setState(() {
    //     urlUpdating = true;
    //   });
    //   if (updatedUrl.isEmpty) throw Exception("Failed to fetch updated URL");
    // }
    // if (widget.isBannerSlider) {
    //   final playLink = await fetchLiveFeaturedTVById(selectedChannel.id);
    //   if (playLink['url'] != null && playLink['url']!.isNotEmpty) {
    //     updatedUrl = playLink['url']!;
    //     if (playLink['stream_type'] == 'YoutubeLive') {
    //       updatedUrl = await _socketService.getUpdatedUrl(playLink['url']!);
    //       setState(() {
    //         urlUpdating = true;
    //       });
    //     }
    //   } else {
    //     throw Exception("Invalid play link for VOD");
    //   }
    // } else if (selectedChannel.streamType == 'YoutubeLive' ||
    //     selectedChannel.streamType == 'Youtube') {
    //   updatedUrl = await _fetchUpdatedUrl(selectedChannel.url);
    //   setState(() {
    //     urlUpdating = true;
    //   });
    //   if (updatedUrl.isEmpty) throw Exception("Failed to fetch updated URL");
    // }

    // if (selectedChannel.contentType == '1' ||
    //     selectedChannel.contentType == 1 && widget.source == 'isSearchScreen') {
    //   // final playLink =
    //   //     await fetchLiveFeaturedTVById(selectedChannel.id);
    //   final playLink = await fetchMoviePlayLink(contentId);

    //   print('hellow isSearchScreen$playLink');
    //   if (playLink['url'] != null && playLink['url']!.isNotEmpty) {
    //     updatedUrl = playLink['url']!;
    //     if (playLink['type'] == 'Youtube' ||
    //         playLink['type'] == 'YoutubeLive' ||
    //         playLink['content_type'] == '1' ||
    //         playLink['content_type'] == 1) {
    //       updatedUrl = await _socketService.getUpdatedUrl(playLink['url']!);
    //       setState(() {
    //         urlUpdating = true;
    //       });
    //       print('hellow isSearchScreen$updatedUrl');
    //     }
    //   }
    // }

    // if (widget.isVOD ||
    //         widget.source == 'isSearchScreenViaDetailsPageChannelList'
    //     //|| widget.source == 'isSearchScreen'
    //     ) {
    //   print('hellow isVOD');

    //   if (selectedChannel.contentType == '1' ||
    //       selectedChannel.contentType == 1) {
    //     // final playLink =
    //     //     await fetchLiveFeaturedTVById(selectedChannel.id);
    //     final playLink = await fetchMoviePlayLink(contentId);

    //     print('hellow isVOD$playLink');
    //     if (playLink['url'] != null && playLink['url']!.isNotEmpty) {
    //       updatedUrl = playLink['url']!;
    //       if (playLink['type'] == 'Youtube' ||
    //           playLink['type'] == 'YoutubeLive' ||
    //           playLink['content_type'] == '1' ||
    //           playLink['content_type'] == 1) {
    //         updatedUrl = await _socketService.getUpdatedUrl(playLink['url']!);
    //         setState(() {
    //           urlUpdating = true;
    //         });
    //         print('hellow isVOD$updatedUrl');
    //       }
    //     }
    //   }
    // }

    // String modifiedUrl =
    //     '${updatedUrl}?network-caching=5000&live-caching=500&rtsp-tcp';

    _controller = VlcPlayerController.network(
      modifiedUrl,
      hwAcc: HwAcc.auto,
      autoPlay: true,
      // options: VlcPlayerOptions(),
      options: VlcPlayerOptions(
        video: VlcVideoOptions([
          VlcVideoOptions.dropLateFrames(true),
          VlcVideoOptions.skipFrames(true),
        ]),
      ),
    );
    if (!urlUpdating) {
      _controller!.initialize();
      await _retryPlayback(modifiedUrl, 5);
    } else {
      await Future.delayed(Duration(seconds: 5));
      _controller!.initialize();
      await _retryPlayback(modifiedUrl, 5);
    }
    setState(() {
      _isVideoInitialized = true;
    });
    Timer(Duration(seconds: widget.isVOD ? 9 : 3), () {
      setState(() {
        _loadingVisible = false;
      });
    });
    // } catch (error) {
    //   print("Error initializing the video: $error");
    //   setState(() {
    //     _isVideoInitialized = false;
    //     _loadingVisible = false;
    //   });
    // }
    bool _hasRenderedFirstFrame = false;

    _controller!.addListener(() {
      if (_controller!.value.isInitialized &&
          _controller!.value.isPlaying &&
          !_isBuffering &&
          !_hasRenderedFirstFrame) {
        // Video is initialized, playing, and buffering has completed
        setState(() {
          _loadingVisible = false;
          _hasRenderedFirstFrame = true; // Prevent further prints
        });
        print("First frame rendered, hiding loading indicator.");
      }
    });

    _controller?.addListener(() {
      if (mounted && _controller!.value.hasError) {
        print("VLC Player Error: ${_controller!.value.errorDescription}");
        // setState(() {
        //   _isVideoInitialized = false;
        // });
      }
    });
  }

  // Future<Map<String, String>> fetchHomeCategoryById(String contentId) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final cachedData = prefs.getString('live_featured_tv');

  //   List<dynamic> responseData;

  //   // Use cached data if available
  //   if (cachedData != null) {
  //     responseData = json.decode(cachedData);
  //   } else {
  //     // Fetch from API if cache is not available
  //     final response = await https.get(
  //       Uri.parse('https://api.ekomflix.com/android/getSelectHomeCategory'),
  //       headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
  //     );

  //     if (response.statusCode == 200) {
  //       responseData = json.decode(response.body);
  //       // Cache the data
  //       prefs.setString('live_featured_tv', json.encode(responseData));
  //     } else {
  //       throw Exception('Failed to load featured live TV');
  //     }
  //   }

  //   // Find the matched item by id
  //   final matchedItem = responseData.firstWhere(
  //     (channel) => channel['id'] == contentId,
  //     orElse: () => null,
  //   );

  //   if (matchedItem != null) {
  //     return {
  //       'url': matchedItem['url'] ?? '',
  //       'type': matchedItem['type'] ?? '',
  //     };
  //   } else {
  //     throw Exception('No matching channel found for id $contentId');
  //   }
  // }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isVideoInitialized && !_controller!.value.isPlaying) {
      _controller!.play();
    }
  }

  Future<void> _retryPlayback(String url, int retries) async {
    for (int i = 0; i < retries; i++) {
      if (!mounted || !_controller!.value.isInitialized) return;

      try {
        await _controller!.setMediaFromNetwork(url);
        await _controller!.play();
        return; // Exit on success
      } catch (e) {
        print("Retry ${i + 1} failed: $e");
        await Future.delayed(Duration(seconds: 1));
      }
    }
    print("All retries failed for URL: $url");
  }

  Future<void> _onItemTap(int index) async {
    var selectedChannel = widget.channelList[index];
    String updatedUrl = selectedChannel.url;

    setState(() {
      _loadingVisible = true; // Show loading indicator
    });

    try {
      final int contentId = int.tryParse(selectedChannel.id) ?? 0;

      if (widget.source == 'isHomeCategory') {
        final playLink =
            await fetchLiveFeaturedTVById(selectedChannel.contentId);

        if (playLink['url'] != null && playLink['url']!.isNotEmpty) {
          updatedUrl = playLink['url']!;
          if (playLink['stream_type'] == 'YoutubeLive') {
            updatedUrl = await _socketService.getUpdatedUrl(updatedUrl);
          }
        } else {
          throw Exception("Invalid play link for VOD");
        }
      } else if (selectedChannel.streamType == 'YoutubeLive' ||
          selectedChannel.streamType == 'Youtube') {
        updatedUrl = await _fetchUpdatedUrl(selectedChannel.url);
        if (updatedUrl.isEmpty) throw Exception("Failed to fetch updated URL");
      }

      if (widget.isBannerSlider) {
        final playLink =
            await fetchLiveFeaturedTVById(selectedChannel.contentId);

        if (playLink['url'] != null && playLink['url']!.isNotEmpty) {
          updatedUrl = playLink['url']!;
          if (playLink['stream_type'] == 'YoutubeLive') {
            updatedUrl = await _socketService.getUpdatedUrl(playLink['url']!);
          }
        } else {
          throw Exception("Invalid play link for VOD");
        }
      } else if (selectedChannel.streamType == 'YoutubeLive' ||
          selectedChannel.streamType == 'Youtube') {
        updatedUrl = await _fetchUpdatedUrl(selectedChannel.url);
        if (updatedUrl.isEmpty) throw Exception("Failed to fetch updated URL");
      }

      if (selectedChannel.contentType == '1' ||
          selectedChannel.contentType == 1 &&
              widget.source == 'isSearchScreen') {
        // final playLink =
        //     await fetchLiveFeaturedTVById(selectedChannel.id);
        final playLink = await fetchMoviePlayLink(contentId);

        print('hellow isSearchScreen$playLink');
        if (playLink['url'] != null && playLink['url']!.isNotEmpty) {
          updatedUrl = playLink['url']!;
          if (playLink['type'] == 'Youtube' ||
              playLink['type'] == 'YoutubeLive' ||
              playLink['content_type'] == '1' ||
              playLink['content_type'] == 1) {
            updatedUrl = await _socketService.getUpdatedUrl(playLink['url']!);
            print('hellow isSearchScreen$updatedUrl');
          }
        }
      }

      if (widget.isVOD ||
              widget.source == 'isSearchScreenViaDetailsPageChannelList'
          //|| widget.source == 'isSearchScreen'
          ) {
        print('hellow isVOD');

        if (selectedChannel.contentType == '1' ||
            selectedChannel.contentType == 1) {
          // final playLink =
          //     await fetchLiveFeaturedTVById(selectedChannel.id);
          final playLink = await fetchMoviePlayLink(contentId);

          print('hellow isVOD$playLink');
          if (playLink['url'] != null && playLink['url']!.isNotEmpty) {
            updatedUrl = playLink['url']!;
            if (playLink['type'] == 'Youtube' ||
                playLink['type'] == 'YoutubeLive' ||
                playLink['content_type'] == '1' ||
                playLink['content_type'] == 1) {
              updatedUrl = await _socketService.getUpdatedUrl(playLink['url']!);
              print('hellow isVOD$updatedUrl');
            }
          }
        }
      }

      // Store modifiedUrl
      String _currentModifiedUrl =
          '${updatedUrl}?network-caching=5000&live-caching=500&rtsp-tcp';

      // Reinitialize the VLC player
      if (_controller != null && _controller!.value.isInitialized) {
        // String modifiedUrl =
        //     '${updatedUrl}?network-caching=1000&live-caching=500&rtsp-tcp';
        // _controller!.setMediaFromNetwork(_currentModifiedUrl);
        // await _controller!.play();
        // Attempt playback with retries
        await _retryPlayback(_currentModifiedUrl, 5);
        setState(() {
          _focusedIndex = index;
        });
      } else {
        throw Exception("VLC Controller is not initialized");
      }

      setState(() {
        _focusedIndex = index; // Update focus index
        _currentModifiedUrl = _currentModifiedUrl;
      });

      _scrollToFocusedItem(); // Ensure the channel is visible
      _resetHideControlsTimer();
    } catch (e) {
      print("Error switching channel: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to switch channel: ${e.toString()}")),
      );
    } finally {
      setState(() {
        _loadingVisible = false; // Hide loading indicator
      });
    }
  }

  Future<String> _fetchUpdatedUrl(String originalUrl) async {
    for (int i = 0; i < _maxRetries; i++) {
      try {
        final updatedUrl = await SocketService().getUpdatedUrl(originalUrl);
        print("Updated URL on retry $i: $updatedUrl");
        return updatedUrl;
      } catch (e) {
        print("Retry ${i + 1} failed: $e");
        if (i == _maxRetries - 1) rethrow; // Rethrow on final failure
        await Future.delayed(Duration(seconds: _retryDelay));
      }
    }
    return ''; // Return empty string if all retries fail
  }

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

  void _playNext() {
    if (_focusedIndex < widget.channelList.length - 1) {
      _onItemTap(_focusedIndex + 1);
      Future.delayed(Duration(milliseconds: 50), () {
        FocusScope.of(context).requestFocus(nextButtonFocusNode);
      });
    }
  }

  void _playPrevious() {
    if (_focusedIndex > 0) {
      _onItemTap(_focusedIndex - 1);
      Future.delayed(Duration(milliseconds: 50), () {
        FocusScope.of(context).requestFocus(prevButtonFocusNode);
      });
    }
  }

  void _togglePlayPause() {
    if (_controller != null && _controller!.value.isInitialized) {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
    }

    Future.delayed(Duration(milliseconds: 50), () {
      FocusScope.of(context).requestFocus(playPauseButtonFocusNode);
    });
    _resetHideControlsTimer();
  }

  void _scrollToFocusedItem() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        double offset = (_focusedIndex * 95.0).clamp(
          0.0,
          _scrollController.position.maxScrollExtent,
        );
        _scrollController.animateTo(
          offset,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _resetHideControlsTimer() {
    // Set initial focus and scroll
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.channelList.isEmpty) {
        FocusScope.of(context).requestFocus(playPauseButtonFocusNode);
      } else {
        FocusScope.of(context).requestFocus(focusNodes[_focusedIndex]);
        _scrollToFocusedItem();
      }
    });
    _hideControlsTimer.cancel();
    setState(() {
      _controlsVisible = true;
    });
    _startHideControlsTimer();
  }

  void _playChannelAtIndex(int index) {
    _controller!.pause();
    setState(() {
      _controller = VlcPlayerController.network(widget.channelList[index].url)
        ..initialize().then((_) {
          setState(() {});
          _controller!.play();
        });
    });
  }

  void _startHideControlsTimer() {
    _hideControlsTimer = Timer(Duration(seconds: 10), () {
      setState(() {
        _controlsVisible = false;
      });
    });
  }

  // Future<void> _saveLastPlayedVideo(
  //     String videoUrl, Duration position, String bannerImageUrl) async {
  //   if (_controller is VlcPlayerController) {
  //     position = (_controller as VlcPlayerController).value.position;
  //   } else {
  //     position = Duration.zero; // Or handle accordingly for VLC if needed
  //   }
  //   SharedPreferences prefs = await SharedPreferences.getInstance();

  //   List<String>? lastPlayedVideos =
  //       prefs.getStringList('last_played_videos') ?? [];
  //   String newVideoEntry =
  //       "$videoUrl|${position.inMilliseconds}|$bannerImageUrl";
  //   lastPlayedVideos.insert(0, newVideoEntry);

  //   if (lastPlayedVideos.length > 12) {
  //     lastPlayedVideos = lastPlayedVideos.sublist(0, 12);
  //   }

  //   await prefs.setStringList('last_played_videos', lastPlayedVideos);
  // }

  // Future<void> _saveLastPlayedVideo(
  //     String videoUrl, Duration position, String bannerImageUrl) async {
  //   if (_controller is VlcPlayerController) {
  //     position = (_controller as VlcPlayerController).value.position;
  //   } else {
  //     position = Duration.zero;
  //   }
  //   SharedPreferences prefs = await SharedPreferences.getInstance();

  //   // Get correct video name based on source
  //   String videoName = '';

  //   if (widget.isVOD) {
  //     // For VOD content
  //     if (widget.channelList.isNotEmpty &&
  //         _focusedIndex < widget.channelList.length) {
  //       videoName = widget.channelList[_focusedIndex].name ?? 'Untitled Video';
  //     }
  //   } else if (widget.isBannerSlider) {
  //     // For banner slider content
  //     if (widget.channelList.isNotEmpty &&
  //         _focusedIndex < widget.channelList.length) {
  //       videoName = widget.channelList[_focusedIndex].name ?? 'Untitled Video';
  //     }
  //   } else if (widget.isSearch) {
  //     // For search results
  //     if (widget.channelList.isNotEmpty &&
  //         _focusedIndex < widget.channelList.length) {
  //       videoName = widget.channelList[_focusedIndex].name ?? 'Untitled Video';
  //     }
  //   } else {
  //     // For regular channel content
  //     if (widget.channelList.isNotEmpty &&
  //         _focusedIndex < widget.channelList.length) {
  //       var currentChannel = widget.channelList[_focusedIndex];
  //       videoName = currentChannel.name ?? 'Untitled Video';
  //     }
  //   }

  //   // Make sure we have the correct banner URL
  //   String currentBannerUrl = '';
  //   if (widget.channelList.isNotEmpty &&
  //       _focusedIndex < widget.channelList.length) {
  //     currentBannerUrl =
  //         widget.channelList[_focusedIndex].banner ?? bannerImageUrl;
  //   } else {
  //     currentBannerUrl = bannerImageUrl;
  //   }

  //   List<String>? lastPlayedVideos =
  //       prefs.getStringList('last_played_videos') ?? [];

  //   // Create new entry with verified data
  //   String newVideoEntry =
  //       "$videoUrl|${position.inMilliseconds}|$currentBannerUrl|$videoName";

  //   // Check if this video already exists in the list
  //   int existingIndex =
  //       lastPlayedVideos.indexWhere((entry) => entry.split('|')[0] == videoUrl);
  //   if (existingIndex != -1) {
  //     // Update existing entry
  //     lastPlayedVideos[existingIndex] = newVideoEntry;
  //   } else {
  //     // Add new entry
  //     lastPlayedVideos.insert(0, newVideoEntry);
  //   }

  //   // Maintain list size
  //   if (lastPlayedVideos.length > 12) {
  //     lastPlayedVideos = lastPlayedVideos.sublist(0, 12);
  //   }

  //   await prefs.setStringList('last_played_videos', lastPlayedVideos);
  // }


Future<void> _saveLastPlayedVideo(
    String unUpdatedUrl, Duration position, String bannerImageUrl) async {
  if (_controller is VlcPlayerController) {
    position = (_controller as VlcPlayerController).value.position;
  } else {
    position = Duration.zero;
  }
  SharedPreferences prefs = await SharedPreferences.getInstance();

  String videoName = '';
  String videoSource = widget.source;
  String videoId = '';  // Added videoId variable

  if (widget.channelList.isNotEmpty && _focusedIndex < widget.channelList.length) {
    var currentChannel = widget.channelList[_focusedIndex];
    
    if (widget.isVOD) {
      videoName = currentChannel.name ?? 'Untitled Video';
      videoId = currentChannel.id?.toString() ?? '';  // Get ID for VOD content
    } else if (widget.isBannerSlider) {
      videoName = currentChannel.name ?? 'Untitled Video';
      videoId = currentChannel.contentId?.toString() ?? '';  // Get contentId for banner slider
    } else if (widget.isSearch) {
      videoName = currentChannel.name ?? 'Untitled Video';
      videoId = currentChannel.id?.toString() ?? '';  // Get ID for search results
    } else {
      videoName = currentChannel.name ?? 'Untitled Video';
      videoId = currentChannel.id?.toString() ?? '';  // Get ID for regular channels
    }
  }

  String currentBannerUrl = '';
  if (widget.channelList.isNotEmpty && _focusedIndex < widget.channelList.length) {
    currentBannerUrl = widget.channelList[_focusedIndex].banner ?? bannerImageUrl;
  } else {
    currentBannerUrl = bannerImageUrl;
  }

  List<String>? lastPlayedVideos = prefs.getStringList('last_played_videos') ?? [];

  // Update entry format to include id
  String newVideoEntry = "$unUpdatedUrl|${position.inMilliseconds}|$currentBannerUrl|$videoName|$videoSource|$videoId";

  // Check if video exists using both URL and ID
  int existingIndex = lastPlayedVideos.indexWhere((entry) {
    List<String> parts = entry.split('|');
    return parts[0] == unUpdatedUrl || (parts.length >= 6 && parts[5] == videoId);
  });

  if (existingIndex != -1) {
    lastPlayedVideos[existingIndex] = newVideoEntry;
  } else {
    lastPlayedVideos.insert(0, newVideoEntry);
  }

  if (lastPlayedVideos.length > 12) {
    lastPlayedVideos = lastPlayedVideos.sublist(0, 12);
  }

  await prefs.setStringList('last_played_videos', lastPlayedVideos);
}

  void _seekForward() {
    if (_controller != null) {
      final newPosition = (_controller)!.value.position + Duration(seconds: 60);
      (_controller)!.seekTo(newPosition);
    }
    Future.delayed(Duration(milliseconds: 50), () {
      FocusScope.of(context).requestFocus(forwardButtonFocusNode);
    });
  }

  void _seekBackward() {
    if (_controller != null) {
      final newPosition = (_controller)!.value.position - Duration(seconds: 60);
      (_controller)!
          .seekTo(newPosition > Duration.zero ? newPosition : Duration.zero);
    }
    Future.delayed(Duration(milliseconds: 50), () {
      FocusScope.of(context).requestFocus(backwardButtonFocusNode);
    });
  }

// void _onItemTap(int index) {
//   _focusedIndex = index;
//   _playChannelAtIndex(index);
// }

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
          _resetHideControlsTimer();
          if (playPauseButtonFocusNode.hasFocus ||
              backwardButtonFocusNode.hasFocus ||
              forwardButtonFocusNode.hasFocus ||
              prevButtonFocusNode.hasFocus ||
              nextButtonFocusNode.hasFocus ||
              progressIndicatorFocusNode.hasFocus) {
            Future.delayed(Duration(milliseconds: 50), () {
              if (!widget.isLive) {
                FocusScope.of(context).requestFocus(focusNodes[_focusedIndex]);
              }
            });
          } else if (_focusedIndex > 0) {
            if (widget.channelList.isEmpty) return;
            setState(() {
              _focusedIndex--;
              FocusScope.of(context).requestFocus(focusNodes[_focusedIndex]);
              _scrollToFocusedItem();
            });
          }
          break;

        case LogicalKeyboardKey.arrowDown:
          _resetHideControlsTimer();
          // if (
          //   playPauseButtonFocusNode.hasFocus ||
          //     backwardButtonFocusNode.hasFocus ||
          //     forwardButtonFocusNode.hasFocus ||
          //     prevButtonFocusNode.hasFocus ||
          //     nextButtonFocusNode.hasFocus) {
          //   Future.delayed(Duration(milliseconds: 50), () {
          //     if (!widget.isLive) {
          //       FocusScope.of(context).requestFocus(progressIndicatorFocusNode);
          //     }
          //   });
          // } else
          if (progressIndicatorFocusNode.hasFocus) {
            FocusScope.of(context).requestFocus(focusNodes[_focusedIndex]);
          } else if (_focusedIndex < widget.channelList.length - 1) {
            setState(() {
              _focusedIndex++;
              FocusScope.of(context).requestFocus(focusNodes[_focusedIndex]);
              _scrollToFocusedItem();
            });
          } else if (_focusedIndex < widget.channelList.length) {
            Future.delayed(Duration(milliseconds: 50), () {
              FocusScope.of(context).requestFocus(playPauseButtonFocusNode);
            });
          }
          break;

        case LogicalKeyboardKey.arrowRight:
          _resetHideControlsTimer();
          if (progressIndicatorFocusNode.hasFocus) {
            if (!widget.isLive) {
              _seekForward();
            }
            Future.delayed(Duration(milliseconds: 50), () {
              FocusScope.of(context).requestFocus(progressIndicatorFocusNode);
            });
          } else if (focusNodes.any((node) => node.hasFocus)) {
            Future.delayed(Duration(milliseconds: 50), () {
              FocusScope.of(context).requestFocus(playPauseButtonFocusNode);
            });
          } else if (playPauseButtonFocusNode.hasFocus) {
            Future.delayed(Duration(milliseconds: 50), () {
              if (widget.channelList.isEmpty && widget.isLive) {
                FocusScope.of(context).requestFocus(progressIndicatorFocusNode);
              } else if (widget.isLive && !widget.channelList.isEmpty) {
                FocusScope.of(context).requestFocus(prevButtonFocusNode);
              } else {
                FocusScope.of(context).requestFocus(backwardButtonFocusNode);
              }
            });
          } else if (backwardButtonFocusNode.hasFocus) {
            Future.delayed(Duration(milliseconds: 50), () {
              FocusScope.of(context).requestFocus(forwardButtonFocusNode);
            });
          } else if (forwardButtonFocusNode.hasFocus) {
            Future.delayed(Duration(milliseconds: 50), () {
              if (widget.channelList.isEmpty) {
                FocusScope.of(context).requestFocus(progressIndicatorFocusNode);
              } else {
                FocusScope.of(context).requestFocus(prevButtonFocusNode);
              }
            });
          } else if (prevButtonFocusNode.hasFocus) {
            Future.delayed(Duration(milliseconds: 50), () {
              FocusScope.of(context).requestFocus(nextButtonFocusNode);
            });
          } else if (nextButtonFocusNode.hasFocus) {
            Future.delayed(Duration(milliseconds: 50), () {
              FocusScope.of(context).requestFocus(progressIndicatorFocusNode);
            });
          }
          break;

        case LogicalKeyboardKey.arrowLeft:
          _resetHideControlsTimer();
          if (progressIndicatorFocusNode.hasFocus) {
            if (!widget.isLive) {
              _seekBackward();
            }
            Future.delayed(Duration(milliseconds: 50), () {
              FocusScope.of(context).requestFocus(progressIndicatorFocusNode);
            });
          } else if (nextButtonFocusNode.hasFocus) {
            Future.delayed(Duration(milliseconds: 50), () {
              FocusScope.of(context).requestFocus(prevButtonFocusNode);
            });
          } else if (prevButtonFocusNode.hasFocus) {
            Future.delayed(Duration(milliseconds: 50), () {
              if (widget.isLive) {
                FocusScope.of(context).requestFocus(playPauseButtonFocusNode);
              } else {
                FocusScope.of(context).requestFocus(forwardButtonFocusNode);
              }
            });
          } else if (forwardButtonFocusNode.hasFocus) {
            Future.delayed(Duration(milliseconds: 50), () {
              FocusScope.of(context).requestFocus(playPauseButtonFocusNode);
            });
          } else if (backwardButtonFocusNode.hasFocus) {
            Future.delayed(Duration(milliseconds: 50), () {
              FocusScope.of(context).requestFocus(playPauseButtonFocusNode);
            });
          } else if (playPauseButtonFocusNode.hasFocus) {
            Future.delayed(Duration(milliseconds: 50), () {
              FocusScope.of(context).requestFocus(focusNodes[_focusedIndex]);
              _scrollToFocusedItem();
            });
          } else if (focusNodes.any((node) => node.hasFocus)) {
            Future.delayed(Duration(milliseconds: 50), () {
              FocusScope.of(context).requestFocus(playPauseButtonFocusNode);
            });
          }
          break;

        case LogicalKeyboardKey.select:
        case LogicalKeyboardKey.enter:
          _resetHideControlsTimer();
          if (nextButtonFocusNode.hasFocus) {
            _playNext();
            FocusScope.of(context).requestFocus(nextButtonFocusNode);
          } else if (prevButtonFocusNode.hasFocus) {
            _playPrevious();
            FocusScope.of(context).requestFocus(prevButtonFocusNode);
          } else if (forwardButtonFocusNode.hasFocus) {
            _seekForward();
            FocusScope.of(context).requestFocus(forwardButtonFocusNode);
          } else if (backwardButtonFocusNode.hasFocus) {
            _seekBackward();
            FocusScope.of(context).requestFocus(backwardButtonFocusNode);
          } else if (playPauseButtonFocusNode.hasFocus) {
            _togglePlayPause();
            FocusScope.of(context).requestFocus(playPauseButtonFocusNode);
          } else {
            // if (widget.isLive) {
            _onItemTap(_focusedIndex);
            // } else {
            // FocusScope.of(context).requestFocus(playPauseButtonFocusNode);
            // }
          }
          break;
      }
    }
  }

  Widget _buildVideoPlayer() {
    if (!_isVideoInitialized || _controller == null) {
      return Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Get screen dimensions
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;

        // Get video dimensions
        final videoWidth = _controller!.value.size?.width ?? screenWidth;
        final videoHeight = _controller!.value.size?.height ?? screenHeight;

        // Calculate aspect ratios
        final videoRatio = videoWidth / videoHeight;
        final screenRatio = screenWidth / screenHeight;

        // Default scale factors
        double scaleX = 1.0;
        double scaleY = 1.0;

        // Calculate optimal scaling
        if (videoRatio < screenRatio) {
          // Video is too narrow, scale width while maintaining aspect ratio
          scaleX = (screenRatio / videoRatio).clamp(1.0, 1.35);
          // Adjust height if width scaling is too aggressive
          if (scaleX > 1.2) {
            scaleY = (1.0 / (scaleX - 1.0)).clamp(0.85, 1.0);
          }
        } else {
          // Video is too wide, scale height while maintaining aspect ratio
          scaleY = (videoRatio / screenRatio).clamp(0.85, 1.0);
          scaleX = scaleX.clamp(1.0, 1.35); // Limit horizontal scaling
        }

        return Container(
          width: screenWidth,
          height: screenHeight,
          color: Colors.black,
          child: Center(
            child: Transform(
              transform: Matrix4.identity()..scale(scaleX, scaleY, 1.0),
              alignment: Alignment.center,
              child: VlcPlayer(
                controller: _controller!,
                placeholder: Center(child: CircularProgressIndicator()),
                aspectRatio: 16 / 9,
              ),
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
        _controller!.pause();
        await _saveLastPlayedVideo(
            widget.unUpdatedUrl ,
            _controller?.value.position ?? Duration.zero,
            widget.bannerImageUrl);
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
                  // Video Player - यहाँ नया implementation जोड़ा गया है
                  if (_isVideoInitialized && _controller != null)
                    _buildVideoPlayer(), // नया _buildVideoPlayer method का उपयोग

                  // Loading Indicator
                  if (_loadingVisible || !_isVideoInitialized || _isBuffering)
                    Container(
                      color: Colors.black54,
                      child: Center(child: LoadingIndicator()),
                    ),

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
    // if (!_isVolumeIndicatorVisible) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.volume_up, color: Colors.white, size: 24),
          Expanded(
            child: LinearProgressIndicator(
              value: _currentVolume, // Dynamic value from _currentVolume
              color: Colors.blue,
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
      left: MediaQuery.of(context).size.width * 0.0,
      right: MediaQuery.of(context).size.width * 0.78,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        // color: Colors.black.withOpacity(0.3),
        child: ListView.builder(
          controller: _scrollController,
          itemCount: widget.channelList.length,
          itemBuilder: (context, index) {
            final channel = widget.channelList[index];
            final bool isBase64 = channel.banner?.startsWith('data:image') ??
                false; // Check if banner is base64
            return Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Focus(
                focusNode: focusNodes[index],
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
                                ? Colors.blue
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
                                  ?
                                  // Image.memory(
                                  //     _getImageFromBase64String(
                                  //         channel.banner ?? ''),
                                  //     fit: BoxFit.cover,
                                  //     errorBuilder:
                                  //         (context, error, stackTrace) =>
                                  //             Container(color: Colors.grey[800]),
                                  //   )
                                  Image.memory(
                                      _getCachedImage(
                                          channel.banner ?? localImage),
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              localImage,
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

  Widget _buildCustomProgressIndicator() {
    double playedProgress =
        (_controller?.value.position.inMilliseconds.toDouble() ?? 0.0) /
            (_controller?.value.duration.inMilliseconds.toDouble() ?? 1.0);

    double bufferedProgress = (playedProgress + 0.02).clamp(0.0, 1.0);

    return Container(
        // Add padding to make the indicator more visible when focused
        padding: EdgeInsets.all(screenhgt * 0.03),
        // Change background color based on focus state
        decoration: BoxDecoration(
          color: progressIndicatorFocusNode.hasFocus
              ? const Color.fromARGB(
                  200, 16, 62, 99) // Blue background when focused
              : Colors.transparent,
          // Optional: Add rounded corners when focused
          borderRadius: progressIndicatorFocusNode.hasFocus
              ? BorderRadius.circular(4.0)
              : null,
        ),
        child: Stack(
          children: [
            // Buffered progress
            LinearProgressIndicator(
              value: bufferedProgress.isNaN ? 0.0 : bufferedProgress,
              color: Colors.green, // Buffered color
              backgroundColor: Colors.grey, // Background
            ),
            // Played progress
            LinearProgressIndicator(
              value: playedProgress.isNaN ? 0.0 : playedProgress,
              color: Colors.blue, // Played color
              backgroundColor: Colors.transparent, // Transparent to overlay
            ),
          ],
        ));
  }

  Widget _buildControls() {
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
                Expanded(
                  flex: 2,
                  child: Container(
                    color: playPauseButtonFocusNode.hasFocus
                        ? const Color.fromARGB(200, 16, 62, 99)
                        : Colors.transparent,
                    child: Center(
                      child: Focus(
                        focusNode: playPauseButtonFocusNode,
                        onFocusChange: (hasFocus) {
                          setState(() {
                            // Change color based on focus state
                          });
                        },
                        child: IconButton(
                          icon: Icon(
                            (_controller is VlcPlayerController &&
                                    (_controller as VlcPlayerController)
                                        .value
                                        .isPlaying)
                                ? Icons.pause
                                : Icons.play_arrow,
                            color: playPauseButtonFocusNode.hasFocus
                                ? Colors.blue
                                : Colors.white,
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
                            setState(() {
                              // Change color based on focus state
                            });
                          },
                          child: IconButton(
                            icon: Icon(
                              Icons.replay_10,
                              color: backwardButtonFocusNode.hasFocus
                                  ? Colors.blue
                                  : Colors.white,
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
                            setState(() {
                              // Change color based on focus state
                            });
                          },
                          child: IconButton(
                            icon: Icon(
                              Icons.forward_10,
                              color: forwardButtonFocusNode.hasFocus
                                  ? Colors.blue
                                  : Colors.white,
                            ),
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
                            setState(() {
                              // Change color based on focus state
                            });
                          },
                          child: IconButton(
                            icon: Icon(
                              Icons.skip_previous,
                              color: prevButtonFocusNode.hasFocus
                                  ? Colors.blue
                                  : Colors.white,
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
                            setState(() {
                              // Change color based on focus state
                            });
                          },
                          child: IconButton(
                            icon: Icon(
                              Icons.skip_next,
                              color: nextButtonFocusNode.hasFocus
                                  ? Colors.blue
                                  : Colors.white,
                            ),
                            onPressed: _playNext,
                          ),
                        ),
                      ),
                    ),
                  ),
                // Expanded(flex: 1, child: Container()),
                Expanded(flex: 5, child: _buildVolumeIndicator()),
                // Expanded(flex: 1, child: Container()),
                Expanded(
                  flex: 20,
                  child: Center(
                    child: Focus(
                      focusNode: progressIndicatorFocusNode,
                      onFocusChange: (hasFocus) {
                        setState(() {
                          // Handle focus changes if needed
                        });
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
                Expanded(
                  flex: widget.isLive ? 3 : 1,
                  child: Center(
                    child: widget.isLive
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.circle, color: Colors.red, size: 15),
                              SizedBox(width: 5),
                              Text(
                                'Live',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        : Container(),
                  ),
                ),
              ],
            ),
          ),
          // Container(
          //   padding: EdgeInsets.symmetric(vertical: 8.0),
          //   color: progressIndicatorFocusNode.hasFocus
          //       ? const Color.fromARGB(200, 16, 62, 99)
          //       : Colors.black54,
          //   child: Row(
          //     children: [

          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }
}
