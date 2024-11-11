import 'dart:async';
// import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:keep_screen_on/keep_screen_on.dart';
import 'package:mobi_tv_entertainment/video_widget/socket_service.dart';
import 'package:mobi_tv_entertainment/widgets/small_widgets/loading_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

import '../menu_screens/home_sub_screen/sub_vod.dart';
import '../widgets/models/news_item_model.dart';

class VideoScreen extends StatefulWidget {
  final String videoUrl;
  final List<dynamic> channelList;
  final String bannerImageUrl;
  final Duration startAtPosition;
  final bool isLive;
  final bool isVOD;
  final String videoType;

  VideoScreen({
    required this.videoUrl,
    required this.channelList,
    required this.bannerImageUrl,
    required this.startAtPosition,
    required this.videoType,
    required this.isLive,
    required this.isVOD,
  });

  @override
  _VideoScreenState createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> with WidgetsBindingObserver {
  // final SocketService _socketService = SocketService();
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
  bool _isPlayPauseFocused = false;
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
  bool _isVolumeIndicatorVisible = false;
  Timer? _volumeIndicatorTimer;
  static const platform = MethodChannel('com.example.volume');
  bool _loadingVisible = false;
  Duration _lastKnownPosition = Duration.zero;
  bool _wasPlayingBeforeDisconnection = false;
    int _maxRetries = 3;
  int _retryDelay = 5; // seconds
  final SocketService _socketService = SocketService();


  // final ItemScrollController _itemScrollController = ItemScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    KeepScreenOn.turnOn();
    
    _initializeVolume();
    _listenToVolumeChanges();
    // _initializeVolume();
    // _socketService.initSocket();

    _focusedIndex = widget.channelList.indexOf(widget.videoUrl);

    // Initial focused index
    _focusedIndex = widget.channelList.indexWhere(
      (channel) => channel.url == widget.videoUrl,
    );
    _focusedIndex = _focusedIndex >= 0 ? _focusedIndex : 0;

    // Initialize focus nodes for channels
    focusNodes = List.generate(
      widget.channelList.length,
      (index) => FocusNode(),
    );

    // Listener for focus node changes
    _channelListFocusNode.addListener(() {
      setState(() {
        _isFocused = _channelListFocusNode.hasFocus;
      });
    });

    // Set initial focus and scroll
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(focusNodes[_focusedIndex]);
      _scrollToFocusedItem();
    });

    // Initialize VLC controller and start controls hide timer
    _initializeVLCController();
    _startHideControlsTimer();
  }

  @override
  void dispose() {
    try {
      _controller?.stop();
      Future.delayed(Duration(milliseconds: 100), () {
        _controller?.dispose();
      });
    } catch (e) {
      print("Error in dispose: $e");
    }
    _saveLastPlayedVideo(widget.videoUrl,
        _controller?.value.position ?? Duration.zero, widget.bannerImageUrl);
    // _socketService.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _hideControlsTimer.cancel();
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
    KeepScreenOn.turnOff();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // ऐप बैकग्राउंड में जाने पर वीडियो पॉज़ करें
      if (_controller!.value.isInitialized && _controller!.value.isPlaying) {
        _lastKnownPosition = _controller!.value.position;
        _wasPlayingBeforeDisconnection = true; // इस लाइन को जोड़ें
        _controller!.pause();
      } else {
        _wasPlayingBeforeDisconnection = false; // इस लाइन को जोड़ें
      }
    } else if (state == AppLifecycleState.resumed) {
      // ऐप फोरग्राउंड में वापस आने पर वीडियो रीज्यूम करें
      if (_controller!.value.isInitialized) {
        _controller!.seekTo(_lastKnownPosition);
        if (_wasPlayingBeforeDisconnection) {
          // इस चेक को जोड़ें
          _controller!.play();
        }
      }
    }
  }

  void _handleNetworkError() {
    _wasPlayingBeforeDisconnection = _controller!.value.isPlaying;
    _lastKnownPosition = _controller!.value.position;
    _controller!.pause();
    Future.delayed(Duration(seconds: 5), () {
      if (!_controller!.value.isPlaying) {
        _reinitializeVideo();
      }
    });
  }

  Future<void> _reinitializeVideo() async {
    final currentPosition = _lastKnownPosition;
    await _controller!.dispose();

    _controller = VlcPlayerController.network(widget.videoUrl);
    try {
      _controller!.initialize();
      await _controller!.seekTo(currentPosition);
      setState(() {
        _totalDuration = _controller!.value.duration;
        _currentPosition = currentPosition;
      });
      if (_wasPlayingBeforeDisconnection) {
        _controller!.play();
      }
      _controller!.addListener(_videoListener);
    } catch (error) {
      print('Error reinitializing video: $error');
      _handleNetworkError();
    }
  }

  void _videoListener() {
    setState(() {
      _isBuffering = _controller!.value.isBuffering;
      if (!_isBuffering) {
        _lastKnownPosition = _controller!.value.position;
      }
    });

    if (_controller!.value.hasError) {
      print('Video error: ${_controller!.value.errorDescription}');
      _handleNetworkError();
    }
  }

  // @override
  // void didChangeAppLifecycleState(AppLifecycleState state) {
  //   if (state == AppLifecycleState.paused) {
  //     _controller!.pause();
  //   } else if (state == AppLifecycleState.resumed) {
  //     _controller!.play();
  //   }
  // }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isVideoInitialized && !_controller!.value.isPlaying) {
      _controller!.play();
    }
  }

