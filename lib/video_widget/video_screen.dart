import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:keep_screen_on/keep_screen_on.dart';
import 'package:video_player/video_player.dart';

import '../main.dart';

class VideoScreen extends StatefulWidget {
  final String videoUrl;
  final String videoTitle;
  final List<dynamic> channelList;
  // final Function(bool) onFabFocusChanged;

  VideoScreen({
    required this.videoUrl,
    required this.videoTitle,
    required this.channelList,
    // required this.onFabFocusChanged,
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
  bool _isConnected =
      true; // This is a placeholder; handle connectivity manually.
  bool _isVideoInitialized = false;
  Timer? _connectivityCheckTimer;

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
          _isVideoInitialized = true;
        });
        _controller.play();
        _startPositionUpdater();
        _startConnectivityCheck();
        KeepScreenOn.turnOn();
      });

    _controller.addListener(() {
      if (_controller.value.isBuffering != _isBuffering) {
        setState(() {
          _isBuffering = _controller.value.isBuffering;
        });
        if (!_controller.value.isPlaying &&
            !_controller.value.isBuffering &&
            _controller.value.isInitialized) {
          _controller.play();
        }
      }
    });

    @override
    void didChangeAppLifecycleState(AppLifecycleState state) {
      if (state == AppLifecycleState.paused) {
        _controller.pause();
      } else if (state == AppLifecycleState.resumed) {
        _controller.play();
      }
    }

    @override
    void didChangeDependencies() {
      super.didChangeDependencies();
      if (_isVideoInitialized && !_controller.value.isPlaying) {
        _controller.play();
      }
    }

    _startHideControlsTimer();
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(screenFocusNode);
    });

    // Handle connectivity manually
    // You can implement your own method to check connectivity status here.
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
    _connectivityCheckTimer?.cancel();
    KeepScreenOn.turnOff();
    super.dispose();
  }

  void _startConnectivityCheck() {
    _connectivityCheckTimer =
        Timer.periodic(Duration(seconds: 5), (timer) async {
      try {
        final result = await InternetAddress.lookup('google.com');
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          _updateConnectionStatus(true);
        } else {
          _updateConnectionStatus(false);
        }
      } on SocketException catch (_) {
        _updateConnectionStatus(false);
      }
    });
  }

  void _updateConnectionStatus(bool isConnected) {
    if (isConnected != _isConnected) {
      setState(() {
        _isConnected = isConnected;
      });
      if (!isConnected) {
        _controller.pause();
      } else if (_controller.value.isBuffering ||
          !_controller.value.isPlaying) {
        _controller.play();
      }
    }
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
    return WillPopScope(
      onWillPop: () async {
        _controller.pause();
        Navigator.of(context).pop(true);
        return false;
      },
      child: Scaffold(
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
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: screenwdt,
                            height: screenhgt,
                            child: VideoPlayer(_controller),
                          ),
                        ),
                      )
                      //  AspectRatio(
                      //     aspectRatio: 16 / 9,
                      //     child: VideoPlayer(_controller),
                      //   )
                      // LayoutBuilder(
                      //     builder: (context, constraints) {
                      //       final aspectRatio =
                      //       _controller.value.aspectRatio;
                      //       final videoWidth = constraints.maxWidth;
                      //       final videoHeight = videoWidth / aspectRatio;

                      //       return SizedBox(
                      //         width: videoWidth,
                      //         height: videoHeight > constraints.maxHeight
                      //             ? constraints.maxHeight
                      //             : videoHeight,
                      //         child: AspectRatio(
                      //           aspectRatio: aspectRatio,
                      //           child: VideoPlayer(_controller),
                      //         ),
                      //       );
                      //     },
                      //   )
                      : SpinKitFadingCircle(
                          color: borderColor,
                          size: 50.0,
                        ),
                ),
                if (_controlsVisible)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
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
                                    backgroundColor: Colors.yellow),
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
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
