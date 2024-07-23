// import 'dart:async';
// import 'dart:convert';
// import 'package:container_gradient_border/container_gradient_border.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter/widgets.dart';
// import 'package:http/http.dart' as http;
// import 'package:mobi_tv_entertainment/main.dart';
// import 'package:video_player/video_player.dart';

// class Channel {
//   final String name;
//   final String banner;
//   final String genres;
//   final String videoUrl;

//   Channel({
//     required this.name,
//     required this.banner,
//     required this.genres,
//     required this.videoUrl,
//   });

//   factory Channel.fromJson(Map<String, dynamic> json) {
//     return Channel(
//       name: json['name'] ?? 'Unknown',
//       banner: json['banner'] ?? '',
//       genres: json['genres'] ?? 'Unknown',
//       videoUrl: json['url'] ?? '',
//     );
//   }
// }

// Future<List<Channel>> fetchChannels() async {
//   try {
//     final response = await http.get(
//       Uri.parse('https://mobifreetv.com/android/getFeaturedLiveTV'),
//       headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
//     );

//     if (response.statusCode == 200) {
//       List<dynamic> data = json.decode(response.body);
//       return data.map((channel) => Channel.fromJson(channel)).toList();
//     } else {
//       print('Failed to load channels. Status code: ${response.statusCode}');
//       throw Exception('Failed to load channels');
//     }
//   } catch (e) {
//     print('Error fetching channels: $e');
//     throw e;
//   }
// }

// class VideoPlayerScreen extends StatefulWidget {
//   final String videoUrl;
//   final String genres;

//   VideoPlayerScreen({
//     required this.videoUrl,
//     required this.genres,
//   });

//   @override
//   _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
// }

// class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
//   late VideoPlayerController _controller;
//   bool _isError = false;
//   String _errorMessage = '';
//   late Future<List<Channel>> futureChannels;
//   bool showChannels = false;
//   Timer? _timer;
//   DateTime? _lastActivityTime; // Track last activity time

//   @override
//   void initState() {
//     super.initState();
//     futureChannels = fetchChannelsByGenres(widget.genres);
//     _initializeVideoPlayer();

//     // Initialize timer to hide channels after 10 seconds of inactivity
//     _startTimer();
//   }

//   void _initializeVideoPlayer() {
//     _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
//       ..initialize().then((_) {
//         setState(() {});
//         _controller.play();
//       }).catchError((error) {
//         setState(() {
//           _isError = true;
//           _errorMessage = error.toString();
//         });
//       });
//   }

//   void _startTimer() {
//     _timer = Timer.periodic(Duration(seconds: 10), (timer) {
//       if (_lastActivityTime == null ||
//           DateTime.now().difference(_lastActivityTime!) >
//               Duration(seconds: 10)) {
//         setState(() {
//           showChannels = false;
//         });
//       }
//     });
//   }

//   void _resetTimer() {
//     _lastActivityTime = DateTime.now();
//     if (_timer != null) {
//       _timer!.cancel();
//     }
//     _startTimer();
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     _timer?.cancel();
//     super.dispose();
//   }

//   Future<List<Channel>> fetchChannelsByGenres(String genres) async {
//     try {
//       final response = await http.get(
//         Uri.parse('https://mobifreetv.com/android/getFeaturedLiveTV'),
//         headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
//       );

//       if (response.statusCode == 200) {
//         List<dynamic> data = json.decode(response.body);
//         List<Channel> filteredChannels = data
//             .map((channel) => Channel.fromJson(channel))
//             .where((channel) => channel.genres == genres)
//             .toList();
//         return filteredChannels;
//       } else {
//         print('Failed to load channels. Status code: ${response.statusCode}');
//         throw Exception('Failed to load channels');
//       }
//     } catch (e) {
//       print('Error fetching channels: $e');
//       throw e;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: _isError
//             ? Text('Error loading video: $_errorMessage')
//             : _controller.value.isInitialized
//                 ? Stack(
//                     children: [
//                       Positioned.fill(
//                         child: AspectRatio(
//                           aspectRatio: 16 / 9,
//                           child: VideoPlayer(_controller),
//                         ),
//                       ),
//                       Positioned(
//                         left: 0,
//                         right: 0,
//                         bottom: 0,
//                         child: AnimatedOpacity(
//                           duration: const Duration(milliseconds: 300),
//                           opacity: showChannels ? 1.0 : 0.0,
//                           child: Container(
//                             height: 150,
//                             color: Colors.black.withOpacity(0.5),
//                             child: FutureBuilder<List<Channel>>(
//                               future: futureChannels,
//                               builder: (context, snapshot) {
//                                 if (snapshot.connectionState ==
//                                     ConnectionState.waiting) {
//                                   return const Center(
//                                       child: CircularProgressIndicator());
//                                 } else if (snapshot.hasError) {
//                                   return Center(
//                                       child: Text('Error: ${snapshot.error}'));
//                                 } else if (!snapshot.hasData ||
//                                     snapshot.data!.isEmpty) {
//                                   return const Center(
//                                       child: Text('No channels found'));
//                                 } else {
//                                   List<Channel> channels = snapshot.data!;
//                                   return ListView.builder(
//                                     scrollDirection: Axis.horizontal,
//                                     itemCount: channels.length,
//                                     itemBuilder: (context, index) {
//                                       return Padding(
//                                         padding: const EdgeInsets.symmetric(
//                                             horizontal: 8.0),
//                                         child: showChannels
//                                             ? ChannelItem(
//                                                 channel: channels[index],
//                                                 onPressed: () {
//                                                   _controller.pause();
//                                                   _resetTimer();
//                                                 },
//                                                 onFocused: () {
//                                                   _resetTimer();
//                                                 },
//                                               )
//                                             : const SizedBox.shrink(),
//                                       );
//                                     },
//                                   );
//                                 }
//                               },
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   )
//                 : const CircularProgressIndicator(),
//       ),
//       floatingActionButton: Stack(
//         children: [
//           AnimatedPositioned(
//             duration: const Duration(milliseconds: 300),
//             bottom: showChannels ? 160 : 16,
//             right: 16,
//             child: FloatingActionButton(
//               onPressed: () {
//                 setState(() {
//                   showChannels = !showChannels;
//                   _resetTimer();
//                 });
//               },
//               child: Icon(showChannels ? Icons.close : Icons.grid_view),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class CategoryScreen extends StatefulWidget {
//   @override
//   _CategoryScreenState createState() => _CategoryScreenState();
// }