// Future<void> _initializeVLCController() async {
//   try {
//     setState(() {
//       _isBuffering = true;
//       _isVideoInitialized = false;
//       _loadingVisible = true; // Show loading initially
//     });

//     // Initialize the VLC player controller
//     _controller = VlcPlayerController.network(
//       widget.videoUrl,
//       hwAcc: HwAcc.full,
//       autoPlay: true,
//       options: VlcPlayerOptions(),
//     );

//     // Add listener for initialization
//     _controller!.addListener(() {
//       // Check if video is initialized and buffering has completed
//       if (_controller!.value.isInitialized && _isBuffering) {
//         setState(() {
//           _isBuffering = false;
//           _isVideoInitialized = true;
//           _loadingVisible = false; // Hide loading once video is ready
//         });
//       }

//       // Additional logic for errors or state changes
//       if (_controller!.value.hasError) {
//         print("Video Error: ${_controller!.value.errorDescription}");
//         setState(() {
//           _isBuffering = false;
//           _loadingVisible = false; // Hide loading on error
//         });
//       }
//     });

//     // Start initializing the controller
//      _controller!.initialize();

//     setState(() {
//       _isVideoInitialized = true;
//       _isBuffering = false;
//       // _loadingVisible = false; // Ensure loading is hidden
//     });
//         // Automatically hide loading after 3 seconds
  // Timer(Duration(seconds: 4), () {
  //   setState(() {
  //     _loadingVisible = false;
  //   });
  // });
//   } catch (error) {
//     print("Error initializing the video: $error");
//     setState(() {
//       _isVideoInitialized = false;
//       _isBuffering = false;
//       _loadingVisible = false; // Hide loading on failure
//     });
//   }
// }

//   void _onItemTap(int index) async {
//     final selectedChannel = widget.channelList[index];

//     // Show loading indicator immediately when video is selected
//     setState(() {
//       _isBuffering = true;
//       _isVideoInitialized = false; // Reset initialization state
//       _loadingVisible = true; // Show loading initially

//     });

//     // Update the URL of the existing VLC controller
//     if (_controller != null && _controller!.value.isInitialized) {
//       try {
//         await _controller!.setMediaFromNetwork(
//           selectedChannel.url,
//         );

//         // Add listener for initialization
//         _controller!.addListener(() {
//           if (_controller!.value.isInitialized && _isBuffering) {
//             setState(() {
//               _isBuffering = false;
//               _isVideoInitialized = true;
//       // _loadingVisible = false; // Show loading initially

//             });
//           }
//         });

//     //         // Automatically hide loading after 3 seconds
//     // Timer(Duration(seconds: 4), () {
//     //   setState(() {
//     //     _loadingVisible = false;
//     //   });
//     // });

