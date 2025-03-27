import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as https;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:keep_screen_on/keep_screen_on.dart';
import 'package:mobi_tv_entertainment/main.dart';
import 'package:mobi_tv_entertainment/menu_screens/home_sub_screen/home_category.dart';
import 'package:mobi_tv_entertainment/video_widget/network_reconnection_screen.dart';
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
// Add these imports at the top of your video_screen.dart file
import 'package:flutter/material.dart';
import 'dart:async';

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
  // final ScrollController _scrollController = ScrollController();
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

  // Uint8List _getImageFromBase64String(String base64String) {
  //   // Split the base64 string to remove metadata if present
  //   return base64Decode(base64String.split(',').last);
  // }

  Map<String, Uint8List> _imageCache = {};

  // Uint8List _getCachedImage(String base64String) {
  //   if (!_imageCache.containsKey(base64String)) {
  //     _imageCache[base64String] = base64Decode(base64String.split(',').last);
  //   }
  //   return _imageCache[base64String]!;
  // }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    // if (widget.liveStatus) {
    //   print("✅ BannerSlider ne liveStatus TRUE bheja hai.");
    // } else {
    //   print("❌ BannerSlider ne liveStatus FALSE bheja hai.");
    // }

    // printLastPlayedPositions();
    _previewPosition = _controller?.value.position ?? Duration.zero;
    Timer.periodic(Duration(minutes: 5), (timer) {
      if (mounted) {
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
    if (widget.isBannerSlider) {
      _focusedIndex = widget.channelList.indexWhere(
        (channel) => channel.contentId.toString() == widget.videoId.toString(),
      );
      // print(
      //     "Focused Index: $_focusedIndex, Video ID: ${widget.videoId}, Channel List Length: ${widget.channelList.length}");
    } else if (widget.isVOD || widget.source == 'isLiveScreen') {
      _focusedIndex = widget.channelList.indexWhere(
        (channel) => channel.id.toString() == widget.videoId.toString(),
      );
      // print(
      //     "Focused Index: $_focusedIndex, Video ID: ${widget.videoId}, Channel List Length: ${widget.channelList.length}");
    } else {
      _focusedIndex = widget.channelList.indexWhere(
        (channel) => channel.url == widget.videoUrl,
      );
    }
    // print(
    //     "Focused Index: $_focusedIndex, Video ID: ${widget.videoId}, Channel List Length: ${widget.channelList.length}");

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
    _initializeVLCController(_focusedIndex);
    _startHideControlsTimer();
    _startNetworkMonitor();
    _startPositionUpdater();
  }

  // @override
  // void dispose() {
  //   _saveLastPlayedVideoBeforeDispose();
  //     if (_controller != null) {
  //   _controller!.pause();
  //   // Add a small delay before disposal
  //   Future.delayed(Duration(milliseconds: 200), () {
  //     _controller!.dispose();
  //   });
  // }
  //   // _controller?.stop();
  //   // _controller?.dispose();
  //   _scrollController.dispose();
  //   _controller?.removeListener(() {});
  //   _connectivityCheckTimer?.cancel();
  //   _hideControlsTimer?.cancel();
  //   _volumeIndicatorTimer?.cancel(); // Cancel the volume timer if running
  //   // Clean up FocusNodes
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

  //   // Dispose of socket service if necessary
  //   try {
  //     _socketService.dispose();
  //   } catch (e) {
  //     print("Error disposing socket service: $e");
  //   }

  //   // Ensure screen-on feature is turned off
  //   KeepScreenOn.turnOff();

  //   WidgetsBinding.instance.removeObserver(this);

  //   super.dispose();
  // }

  // @override
  // void dispose() {
  //   // First cancel all timers and async operations
  //   _connectivityCheckTimer?.cancel();
  //   _hideControlsTimer.cancel();
  //   _volumeIndicatorTimer?.cancel();
  //   _networkCheckTimer?.cancel();
  //   _seekTimer?.cancel();

  //   // Save state before disposal if needed
  //   _saveLastPlayedVideoBeforeDispose();

  //   // Capture controller reference locally, then clear the class property
  //   final localController = _controller;
  //   _controller = null;

  //   // Use a separate function to handle controller cleanup
  //   Future.microtask(() async {
  //     await safeReleaseVlc(localController);
  //   });

  //   // Clean up all other resources
  //   _scrollController.dispose();
  //   focusNodes.forEach((node) => node.dispose());
  //   screenFocusNode.dispose();
  //   _channelListFocusNode.dispose();
  //   playPauseButtonFocusNode.dispose();
  //   progressIndicatorFocusNode.dispose();
  //   backwardButtonFocusNode.dispose();
  //   forwardButtonFocusNode.dispose();
  //   nextButtonFocusNode.dispose();
  //   prevButtonFocusNode.dispose();

  //   // Clear caches
  //   _imageCache.clear();
  //   _bannerCache.clear();

  //   // Dispose of socket service
  //   try {
  //     _socketService.dispose();
  //   } catch (e) {
  //     print("Socket service disposal error: $e");
  //   }

  //   // Ensure screen-on feature is turned off
  //   KeepScreenOn.turnOff();

  //   // Remove observer
  //   WidgetsBinding.instance.removeObserver(this);

  //   super.dispose();
  // }


//   @override
// void dispose() {
//   // First cancel all timers and async operations
//   _connectivityCheckTimer?.cancel();
//   _hideControlsTimer.cancel();
//   _volumeIndicatorTimer?.cancel();
//   _networkCheckTimer?.cancel();
//   _seekTimer?.cancel();

//   // Save state before disposal if needed
//   try {
//     _saveLastPlayedVideoBeforeDispose();
//   } catch (e) {
//     print("Non-critical error during save: $e");
//   }

//   // Capture controller reference locally, then clear the class property
//   final localController = _controller;
//   _controller = null;

//   // Use a separate function to handle controller cleanup
//   Future.microtask(() async {
//     await safeReleaseVlc(localController);
//   });

//   // Clean up all other resources
//   _scrollController.dispose();
//   focusNodes.forEach((node) => node.dispose());
//   screenFocusNode.dispose();
//   _channelListFocusNode.dispose();
//   playPauseButtonFocusNode.dispose();
//   progressIndicatorFocusNode.dispose();
//   backwardButtonFocusNode.dispose();
//   forwardButtonFocusNode.dispose();
//   nextButtonFocusNode.dispose();
//   prevButtonFocusNode.dispose();

//   // Clear caches
//   _imageCache.clear();
//   _bannerCache.clear();

//   // Turn off screen-on feature
//   try {
//     KeepScreenOn.turnOff();
//   } catch (e) {
//     print("Non-critical error turning screen off: $e");
//   }

//   // Remove observer
//   WidgetsBinding.instance.removeObserver(this);

//   super.dispose();
// }

@override
void dispose() async{
  // Cancel timers
  _connectivityCheckTimer?.cancel();
  _hideControlsTimer.cancel();
  _volumeIndicatorTimer?.cancel();
  _networkCheckTimer?.cancel();
  _seekTimer?.cancel();

  // Don't even attempt to touch the VLC controller
  _controller = null;

  // Release UI resources
  _scrollController.dispose();
  focusNodes.forEach((node) => node.dispose());
  screenFocusNode.dispose();
  _channelListFocusNode.dispose();
  playPauseButtonFocusNode.dispose();
  progressIndicatorFocusNode.dispose();
  backwardButtonFocusNode.dispose();
  forwardButtonFocusNode.dispose();
  nextButtonFocusNode.dispose();
  prevButtonFocusNode.dispose();
  
  // Force GC via platform
  platform.invokeMethod('forceKillVlc');
  
  WidgetsBinding.instance.removeObserver(this);
  super.dispose();
      await _controller!.stopRendererScanning();
    await _controller!.dispose();
}



Future<void> safeReleaseVlc(VlcPlayerController? controller) async {
  if (controller == null) return;
  
  try {
    // Remove all listeners first to prevent callbacks
    controller.removeListener(() {});
    
    // Set up a timeout to ensure we don't block indefinitely
    bool disposalCompleted = false;
    
    // Try to detach the VLC surface first via platform method
    try {
      platform.invokeMethod('detachVlcSurface');
    } catch (e) {
      print("Error during surface detachment: $e");
    }
    
    // Create a timeout that will force-complete after a very short period
    Timer(Duration(milliseconds: 300), () {
      if (!disposalCompleted) {
        print("VLC disposal timeout - forcing completion");
        // Try to force resources cleanup via platform method
        try {
          platform.invokeMethod('forceReleaseResources');
        } catch (e) {
          print("Force release error: $e");
        }
      }
    });
    
    // Try a controlled disposal with timeout, but don't await it
    try {
      controller.dispose().timeout(
        Duration(milliseconds: 100), 
        onTimeout: () {
          print("Controller disposal timed out");
          return;
        }
      );
    } catch (e) {
      print("VLC disposal error (non-critical): $e");
    }
    
    disposalCompleted = true;
  } catch (e) {
    print("Error during VLC cleanup: $e");
  }
}

static Future<void> _releaseVlcInBackground(VlcPlayerController? controller) async {
  if (controller == null) return;
  
  try {
    // Just try to dispose without blocking
    controller.dispose().timeout(
      Duration(milliseconds: 300),
      onTimeout: () {
        print("Background disposal timed out");
        return;
      }
    );
  } catch (e) {
    print("Background VLC disposal error: $e");
  }
}





Future<bool> _handleBackPress() async {
  // Immediately detach VLC controller from the view
  if (_controller != null) {
    _controller!.removeListener(() {});
  }
  
  // Navigate back immediately
  Navigator.of(context).pop();
  
  // Schedule cleanup for after navigation completes
  Future.microtask(() {
    final localController = _controller;
    _controller = null;
    
    if (localController != null) {
      try {
        localController.dispose().timeout(
          Duration(milliseconds: 500),
          onTimeout: () => print("Disposal timed out")
        );
      } catch (e) {
        print("Error during cleanup: $e");
      }
    }
  });
  
  return false;
}



  // Future<void> safeReleaseVlc(VlcPlayerController? controller) async {
  //   if (controller == null) return;

  //   try {
  //     // First cancel all listeners to prevent callbacks during cleanup
  //     controller.removeListener(() {});

  //     // Pause playback
  //     if (controller.value.isPlaying) {
  //       await controller.pause();
  //     }

  //     // Wait a moment for the pause to take effect
  //     await Future.delayed(Duration(milliseconds: 50));

  //     // Stop playback completely
  //     try {
  //       await controller.stop();
  //     } catch (e) {
  //       print("Non-critical stop error: $e");
  //     }

  //     // Wait for stop to complete
  //     await Future.delayed(Duration(milliseconds: 50));

  //     // Finally dispose
  //     await controller.dispose();
  //   } catch (e) {
  //     print("Safe VLC release error: $e");
  //   }
  // }


//   @override
// void didChangeAppLifecycleState(AppLifecycleState state) {
//   if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
//     // Force cleanup when app goes to background
//     final localController = _controller;
//     _controller = null;
    
//     // Use platform method to force cleanup
//     platform.invokeMethod('emergencyReleaseVlc');
    
//     if (localController != null) {
//       try {
//         // Only attempt to pause, nothing else
//         localController.pause();
//       } catch (e) {
//         // Ignore errors
//       }

//   }
// }



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
            // widget.videoUrl,
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
    // if (_scrollController.position.pixels ==
    //     _scrollController.position.maxScrollExtent) {
    //   // _fetchData();
    // }
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

      // const double itemHeight = 95.0; // Change if needed
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

  void _setInitialFocus() {
    if (widget.channelList.isEmpty) {
      print('Channel list is empty, focusing on Play/Pause button');
      FocusScope.of(context).requestFocus(playPauseButtonFocusNode);
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('Setting initial focus to index: $_focusedIndex');
      FocusScope.of(context).requestFocus(focusNodes[_focusedIndex]);
      _scrollToFocusedItem();
    });
  }

  // Future<void> _onNetworkReconnected() async {
  //   // if (_controller == null || !_controller!.value.isInitialized) {
  //   //   print("⚠️ VLC Controller is null or not initialized. Reinitializing...");
  //   //   await _initializeVLCController(_focusedIndex); // Reinitialize player
  //   //   return;
  //   // }
  //   if (_controller != null && _controller!.value.isInitialized) {
  //     try {
  //       print("🌐 Network reconnected, resuming playback...");

  //       // Ensure stable network connection before resuming
  //       bool isConnected = await _isInternetAvailable();
  //       if (!isConnected) {
  //         print("⚠️ Network not stable yet. Retrying...");
  //         return;
  //       }

  //       // Ensure we have a valid playback URL
  //       if (_currentModifiedUrl == null || _currentModifiedUrl!.isEmpty) {
  //         var selectedChannel = widget.channelList[_focusedIndex];
  //         _currentModifiedUrl =
  //             '${selectedChannel.url}?network-caching=5000&live-caching=2000&rtsp-tcp';
  //       }

  //       print("🎥 Resuming playback with URL: $_currentModifiedUrl");

  //       // Restart playback based on content type
  //       if (_controller!.value.isInitialized) {
  //         String netReconnectUrl = isOnItemTapUsed? GlobalVariables.UpdatedUrl : widget.videoUrl;
  //         netReconnectUrl = '${netReconnectUrl}?network-caching=8000&live-caching=2000&rtsp-tcp';
  //           if (GlobalVariables.liveStatus == true) {
  //             await _controller!
  //                 .setMediaFromNetwork(netReconnectUrl);
  //           } else {
  //             await _controller!
  //                 .setMediaFromNetwork(netReconnectUrl);
  //             // if (_lastKnownPosition > Duration.zero) {
  //             print("⏩ Seeking to last known position: $_lastKnownPosition");
  //             await _seekToPositionOnNetReconnect(
  //                 _resumePositionOnNetDisconnection);
  //             // }
  //           }
  //           await _controller!.play();

  //       }
  //     } catch (e) {
  //       print("❌ Error during reconnection: $e");
  //     }
  //   }
  // }

  bool _disablePlayNextAfterReconnect = false;

  // void _startNetworkMonitor() {
  //   _networkCheckTimer = Timer.periodic(Duration(seconds: 5), (_) async {
  //     bool isConnected = await _isInternetAvailable();
  //     if (!isConnected && !_wasDisconnected) {

  //       _wasDisconnected = true;
  //       print("🚫 Network disconnected");
  //       _disablePlayNextAfterReconnect = true;
  //       _resumePositionOnNetDisconnection = _controller!.value.position;
  //     } else if (isConnected && _wasDisconnected) {
  //       _wasDisconnected = false;
  //       print("✅ Network reconnected, attempting to resume video...");
  //       if (_controller?.value.isInitialized ?? false) {
  //       _onNetworkReconnected();
  //       }
  //     }
  //   });
  // }

// Future<void> _handleNetworkReconnection() async {
//   if (!mounted) return;

//   print("✅ Network reconnected, preparing for navigation...");

//   // Save current state before navigation
//   Duration currentPosition = _controller?.value.position ?? Duration.zero;
//   String currentUrl = isOnItemTapUsed ? GlobalVariables.UpdatedUrl : widget.videoUrl;
//   String unUpdatedUrl = GlobalVariables.unUpdatedUrl.isNotEmpty ?
//                         GlobalVariables.unUpdatedUrl : widget.unUpdatedUrl;

//   Map<String, dynamic> videoParams = {
//     'videoUrl': currentUrl,
//     'unUpdatedUrl': unUpdatedUrl,
//     'channelList': widget.channelList,
//     'bannerImageUrl': GlobalVariables.banner.isNotEmpty ? GlobalVariables.banner : widget.bannerImageUrl,
//     'startAtPosition': _resumePositionOnNetDisconnection,
//     'videoType': widget.videoType,
//     'isLive': widget.liveStatus ?? widget.isLive,
//     'isVOD': widget.isVOD,
//     'isSearch': widget.isSearch,
//     'isHomeCategory': widget.isHomeCategory,
//     'isBannerSlider': widget.isBannerSlider,
//     'videoId': widget.videoId,
//     'source': widget.source,
//     'name': GlobalVariables.name.isNotEmpty ? GlobalVariables.name : widget.name,
//     'liveStatus': GlobalVariables.liveStatus,
//     'totalDuration': _controller?.value.duration ?? widget.totalDuration,
//     'focusedIndex': _focusedIndex,
//   };

//   // Stop current video playback
//   if (_controller != null && _controller!.value.isInitialized) {
//     await _controller!.pause();
//   }

//   // Navigate to reconnection animation screen
//   if (context.mounted) {
//     Navigator.of(context).push(
//       MaterialPageRoute(
//         builder: (context) => NetworkReconnectionAnimation(
//           videoParams: videoParams,
//           onReconnectComplete: (context) {
//             // After countdown completes, navigate back to VideoScreen with preserved parameters
//             Navigator.of(context).pushReplacement(
//               MaterialPageRoute(
//                 builder: (context) => VideoScreen(
//                   videoUrl: videoParams['videoUrl'],
//                   unUpdatedUrl: videoParams['unUpdatedUrl'],
//                   channelList: videoParams['channelList'],
//                   bannerImageUrl: videoParams['bannerImageUrl'],
//                   startAtPosition: videoParams['startAtPosition'],
//                   videoType: videoParams['videoType'],
//                   isLive: videoParams['isLive'],
//                   isVOD: videoParams['isVOD'],
//                   isSearch: videoParams['isSearch'],
//                   isHomeCategory: videoParams['isHomeCategory'],
//                   isBannerSlider: videoParams['isBannerSlider'],
//                   videoId: videoParams['videoId'],
//                   source: videoParams['source'],
//                   name: videoParams['name'],
//                   liveStatus: videoParams['liveStatus'],
//                   totalDuration: videoParams['totalDuration'],
//                 ),
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }

// void _startNetworkMonitor() {
//   _networkCheckTimer = Timer.periodic(Duration(seconds: 5), (_) async {
//     bool isConnected = await _isInternetAvailable();

//     if (!isConnected && !_wasDisconnected) {
//       _wasDisconnected = true;
//       print("🚫 Network disconnected");
//       _disablePlayNextAfterReconnect = true;
//       _resumePositionOnNetDisconnection = _controller?.value.position ?? Duration.zero;

//       // Make sure we save the current state
//       GlobalVariables.position = _controller?.value.position ?? Duration.zero;
//       GlobalVariables.duration = _controller?.value.duration ?? Duration.zero;
//           print("🎮 Controller Status: {");
//           print("  isInitialized: ${_controller!.value.isInitialized}");
//           print("  isPlaying: ${_controller!.value.isPlaying}");
//           print("  position: ${_controller!.value.position}");
//           print("  hasError: ${_controller!.value.hasError}");
//           print("}");

//     } else if (isConnected && _wasDisconnected) {
//       _wasDisconnected = false;

//       // Only proceed with reconnection if controller exists and is initialized
//       if (_controller != null && _controller!.value.isInitialized) {
//         _handleNetworkReconnection();
//       } else {
//         print("⚠️ Controller not initialized, skipping reconnection handler");
//       }
//     }
//   });
// }

  void _startNetworkMonitor() {
    _networkCheckTimer = Timer.periodic(Duration(seconds: 5), (_) async {
      bool isConnected = await _isInternetAvailable();

      if (!isConnected && !_wasDisconnected) {
        _wasDisconnected = true;
        print("🚫 Network disconnected - Detailed Controller State:");

        // Capture detailed controller state when network disconnects
        if (_controller != null) {
          print("🎮 Controller Status: {");
          print("  isInitialized: ${_controller!.value.isInitialized}");
          print("  isPlaying: ${_controller!.value.isPlaying}");
          print("  position: ${_controller!.value.position}");
          print("  duration: ${_controller!.value.duration}");
          print("  hasError: ${_controller!.value.hasError}");
          if (_controller!.value.hasError) {
            print("  errorDescription: ${_controller!.value.errorDescription}");
          }
          print("  playingState: ${_controller!.value.playingState}");
          print("  isBuffering: ${_controller!.value.isBuffering}");
          print("  size: ${_controller!.value.size}");
          print("  playbackSpeed: ${_controller!.value.playbackSpeed}");
          print("  activeAudioTrack: ${_controller!.value.activeAudioTrack}");
          print("  activeVideoTrack: ${_controller!.value.activeVideoTrack}");
          print("}");
        } else {
          print("  Controller is null");
        }

        _disablePlayNextAfterReconnect = true;
        _resumePositionOnNetDisconnection =
            _controller?.value.position ?? Duration.zero;

        // Make sure we save the current state
        GlobalVariables.position = _controller?.value.position ?? Duration.zero;
        GlobalVariables.duration = _controller?.value.duration ?? Duration.zero;
      } else if (isConnected && _wasDisconnected) {
        _wasDisconnected = false;

        print("✅ Network reconnected - Detailed Controller State:");
        // Capture detailed controller state when network reconnects
        if (_controller != null) {
          print("🎮 Controller Status: {");
          print("  isInitialized: ${_controller!.value.isInitialized}");
          print("  isPlaying: ${_controller!.value.isPlaying}");
          print("  position: ${_controller!.value.position}");
          print("  duration: ${_controller!.value.duration}");
          print("  hasError: ${_controller!.value.hasError}");
          if (_controller!.value.hasError) {
            print("  errorDescription: ${_controller!.value.errorDescription}");
          }
          print("  playingState: ${_controller!.value.playingState}");
          print("  isBuffering: ${_controller!.value.isBuffering}");
          print("  size: ${_controller!.value.size}");
          print("  playbackSpeed: ${_controller!.value.playbackSpeed}");
          print("}");

          // Only proceed with reconnection if controller exists and is initialized
          if (_controller!.value.isInitialized) {
            _handleNetworkReconnection();
          } else {
            print(
                "⚠️ Controller not initialized, skipping reconnection handler");
          }
        } else {
          print("  Controller is null");
        }
      }
    });
  }

