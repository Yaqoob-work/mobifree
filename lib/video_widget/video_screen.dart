import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:keep_screen_on/keep_screen_on.dart';
import 'package:mobi_tv_entertainment/main.dart';
import 'package:video_player/video_player.dart';

class VideoScreen extends StatefulWidget {
  final String videoUrl;
  final String videoTitle;
  final List<dynamic> channelList;
  final Function(bool) onFabFocusChanged;

  VideoScreen({
    required this.videoUrl,
    required this.videoTitle,
    required this.channelList,
    required this.onFabFocusChanged, required String genres, required List channels, required int initialIndex,
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
  bool _isBuffering = false; // Track buffering state

  final FocusNode screenFocusNode = FocusNode();
  final FocusNode playPauseFocusNode = FocusNode();
  final FocusNode rewindFocusNode = FocusNode();
  final FocusNode forwardFocusNode = FocusNode();
  final FocusNode backFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() {
          _totalDuration = _controller.value.duration;
        });
        _controller.play();
        _startPositionUpdater();
        KeepScreenOn.turnOn(); // Keep the screen on for this page
      });

    _controller.addListener(() {
      if (_controller.value.isBuffering != _isBuffering) {
        setState(() {
          _isBuffering = _controller.value.isBuffering;
        });
        if (!_isBuffering && _controller.value.isInitialized) {
          _controller.play(); // Resume playback when buffering is complete
        }
      }
    });

    _startHideControlsTimer();
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(screenFocusNode);
    });
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
    KeepScreenOn.turnOff(); // Disable screen wake when leaving this page
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _controller.pause(); // Pause video when app goes into background
    } else if (state == AppLifecycleState.resumed) {
      _controller.play(); // Resume video playback when app comes back into foreground
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

  // void _onRewind() {
  //   _controller.seekTo(_controller.value.position - Duration(minutes: 1));
  //   _resetHideControlsTimer();
  // }

  // void _onForward() {
  //   _controller.seekTo(_controller.value.position + Duration(minutes: 1));
  //   _resetHideControlsTimer();
  // }

  void _togglePlayPause() {
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
    _resetHideControlsTimer();
  }

  // void _navigateBack() {
  //   Navigator.pop(context);
  // }

  // String _formatDuration(Duration duration) {
  //   String twoDigits(int n) => n.toString().padLeft(2, '0');
  //   String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
  //   String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
  //   return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
  // }

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
              // _onRewind();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              // _onForward();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
                event.logicalKey == LogicalKeyboardKey.arrowDown) {
              _resetHideControlsTimer();
              return KeyEventResult.handled;
            } 
            else if (event.logicalKey == LogicalKeyboardKey.escape) {
              // _navigateBack(); // Use 'escape' key for back navigation
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
                  bottom: screenhgt*0.05,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
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
                           SizedBox(width: 20,),
                            Expanded(
                              flex: 2,
                                child: Center(
                                  child: Row(
                                    children: [
                                      Icon(Icons.circle,color: borderColor,size: 15,),
                                      SizedBox(width: 5,),
                                      Text(
                                        'Live',
                                        style: TextStyle(
                                            color: borderColor, fontSize: 20,fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                            ),
                            SizedBox(width: 20,),
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
    );
  }
}