//          _controller!.play();

//         // Update state
//         setState(() {
//           _focusedIndex = index;
//         });

//         // Scroll to the focused item and restart the controls hide timer
//         _scrollToFocusedItem();
//         _resetHideControlsTimer();
//       } catch (error) {
//         print("Error switching channel: $error");
//         setState(() {
//           _isBuffering = false;
//           _isVideoInitialized =
//               true; // Set to true to hide loading indicator on error
//         });
//       }
//     } else {
//       print("Controller is not initialized");
//       setState(() {
//         _isBuffering = false;
//         _isVideoInitialized =
//             true; // Set to true to hide loading indicator on error
//       });
//     }
//   }

  Future<void> _initializeVLCController() async {
    try {
      setState(() {
        _loadingVisible = true; // Show loading initially
      });
      _controller = VlcPlayerController.network(
        widget.videoUrl,
        hwAcc: HwAcc.full,
        autoPlay: true,
        options: VlcPlayerOptions(),
      );
      _controller!.initialize();
      setState(() {
        _isVideoInitialized = true;
      });
      Timer(Duration(seconds: 2), () {
        setState(() {
          _loadingVisible = false;
        });
      });
    } catch (error) {
      print("Error initializing the video: $error");
      setState(() {
        _isVideoInitialized = false;
        _loadingVisible = false;
      });
    }

    _controller?.addListener(() {
      if (mounted && _controller!.value.hasError) {
        print("VLC Player Error: ${_controller!.value.errorDescription}");
        setState(() {
          _isVideoInitialized = false;
        });
      }
    });
  }

  // void _onItemTap(int index) async {
  //   final selectedChannel = widget.channelList[index];

  //   // Update the URL of the existing VLC controller
  //   if (_controller != null && _controller!.value.isInitialized) {
  //     try {
  //       setState(() {
  //         _loadingVisible = true; // Show loading initially
  //       });
  //       await _controller!.setMediaFromNetwork(
  //         selectedChannel.url,
  //         // options: VlcPlayerOptions(),
  //       );
  //       await _controller!.play();

  //       // Update state
  //       setState(() {
  //         _focusedIndex = index;
  //       });

  //       // Scroll to the focused item and restart the controls hide timer
  //       _scrollToFocusedItem();
  //       _resetHideControlsTimer();
  //       Timer(Duration(seconds: 2), () {
  //         setState(() {
  //           _loadingVisible = false;
  //         });
  //       });
  //     } catch (error) {
  //       print("Error switching channel: $error");
  //     }
  //   } else {
  //     print("Controller is not initialized");
  //   }
  // }





// void _onItemTap(int index) async {
//   final selectedChannel = widget.channelList[index];

//   setState(() {
//     _loadingVisible = true; // Show loading indicator
//   });

//   try {
//     // Step 1: Fetch the updated URL if required
//     String updatedUrl = selectedChannel.url;
//     if (selectedChannel.streamType == 'YoutubeLive') {
//       updatedUrl = await _fetchUpdatedUrl(selectedChannel.url);
//       if (updatedUrl.isEmpty) throw Exception("Failed to fetch updated URL");
//     }

//     // Step 2: Create a new instance of NewsItemModel with the updated URL
//     final updatedChannel = NewsItemModel(
//       id: selectedChannel.id,
//       name: selectedChannel.name,
//       description: selectedChannel.description,
//       url: updatedUrl, // Set the new URL here
//       banner: selectedChannel.banner,
//       streamType: selectedChannel.streamType,
//       genres: selectedChannel.genres,
//       status: selectedChannel.status,
//     );

//     // Step 3: Pass the updatedChannel URL to VLC controller
//     if (_controller != null && _controller!.value.isInitialized) {
//       await _controller!.setMediaFromNetwork(updatedChannel.url);
//       await _controller!.play();

//       // Update UI state
//       setState(() {
//         _focusedIndex = index;
//         _loadingVisible = false; // Hide loading
//       });

