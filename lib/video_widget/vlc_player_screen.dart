// import 'dart:async';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_spinkit/flutter_spinkit.dart';
// import 'package:flutter_vlc_player/flutter_vlc_player.dart';
// import 'package:keep_screen_on/keep_screen_on.dart';
// import 'package:mobi_tv_entertainment/main.dart';

// class VlcPlayerScreen extends StatefulWidget {
  // final String videoUrl;
  // final String videoTitle;

  // const VlcPlayerScreen({
  //   Key? key,
  //   required this.videoUrl,
  //   required this.videoTitle,
  //   required List channelList,
  //   required Null Function(dynamic bool) onFabFocusChanged,
  //   required String genres,
  //   required List channels,
  //   required int initialIndex,
  // }) : super(key: key);

//   @override
//   VlcPlayerScreenState createState() => VlcPlayerScreenState();
// }

// class VlcPlayerScreenState extends State<VlcPlayerScreen>
//     with WidgetsBindingObserver {
//   VlcPlayerController? _vlcPlayerController;
//   bool _controlsVisible = true;
//   Timer? _hideControlsTimer;
//   bool _isBuffering = false;
//   bool _isConnected = true;
//   double _progress = 0.0;

//   final FocusNode screenFocusNode = FocusNode();
//   final FocusNode playPauseFocusNode = FocusNode();
//   final FocusNode rewindFocusNode = FocusNode();
//   final FocusNode forwardFocusNode = FocusNode();
//   final FocusNode backFocusNode = FocusNode();

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);

//     _checkConnectivityAndInitialize();

//     KeepScreenOn.turnOn();
//     _startHideControlsTimer();

//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       FocusScope.of(context).requestFocus(screenFocusNode);
//     });
//   }

//   Future<void> _checkConnectivityAndInitialize() async {
//     bool isConnected = await _checkInternetConnection();
//     if (!isConnected) {
//       setState(() {
//         _isConnected = false;
//       });
//       _showErrorDialog('No internet connection. Please check your network settings.');
//     } else {
//       setState(() {
//         _isConnected = true;
//       });
//       // Delay the initialization of VlcPlayerController
//       Future.delayed(Duration(milliseconds: 5000), () {
//         _initializePlayer();
//       });
//     }
//   }

//   Future<bool> _checkInternetConnection() async {
//     try {
//       final result = await InternetAddress.lookup('google.com');
//       return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
//     } on SocketException catch (_) {
//       return false;
//     }
//   }

//   void _initializePlayer() {
//     try {
//       _vlcPlayerController = VlcPlayerController.network(
//         widget.videoUrl,
//         hwAcc: HwAcc.disabled,
//         autoPlay: true,
//         options: VlcPlayerOptions(
//           advanced: VlcAdvancedOptions([
//             VlcAdvancedOptions.networkCaching(2000),
//           ]),
//           rtp: VlcRtpOptions([
//             VlcRtpOptions.rtpOverRtsp(true),
//           ]),
//         ),
//       );
//       _vlcPlayerController!.addListener(_onPlayerChange);
//       _vlcPlayerController!.initialize().then((_) {
//         setState(() {}); // Trigger a rebuild once initialized
//       }).catchError((error) {
//         print('Error initializing VLC player: $error');
//         _showErrorDialog('Failed to initialize video player. Please try again.');
//       });
//     } catch (e) {
//       print('Error creating VlcPlayerController: $e');
//       _showErrorDialog('An error occurred while setting up the video player.');
//     }
//   }

//   void _onPlayerChange() {
//     if (!mounted) return;
//     setState(() {
//       if (_vlcPlayerController != null) {
//         _isBuffering = _vlcPlayerController!.value.isBuffering;
//         if (_vlcPlayerController!.value.duration != null &&
//             _vlcPlayerController!.value.duration!.inSeconds != 0) {
//           _progress = _vlcPlayerController!.value.position.inSeconds /
//               _vlcPlayerController!.value.duration!.inSeconds;
//         }
//       }
//     });
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     _vlcPlayerController?.removeListener(_onPlayerChange);
//     _vlcPlayerController?.dispose();
//     _hideControlsTimer?.cancel();
//     screenFocusNode.dispose();
//     playPauseFocusNode.dispose();
//     rewindFocusNode.dispose();
//     forwardFocusNode.dispose();
//     backFocusNode.dispose();
//     KeepScreenOn.turnOff();
//     super.dispose();
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (_vlcPlayerController == null) return;
//     if (state == AppLifecycleState.resumed) {
//       if (!_vlcPlayerController!.value.isPlaying &&
//           !_vlcPlayerController!.value.isBuffering) {
//         _vlcPlayerController!.play();
//       }
//     } else if (state == AppLifecycleState.paused) {
//       _vlcPlayerController!.pause();
//     }
//   }

//   void _startHideControlsTimer() {
//     _hideControlsTimer?.cancel();
//     _hideControlsTimer = Timer(Duration(seconds: 10), () {
//       if (mounted) {
//         setState(() {
//           _controlsVisible = false;
//         });
//       }
//     });
//   }

//   void _resetHideControlsTimer() {
//     setState(() {
//       _controlsVisible = true;
//     });
//     _startHideControlsTimer();
//   }

//   void _togglePlayPause() {
//     if (_vlcPlayerController == null) return;
//     if (_vlcPlayerController!.value.isPlaying) {
//       _vlcPlayerController!.pause();
//     } else {
//       _vlcPlayerController!.play();
//     }
//     _resetHideControlsTimer();
//   }