// // Enhanced handling of network reconnection
//   Future<void> _handleNetworkReconnection() async {
//     if (!mounted) return;

//     print("✅ Network reconnected, preparing for navigation...");

//     // Save current state before navigation
//     Duration currentPosition = _controller?.value.position ?? Duration.zero;
//     String currentUrl =
//         isOnItemTapUsed ? GlobalVariables.UpdatedUrl : widget.videoUrl;
//     String unUpdatedUrl = GlobalVariables.unUpdatedUrl.isNotEmpty
//         ? GlobalVariables.unUpdatedUrl
//         : widget.unUpdatedUrl;

//     // Log additional information about the controller and variables
//     print("🔄 Reconnection Variables: {");
//     print("  currentPosition: $currentPosition");
//     print(
//         "  resumePositionOnNetDisconnection: $_resumePositionOnNetDisconnection");
//     print("  currentUrl: $currentUrl");
//     print("  unUpdatedUrl: $unUpdatedUrl");
//     print("  isOnItemTapUsed: $isOnItemTapUsed");
//     print("  liveStatus: ${GlobalVariables.liveStatus}");
//     print("}");

//     Map<String, dynamic> videoParams = {
//       'videoUrl': currentUrl,
//       'unUpdatedUrl': unUpdatedUrl,
//       'channelList': widget.channelList,
//       'bannerImageUrl': GlobalVariables.banner.isNotEmpty
//           ? GlobalVariables.banner
//           : widget.bannerImageUrl,
//       'startAtPosition': _resumePositionOnNetDisconnection,
//       'videoType': widget.videoType,
//       'isLive': widget.liveStatus ?? widget.isLive,
//       'isVOD': widget.isVOD,
//       'isSearch': widget.isSearch,
//       'isHomeCategory': widget.isHomeCategory,
//       'isBannerSlider': widget.isBannerSlider,
//       'videoId': widget.videoId,
//       'source': widget.source,
//       'name':
//           GlobalVariables.name.isNotEmpty ? GlobalVariables.name : widget.name,
//       'liveStatus': GlobalVariables.liveStatus,
//       'totalDuration': _controller?.value.duration ?? widget.totalDuration,
//       'focusedIndex': _focusedIndex,
//     };