//       _scrollToFocusedItem(); // Ensure the item is scrolled into view
//       _resetHideControlsTimer();
//     } else {
//       throw Exception("VLC Controller is not initialized");
//     }
//   } catch (e) {
//     print("Error switching channel: $e");
//     setState(() {
//       _loadingVisible = false;
//     });
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text("Failed to switch channel: ${e.toString()}")),
//     );
//   }
// }


// void _onItemTap(int index) async {
//   final selectedChannel = widget.channelList[index];

//   setState(() {
//     _loadingVisible = true; // Show loading indicator
//   });

//   try {
//     String updatedUrl = selectedChannel.url;

//     // Handle `isVOD` case
//     if (widget.isVOD) {
//       // Fetch play link for the VOD movie
//       final playLink = await fetchMoviePlayLink(selectedChannel.id);

//       if (playLink['url'] != null && playLink['url']!.isNotEmpty) {
//         updatedUrl = playLink['url']!;
//         // Update the URL using the socket if needed
//         if (playLink['type'] == 'Youtube' || playLink['type'] == 'YoutubeLive') {
//           updatedUrl = await _socketService.getUpdatedUrl(playLink['url']!);
//         }
//       } else {
//         throw Exception("Invalid play link for VOD");
//       }
//     }

//     // Update the VLC player controller with the updated URL
//     if (_controller != null && _controller!.value.isInitialized) {
//       await _controller!.setMediaFromNetwork(updatedUrl);
//       await _controller!.play();

//       // Update UI state
//       setState(() {
//         _focusedIndex = index;
//         _loadingVisible = false; // Hide loading indicator
//       });

//       _scrollToFocusedItem(); // Scroll to the selected item
//       _resetHideControlsTimer();
//     } else {
//       throw Exception("VLC Controller is not initialized");
//     }
//   } catch (e) {
//     print("Error switching channel: $e");
//     setState(() {
//       _loadingVisible = false;
//     });
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text("Failed to switch channel: ${e.toString()}")),
//     );
//   }
// }



