// // last_played_videos_page.dart

// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_spinkit/flutter_spinkit.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:mobi_tv_entertainment/main.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:mobi_tv_entertainment/video_widget/socket_service.dart';
// import 'package:mobi_tv_entertainment/video_widget/video_screen.dart';
// import 'package:mobi_tv_entertainment/widgets/small_widgets/loading_indicator.dart';
// import 'package:mobi_tv_entertainment/widgets/models/news_item_model.dart';

// class LastPlayedVideosPage extends StatefulWidget {
//   @override
//   _LastPlayedVideosPageState createState() => _LastPlayedVideosPageState();
// }

// class _LastPlayedVideosPageState extends State<LastPlayedVideosPage> {
//   List<Map<String, dynamic>> lastPlayedVideos = [];
//   final SocketService _socketService = SocketService();
//   bool _isNavigating = false;
//   final int _maxRetries = 3;
//   final int _retryDelay = 5;
//   late StreamSubscription refreshSubscription;
//   Key refreshKey = UniqueKey();

//   @override
//   void initState() {
//     super.initState();
//     _socketService.initSocket();
//     refreshSubscription =
//         GlobalEventBus.eventBus.on<RefreshPageEvent>().listen((event) {
//       if (event.pageId == 'uniquePageId') {
//         _loadLastPlayedVideos();
//         Future.delayed(Duration(milliseconds: 500), () {
//           if (mounted) {
//             setState(() {
//               refreshKey = UniqueKey();
//             });
//             _loadLastPlayedVideos();
//           }
//         });
//       }
//     });
//     _loadLastPlayedVideos();
//   }

//   @override
//   void dispose() {
//     _socketService.dispose();
//     refreshSubscription.cancel();
//     super.dispose();
//   }

//   Future<void> _loadLastPlayedVideos() async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       List<String>? storedVideos = prefs.getStringList('last_played_videos');

//       if (storedVideos != null && storedVideos.isNotEmpty) {
//         setState(() {
//           lastPlayedVideos = storedVideos.map((videoEntry) {
//             List<String> details = videoEntry.split('|');

//             Duration position;
//             try {
//               position = Duration(milliseconds: int.tryParse(details[1]) ?? 0);
//             } catch (e) {
//               position = Duration.zero;
//             }

//             String videoId = '';
//             if (details.length > 5) {
//               videoId = details[5].trim();
//               if (videoId == 'null' || videoId == '') {
//                 videoId = '0';
//               }
//             }

//             return {
//               'videoUrl': details.isNotEmpty ? details[0] : '',
//               'position': position,
//               'bannerImageUrl': details.length > 2 ? details[2] : '',
//               'videoName': details.length > 3 ? details[3] : '',
//               'source': details.length > 4 ? details[4] : '',
//               'videoId': videoId,
//               'focusNode': FocusNode(),
//             };
//           }).toList();
//         });
//       }
//     } catch (e) {
//       print("Error loading last played videos: $e");
//       setState(() {
//         lastPlayedVideos = [];
//       });
//     }
//   }

//   void addNewBannerOrVideo(Map<String, dynamic> newVideo) async {
//     final prefs = await SharedPreferences.getInstance();
//     List<String> storedVideos = prefs.getStringList('last_played_videos') ?? [];

//     String newVideoEntry =
//         '${newVideo['videoUrl']}|${newVideo['position'].inMilliseconds}|${newVideo['bannerImageUrl']}|${newVideo['videoName']}';
//     storedVideos.insert(0, newVideoEntry);

//     if (storedVideos.length > 10) {
//       storedVideos = storedVideos.sublist(0, 10);
//     }

//     await prefs.setString('last_played_videos', json.encode(storedVideos));
//     await _loadLastPlayedVideos();
//   }

//   bool isYoutubeUrl(String? url) {
//     if (url == null || url.isEmpty) return false;

//     url = url.toLowerCase().trim();

//     bool isYoutubeId = RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(url);
//     if (isYoutubeId) return true;

//     return url.contains('youtube.com') ||
//         url.contains('youtu.be') ||
//         url.contains('youtube.com/shorts/');
//   }

//   void _playVideo(Map<String, dynamic> videoData, Duration position) async {
//     if (_isNavigating) return;
//     _isNavigating = true;

//     bool shouldPlayVideo = true;
//     bool shouldPop = true;

//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return WillPopScope(
//           onWillPop: () async {
//             shouldPlayVideo = false;
//             shouldPop = false;
//             return true;
//           },
//           child: LoadingIndicator(),
//         );
//       },
//     );

//     Timer(Duration(seconds: 10), () {
//       _isNavigating = false;
//     });

//     try {
//       final currentIndex = lastPlayedVideos
//           .indexWhere((video) => video['videoUrl'] == videoData['videoUrl']);

//       List<NewsItemModel> channelList = [];
//       for (int i = 0; i < lastPlayedVideos.length; i++) {
//         String videoUrl = lastPlayedVideos[i]['videoUrl'] ?? '';
//         String videoIdString = lastPlayedVideos[i]['videoId'] ?? '0';
//         String contentIdString = lastPlayedVideos[i]['videoId'] ?? '0';
//         String streamType = isYoutubeUrl(videoUrl) ? 'YoutubeLive' : 'M3u8';

//         channelList.add(NewsItemModel(
//             id: videoIdString,
//             url: videoUrl,
//             banner: lastPlayedVideos[i]['bannerImageUrl'] ?? '',
//             name: lastPlayedVideos[i]['videoName'] ?? '',
//             contentId: contentIdString,
//             status: '1',
//             streamType: streamType,
//             contentType: '1',
//             genres: ''));
//       }