//     // Stop current video playback
//     if (_controller != null && _controller!.value.isInitialized) {
//       try {
//         print("📱 Pausing playback before navigation");
//         await _controller!.pause();
//       } catch (e) {
//         print("⚠️ Error pausing controller: $e");
//       }
//     }

//     // Navigate to reconnection animation screen
//     if (context.mounted) {
//       Navigator.of(context).push(
//         MaterialPageRoute(
//           builder: (context) => NetworkReconnectionAnimation(
//             videoParams: videoParams,
//             onReconnectComplete: (context) {
//               // After countdown completes, navigate back to VideoScreen with preserved parameters
//               Navigator.of(context).pushReplacement(
//                 MaterialPageRoute(
//                   builder: (context) => VideoScreen(
//                     videoUrl: videoParams['videoUrl'],
//                     unUpdatedUrl: videoParams['unUpdatedUrl'],
//                     channelList: videoParams['channelList'],
//                     bannerImageUrl: videoParams['bannerImageUrl'],
//                     startAtPosition: videoParams['startAtPosition'],
//                     videoType: videoParams['videoType'],
//                     isLive: videoParams['isLive'],
//                     isVOD: videoParams['isVOD'],
//                     isSearch: videoParams['isSearch'],
//                     isHomeCategory: videoParams['isHomeCategory'],
//                     isBannerSlider: videoParams['isBannerSlider'],
//                     videoId: videoParams['videoId'],
//                     source: videoParams['source'],
//                     name: videoParams['name'],
//                     liveStatus: videoParams['liveStatus'],
//                     totalDuration: videoParams['totalDuration'],
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),
//       );
//     }
//   }



Future<void> _handleNetworkReconnection() async {
  if (!mounted) return;
  
  print("✅ Network reconnected, preparing to restore video playback");

  // First, clean up the old controller properly
  if (_controller != null) {
    try {
      // Pause and stop any ongoing playback to prevent resource conflicts
      if (_controller!.value.isPlaying) {
        await _controller!.pause();
      }
      
      // Save state before destroying the controller
      final currentPosition = _controller?.value.position ?? Duration.zero;
      _resumePositionOnNetDisconnection = currentPosition;
      
      // Clear the controller reference after capturing position
      final oldController = _controller;
      _controller = null;
      
      // Dispose the old controller in the background
      Future.microtask(() {
        try {
          oldController?.dispose();
        } catch (e) {
          print("Non-critical disposal error: $e");
        }
      });
      
    } catch (e) {
      print("Error while cleaning up old controller: $e");
    }
  }
  
  // Set loading state
  setState(() {
    _loadingVisible = true;
    _isVideoInitialized = false;
  });
  
  // Get the current URL
  String currentUrl = isOnItemTapUsed ? GlobalVariables.UpdatedUrl : widget.videoUrl;
  
  try {
    // Create a new controller with buffering parameters
    String modifiedUrl = '$currentUrl?network-caching=12000&live-caching=5000&rtsp-tcp';
    
    // Create and initialize a new controller
    _controller = VlcPlayerController.network(
      modifiedUrl,
      hwAcc: HwAcc.auto,
      options: VlcPlayerOptions(
        advanced: VlcAdvancedOptions([
          '--network-caching=12000',
          '--file-caching=5000',
          '--live-caching=5000',
          '--rtsp-tcp',
        ]),
        video: VlcVideoOptions([
          VlcVideoOptions.dropLateFrames(true),
          VlcVideoOptions.skipFrames(true),
        ]),
      ),
    );
    
    // Initialize the new controller
    await _controller!.initialize();
    
    // Add listeners for monitoring video state
    _controller!.addListener(() {
      if (_controller!.value.hasError) {
        print("VLC Error: ${_controller!.value.errorDescription}");
      }
      
      if (_controller!.value.isBuffering) {
        setState(() {
          _isBuffering = true;
        });
      } else {
        setState(() {
          _isBuffering = false;
          _loadingVisible = false;
        });
      }
      
      // Additional listener code as needed
    });
    
    // Seek to the last known position for VOD content
    if (!widget.liveStatus && _resumePositionOnNetDisconnection > Duration.zero) {
      await Future.delayed(Duration(milliseconds: 500));
      await _controller!.seekTo(_resumePositionOnNetDisconnection);
    }
    
    // Start playback
    await _controller!.play();
    
    setState(() {
      _isVideoInitialized = true;
      _loadingVisible = false;
    });
    
    print("✅ Video playback successfully restored after network reconnection");
    
  } catch (e) {
    print("❌ Error during reconnection: $e");
    
    // If we fail, show error state and reset controller
    setState(() {
      _loadingVisible = false;
      _isVideoInitialized = false;
    });
    
    // Optionally retry after a delay
    Future.delayed(Duration(seconds: 3), () {
      if (mounted && _wasDisconnected) {
        _handleNetworkReconnection();
      }
    });
  }
}

  // Add these modifications to your _VideoScreenState class

// // Add this method to your _VideoScreenState class
// Future<void> _onNetworkReconnected() async {
//   if (!mounted) return;

