import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:keep_screen_on/keep_screen_on.dart';
import 'package:mobi_tv_entertainment/main.dart';
import 'package:video_player/video_player.dart';

class VideoMovieScreen extends StatefulWidget {
  final String videoUrl;
  final String videoTitle;
  final List<dynamic> channelList;

  VideoMovieScreen(
      {required this.videoUrl,
      required this.videoTitle,
      required this.channelList,
      required String videoBanner,
      required Null Function(bool focused) onFabFocusChanged,
      required String genres,
      required String videoType,
      required String url,
      required String type});

  @override
  _VideoMovieScreenState createState() => _VideoMovieScreenState();
}

class _VideoMovieScreenState extends State<VideoMovieScreen>
    with WidgetsBindingObserver {
  late VideoPlayerController _controller;
  bool _controlsVisible = true;
  late Timer _hideControlsTimer;
  Duration _totalDuration = Duration.zero;
  Duration _currentPosition = Duration.zero;
  bool _isBuffering = false;
  Duration _lastKnownPosition = Duration.zero;
  bool _wasPlayingBeforeDisconnection = false;
  bool _isConnected = true;
  bool _userPaused = false;
  Timer? _connectivityCheckTimer;
  bool _isVideoInitialized = false;

  final FocusNode screenFocusNode = FocusNode();
  final FocusNode playPauseFocusNode = FocusNode();
  final FocusNode rewindFocusNode = FocusNode();
  final FocusNode forwardFocusNode = FocusNode();
  final FocusNode backFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeVideo();
    _startConnectivityCheck();
    KeepScreenOn.turnOn();
    _startHideControlsTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(screenFocusNode);
    });
  }

  Future<void> _initializeVideo() async {
    _controller = VideoPlayerController.network(widget.videoUrl);
    try {
      await _controller.initialize();
      setState(() {
        _isVideoInitialized = true;
        _totalDuration = _controller.value.duration;
      });
      _controller.play();
      _startPositionUpdater();
      _controller.addListener(_videoListener);
    } catch (error) {
      print('Something Went Wrong');
      _handleNetworkError();
    }
  }

  void _handleNetworkError() {
    _wasPlayingBeforeDisconnection = _controller.value.isPlaying;
    _lastKnownPosition = _controller.value.position;
    _controller.pause();
    Future.delayed(Duration(seconds: 5), () {
      if (!_controller.value.isPlaying && !_userPaused) {
        _reinitializeVideo();
      }
    });
  }

  Future<void> _reinitializeVideo() async {
    final currentPosition = _lastKnownPosition;
    await _controller.dispose();

    _controller = VideoPlayerController.network(widget.videoUrl);
    try {
      await _controller.initialize();
      await _controller.seekTo(currentPosition);
      setState(() {
        
        _totalDuration = _controller.value.duration;
        _currentPosition = currentPosition;
      });
      if (_wasPlayingBeforeDisconnection && !_userPaused) {
        _controller.play();
      }
      _controller.addListener(_videoListener);
    } catch (error) {
      print('Something Went Wrong');
      _handleNetworkError();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_controller.value.isPlaying) {
      _controller.pause();
    }
    _controller.removeListener(_videoListener);
    _connectivityCheckTimer?.cancel();

    _controller.dispose();
    _hideControlsTimer.cancel();
    screenFocusNode.dispose();
    playPauseFocusNode.dispose();
    rewindFocusNode.dispose();
    forwardFocusNode.dispose();
    backFocusNode.dispose();
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
    if (state == AppLifecycleState.paused) {
      _lastKnownPosition = _controller.value.position;
      _controller.pause();
    } else if (state == AppLifecycleState.resumed) {
      _controller.seekTo(_lastKnownPosition);
      if (!_userPaused) {
        _controller.play();
      }
    }
  }

  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isVideoInitialized && !_controller.value.isPlaying) {
      _controller.play();
    }
  }

  void _videoListener() {
    setState(() {
      _isBuffering = _controller.value.isBuffering;
      if (!_isBuffering) {
        _lastKnownPosition = _controller.value.position;
      }
    });

    if (_controller.value.hasError) {
      print('Something Went Wrong');
      _handleNetworkError();
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

  void _onRewind() {
    _controller.seekTo(_controller.value.position - Duration(minutes: 1));
    _resetHideControlsTimer();
  }

  void _onForward() {
    _controller.seekTo(_controller.value.position + Duration(minutes: 1));
    _resetHideControlsTimer();
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _userPaused = true;
      } else {
        _controller.play();
        _userPaused = false;
      }
    });
    _resetHideControlsTimer();
  }

  void _navigateBack() {
    Navigator.pop(context);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _controller.pause();
        return true;
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
                _onRewind();
                return KeyEventResult.handled;
              } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                _onForward();
                return KeyEventResult.handled;
              } else if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
                  event.logicalKey == LogicalKeyboardKey.arrowDown) {
                _resetHideControlsTimer();
                return KeyEventResult.handled;
              } else if (event.logicalKey == LogicalKeyboardKey.escape) {
                _navigateBack();
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
                      // AspectRatio(
                      //     aspectRatio: 16 / 9, // Fixed aspect ratio
                      //     child: FittedBox(
                      //       fit: widget.videoUrl.contains('youtube')
                      //           ? BoxFit.cover
                      //           : BoxFit.contain,
                      //       child: SizedBox(
                      //         width: _controller.value.size.width,
                      //         height: _controller.value.size.height,
                      //         child: VideoPlayer(_controller),
                      //       ),
                      //     ),
                      //   )
                      : SpinKitFadingCircle(
                          color: borderColor,
                          size: 50.0,
                        ),
                  // AspectRatio(
                  //     aspectRatio: 16 / 9,
                  //     child: VideoPlayer(_controller),
                  //   )
                  //       LayoutBuilder(
                  //           builder: (context, constraints) {
                  //             final aspectRatio = _controller.value.aspectRatio;
                  //             final videoWidth = constraints.maxWidth;
                  //             final videoHeight = videoWidth / aspectRatio;
      
                  //             return SizedBox(
                  //               width: videoWidth,
                  //               height: videoHeight > constraints.maxHeight
                  //                   ? constraints.maxHeight
                  //                   : videoHeight,
                  //               child: AspectRatio(
                  //                 aspectRatio: aspectRatio,
                  //                 child: VideoPlayer(_controller),
                  //               ),
                  //             );
                  //           },
                  //         )
                  //       : SpinKitFadingCircle(
                  //           color: borderColor,
                  //           size: 50.0,
                  //         ),
                ),
                if (_controlsVisible)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        Container(
                          color: Colors.black.withOpacity(0.5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 1,
                                child: Center(
                                  child: IconButton(
                                    icon: Icon(
                                      _controller.value.isPlaying
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                      color: highlightColor,
                                    ),
                                    onPressed: _togglePlayPause,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Center(
                                  child: Text(
                                    _formatDuration(_currentPosition),
                                    style: TextStyle(
                                        color: highlightColor, fontSize: 20),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 6,
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
                              Expanded(
                                flex: 2,
                                child: Center(
                                  child: Text(
                                    _formatDuration(_totalDuration),
                                    style: TextStyle(
                                        color: highlightColor, fontSize: 20),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
