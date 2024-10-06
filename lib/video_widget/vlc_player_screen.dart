import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:keep_screen_on/keep_screen_on.dart';
import 'package:mobi_tv_entertainment/main.dart';

class VlcPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String videoTitle;

  const VlcPlayerScreen({
    Key? key,
    required this.videoUrl,
    required this.videoTitle,
    required List channelList,
    required Null Function(dynamic bool) onFabFocusChanged,
    required String genres,
    required List channels,
    required int initialIndex, required String bannerImageUrl, required Duration startAtPosition,
  }) : super(key: key);

  @override
  VlcPlayerScreenState createState() => VlcPlayerScreenState();
}

class VlcPlayerScreenState extends State<VlcPlayerScreen>
    with WidgetsBindingObserver {
  late VlcPlayerController _vlcPlayerController;
  bool _controlsVisible = true;
  late Timer _hideControlsTimer;
  bool _isBuffering = false;
  bool _isConnected = true;
  double _progress = 0.0;

  final FocusNode screenFocusNode = FocusNode();
  final FocusNode playPauseFocusNode = FocusNode();
  final FocusNode rewindFocusNode = FocusNode();
  final FocusNode forwardFocusNode = FocusNode();
  final FocusNode backFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _vlcPlayerController = VlcPlayerController.network(
      widget.videoUrl,
      hwAcc: HwAcc.full,
      autoPlay: true,
    )..addListener(() {
        if (_vlcPlayerController.value.isBuffering != _isBuffering) {
          setState(() {
            _isBuffering = _vlcPlayerController.value.isBuffering;
          });
        }

        // Update progress bar
        if (_vlcPlayerController.value.duration != null) {
          setState(() {
            _progress = _vlcPlayerController.value.position.inSeconds /
                _vlcPlayerController.value.duration!.inSeconds;
          });
        }
      });

    KeepScreenOn.turnOn();
    _startHideControlsTimer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(screenFocusNode);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _vlcPlayerController.dispose();
    _hideControlsTimer.cancel();
    screenFocusNode.dispose();
    playPauseFocusNode.dispose();
    rewindFocusNode.dispose();
    forwardFocusNode.dispose();
    backFocusNode.dispose();
    KeepScreenOn.turnOff();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_vlcPlayerController.value.isPlaying &&
          !_vlcPlayerController.value.isBuffering) {
        _vlcPlayerController.play();
      }
    } else if (state == AppLifecycleState.paused) {
      _vlcPlayerController.pause();
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

  void _togglePlayPause() {
    if (_vlcPlayerController.value.isPlaying) {
      _vlcPlayerController.pause();
    } else {
      _vlcPlayerController.play();
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
                child: VlcPlayer(
                  controller: _vlcPlayerController,
                  aspectRatio: 16 / 9,
                  placeholder: Center(
                    child: SpinKitFadingCircle(
                      color: borderColor,
                      size: 50.0,
                    ),
                  ),
                ),
              ),
              if (_controlsVisible)
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  // child: Column(
                  //   children: [

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
                                  _vlcPlayerController.value.isPlaying
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
                          flex: 20,
                          child: LinearProgressIndicator(
                            value: _progress.isNaN ? 0 : _progress,
                            color: borderColor,
                            backgroundColor: Colors.green,
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
                  // ],
                  // ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}



