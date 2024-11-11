// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter_spinkit/flutter_spinkit.dart';
// import '../video_widget/socket_service.dart';
// import '../video_widget/video_movie_screen.dart'; // Assuming this is for the details page
// import '../video_widget/video_screen.dart'; // For other parts of the app

// class ReusableVideoPlayer extends StatefulWidget {
//   late final String videoUrl;
//   final String videoType;
//   final String videoTitle;
//   final String genres;
//   final String bannerImageUrl;
//   final Function? onVideoEnd;
//   final bool isFromDetailsPage; // New flag to determine which screen to use

//   ReusableVideoPlayer({
//     required this.videoUrl,
//     required this.videoType,
//     required this.videoTitle,
//     required this.genres,
//     required this.bannerImageUrl,
//     this.onVideoEnd,
//     this.isFromDetailsPage = false, // Defaults to false for other parts of the app
//   });

//   @override
//   _ReusableVideoPlayerState createState() => _ReusableVideoPlayerState();
// }

// class _ReusableVideoPlayerState extends State<ReusableVideoPlayer> {
//   final SocketService _socketService = SocketService();
//   bool _isLoading = false;
//   bool _shouldContinueLoading = true;
//   int _maxRetries = 3;
//   int _retryDelay = 5; // seconds

//   @override
//   void initState() {
//     super.initState();
//     _socketService.initSocket();
//     _checkServerStatus();
//     _playVideo(context); // Automatically start playing the video
//   }

//   @override
//   void dispose() {
//     _socketService.dispose();
//     super.dispose();
//   }

//   // Method to check server status and reconnect if needed
//   void _checkServerStatus() {
//     Timer.periodic(Duration(seconds: 10), (timer) {
//       if (!_socketService.socket.connected) {
//         print('YouTube server down, retrying...');
//         _socketService.initSocket();
//       }
//     });
//   }

//   Future<void> _updateUrlIfNeeded() async {
//     if (widget.videoType == 'YoutubeLive') {
//       for (int i = 0; i < _maxRetries; i++) {
//         if (!_shouldContinueLoading) break;
//         try {
//           String updatedUrl = await _socketService.getUpdatedUrl(widget.videoUrl);
//           setState(() {
//             widget.videoUrl = updatedUrl;
//           });
//           break;
//         } catch (e) {
//           if (i == _maxRetries - 1) rethrow;
//           await Future.delayed(Duration(seconds: _retryDelay));
//         }
//       }
//     }
//   }

//   Future<void> _playVideo(BuildContext context) async {
//     setState(() {
//       _isLoading = true;
//     });
//     _shouldContinueLoading = true;

//     try {
//       await _updateUrlIfNeeded();
//       if (_shouldContinueLoading) {
//         // Navigate to either VideoMovieScreen or VideoScreen based on the page source
//         await Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => widget.isFromDetailsPage
//                 ? VideoMovieScreen( // Play from VideoMovieScreen if from details page
//                     videoUrl: widget.videoUrl,
//                     videoTitle: widget.videoTitle,
//                     genres: widget.genres,
//                     videoBanner: widget.bannerImageUrl,
//                     channelList: [], onFabFocusChanged: (bool focused) {  }, videoType: '', url: '', 
//                     // type: '', // Add if necessary
//                   )
//                 : VideoScreen( // Play from VideoScreen for other parts of the app
//                     videoUrl: widget.videoUrl,
//                     // videoTitle: widget.videoTitle,
//                     // genres: widget.genres,
//                     bannerImageUrl: widget.bannerImageUrl,
//                     // channelList: [], // Add if necessary
//                     startAtPosition: Duration.zero, 
//                     videoType: widget.videoType,
//                     // channels: [], initialIndex: 1,
//                     categoryItems: [],
//                   ),
//           ),
//         );
//       }
//     } catch (e) {
//       _handleVideoError(context);
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   void _handleVideoError(BuildContext context) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('Something Went Wrong', style: TextStyle(fontSize: 20)),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       children: [
//         if (_isLoading)
//           Center(
//             child: SpinKitFadingCircle(
//               color: Colors.white,
//               size: 50.0,
//             ),
//           ),
//       ],
//     );
//   }
// }