void _onItemTap(int index) async {
  final selectedChannel = widget.channelList[index];

  setState(() {
    _loadingVisible = true; // Show loading indicator
  });

  try {
    // Step 1: Initialize updated URL
    String updatedUrl = selectedChannel.url;

    // Step 2: Check if `selectedChannel` has `streamType`
    if (selectedChannel is NewsItemModel && selectedChannel.streamType == 'YoutubeLive') {
      updatedUrl = await _fetchUpdatedUrl(selectedChannel.url);
      if (updatedUrl.isEmpty) throw Exception("Failed to fetch updated URL");
    }

    // Step 3: Handle `isVOD` case
    if (widget.isVOD) {
      final playLink = await fetchMoviePlayLink(selectedChannel.id);

      if (playLink['url'] != null && playLink['url']!.isNotEmpty) {
        updatedUrl = playLink['url']!;
        // Update the URL via socket if needed
        if (playLink['type'] == 'Youtube' || playLink['type'] == 'YoutubeLive') {
          updatedUrl = await _socketService.getUpdatedUrl(playLink['url']!);
        }
      } else {
        throw Exception("Invalid play link for VOD");
      }
    }

    // Step 4: Update VLC Player with the new URL
    if (_controller != null && _controller!.value.isInitialized) {
      await _controller!.setMediaFromNetwork(updatedUrl);
      await _controller!.play();

      // Update UI state
      setState(() {
        _focusedIndex = index;
        _loadingVisible = false; // Hide loading indicator
      });

      _scrollToFocusedItem(); // Ensure item is in view
      _resetHideControlsTimer(); // Reset hide controls timer
    } else {
      throw Exception("VLC Controller is not initialized");
    }
  } catch (e) {
    print("Error switching channel: $e");
    setState(() {
      _loadingVisible = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Failed to switch channel: ${e.toString()}")),
    );
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

  void _saveLastPlayedVideo(
      String videoUrl, Duration position, String bannerImageUrl) async {
    if (_controller is VlcPlayerController) {
      position = (_controller as VlcPlayerController).value.position;
    } else {
      position = Duration.zero; // Or handle accordingly for VLC if needed
    }
    SharedPreferences prefs = await SharedPreferences.getInstance();

    List<String>? lastPlayedVideos =
        prefs.getStringList('last_played_videos') ?? [];
    String newVideoEntry =
        "$videoUrl|${position.inMilliseconds}|$bannerImageUrl";
    lastPlayedVideos.insert(0, newVideoEntry);

    if (lastPlayedVideos.length > 12) {
      lastPlayedVideos = lastPlayedVideos.sublist(0, 12);
    }

    await prefs.setStringList('last_played_videos', lastPlayedVideos);
  }

  void _seekForward() {
    if (_controller is VlcPlayerController) {
      final newPosition = (_controller as VlcPlayerController).value.position +
          Duration(seconds: 60);
      (_controller as VlcPlayerController).seekTo(newPosition);
    }
    Future.delayed(Duration(milliseconds: 50), () {
      FocusScope.of(context).requestFocus(forwardButtonFocusNode);
    });
  }

  void _seekBackward() {
    if (_controller is VlcPlayerController) {
      final newPosition = (_controller as VlcPlayerController).value.position -
          Duration(seconds: 60);
      (_controller as VlcPlayerController)
          .seekTo(newPosition > Duration.zero ? newPosition : Duration.zero);
    }
    Future.delayed(Duration(milliseconds: 50), () {
      FocusScope.of(context).requestFocus(backwardButtonFocusNode);
    });
  }

  void _handleFocusChange(bool isFocused) {
    setState(() {
      _isPlayPauseFocused = isFocused;
    });
  }

  void _startPositionUpdater() {
    Timer.periodic(Duration(seconds: 1), (_) {
      if (_controller is VlcPlayerController &&
          (_controller as VlcPlayerController).value.isInitialized) {
        setState(() {
          _currentPosition =
              (_controller as VlcPlayerController).value.position;
        });
      }
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
          if (progressIndicatorFocusNode.hasFocus) {
            Future.delayed(Duration(milliseconds: 50), () {
              FocusScope.of(context).requestFocus(playPauseButtonFocusNode);
            });
          } else if (_focusedIndex > 0) {
            setState(() {
              _focusedIndex--;
              FocusScope.of(context).requestFocus(focusNodes[_focusedIndex]);
              _scrollToFocusedItem();
            });
          }
          break;

        case LogicalKeyboardKey.arrowDown:
          _resetHideControlsTimer();
          if (playPauseButtonFocusNode.hasFocus ||
              backwardButtonFocusNode.hasFocus ||
              forwardButtonFocusNode.hasFocus ||
              prevButtonFocusNode.hasFocus ||
              nextButtonFocusNode.hasFocus) {
            Future.delayed(Duration(milliseconds: 50), () {
              FocusScope.of(context).requestFocus(progressIndicatorFocusNode);
            });
          } else if (_focusedIndex < widget.channelList.length - 1) {
            setState(() {
              _focusedIndex++;
              FocusScope.of(context).requestFocus(focusNodes[_focusedIndex]);
              _scrollToFocusedItem();
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
              FocusScope.of(context).requestFocus(backwardButtonFocusNode);
            });
          } else if (backwardButtonFocusNode.hasFocus) {
            Future.delayed(Duration(milliseconds: 50), () {
              FocusScope.of(context).requestFocus(forwardButtonFocusNode);
            });
          } else if (forwardButtonFocusNode.hasFocus) {
            Future.delayed(Duration(milliseconds: 50), () {
              FocusScope.of(context).requestFocus(prevButtonFocusNode);
            });
          } else if (prevButtonFocusNode.hasFocus) {
            Future.delayed(Duration(milliseconds: 50), () {
              FocusScope.of(context).requestFocus(nextButtonFocusNode);
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
              FocusScope.of(context).requestFocus(forwardButtonFocusNode);
            });
          } else if (forwardButtonFocusNode.hasFocus) {
            Future.delayed(Duration(milliseconds: 50), () {
              FocusScope.of(context).requestFocus(backwardButtonFocusNode);
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _controller!.pause();
        Navigator.of(context).pop(true);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Focus(
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
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_loadingVisible || !_isVideoInitialized)
                        AnimatedOpacity(
                          opacity:
                              _loadingVisible ? 1.0 : 0.0, // Show when loading
                          duration:
                              Duration(milliseconds: 3000), // Smooth transition
                          child: Center(child: LoadingIndicator()),
                        ),
                      if (_isVideoInitialized)
                        VlcPlayer(
                          controller: _controller!,
                          aspectRatio: 16 / 9,
                        ),
                    ],
                  ),
                ),
                AnimatedOpacity(
                  opacity: _loadingVisible
                      ? 1.0
                      : 0.0, // 1.0 when visible, 0.0 when invisible
                  duration: Duration(seconds: 4), // Fade duration
                  child: Container(
                      color: Colors.black,
                      child: Center(child: LoadingIndicator())),
                ),
                if (_controlsVisible) _buildChannelList(),
                if (_controlsVisible) _buildControls(),
              ],
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
      right: MediaQuery.of(context).size.width * 0.82,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        color: Colors.black.withOpacity(0.3),
        child: ListView.builder(
          controller: _scrollController,
          itemCount: widget.channelList.length,
          itemBuilder: (context, index) {
            final channel = widget.channelList[index];
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
                    height: 80,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _focusedIndex == index
                            ? Colors.blue
                            : Colors.transparent,
                        width: 3.0,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: _focusedIndex == index
                          ? Colors.black26
                          : Colors.transparent,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CachedNetworkImage(
                              imageUrl: channel.banner ?? '',
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) =>
                                  Container(color: Colors.grey[800]),
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
                                      Colors.black.withOpacity(0.7),
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
                    color: _isPlayPauseFocused
                        ? Colors.black87
                        : Colors.transparent,
                    child: Center(
                      child: Focus(
                        focusNode: playPauseButtonFocusNode,
                        onFocusChange: _handleFocusChange,
                        child: IconButton(
                          icon: Icon(
                            (_controller is VlcPlayerController &&
                                    (_controller as VlcPlayerController)
                                        .value
                                        .isPlaying)
                                ? Icons.pause
                                : Icons.play_arrow,
                            color: _isPlayPauseFocused
                                ? Colors.blue
                                : Colors.white,
                          ),
                          onPressed: _togglePlayPause,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Container(
                    color: backwardButtonFocusNode.hasFocus
                        ? Colors.black87
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
                          onPressed: _seekBackward,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Container(
                    color: forwardButtonFocusNode.hasFocus
                        ? Colors.black87
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
                Expanded(
                  flex: 2,
                  child: Container(
                    color: prevButtonFocusNode.hasFocus
                        ? Colors.black87
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
                Expanded(
                  flex: 2,
                  child: Container(
                    color: nextButtonFocusNode.hasFocus
                        ? Colors.black87
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
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            color: progressIndicatorFocusNode.hasFocus
                ? Colors.black87
                : Colors.black54,
            child: Row(
              children: [
                Expanded(flex: 1, child: Container()),
                // Expanded(
                //   flex: 15,
                // child: Center(
                //   child: Focus(
                //     focusNode: progressIndicatorFocusNode,
                //     onFocusChange: (hasFocus) {
                //       setState(() {
                //         // Change color or handle other focus changes here if needed
                //       });
                //     },
                //       child: widget.videoType == 'VLC'
                //           ? Container()
                //           : VideoProgressIndicator(
                //               _controller,
                //               allowScrubbing: true,
                //               colors: VideoProgressColors(
                //                 playedColor: Colors.blue,
                //                 bufferedColor: Colors.green,
                //                 backgroundColor: Colors.yellow,
                //               ),
                //             ),
                //     ),
                //   ),
                // ),
                Expanded(flex: 5, child: _buildVolumeIndicator()),
                Expanded(flex: 1, child: Container()),
                Expanded(
                  flex: 20,
                  child: Center(
                    child: Focus(
                      focusNode: progressIndicatorFocusNode,
                      onFocusChange: (hasFocus) {
                        setState(() {
                          // Change color or handle other focus changes here if needed
                        });
                      },
                      child: LinearProgressIndicator(
                        value: _progress.isNaN ? 0 : _progress,
                        color: Colors.white, // Adjusted borderColor to white
                        backgroundColor: Colors.green,
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