// class _CategoryScreenState extends State<CategoryScreen> {
//   late Future<List<Channel>> futureChannels;

//   @override
//   void initState() {
//     super.initState();
//     futureChannels = fetchChannels();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.cardColor,
//       body: FutureBuilder<List<Channel>>(
//         future: futureChannels,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           } else if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
//             return const Center(child: Text('No channels found'));
//           } else {
//             List<Channel> channels = snapshot.data!;
//             Map<String, List<Channel>> groupedChannels = {};

//             for (var channel in channels) {
//               if (groupedChannels[channel.genres] == null) {
//                 groupedChannels[channel.genres] = [];
//               }
//               groupedChannels[channel.genres]!.add(channel);
//             }

//             return ListView(
//               children: groupedChannels.entries.map((entry) {
//                 return Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Padding(
//                       padding: const EdgeInsets.only(
//                           top: 8.0, left: 16.0, right: 16.0),
//                       child: Text(
//                         entry.key,
//                         style: const TextStyle(
//                             fontSize: 20,
//                             fontWeight: FontWeight.bold,
//                             color: AppColors.hintColor),
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Container(
//                       height: 140,
//                       child: ListView.builder(
//                         scrollDirection: Axis.horizontal,
//                         itemCount: entry.value.length,
//                         itemBuilder: (context, index) {
//                           return Padding(
//                             padding:
//                                 const EdgeInsets.symmetric(horizontal: 8.0),
//                             child: ChannelItem(
//                               channel: entry.value[index],
//                               onPressed: () {
//                                 // Implement actions on selection if needed
//                               },
//                             ),
//                           );
//                         },
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                   ],
//                 );
//               }).toList(),
//             );
//           }
//         },
//       ),
//     );
//   }
// }

// class ChannelItem extends StatefulWidget {
//   final Channel channel;
//   final VoidCallback onPressed;
//   final VoidCallback? onFocused;

//   ChannelItem({
//     required this.channel,
//     required this.onPressed,
//     this.onFocused,
//   });

//   @override
//   _ChannelItemState createState() => _ChannelItemState();
// }

// class _ChannelItemState extends State<ChannelItem> {
//   late FocusNode _focusNode;
//   bool _isFocused = false;

//   @override
//   void initState() {
//     super.initState();
//     _focusNode = FocusNode();
//   }

//   @override
//   void dispose() {
//     _focusNode.dispose();
//     super.dispose();
//   }

//   void _handleSelect() {
//     widget.onPressed();
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => VideoPlayerScreen(
//           videoUrl: widget.channel.videoUrl,
//           genres: widget.channel.genres,
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Focus(
//       focusNode: _focusNode,
//       onFocusChange: (hasFocus) {
//         setState(() {
//           _isFocused = hasFocus;
//         });
//         if (hasFocus && widget.onFocused != null) {
//           widget.onFocused!();
//         }
//       },
//       onKeyEvent: (node, event) {
//         if (event is KeyDownEvent &&
//             event.logicalKey == LogicalKeyboardKey.select) {
//           _handleSelect();
//           return KeyEventResult.handled;
//         }
//         return KeyEventResult.ignored;
//       },
//       child: GestureDetector(
//         onTap: _handleSelect,
//         child: Padding(
//           padding: const EdgeInsets.all(1.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               AnimatedContainer(
//                 duration: const Duration(milliseconds: 300),
//                 width: _focusNode.hasFocus ? 120 : 80,
//                 height: _focusNode.hasFocus ? 100 : 80,
//                 // decoration: BoxDecoration(
//                 //   border: Border.all(
//                 //     color: _isFocused
//                 //         ?
//                 //          AppColors.primaryColor
//                 //         // GradientColor.fromLinearGradient(myGradient)

//                 //         : Colors.transparent,
//                 //     width: 5.0,
//                 //   ),
//                 //   borderRadius: BorderRadius.circular(13.0),
//                 // ),
//                 child: ContainerGradientBorder(
//                   width: _focusNode.hasFocus ? 110 : 70,
//                   height: _focusNode.hasFocus ? 90 : 70,
//                   start: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                   borderWidth: 7,
//                   colorList: const [
//                     AppColors.primaryColor,
//                     AppColors.highlightColor
//                   ],
//                   borderRadius: 10,
//                   child: ClipRRect(
//                     borderRadius: BorderRadius.circular(8.0),
//                     child: Image.network(
//                       widget.channel.banner,
//                       fit: BoxFit.cover,
//                       width: _focusNode.hasFocus ? 110 : 70,
//                       height: _focusNode.hasFocus ? 90 : 70,
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 2),
//               Container(
//                 width: _focusNode.hasFocus ? 100 : 80,
//                 child: Text(
//                   widget.channel.name,
//                   style: TextStyle(
//                     fontSize: 20,
//                     color: _isFocused
//                         ? AppColors.highlightColor
//                         // GradientColor.fromLinearGradient(myGradient)

//                         : AppColors.hintColor,
//                     // Yellow color when focused, white otherwise
//                   ),
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