//   // Prepare parameters for navigation
//   Map<String, dynamic> videoParams = {
//     'videoUrl': isOnItemTapUsed ? GlobalVariables.UpdatedUrl : widget.videoUrl,
//     'unUpdatedUrl': GlobalVariables.unUpdatedUrl.isNotEmpty ? GlobalVariables.unUpdatedUrl : widget.unUpdatedUrl,
//     'channelList': widget.channelList,
//     'bannerImageUrl': GlobalVariables.banner.isNotEmpty ? GlobalVariables.banner : widget.bannerImageUrl,
//     'startAtPosition': _resumePositionOnNetDisconnection,
//     'videoType': widget.videoType,
//     'isLive': widget.isLive,
//     'isVOD': widget.isVOD,
//     'isSearch': widget.isSearch,
//     'isHomeCategory': widget.isHomeCategory,
//     'isBannerSlider': widget.isBannerSlider,
//     'videoId': widget.videoId,
//     'source': widget.source,
//     'name': GlobalVariables.name.isNotEmpty ? GlobalVariables.name : widget.name,
//     'liveStatus': GlobalVariables.liveStatus,
//     'selectedChannelIndex': _focusedIndex,
//     'totalDuration': _controller?.value.duration ?? widget.totalDuration,
//   };

//   // Hide loading indicators if any
//   setState(() {
//     _loadingVisible = false;
//   });

//   // Navigate to reconnection handler screen
//   Navigator.of(context).push(
//     MaterialPageRoute(
//       builder: (context) => ReconnectionHandlerScreen(
//         videoParams: videoParams,
//         onReconnectComplete: (context) {
//           // After 3 seconds, navigate back to VideoScreen with preserved parameters
//           Navigator.of(context).pushReplacement(
//             MaterialPageRoute(
//               builder: (context) => VideoScreen(
//                 videoUrl: videoParams['videoUrl'],
//                 unUpdatedUrl: videoParams['unUpdatedUrl'],
//                 channelList: videoParams['channelList'],
//                 bannerImageUrl: videoParams['bannerImageUrl'],
//                 startAtPosition: videoParams['startAtPosition'],
//                 videoType: videoParams['videoType'],
//                 isLive: videoParams['isLive'],
//                 isVOD: videoParams['isVOD'],
//                 isSearch: videoParams['isSearch'],
//                 isHomeCategory: videoParams['isHomeCategory'],
//                 isBannerSlider: videoParams['isBannerSlider'],
//                 videoId: videoParams['videoId'],
//                 source: videoParams['source'],
//                 name: videoParams['name'],
//                 liveStatus: videoParams['liveStatus'],
//                 totalDuration: videoParams['totalDuration'],
//               ),
//             ),
//           );
//         },
//       ),
//     ),
//   );
// }

// // Replace the existing _startNetworkMonitor() method with this one
// void _startNetworkMonitor() {
//   _networkCheckTimer = Timer.periodic(Duration(seconds: 5), (_) async {
//     bool isConnected = await _isInternetAvailable();
//     if (!isConnected && !_wasDisconnected) {
//       _wasDisconnected = true;
//       print("🚫 Network disconnected");
//       _disablePlayNextAfterReconnect = true;
//       _resumePositionOnNetDisconnection = _controller!.value.position;
//     } else if (isConnected && _wasDisconnected) {
//       _wasDisconnected = false;
//       print("✅ Network reconnected, navigating to temporary screen...");

//       // Instead of trying to recover in place, navigate to temporary screen first
//       _onNetworkReconnected();
//     }
//   });
// }

