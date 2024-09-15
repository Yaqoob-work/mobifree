// import 'dart:async';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_spinkit/flutter_spinkit.dart';
// import 'package:keep_screen_on/keep_screen_on.dart';
// import 'package:mobi_tv_entertainment/main.dart';
// import 'package:better_player/better_player.dart';

// class VideoScreen extends StatefulWidget {
//   final String videoUrl;
//   final String videoTitle;
//   final List<dynamic> channelList;
//   final Function(bool) onFabFocusChanged;

//   VideoScreen({
//     required this.videoUrl,
//     required this.videoTitle,
//     required this.channelList,
//     required this.onFabFocusChanged,
//     required String genres,
//     required List channels,
//     required int initialIndex,
//   });

//   @override
//   _VideoScreenState createState() => _VideoScreenState();
// }

// class _VideoScreenState extends State<VideoScreen> with WidgetsBindingObserver {
//   late BetterPlayerController _betterPlayerController;
//   bool _controlsVisible = true;
//   late Timer _hideControlsTimer;
//   bool _isBuffering = false;
//   bool _isConnected = true;
//   Timer? _connectivityCheckTimer;
//   Duration _currentPosition = Duration.zero;
//   Duration _totalDuration = Duration.zero;

//   final FocusNode screenFocusNode = FocusNode();
//   final FocusNode playPauseFocusNode = FocusNode();

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     _initializePlayer();
//     _startConnectivityCheck();
//     KeepScreenOn.turnOn();

//     _startHideControlsTimer();
//     WidgetsBinding.instance!.addPostFrameCallback((_) {
//       FocusScope.of(context).requestFocus(screenFocusNode);
//     });
//   }

//   void _initializePlayer() {
//     BetterPlayerDataSource dataSource = BetterPlayerDataSource(
//       BetterPlayerDataSourceType.network,
//       widget.videoUrl,
//       liveStream: true,
//     );

//     _betterPlayerController = BetterPlayerController(
//       BetterPlayerConfiguration(
//         aspectRatio: 16 / 9,
//         fit: BoxFit.contain,
//         autoPlay: true,
//         controlsConfiguration: BetterPlayerControlsConfiguration(
//           showControls: false,
//         ),
//       ),
//       betterPlayerDataSource: dataSource,
//     );

//     _betterPlayerController.addEventsListener((event) {
//       if (event.betterPlayerEventType == BetterPlayerEventType.initialized) {
//         setState(() {
//           _totalDuration = _betterPlayerController.videoPlayerController!.value.duration!;
//         });
//       }
//     });

//     // Position updater
//     Timer.periodic(Duration(milliseconds: 500), (_) {
//       if (_betterPlayerController.videoPlayerController != null &&
//           _betterPlayerController.videoPlayerController!.value.initialized) {
//         setState(() {
//           _currentPosition = _betterPlayerController.videoPlayerController!.value.position;
//         });
//       }
//     });
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     _betterPlayerController.dispose();
//     _hideControlsTimer.cancel();
//     screenFocusNode.dispose();
//     playPauseFocusNode.dispose();
//     _connectivityCheckTimer?.cancel();
//     KeepScreenOn.turnOff();
//     super.dispose();
//   }

//   void _startConnectivityCheck() {
//     _connectivityCheckTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
//       try {
//         final result = await InternetAddress.lookup('google.com');
//         if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
//           _updateConnectionStatus(true);
//         } else {
//           _updateConnectionStatus(false);
//         }
//       } on SocketException catch (_) {
//         _updateConnectionStatus(false);
//       }
//     });
//   }

//   void _updateConnectionStatus(bool isConnected) {
//     if (isConnected != _isConnected) {
//       setState(() {
//         _isConnected = isConnected;
//       });
//       if (!isConnected) {
//         _betterPlayerController.pause();
//       } else if (!_betterPlayerController.isPlaying()!) {
//         _betterPlayerController.play();
//       }
//     }
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.resumed) {
//       if (!_betterPlayerController.isPlaying()!) {
//         _betterPlayerController.play();
//       }
//     } else if (state == AppLifecycleState.paused) {
//       _betterPlayerController.pause();
//     }
//   }

//   void _startHideControlsTimer() {
//     _hideControlsTimer = Timer(Duration(seconds: 10), () {
//       setState(() {
//         _controlsVisible = false;
//       });
//     });
//   }

//   void _resetHideControlsTimer() {
//     _hideControlsTimer.cancel();
//     setState(() {
//       _controlsVisible = true;
//     });
//     _startHideControlsTimer();
//   }

//   void _togglePlayPause() {
//     if (_betterPlayerController.isPlaying()!) {
//       _betterPlayerController.pause();
//     } else {
//       _betterPlayerController.play();
//     }
//     _resetHideControlsTimer();
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
//             } else if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
//                 event.logicalKey == LogicalKeyboardKey.arrowDown) {
//               _resetHideControlsTimer();
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
//                 child: AspectRatio(
//                   aspectRatio: 16 / 9,
//                   child: BetterPlayer(controller: _betterPlayerController),
//                 ),
//               ),
//               if (_controlsVisible)
//                 Positioned(
//                   bottom: 0,
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
//                               onFocusChange: (hasFocus) {
//                                 setState(() {
//                                   // Change button color on focus
//                                 });
//                               },
//                               child: IconButton(
//                                 icon: Icon(
//                                   _betterPlayerController.isPlaying()!
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
//                           flex: 15,
//                           child: CustomProgressIndicator(
//                             currentPosition: _currentPosition,
//                             totalDuration: _totalDuration,
//                             onSeek: (double value) {
//                               final Duration newPosition = Duration(seconds: (value * _totalDuration.inSeconds).round());
//                               _betterPlayerController.seekTo(newPosition);
//                             },
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
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class CustomProgressIndicator extends StatelessWidget {
//   final Duration currentPosition;
//   final Duration totalDuration;
//   final Function(double) onSeek;

//   CustomProgressIndicator({
//     required this.currentPosition,
//     required this.totalDuration,
//     required this.onSeek,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final double progress = totalDuration.inSeconds > 0
//         ? currentPosition.inSeconds / totalDuration.inSeconds
//         : 0.0;

//     return SliderTheme(
//       data: SliderTheme.of(context).copyWith(
//         activeTrackColor: borderColor,
//         inactiveTrackColor: Colors.grey,
//         thumbColor: borderColor,
//         overlayColor: borderColor.withAlpha(32),
//         thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8.0),
//         overlayShape: RoundSliderOverlayShape(overlayRadius: 16.0),
//       ),
//       child: Slider(
//         value: progress,
//         onChanged: onSeek,
//       ),
//     );
//   }
// }