//   void _showErrorDialog(String message) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text('Error'),
//           content: Text(message),
//           actions: <Widget>[
//             TextButton(
//               child: Text('OK'),
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Focus(
//         focusNode: screenFocusNode,
//         onKeyEvent: (node, event) {
//           if (event is KeyDownEvent) {
//             if (event.logicalKey == LogicalKeyboardKey.select ||
//                 event.logicalKey == LogicalKeyboardKey.enter ||
//                 event.logicalKey == LogicalKeyboardKey.mediaPlayPause) {
//               _togglePlayPause();
//               return KeyEventResult.handled;
//             } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
//               // Handle rewind
//               _vlcPlayerController?.seekTo(Duration(seconds: _vlcPlayerController!.value.position.inSeconds - 10));
//               return KeyEventResult.handled;
//             } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
//               // Handle forward
//               _vlcPlayerController?.seekTo(Duration(seconds: _vlcPlayerController!.value.position.inSeconds + 10));
//               return KeyEventResult.handled;
//             } else if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
//                 event.logicalKey == LogicalKeyboardKey.arrowDown) {
//               _resetHideControlsTimer();
//               return KeyEventResult.handled;
//             } else if (event.logicalKey == LogicalKeyboardKey.escape) {
//               Navigator.of(context).pop();
//               return KeyEventResult.handled;
//             }
//           }
//           return KeyEventResult.ignored;
//         },
//         child: GestureDetector(
//           onTap: _resetHideControlsTimer,
//           child: Stack(
//             children: [
//               Center(
//                 child: _isConnected
//                     ? (_vlcPlayerController != null
//                         ? VlcPlayer(
//                             controller: _vlcPlayerController!,
//                             aspectRatio: 16 / 9,
//                             placeholder: Center(
//                               child: SpinKitFadingCircle(
//                                 color: borderColor,
//                                 size: 50.0,
//                               ),
//                             ),
//                           )
//                         : Center(
//                             child: CircularProgressIndicator(),
//                           ))
//                     : Center(
//                         child: Text(
//                           'No internet connection',
//                           style: TextStyle(color: Colors.white),
//                         ),
//                       ),
//               ),
//               if (_controlsVisible)
//                 Positioned(
//                   bottom: 20,
//                   left: 0,
//                   right: 0,
//                   child: Container(
//                     color: Colors.black.withOpacity(0.5),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.start,
//                       children: [
//                         Expanded(
//                           flex: 2,
//                           child: Center(
//                             child: Focus(
//                               focusNode: playPauseFocusNode,
//                               child: IconButton(
//                                 icon: Icon(
//                                   _vlcPlayerController?.value.isPlaying ?? false
//                                       ? Icons.pause
//                                       : Icons.play_arrow,
//                                   color: Colors.white,
//                                 ),
//                                 onPressed: _togglePlayPause,
//                               ),
//                             ),
//                           ),
//                         ),
//                         Expanded(
//                           flex: 20,
//                           child: LinearProgressIndicator(
//                             value: _progress.isNaN ? 0 : _progress,
//                             color: borderColor,
//                             backgroundColor: Colors.grey,
//                           ),
//                         ),
//                         SizedBox(width: 20),
//                         Expanded(
//                           flex: 2,
//                           child: Center(
//                             child: Row(
//                               children: [
//                                 Icon(
//                                   Icons.circle,
//                                   color: Colors.red,
//                                   size: 15,
//                                 ),
//                                 SizedBox(width: 5),
//                                 Text(
//                                   'Live',
//                                   style: TextStyle(
//                                     color: Colors.red,
//                                     fontSize: 20,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                         SizedBox(width: 20),
//                       ],
//                     ),
//                   ),
//                 ),
//               if (_isBuffering)
//                 Center(
//                   child: SpinKitFadingCircle(
//                     color: borderColor,
//                     size: 50.0,
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

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
    required int initialIndex,
  }) : super(key: key);


  @override
  _VlcPlayerScreenState createState() => _VlcPlayerScreenState();
}

class _VlcPlayerScreenState extends State<VlcPlayerScreen> {
  late VlcPlayerController _vlcController;
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    // Initialize the VlcPlayerController with a sample video URL
    _vlcController = VlcPlayerController.network(
      widget.videoUrl,
      hwAcc: HwAcc.full, // Enable hardware acceleration for smooth TV playback
      autoPlay: true, // Auto-play the video on initialization
    );
  }

  @override
  void dispose() {
    _vlcController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Stack(
          children: [
            VlcPlayer(
              controller: _vlcController,
              aspectRatio: 16 / 9,
              placeholder: Center(child: CircularProgressIndicator()),
            ),
            Positioned(
              bottom: 30,
              left: 30,
              child: _buildPlaybackControls(), // Playback controls
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaybackControls() {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            _isPlaying ? Icons.pause : Icons.play_arrow,
            color: Colors.white,
            size: 36.0,
          ),
          onPressed: _togglePlayPause,
        ),
        IconButton(
          icon: Icon(
            Icons.stop,
            color: Colors.white,
            size: 36.0,
          ),
          onPressed: _stopPlayback,
        ),
      ],
    );
  }

  void _togglePlayPause() {
    setState(() {
      if (_isPlaying) {
        _vlcController.pause();
      } else {
        _vlcController.play();
      }
      _isPlaying = !_isPlaying;
    });
  }

  void _stopPlayback() {
    _vlcController.stop();
    setState(() {
      _isPlaying = false;
    });
  }
}