// Add an import at the top of your file
// import 'path/to/network_reconnect_handler.dart';

  Future<bool> _isInternetAvailable() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // void _startPositionUpdater() {
  //   Timer.periodic(Duration(seconds: 1), (_) {
  //     if (mounted && _controller?.value.isInitialized == true) {
  //       setState(() {
  //         _lastKnownPosition = _controller!.value.position;
  //       });
  //     }
  //   });
  // }

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

  // void printLastPlayedPositions() {
  //   for (int i = 0; i < widget.channelList.length; i++) {
  //     final video = widget.channelList[i];
  //     // final positionkagf = video.startAtPosition ??
  //     Duration.zero; // Safely handle null values
  //     // print('Video $i: PositionprintLastPlayed - ${positionkagf}');
  //   }
  // }

  // void printAllStartAtPositions() {
  //   for (int i = 0; i < widget.channelList.length; i++) {
  //     var channel = widget.channelList[i];
  //     print("Index: $i");
  //     print("Channel Name: ${channel.name}");
  //     print("Channel ID: ${channel.id}");
  //     print("StartAtPositions: ${widget.startAtPosition}");
  //     print("---------------------------");
  //   }
  // }

  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();
  //   if (_isVideoInitialized && !_controller!.value.isPlaying) {
  //     _controller!.play();
  //   }
  // }

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

        // Seek karein bina reloading ke
        await _controller!.seekTo(position);
        // OR: await _controller!.setTime(position.inMilliseconds);

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

  // Future<void> _seekToPositionOntap(Duration position) async {
  //   if (_isSeekingOntap || _controller == null || !_controller!.value.isInitialized) return; // Skip if a seek operation is already in progress

  //   _isSeekingOntap = true;
  //   try {
  //     print("Seeking to position: $position");
  //     await _controller!.seekTo(position); // Perform the seek operation
  //     await _controller!.play(); // Start playback from the new position
  //   } catch (e) {
  //     print("Error during seek: $e");
  //   } finally {
  //     // Add a small delay to ensure the operation completes before resetting the flag
  //     await Future.delayed(Duration(milliseconds: 500));
  //     _isSeekingOntap = false;
  //   }
  // }

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

        // Seek karein bina reloading ke
        await _controller!.seekTo(position);
        // OR: await _controller!.setTime(position.inMilliseconds);

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

  bool _hasSeeked = false;

  Future<void> _initializeVLCController(int index) async {
    // printAllStartAtPositions();

    setState(() {
      _hasSeeked = false;
    });

    String _currentModifiedUrl =
        '${widget.videoUrl}?network-caching=8000&live-caching=3000&rtsp-tcp';

    // Initialize the controller
    if (_controller == null) {
      _controller = VlcPlayerController.network(
        _currentModifiedUrl,
        hwAcc: HwAcc.auto,
        // autoPlay: true,
        options: VlcPlayerOptions(
          advanced: VlcAdvancedOptions([
            //   '--no-video-title-show', // Hide video title overlay
            //   '--no-spu', // Disable subtitles for faster loading
            //   '--network-caching=3000', // Reduce caching delay
            //   '--file-caching=3000',
            //   '--live-caching=1000',
            // '--rtsp-tcp',
          ]),
          video: VlcVideoOptions([
            VlcVideoOptions.dropLateFrames(true),
            VlcVideoOptions.skipFrames(true),
          ]),
        ),
        // options: VlcPlayerOptions(
        //   video: VlcVideoOptions([
        //     VlcVideoOptions.dropLateFrames(true),
        //     VlcVideoOptions.skipFrames(true),
        //   ]),
        // ),
      );

      _controller!.initialize();

// _controller!.initialize().then((_) {
//   print("VLC Player initialized");
//   _controller!.play();
// }).catchError((error) {
//   print("VLC Initialization Error: $error");
// });
      // // Retry playback in case of failures
      // await _retryPlayback(modifiedUrl, 5);
      if (_controller!.value.hasError) {
        print("VLC Error: ${_controller!.value.errorDescription}");
        await _retryPlayback(_currentModifiedUrl, 3);
      }

      // Start playback after initialization
      // if (_controller!.value.isInitialized) {
      _controller!.play();
      // } else {
      //   print("Controller failed to initialize.");
      // }

      //           if (widget.isVOD) {
      //   if (_controller!.value.position > Duration.zero &&
      //       _controller!.value.duration > Duration.zero &&
      //       _controller!.value.position >= _controller!.value.duration) {
      //     print("Video ended. Playing next...");
      //     _playNext(); // Automatically play next video
      //   }
      // }

      _controller!.addListener(() async {
        // if (_controller!.value.isInitialized && !_controller!.value.isPlaying) {
        //   print("Video Paused, Resuming...");
        //   _controller!.play();
        // }

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

        if (_controller!.value.position <= Duration.zero ||
            _controller!.value.isBuffering) {
          _loadingVisible = true;
        } else if (_controller!.value.position > Duration.zero) {
          _loadingVisible = false;
        }
        if (_controller!.value.isBuffering) {
          _isBuffering = true;
        } else {
          _isBuffering = false;
        }

        if (widget.isVOD &&
                (_controller!.value.position >
                    Duration.zero) && // Position is greater than zero
                (_controller!.value.duration >
                    Duration.zero) && // Duration is greater than zero
                (_controller!.value.duration - _controller!.value.position <=
                    Duration(seconds: 5)) // 5 seconds or less remaining
            ) {
          print("Video is about to end. Playing next...");
          _playNext(); // Automatically play next video
        }

        //       if (
        //     _controller!.value.hasError
        //     // || e.toString().contains('LateInitializationError')
        //     || e.toString().contains('Exception')
        // ) {
        //   print("Playback error or video ended. Playing next...");
        //   _playNext();
        // }

        if (_controller!.value.hasError || e.toString().contains('Exception')) {
          print(
              "Playback error detected. Waiting for 5 seconds before deciding...");

          bool playbackRecovered = false;

          // Listen to video controller updates
          void checkPlaybackStatus() {
            if (_controller!.value.isPlaying && !_controller!.value.hasError) {
              playbackRecovered = true;
            }
          }

          _controller!.addListener(checkPlaybackStatus);

          // Wait for 5 seconds
          Future.delayed(Duration(seconds: 10), () {
            _controller!.removeListener(checkPlaybackStatus);
            if (!playbackRecovered) {
              print("Playback did not recover. Playing next...");
              if (_disablePlayNextAfterReconnect) {
                print(
                    "Skipping _playNext() because network was recently reconnected.");
              } else {
                print("Playback did not recover. Playing next...");
                _playNext(); // ✅ PlayNext sirf tab chalega jab network reconnect hone ke baad user ne video change kiya ho
              }
              // _playNext();
            } else {
              print("Playback recovered. Continuing...");
            }
          });
        }

        // Check for playback errors
      });

      setState(() {
        _isVideoInitialized = true;
        _currentModifiedUrl = _currentModifiedUrl;
      });
    }
  }

  Future<void> _retryPlayback(String url, int retries) async {
    for (int i = 0; i < retries; i++) {
      if (!mounted || !_controller!.value.isInitialized) return;

      try {
        await _controller!.setMediaFromNetwork(url);
        // Add position seeking after successful playback start

        // await _controller!.play();

        // _controller!.addListener(() async {
        //   if (_controller!.value.hasError
        //       // || e.toString().contains('LateInitializationError')
        //       ||
        //       e.toString().contains('Exception')) {
        //     print("Playback error or video ended. Playing next...");
        //     _playNext();
        //   }
        // });

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

  Future<void> _onItemTap(int index) async {
    setState(() {
      isOnItemTapUsed = true;
      _hasSeekedOntap = false;
      _disablePlayNextAfterReconnect = false;
    });
    var selectedChannel = widget.channelList[index];
    String updatedUrl = selectedChannel.url;

    // setState(() {
    //   _loadingVisible = true;
    // });

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
      }

      GlobalVariables.unUpdatedUrl = updatedUrl;
      GlobalVariables.position = _controller!.value.position;
      GlobalVariables.duration = _controller!.value.duration;
      GlobalVariables.banner = selectedChannel.banner ?? '';
      GlobalVariables.name = selectedChannel.name ?? '';

      if (selectedChannel.streamType == 'YoutubeLive' ||
          // selectedChannel.type == "YoutubeLive" ||
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

      // Now process YouTube URL if needed
      if (isYoutubeUrl(updatedUrl)) {
        print("Processing as YouTube content");
        updatedUrl = await _socketService.getUpdatedUrl(updatedUrl);
        print("Socket service returned URL: $updatedUrl");
      }

      String apiEndpoint1 = extractApiEndpoint(updatedUrl);
      print("API Endpoint onitemtap1: $apiEndpoint1");

      String _currentModifiedUrl =
          '${updatedUrl}?network-caching=8000&live-caching=3000&rtsp-tcp';

      GlobalVariables.UpdatedUrl = _currentModifiedUrl;

      if (_controller != null && _controller!.value.isInitialized) {
        // _controller!.initialize();

        await _retryPlayback(_currentModifiedUrl, 5);

        _controller!.addListener(() async {
          if (_controller!.value.isInitialized &&
              _controller!.value.duration > Duration.zero &&
              !_isSeekingOntap &&
              !_hasSeekedOntap &&
              !selectedChannel.liveStatus &&
              widget.source == 'isLastPlayedVideos') {
            if (selectedChannel.position > Duration.zero &&
                selectedChannel.position > _controller!.value.position &&
                _controller!.value.position > Duration.zero) {
              if (selectedChannel.position <= _controller!.value.position) {
                print("Video already at the desired position, skipping seek.");
                _isSeekingOntap = true;
                _hasSeekedOntap = true;
                return;
              }

              print("🔹 Channel liveStatus: ${selectedChannel.liveStatus}");
              await _seekToPositionOntap(selectedChannel.position);
              _isSeekingOntap = true;
              _hasSeekedOntap = true;
            }
          }
          _isSeekingOntap = false;
          if (_controller!.value.position <= Duration.zero) {
            _loadingVisible = true;
          } else if (_controller!.value.position > Duration.zero) {
            _loadingVisible = false;
          }

          if (_controller!.value.hasError ||
              e.toString().contains('Exception')) {
            print(
                "Playback error detected. Waiting for 5 seconds before deciding...");

            bool playbackRecovered = false;

            // Listen to video controller updates
            void checkPlaybackStatus() {
              if (_controller!.value.isPlaying &&
                  !_controller!.value.hasError) {
                playbackRecovered = true;
              }
            }

            _controller!.addListener(checkPlaybackStatus);

            // Wait for 5 seconds
            Future.delayed(Duration(seconds: 10), () {
              _controller!.removeListener(checkPlaybackStatus);
              if (!playbackRecovered) {
                print("Playback did not recover. Playing next...");
                if (_disablePlayNextAfterReconnect) {
                  print(
                      "Skipping _playNext() because network was recently reconnected.");
                } else {
                  print("Playback did not recover. Playing next...");
                  _playNext(); // ✅ PlayNext sirf tab chalega jab network reconnect hone ke baad user ne video change kiya ho
                }
                // _playNext();
              } else {
                print("Playback recovered. Continuing...");
              }
            });
          }

          if (widget.isVOD &&
                  (_controller!.value.position >
                      Duration.zero) && // Position is greater than zero
                  (_controller!.value.duration >
                      Duration.zero) && // Duration is greater than zero
                  (_controller!.value.duration - _controller!.value.position <=
                      Duration(seconds: 5)) // 5 seconds or less remaining
              ) {
            print("Video is about to end. Playing next...");
            _playNext(); // Automatically play next video
          }
        });

        setState(() {
          _focusedIndex = index;
        });
      } else {
        throw Exception("VLC Controller is not initialized");
      }

      setState(() {
        _focusedIndex = index;
        _currentModifiedUrl = _currentModifiedUrl;
      });

      _scrollToFocusedItem();
      _resetHideControlsTimer();
      // Add listener for VLC state changes
      // _controller!.addListener(() {
      //   final currentState = _controller!.value.playingState;

      //   if (currentState == PlayingState.playing ) {
      //     // Update visibility state
      //     setState(() {

      //     });
      //   }
      // });
    } catch (e) {
      print("Error switching channel: $e");
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text("Failed to switch channel: ${e.toString()}")),
      // );
    } finally {
      setState(() {
        // _loadingVisible = false;
        // Timer(Duration(seconds: widget.isVOD ? 15 : 5), () {
        //   setState(() {
        //     _loadingVisible = false;
        //   });
        // });
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

  // void _scrollToFocusedItem() {
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     if (_scrollController.hasClients) {
  //       double offset = (_focusedIndex * 95.0).clamp(
  //         0.0,
  //         _scrollController.position.maxScrollExtent,
  //       );
  //       _scrollController.animateTo(
  //         offset,
  //         duration: Duration(milliseconds: 300),
  //         curve: Curves.easeInOut,
  //       );
  //     }
  //   });
  // }

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
  //   String unUpdatedUrl,
  //   Duration position,
  //   Duration duration,
  //   String bannerImageUrl,
  //   String name,
  //   bool liveStatus,
  // ) async {
  //   try {
  //     final prefs = await SharedPreferences.getInstance();
  //     List<String> lastPlayedVideos =
  //         prefs.getStringList('last_played_videos') ?? [];

  //     if (duration <= Duration(seconds: 5) &&
  //         position <= Duration(seconds: 5)) {
  //       print("Invalid duration or position. Skipping save.");
  //       return;
  //     }

  //     // Channel se videoName aur videoId fetch karna
  //     String videoName = '';
  //     String videoId = widget.videoId?.toString() ?? '';

  //     if (widget.channelList.isNotEmpty) {
  //       int index = widget.channelList.indexWhere((channel) =>
  //           channel.url == unUpdatedUrl ||
  //           channel.id == widget.videoId.toString());
  //       if (index != -1) {
  //         // videoName = widget.channelList[index].name ?? '';
  //         videoId = widget.channelList[index].id ?? '';
  //       }
  //     }

  //     // Video entry format
  //     String newVideoEntry =
  //         "$unUpdatedUrl|${position.inMilliseconds}|${duration.inMilliseconds}|$liveStatus|$bannerImageUrl|$videoId|$name";

  //     print(
  //         "Saving video with position: ${position.inMilliseconds} ms and duration: ${duration.inMilliseconds} ms");

  //     // Remove duplicate entries
  //     lastPlayedVideos.removeWhere((entry) {
  //       List<String> parts = entry.split('|');
  //       return parts[0] == unUpdatedUrl || parts[4] == videoId;
  //     });

  //     // Add naya video entry
  //     lastPlayedVideos.insert(0, newVideoEntry);

  //     // List ko limit karna
  //     if (lastPlayedVideos.length > 25) {
  //       lastPlayedVideos = lastPlayedVideos.sublist(0, 25);
  //     }

  //     // SharedPreferences mein save karna
  //     await prefs.setStringList('last_played_videos', lastPlayedVideos);
  //     await prefs.setInt('last_video_duration', duration.inMilliseconds);
  //     await prefs.setInt('last_video_position', position.inMilliseconds);

  //     print("Savedvideo entrysuccessfully: $newVideoEntry");
  //     print("Savedvideo entrysuccessfully: $lastPlayedVideos");
  //   } catch (e) {
  //     print("Error saving last played video: $e");
  //   }
  // }

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

  void _seekForward() {
    if (_controller == null || !_controller!.value.isInitialized) return;

    setState(() {
      // Accumulate seek duration
      _accumulatedSeekForward += _seekDuration;
      // Update preview position instantly
      _previewPosition = _controller!.value.position +
          Duration(seconds: _accumulatedSeekForward);
      // Ensure preview position does not exceed video duration
      if (_previewPosition > _controller!.value.duration) {
        _previewPosition = _controller!.value.duration;
      }
    });

    // Reset and start timer to execute seek after delay
    _seekTimer?.cancel();
    _seekTimer = Timer(Duration(milliseconds: _seekDelay), () {
      if (_controller != null) {
        _controller!.seekTo(_previewPosition);
        setState(() {
          _accumulatedSeekForward = 0; // Reset accumulator after seek
        });
      }

      // Update focus to forward button
      Future.delayed(Duration(milliseconds: 50), () {
        FocusScope.of(context).requestFocus(forwardButtonFocusNode);
      });
    });
  }

  void _seekBackward() {
    if (_controller == null || !_controller!.value.isInitialized) return;

    setState(() {
      // Accumulate seek duration
      _accumulatedSeekBackward += _seekDuration;
      // Update preview position instantly
      final newPosition = _controller!.value.position -
          Duration(seconds: _accumulatedSeekBackward);
      // Ensure preview position does not go below zero
      _previewPosition =
          newPosition > Duration.zero ? newPosition : Duration.zero;
    });

    // Reset and start timer to execute seek after delay
    _seekTimer?.cancel();
    _seekTimer = Timer(Duration(milliseconds: _seekDelay), () {
      if (_controller != null) {
        _controller!.seekTo(_previewPosition);
        setState(() {
          _accumulatedSeekBackward = 0; // Reset accumulator after seek
        });
      }

      // Update focus to backward button
      Future.delayed(Duration(milliseconds: 50), () {
        FocusScope.of(context).requestFocus(backwardButtonFocusNode);
      });
    });
  }

  // void _seekForward() {
  //   if (_controller == null) return;

  //   setState(() {
  //     _accumulatedSeekForward += _seekDuration;
  //     // Instantly update preview to show total accumulated seek time
  //     _previewPosition = _controller!.value.position + Duration(seconds: _accumulatedSeekForward);
  //   });

  //   _seekTimer?.cancel();
  //   _seekTimer = Timer(Duration(milliseconds: _seekDelay), () {
  //     if (_controller != null) {
  //       _controller!.seekTo(_previewPosition);
  //       setState(() {
  //         _accumulatedSeekForward = 0;
  //       });
  //     }

  //     Future.delayed(Duration(milliseconds: 50), () {
  //       FocusScope.of(context).requestFocus(forwardButtonFocusNode);
  //     });
  //   });
  // }

  // void _seekBackward() {
  //   if (_controller == null) return;

  //   setState(() {
  //     _accumulatedSeekBackward += _seekDuration;
  //     // Instantly calculate new preview position based on total accumulated backward seek
  //     final newPosition = _controller!.value.position - Duration(seconds: _accumulatedSeekBackward);
  //     _previewPosition = newPosition > Duration.zero ? newPosition : Duration.zero;
  //   });

  //   _seekTimer?.cancel();
  //   _seekTimer = Timer(Duration(milliseconds: _seekDelay), () {
  //     if (_controller != null) {
  //       _controller!.seekTo(_previewPosition);
  //       setState(() {
  //         _accumulatedSeekBackward = 0;
  //       });
  //     }

  //     Future.delayed(Duration(milliseconds: 50), () {
  //       FocusScope.of(context).requestFocus(backwardButtonFocusNode);
  //     });
  //   });
  // }

  // void _seekForward() {
  //   if (_controller != null) {
  //     final newPosition = (_controller)!.value.position + Duration(seconds: 60);
  //     (_controller)!.seekTo(newPosition);
  //   }
  //   Future.delayed(Duration(milliseconds: 50), () {
  //     FocusScope.of(context).requestFocus(forwardButtonFocusNode);
  //   });
  // }

  // void _seekBackward() {
  //   if (_controller != null) {
  //     final newPosition = (_controller)!.value.position - Duration(seconds: 60);
  //     (_controller)!
  //         .seekTo(newPosition > Duration.zero ? newPosition : Duration.zero);
  //   }
  //   Future.delayed(Duration(milliseconds: 50), () {
  //     FocusScope.of(context).requestFocus(backwardButtonFocusNode);
  //   });
  // }

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
                // _scrollToFocusedItem();
                _scrollListener();
              }
            });
          } else if (_focusedIndex > 0) {
            if (widget.channelList.isEmpty) return;
            setState(() {
              _focusedIndex--;
              FocusScope.of(context).requestFocus(focusNodes[_focusedIndex]);
              // _scrollToFocusedItem();
              _scrollListener();
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
            // _scrollToFocusedItem();
            _scrollListener();
          } else if (_focusedIndex < widget.channelList.length - 1) {
            setState(() {
              _focusedIndex++;
              FocusScope.of(context).requestFocus(focusNodes[_focusedIndex]);
              // _scrollToFocusedItem();
              _scrollListener();
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
                placeholder: Center(child: LoadingIndicator()),
                aspectRatio: 16 / 9,
              ),
            ),
          ),
        );
      },
    );
  }


  // Add this to your _VideoScreenState class
