import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:keep_screen_on/keep_screen_on.dart';
import 'package:mobi_tv_entertainment/main.dart';
import 'package:video_player/video_player.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class VideoScreen extends StatefulWidget {
  final String videoUrl;
  final String videoTitle;
  final List<dynamic> channelList;
  final Function(bool) onFabFocusChanged;

  VideoScreen({
    required this.videoUrl,
    required this.videoTitle,
    required this.channelList,
    required this.onFabFocusChanged,
    required String genres,
    required List channels,
    required int initialIndex,
  });

  @override
  _VideoScreenState createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> with WidgetsBindingObserver {
  late VideoPlayerController _controller;
  bool _controlsVisible = true;
  late Timer _hideControlsTimer;
  Duration _totalDuration = Duration.zero;
  Duration _currentPosition = Duration.zero;
  bool _isBuffering = false;
  bool _isConnected = true;
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  final FocusNode screenFocusNode = FocusNode();
  final FocusNode playPauseFocusNode = FocusNode();
  final FocusNode rewindFocusNode = FocusNode();
  final FocusNode forwardFocusNode = FocusNode();
  final FocusNode backFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {
          _totalDuration = _controller.value.duration;
        });
        _controller.play();
        _startPositionUpdater();
        KeepScreenOn.turnOn();
      });

    _controller.addListener(() {
      if (_controller.value.isBuffering != _isBuffering) {
        setState(() {
          _isBuffering = _controller.value.isBuffering;
        });
        if (!_controller.value.isPlaying && !_controller.value.isBuffering && _controller.value.isInitialized) {
          _controller.play();
        }
      }
    });

    _startHideControlsTimer();
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(screenFocusNode);
    });

    // Listen for connectivity changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      print("Connectivity changed: $result");
      _updateConnectionStatus(result);
    });
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    bool wasConnected = _isConnected;
    _isConnected = result != ConnectivityResult.none;

    if (!wasConnected && _isConnected) {
      if (!_controller.value.isPlaying && !_controller.value.isBuffering && _controller.value.isInitialized) {
        _controller.play();
      }
    } else if (wasConnected && !_isConnected) {
      if (_controller.value.isPlaying) {
        _controller.pause();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _hideControlsTimer.cancel();
    screenFocusNode.dispose();
    playPauseFocusNode.dispose();
    rewindFocusNode.dispose();
    forwardFocusNode.dispose();
    backFocusNode.dispose();
    _connectivitySubscription.cancel();
    KeepScreenOn.turnOff();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_controller.value.isPlaying && !_controller.value.isBuffering) {
        _controller.play();
      }
    } else if (state == AppLifecycleState.paused) {
      _controller.pause();
    }
  }

  void _startHideControlsTimer() {
    _hideControlsTimer = Timer(Duration(seconds: 10), () {
      setState(() {
        _controlsVisible = false;
      });
    });
  }

  void _resetHideControlsTimer() {
    _hideControlsTimer.cancel();
    setState(() {
      _controlsVisible = true;
    });
    _startHideControlsTimer();
  }

  void _startPositionUpdater() {
    Timer.periodic(Duration(seconds: 1), (_) {
      if (_controller.value.isInitialized) {
        setState(() {
          _currentPosition = _controller.value.position;
        });
      }
    });
  }

  void _togglePlayPause() {
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
    _resetHideControlsTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        focusNode: screenFocusNode,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.mediaPlayPause) {
              _togglePlayPause();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              // Handle rewind if needed
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              // Handle forward if needed
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
                event.logicalKey == LogicalKeyboardKey.arrowDown) {
              _resetHideControlsTimer();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.escape) {
              // Handle back navigation if needed
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: GestureDetector(
          onTap: _resetHideControlsTimer,
          child: Stack(
            children: [
              Center(
                child: _controller.value.isInitialized
                    ? AspectRatio(
                        aspectRatio: 16 / 9,
                        child: VideoPlayer(_controller),
                      )
                    : CircularProgressIndicator(),
              ),
              if (_controlsVisible)
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  // child: Column(
                  //   children: [
                  //     Padding(
                  //       padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Container(
                                color: Colors.black.withOpacity(0.5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: Center(
                                  child: Focus(
                                    focusNode: playPauseFocusNode,
                                    onFocusChange: (hasFocus) {
                                      setState(() {
                                        // Change button color on focus
                                      });
                                    },
                                    child: IconButton(
                                      icon: Icon(
                                        _controller.value.isPlaying
                                            ? Icons.pause
                                            : Icons.play_arrow,
                                        color: Colors.white,
                                      ),
                                      onPressed: _togglePlayPause,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 15,
                                child: Center(
                                  child: VideoProgressIndicator(
                                    _controller,
                                    allowScrubbing: true,
                                    colors: VideoProgressColors(
                                        playedColor: borderColor,
                                        bufferedColor: Colors.green,
                                        backgroundColor: Colors.grey),
                                  ),
                                ),
                              ),
                              SizedBox(width: 20),
                              Expanded(
                                flex: 2,
                                child: Center(
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.circle,
                                        color: Colors.red,
                                        size: 15,
                                      ),
                                      SizedBox(width: 5),
                                      Text(
                                        'Live',
                                        style: TextStyle(
                                            color: Colors.red,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(width: 20),
                            ],
                          ),
                        ),
                  //     ),
                  //   ],
                  // ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