//       String source = videoData['source'] ?? '';
//       int videoId = 0;
//       if (videoData['videoId'] != null &&
//           videoData['videoId'].toString().isNotEmpty) {
//         videoId = int.tryParse(videoData['videoId'].toString()) ?? 0;
//       }
//       String originalUrl = videoData['videoUrl'];
//       String updatedUrl = videoData['videoUrl'];

//       if (isYoutubeUrl(updatedUrl)) {
//         updatedUrl = await _socketService.getUpdatedUrl(updatedUrl);
//       }

//       if (shouldPop) {
//         Navigator.of(context, rootNavigator: true).pop();
//       }

//       if (shouldPlayVideo) {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => VideoScreen(
//               videoUrl: updatedUrl,
//               unUpdatedUrl: originalUrl,
//               channelList: channelList,
//               bannerImageUrl: videoData['bannerImageUrl'],
//               startAtPosition: position,
//               videoType: '',
//               isLive: source == 'isLiveScreen',
//               isVOD: source == 'isVOD',
//               isSearch: source == 'isSearchScreen',
//               isHomeCategory: source == 'isHomeCategory',
//               isBannerSlider: source == 'isBannerSlider',
//               videoId: videoId,
//               source: 'isLastPlayedVideos', name: '',
//             ),
//           ),
//         );
//       }
//     } catch (e) {
//       print("Error playing video: $e");
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('Unable to play this content')));
//       }
//     } finally {
//       _isNavigating = false;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: cardColor,
//       body: Column(
//         key: refreshKey,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           if (lastPlayedVideos.isNotEmpty)
//             Padding(
//               padding:
//                   const EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
//               child: Text(
//                 'Continue Watching',
//                 style: TextStyle(
//                   fontSize: Headingtextsz,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//           Expanded(
//             child: lastPlayedVideos.isEmpty
//                 ? Center(child: Text('No recently played videos'))
//                 : ListView.builder(
//                     scrollDirection: Axis.horizontal,
//                     padding: EdgeInsets.symmetric(horizontal: 10),
//                     itemCount: lastPlayedVideos.length > 10
//                         ? 10
//                         : lastPlayedVideos.length,
//                     itemBuilder: (context, index) {
//                       Map<String, dynamic> videoData = lastPlayedVideos[index];
//                       FocusNode focusNode =
//                           videoData['focusNode'] ?? FocusNode();
//                       lastPlayedVideos[index]['focusNode'] = focusNode;

//                       return Focus(
//                         focusNode: focusNode,
//                         onKey: (node, event) {
//                           if (event is RawKeyDownEvent) {
//                             if (event.logicalKey ==
//                                     LogicalKeyboardKey.arrowRight &&
//                                 index < lastPlayedVideos.length - 1) {
//                               FocusScope.of(context).requestFocus(
//                                   lastPlayedVideos[index + 1]['focusNode']);
//                               return KeyEventResult.handled;
//                             } else if (event.logicalKey ==
//                                     LogicalKeyboardKey.arrowLeft &&
//                                 index > 0) {
//                               FocusScope.of(context).requestFocus(
//                                   lastPlayedVideos[index - 1]['focusNode']);
//                               return KeyEventResult.handled;
//                             } else if (event.logicalKey ==
//                                     LogicalKeyboardKey.enter ||
//                                 event.logicalKey == LogicalKeyboardKey.select) {
//                               _playVideo(videoData, videoData['position']);
//                               return KeyEventResult.handled;
//                             }
//                           }
//                           return KeyEventResult.ignored;
//                         },
//                         child: VideoCard(
//                           videoData: videoData,
//                           focusNode: focusNode,
//                           onTap: () =>
//                               _playVideo(videoData, videoData['position']),
//                         ),
//                       );
//                     },
//                   ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class VideoCard extends StatelessWidget {
//   final Map<String, dynamic> videoData;
//   final FocusNode focusNode;
//   final VoidCallback onTap;

//   const VideoCard({
//     required this.videoData,
//     required this.focusNode,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         width: screenwdt * 0.15,
//         margin: EdgeInsets.symmetric(horizontal: 5),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(8),
//           color: focusNode.hasFocus ? Colors.black87 : Colors.black26,
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             ClipRRect(
//               borderRadius: BorderRadius.circular(8),
//               child: CachedNetworkImage(
//                 imageUrl: videoData['bannerImageUrl'] ?? localImage,
//                 fit: BoxFit.cover,
//                 width: double.infinity,
//                 height: screenhgt * 0.15,
//                 placeholder: (context, url) => Container(
//                   color: Colors.grey[300],
//                   child: Center(child: CircularProgressIndicator()),
//                 ),
//                 errorWidget: (context, url, error) => Image.asset(
//                   'assets/logo.png',
//                   fit: BoxFit.cover,
//                   width: double.infinity,
//                   height: screenhgt * 0.15,
//                 ),
//               ),
//             ),
//             SizedBox(height: screenhgt * 0.02),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 5),
//               child: LinearProgressIndicator(
//                 value: videoData['position'].inMilliseconds /
//                     (Duration(minutes: 60).inMilliseconds),
//                 backgroundColor: Colors.grey.shade300,
//                 valueColor: AlwaysStoppedAnimation<Color>(
//                     focusNode.hasFocus ? Colors.blue : Colors.green),
//               ),
//             ),
//             SizedBox(height: screenhgt * 0.02),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 5),
//               child: Text(
//                 videoData['videoName'] ?? '',
//                 style: TextStyle(
//                   fontSize: nametextsz,
//                   color: focusNode.hasFocus ? Colors.white : Colors.grey,
//                 ),
//                 overflow: TextOverflow.ellipsis,
//                 maxLines: 2,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