bool _isDisposing = false;

// Then modify setState calls to check this flag
@override
void setState(VoidCallback fn) {
  if (mounted && !_isDisposing) {
    super.setState(fn);
  }
}

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // onWillPop: () async {
      //   _controller!.pause();
      //   // await _saveLastPlayedVideo(
      //   //     widget.unUpdatedUrl,
      //   //     _controller?.value.position ?? Duration.zero,
      //   //     widget.bannerImageUrl);
      //   await Future.delayed(Duration(milliseconds: 500));
      //   GlobalEventBus.eventBus.fire(RefreshPageEvent('uniquePageId'));
      //   Navigator.of(context).pop(true);
      //   return false;
      // },
onWillPop: () async {
  _isDisposing = true;
  
  // Navigate immediately without waiting for any cleanup
  Navigator.of(context).pop();
  
  // After navigation, try to clean up resources
  Future.microtask(() {
    // Cancel all timers immediately
    _hideControlsTimer.cancel();
    _networkCheckTimer?.cancel();
    _volumeIndicatorTimer?.cancel();
    _seekTimer?.cancel();
    
    // Set controller to null without attempting to dispose it
    _controller = null;
    
    // Force GC
    try {
      platform.invokeMethod('forceKillVlc');
    } catch (e) {
      print("Force kill VLC error: $e");
    }
    
    // Notify event bus after navigation completes
    GlobalEventBus.eventBus.fire(RefreshPageEvent('uniquePageId'));
  });
  
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
                  if (_loadingVisible || !_isVideoInitialized)
                    Container(
                      color: Colors.black54,
                      child: Center(
                          child: RainbowPage(
                        backgroundColor: Colors.black, // हल्का नीला बैकग्राउंड
                      )),
                    ),
                  if (_isBuffering) LoadingIndicator(),
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
          // Icon(Icons.volume_up, color: Colors.white, size: 24),
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
        // height: MediaQuery.of(context).size.height * 0.75,
        // color: Colors.black.withOpacity(0.3),
        child: ListView.builder(
          controller: _scrollController,
          itemCount: widget.channelList.length,
          itemBuilder: (context, index) {
            final channel = widget.channelList[index];
            // Handle different channel ID formats
            // final String channelId = widget.isBannerSlider
            //     ? (channel['contentId']?.toString() ?? channel.contentId?.toString() ?? '')
            //     : (channel['id']?.toString() ?? channel.id?.toString() ?? '');

            final String channelId = widget.isBannerSlider
                ? (channel.contentId?.toString() ??
                    channel.contentId?.toString() ??
                    '')
                : (channel.id?.toString() ?? channel.id?.toString() ?? '');
            // Handle banner for both map and object access
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
                                  ?
                                  // Image.memory(
                                  //     _getImageFromBase64String(
                                  //         channel.banner ?? ''),
                                  //     fit: BoxFit.cover,
                                  //     errorBuilder:
                                  //         (context, error, stackTrace) =>
                                  //             Container(color: Colors.grey[800]),
                                  //   )
                                  // Image.memory(
                                  //     _getCachedImage(
                                  //         channel.banner ?? localImage),
                                  //     fit: BoxFit.cover,
                                  //     errorBuilder:
                                  //         (context, error, stackTrace) =>
                                  //             localImage,
                                  //   )
                                  // :
                                  Image.memory(
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
              minHeight: 6,
              value: bufferedProgress.isNaN ? 0.0 : bufferedProgress,
              color: Colors.green, // Buffered color
              backgroundColor: Colors.grey, // Background
            ),
            // Played progress
            LinearProgressIndicator(
              minHeight: 6,
              value: playedProgress.isNaN ? 0.0 : playedProgress,
              valueColor: AlwaysStoppedAnimation<Color>(
                _previewPosition != _controller!.value.position
                    ? Colors.red.withOpacity(0.5) // Preview seeking
                    : Colors.red, // Normal playback
              ),
              color: const Color.fromARGB(211, 155, 40, 248), // Played color
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
                Expanded(flex: 1, child: Container()),

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
                          if (mounted) {
                            setState(() {
                              // Change color based on focus state
                            });
                          }
                        },
                        child: IconButton(
                          // icon: Icon(
                          //   (_controller is VlcPlayerController &&
                          //           (_controller as VlcPlayerController)
                          //               .value
                          //               .isPlaying)
                          //       ? Icons.pause
                          //       : Icons.play_arrow,
                          //   color: playPauseButtonFocusNode.hasFocus
                          //       ? Colors.blue
                          //       : Colors.white,
                          // ),
                          icon: Image.asset(
                            (_controller is VlcPlayerController &&
                                    (_controller as VlcPlayerController)
                                        .value
                                        .isPlaying)
                                ? 'assets/pause.png' // Add your pause image path here
                                : 'assets/play.png', // Add your play image path here
                            width: 35, // Adjust size as needed
                            height: 35,
                            // color: playPauseButtonFocusNode.hasFocus
                            //     ? Colors.blue
                            //     : Colors.white,
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
                            // icon: Icon(
                            //   Icons.replay_10,
                            //   color: backwardButtonFocusNode.hasFocus
                            //       ? Colors.blue
                            //       : Colors.white,
                            // ),
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
                            // icon: Icon(
                            //   Icons.forward_10,
                            //   color: forwardButtonFocusNode.hasFocus
                            //       ? Colors.blue
                            //       : Colors.white,
                            // ),
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
                            // icon: Icon(
                            //   Icons.skip_previous,
                            //   color: prevButtonFocusNode.hasFocus
                            //       ? Colors.blue
                            //       : Colors.white,
                            // ),
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
                            // icon: Icon(
                            //   Icons.skip_next,
                            //   color: nextButtonFocusNode.hasFocus
                            //       ? Colors.blue
                            //       : Colors.white,
                            // ),
                            icon: Image.asset('assets/next.png',
                                width: 35, height: 35),
                            onPressed: _playNext,
                          ),
                        ),
                      ),
                    ),
                  ),
                // Expanded(flex: 1, child: Container()),
                Expanded(flex: 8, child: _buildVolumeIndicator()),
                // Expanded(flex: 1, child: Container()),
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
                  flex: 20,
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
                Expanded(flex: 1, child: Container()),
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
