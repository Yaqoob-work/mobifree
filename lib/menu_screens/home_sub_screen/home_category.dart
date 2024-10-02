// import 'dart:async';
// import 'dart:convert';
// import 'dart:math';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_spinkit/flutter_spinkit.dart';
// import 'package:http/http.dart' as https;
// import '../../main.dart';
// import '../../video_widget/socket_service.dart';
// import '../../video_widget/video_screen.dart';
// import '../../widgets/utils/color_service.dart';

// Map<String, dynamic> settings = {};

// Future<void> fetchSettings() async {
//   final response = await https.get(
//     Uri.parse('https://api.ekomflix.com/android/getSettings'),
//     headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
//   );

//   if (response.statusCode == 200) {
//     settings = json.decode(response.body);
//   } else {
//     throw Exception('Failed to load settings');
//   }
// }

// Future<List<Category>> fetchCategories() async {
//   await fetchSettings();

//   final response = await https.get(
//     Uri.parse('https://api.ekomflix.com/android/getSelectHomeCategory'),
//     headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
//   );

//   if (response.statusCode == 200) {
//     List jsonResponse = json.decode(response.body);
//     List<Category> categories =
//         jsonResponse.map((category) => Category.fromJson(category)).toList();

//     if (settings['tvenableAll'] == 0) {
//       for (var category in categories) {
//         category.channels.retainWhere(
//             (channel) => settings['channels'].contains(int.parse(channel.id)));
//       }
//     }

//     return categories;
//   } else {
//     throw Exception('Failed to load categories');
//   }
// }

// class HomeCategory extends StatefulWidget {
//   @override
//   _HomeCategoryState createState() => _HomeCategoryState();
// }

// class _HomeCategoryState extends State<HomeCategory> {
//   late Future<List<Category>> _categories;

//   @override
//   void initState() {
//     super.initState();
//     _categories = fetchCategories();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: cardColor,
//       body: FutureBuilder<List<Category>>(
//         future: _categories,
//         builder: (context, snapshot) {
//           if (snapshot.hasData) {
//             List<Category> categories = snapshot.data!;
//             return ListView.builder(
//               itemCount: categories.length,
//               itemBuilder: (context, index) {
//                 return CategoryWidget(category: categories[index]);
//               },
//             );
//           } else if (snapshot.hasError) {
//             return Center(child: Text("${snapshot.error}"));
//           }

//           return Container(
//               color: Colors.black,
//               child: Center(
//                   child: SpinKitFadingCircle(
//                 color: borderColor,
//                 size: 50.0,
//               )));
//         },
//       ),
//     );
//   }
// }

// class Category {
//   final String id;
//   final String text;
//   List<Channel> channels;

//   Category({
//     required this.id,
//     required this.text,
//     required this.channels,
//   });

//   factory Category.fromJson(Map<String, dynamic> json) {
//     var list = json['channels'] as List;
//     List<Channel> channelsList = list.map((i) => Channel.fromJson(i)).toList();

//     return Category(
//       id: json['id'],
//       text: json['text'],
//       channels: channelsList,
//     );
//   }
// }

// class Channel {
//   final String id;
//   final String name;
//   final String description;
//   final String banner;
//   final String genres;
//   String url;
//   String streamType;
//   String type;
//   String status;

//   Channel({
//     required this.id,
//     required this.name,
//     required this.description,
//     required this.banner,
//     required this.genres,
//     required this.url,
//     required this.streamType,
//     required this.type,
//     required this.status,
//   });

//   factory Channel.fromJson(Map<String, dynamic> json) {
//     return Channel(
//       id: json['id'],
//       name: json['name'],
//       banner: json['banner'],
//       genres: json['genres'],
//       url: json['url'] ?? '',
//       streamType: json['stream_type'] ?? '',
//       type: json['Type'] ?? '',
//       status: json['status'] ?? '',
//       description: json['description'] ?? 'no description',
//     );
//   }
// }

// class ChannelWidget extends StatefulWidget {
//   final Channel channel;
//   final VoidCallback onTap;

//   ChannelWidget({required this.channel, required this.onTap});

//   @override
//   _ChannelWidgetState createState() => _ChannelWidgetState();
// }

// class _ChannelWidgetState extends State<ChannelWidget> {
//   bool isFocused = false;
//   Color secondaryColor = Colors.grey; // Default color
// final PaletteColorService _paletteColorService = PaletteColorService();
//   @override
//   void initState() {
//     super.initState();
//     _updateSecondaryColor();
//   }

//     Future<void> _updateSecondaryColor() async {
//     // if (widget.channel.status == '1') {
//       Color color = await _paletteColorService.getSecondaryColor(widget.channel.banner);
//       setState(() {
//         secondaryColor = color;
//       });
//     // }
//   }

//   @override
//   Widget build(BuildContext context) {
//     bool showBanner = widget.channel.status == '1';

//     return FocusableActionDetector(
//       onFocusChange: (hasFocus) {
//         setState(() {
//           isFocused = hasFocus;
//         });
//       },
//       actions: {
//         ActivateIntent: CallbackAction<ActivateIntent>(
//           onInvoke: (ActivateIntent intent) {
//             widget.onTap();
//             return null;
//           },
//         ),
//       },
//       child: GestureDetector(
//         onTap: widget.onTap,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.center,
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             if (showBanner)
//               Stack(
//                 children: [
//                   AnimatedContainer(
//                     width: screenwdt * 0.19,
//                     height: isFocused ? screenhgt * 0.24 : screenhgt * 0.21,
//                     duration: const Duration(milliseconds: 300),
//                     decoration: BoxDecoration(
//                       border:isFocused? Border.all(
//                         color:  secondaryColor ,
//                         width: 4.0,
//                       ):
//                       Border.all(
//                         color:  Colors.transparent,
//                         width: 4.0,
//                       ),
//                       borderRadius: BorderRadius.circular(0),
//                       boxShadow: isFocused
//                           ? [
//                               BoxShadow(
//                                 color: secondaryColor
//                                 // .withOpacity(0.5)
//                                 ,
//                                 blurRadius: 25,
//                                 spreadRadius: 10,
//                               )
//                             ]
//                           : [],
//                     ),
//                     child: CachedNetworkImage(
//                       imageUrl: widget.channel.banner,
//                       fit: BoxFit.cover,
//                       placeholder: (context, url) =>
//                           Container(color: Colors.grey),
//                       width: screenwdt * 0.19,
//                       height: isFocused ? screenhgt * 0.24 : screenhgt * 0.21,
//                     ),
//                   ),
//                 ],
//               ),
//             SizedBox(height: 10),
//             Container(
//               width: screenwdt * 0.19,
//               // height: isFocused ? screenhgt * 0.24 : screenhgt * 0.21,
//               // height: screenhgt * 0.15,

//               child: Column(
//                 children: [
//                   Text(
//                     (widget.channel.name).toUpperCase(),
//                     style: TextStyle(
//                       color: isFocused ? secondaryColor : Colors.grey,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 15,
//                     ),
//                     overflow: TextOverflow.ellipsis,
//                     maxLines: 1,
//                     textAlign: TextAlign.center,
//                   ),
//                   // Text(
//                   //   widget.channel.description,
//                   //   style: TextStyle(
//                   //     color: isFocused ? secondaryColor : Colors.grey,
//                   //     fontWeight: FontWeight.bold,
//                   //   ),
//                   //   overflow: TextOverflow.ellipsis,
//                   //   maxLines: 1,
//                   //   textAlign: TextAlign.center,
//                   // ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class ViewAllWidget extends StatefulWidget {
//   final VoidCallback onTap;
//   final String categoryText;

//   ViewAllWidget({required this.onTap, required this.categoryText});

//   @override
//   _ViewAllWidgetState createState() => _ViewAllWidgetState();
// }

// class _ViewAllWidgetState extends State<ViewAllWidget> {
//   bool isFocused = false;
//   Color focusColor = highlightColor;

//   @override
//   void initState() {
//     super.initState();
//     _updateFocusColor();
//   }

//   Future<void> _updateFocusColor() async {
//     // Generate a random color
//     Random random = Random();
//     Color randomColor = Color.fromARGB(
//       255, // Alpha value
//       random.nextInt(256), // Red
//       random.nextInt(256), // Green
//       random.nextInt(256), // Blue
//     );

//     setState(() {
//       focusColor = randomColor; // Use the random color
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return FocusableActionDetector(
//       onFocusChange: (hasFocus) {
//         setState(() {
//           isFocused = hasFocus;
//         });
//       },
//       actions: {
//         ActivateIntent: CallbackAction<ActivateIntent>(
//           onInvoke: (ActivateIntent intent) {
//             widget.onTap();
//             return null;
//           },
//         ),
//       },
//       child: GestureDetector(
//         onTap: widget.onTap,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.center,
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             AnimatedContainer(
//               width: screenwdt * 0.19,
//               height: isFocused ? screenhgt * 0.24 : screenhgt * 0.21,
//               duration: const Duration(milliseconds: 300),
//               decoration: BoxDecoration(
//                 border:isFocused ? Border.all(
//                   color:  focusColor ,
//                   width: 4.0,
//                 ):
//                 Border.all(
//                   color:  Colors.transparent,
//                   width: 4.0,
//                 ),
//                 color: Colors.grey[800],
//                 boxShadow: isFocused
//                     ? [
//                         BoxShadow(
//                           color: focusColor,
//                           blurRadius: 25,
//                           spreadRadius: 10,
//                         )
//                       ]
//                     : [],
//               ),
//               child: Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Text(
//                       'View All',
//                       style: TextStyle(
//                         color: isFocused ? focusColor : hintColor,
//                         fontWeight: FontWeight.bold,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                     Text(
//                       widget.categoryText,
//                       style: TextStyle(
//                         color: isFocused ? focusColor : hintColor,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 20,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                     Text(
//                       'Channels',
//                       style: TextStyle(
//                         color: isFocused ? focusColor : hintColor,
//                         fontWeight: FontWeight.bold,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             SizedBox(height: 10),
//             Container(
//               width: screenwdt * 0.17,
//               // height: screenhgt * 0.15,
//               child: Column(
//                 children: [
//                   Text(
//                     (widget.categoryText),
//                     style: TextStyle(
//                       color: isFocused ? focusColor : Colors.grey,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 15,
//                     ),
//                     overflow: TextOverflow.ellipsis,
//                     maxLines: 1,
//                     textAlign: TextAlign.center,
//                   ),
//                   // Text(
//                   //   '''See all ${(widget.categoryText).toLowerCase()} channels''',
//                   //   style: TextStyle(
//                   //     color: isFocused ? focusColor : Colors.grey,
//                   //     fontWeight: FontWeight.bold,
//                   //   ),
//                   //   overflow: TextOverflow.ellipsis,
//                   //   maxLines: 3,
//                   //   textAlign: TextAlign.center,
//                   // ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class CategoryWidget extends StatefulWidget {
//   final Category category;

//   CategoryWidget({required this.category});

//   @override
//   State<CategoryWidget> createState() => _CategoryWidgetState();
// }

// class _CategoryWidgetState extends State<CategoryWidget> {
//   bool _isNavigating = false;
//   final SocketService _socketService = SocketService();
//   int _maxRetries = 3;
//   int _retryDelay = 5; // seconds
//   final int timeoutDuration = 10; // seconds
//   bool _shouldContinueLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _socketService.initSocket();
//     fetchSettings();
//   }

//   @override
//   void dispose() {
//     _socketService.dispose();
//     super.dispose();
//   }

//   void _showLoadingIndicator(BuildContext context) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return PopScope(
//           canPop: false,
//           onPopInvoked: (didPop) {
//             if (didPop) return;
//             _shouldContinueLoading = false;
//             Navigator.of(context).pop();
//           },
//           child: Center(
//             child: SpinKitFadingCircle(
//               color: borderColor,
//               size: 50.0,
//             ),
//           ),
//         );
//       },
//     );
//   }

//   void _dismissLoadingIndicator() {
//     if (Navigator.of(context).canPop()) {
//       Navigator.of(context).pop();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     List<Channel> filteredChannels = widget.category.channels
//         .where((channel) => channel.url.isNotEmpty)
//         .toList();

//     return filteredChannels.isNotEmpty
//         ? Container(
//             color: cardColor,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Padding(
//                 // padding: const EdgeInsets.only(left: 10, top: 20, bottom: 10),
//                 // child:
//                 Text(
//                   widget.category.text.toUpperCase(),
//                   style: TextStyle(
//                     color: hintColor,
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 // ),
//                 SizedBox(
//                   height: MediaQuery.of(context).size.height * 0.4,
//                   child: ListView.builder(
//                     scrollDirection: Axis.horizontal,
//                     itemCount: filteredChannels.length > 5
//                         ? 6
//                         : filteredChannels.length,
//                     itemBuilder: (context, index) {
//                       if (index == 5 && filteredChannels.length > 5) {
//                         return Padding(
//                           padding: EdgeInsets.symmetric(horizontal: 10),
//                           child:
//                           Focus(
//                             onKey: (FocusNode node, RawKeyEvent event) {
//                               if (event is RawKeyDownEvent) {
//                                 if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
//                                   // Prevent focus from moving beyond "View All"
//                                   return KeyEventResult.handled;
//                                 }
//                               }
//                               return KeyEventResult.ignored;
//                             },
//                             child: ViewAllWidget(
//                             onTap: () {
//                               _dismissLoadingIndicator();

//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) => CategoryGridView(
//                                     category: widget.category,
//                                     filteredChannels: filteredChannels,
//                                   ),
//                                 ),
//                               );
//                             },
//                             categoryText: widget.category.text.toUpperCase(),
//                           ),
//                         ),
//                         );
//                       }
//                       return Padding(
//                         padding: EdgeInsets.symmetric(horizontal: 0),
//                         child: ChannelWidget(
//                           channel: filteredChannels[index],
//                           onTap: () async {
//                             _showLoadingIndicator(context);
//                             await _playVideo(context, filteredChannels, index);
//                           },
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           )
//         : const SizedBox.shrink();
//   }

//   Future<void> _playVideo(
//       BuildContext context, List<Channel> channels, int index) async {
//     if (_isNavigating) return;
//     _isNavigating = true;
//     _shouldContinueLoading = true;

//     try {
//       await _updateChannelUrlIfNeeded(channels, index);
//       if (_shouldContinueLoading) {
//         _dismissLoadingIndicator();
//         await _navigateToVideoScreen(context, channels, index);
//       }
//     } catch (e) {
//       print("Error playing video: $e");
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Something Went Wrong')),
//       );
//     } finally {
//       _isNavigating = false;
//       if (mounted) {
//         _dismissLoadingIndicator();
//       }
//     }
//   }

//   Future<void> _updateChannelUrlIfNeeded(
//       List<Channel> channels, int index) async {
//     if (channels[index].streamType == 'YoutubeLive') {
//       for (int i = 0; i < _maxRetries; i++) {
//         if (!_shouldContinueLoading) break;
//         try {
//           String updatedUrl =
//               await _socketService.getUpdatedUrl(channels[index].url);
//           channels[index].url = updatedUrl;
//           channels[index].streamType = 'M3u8';
//           break;
//         } catch (e) {
//           if (i == _maxRetries - 1) rethrow;
//           await Future.delayed(Duration(seconds: _retryDelay));
//         }
//       }
//     }
//   }

//   Future<void> _navigateToVideoScreen(
//       BuildContext context, List<Channel> channels, int index) async {
//     if (_shouldContinueLoading) {
//       final result = await Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => PopScope(
//             canPop: false,
//             onPopInvoked: (didPop) {
//               if (didPop) return;
//               Navigator.of(context).pop();
//             },
//             child: VideoScreen(
//               channels: channels,
//               initialIndex: index,
//               videoTitle: channels[index].name,
//               videoUrl: channels[index].url,
//               genres: channels[index].genres,
//               channelList: [], bannerImageUrl: '', startAtPosition: Duration.zero,
//               // onFabFocusChanged: (bool) {},
//             ),
//           ),
//         ),
//       );

//       // Handle any result returned from VideoScreen if needed
//       if (result != null) {
//         // Process the result
//       }
//     }
//   }
// }

// class CategoryGridView extends StatefulWidget {
//   final Category category;
//   final List<Channel> filteredChannels;

//   CategoryGridView({required this.category, required this.filteredChannels});

//   @override
//   _CategoryGridViewState createState() => _CategoryGridViewState();
// }

// class _CategoryGridViewState extends State<CategoryGridView> {
//   final SocketService _socketService = SocketService();
//   final int _maxRetries = 3;
//   final int _retryDelay = 5; // seconds
//   bool _shouldContinueLoading = true;
//   bool _isLoading = false; // State to manage loading indicator

//   Future<void> _updateChannelUrlIfNeeded(
//       List<Channel> channels, int index) async {
//     if (channels[index].streamType == 'YoutubeLive') {
//       for (int i = 0; i < _maxRetries; i++) {
//         if (!_shouldContinueLoading) break;
//         try {
//           String updatedUrl =
//               await _socketService.getUpdatedUrl(channels[index].url);
//           channels[index].url = updatedUrl;
//           channels[index].streamType = 'M3u8';
//           break;
//         } catch (e) {
//           if (i == _maxRetries - 1) rethrow;
//           await Future.delayed(Duration(seconds: _retryDelay));
//         }
//       }
//     }
//   }

//   Future<bool> _onWillPop() async {
//     if (_isLoading) {
//       setState(() {
//         _isLoading = false; // Hide the loading indicator
//         _shouldContinueLoading = false; // Stop ongoing loading
//       });
//       return false; // Prevent back navigation when loading
//     }
//     return true; // Allow navigation if not loading
//   }

//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//       onWillPop: _onWillPop, // Handle back button press
//       child: Scaffold(
//         backgroundColor: cardColor,
//         body: Stack(
//           children: [
//             GridView.builder(
//               padding: EdgeInsets.all(20),
//               gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                 crossAxisCount: 5,
//               ),
//               itemCount: widget.filteredChannels.length,
//               itemBuilder: (context, index) {
//                 return ChannelWidget(
//                   channel: widget.filteredChannels[index],
//                   onTap: () async {
//                     setState(() {
//                       _isLoading = true; // Show loading indicator
//                     });
//                     _shouldContinueLoading = true;

//                     await _updateChannelUrlIfNeeded(
//                         widget.filteredChannels, index);
//                     if (_shouldContinueLoading) {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => VideoScreen(
//                             channels: widget.filteredChannels,
//                             initialIndex: index,
//                             videoUrl: widget.filteredChannels[index].url,
//                             videoTitle: widget.filteredChannels[index].name,
//                             channelList: [],
//                             // onFabFocusChanged: (bool) {},
//                             genres: widget.filteredChannels[index].genres, bannerImageUrl: '', startAtPosition: Duration.zero,
//                           ),
//                         ),
//                       ).then((_) {
//                         setState(() {
//                           _isLoading =
//                               false; // Hide loading indicator after navigation
//                         });
//                       });
//                     }
//                   },
//                 );
//               },
//             ),
//             if (_isLoading)
//               Center(
//                 child: SpinKitFadingCircle(
//                   color: borderColor,
//                   size: 50.0,
//                 ), // Circular loading indicator
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }








import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as https;
import '../../main.dart';
import '../../video_widget/socket_service.dart';
import '../../video_widget/video_screen.dart';
import '../../widgets/utils/color_service.dart';

Map<String, dynamic> settings = {};

Future<void> fetchSettings() async {
  final response = await https.get(
    Uri.parse('https://api.ekomflix.com/android/getSettings'),
    headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
  );

  if (response.statusCode == 200) {
    settings = json.decode(response.body);
  } else {
    throw Exception('Failed to load settings');
  }
}

Future<List<Category>> fetchCategories() async {
  await fetchSettings();

  final response = await https.get(
    Uri.parse('https://api.ekomflix.com/android/getSelectHomeCategory'),
    headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
  );

  if (response.statusCode == 200) {
    List jsonResponse = json.decode(response.body);
    List<Category> categories =
        jsonResponse.map((category) => Category.fromJson(category)).toList();

    if (settings['tvenableAll'] == 0) {
      for (var category in categories) {
        category.channels.retainWhere(
            (channel) => settings['channels'].contains(int.parse(channel.id)));
      }
    }

    return categories;
  } else {
    throw Exception('Failed to load categories');
  }
}

class HomeCategory extends StatefulWidget {
  @override
  _HomeCategoryState createState() => _HomeCategoryState();
}

class _HomeCategoryState extends State<HomeCategory> {
  late Future<List<Category>> _categories;

  @override
  void initState() {
    super.initState();
    _categories = fetchCategories();
    checkServerStatus(); // Check server status for reconnection
  }

  void checkServerStatus() {
    Timer.periodic(Duration(seconds: 10), (timer) {
      // Check if the socket is connected, otherwise attempt to reconnect
      if (!SocketService().socket.connected) {
        print('YouTube server down, retrying...');
        SocketService().initSocket(); // Re-establish the socket connection
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cardColor,
      body: FutureBuilder<List<Category>>(
        future: _categories,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List<Category> categories = snapshot.data!;
            return ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                return CategoryWidget(category: categories[index]);
              },
            );
          } else if (snapshot.hasError) {
            return Center(child: Text("${snapshot.error}"));
          }

          return Container(
              color: Colors.black,
              child: Center(
                  child: SpinKitFadingCircle(
                color: borderColor,
                size: 50.0,
              )));
        },
      ),
    );
  }
}

class Category {
  final String id;
  final String text;
  List<Channel> channels;

  Category({
    required this.id,
    required this.text,
    required this.channels,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    var list = json['channels'] as List;
    List<Channel> channelsList = list.map((i) => Channel.fromJson(i)).toList();

    return Category(
      id: json['id'],
      text: json['text'],
      channels: channelsList,
    );
  }
}

class Channel {
  final String id;
  final String name;
  final String description;
  final String banner;
  final String genres;
  String url;
  String streamType;
  String type;
  String status;

  Channel({
    required this.id,
    required this.name,
    required this.description,
    required this.banner,
    required this.genres,
    required this.url,
    required this.streamType,
    required this.type,
    required this.status,
  });

  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(
      id: json['id'],
      name: json['name'],
      banner: json['banner'],
      genres: json['genres'],
      url: json['url'] ?? '',
      streamType: json['stream_type'] ?? '',
      type: json['Type'] ?? '',
      status: json['status'] ?? '',
      description: json['description'] ?? 'no description',
    );
  }
}

class CategoryWidget extends StatefulWidget {
  final Category category;

  CategoryWidget({required this.category});

  @override
  State<CategoryWidget> createState() => _CategoryWidgetState();
}

class _CategoryWidgetState extends State<CategoryWidget> {
  bool _isNavigating = false;
  final SocketService _socketService = SocketService();
  int _maxRetries = 3;
  int _retryDelay = 5; // seconds
  final int timeoutDuration = 10; // seconds
  bool _shouldContinueLoading = true;

  @override
  void initState() {
    super.initState();
    _socketService.initSocket();
    fetchSettings();
  }

  @override
  void dispose() {
    _socketService.dispose();
    super.dispose();
  }

  void _showLoadingIndicator(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          onPopInvoked: (didPop) {
            if (didPop) return;
            _shouldContinueLoading = false;
            Navigator.of(context).pop();
          },
          child: Center(
            child: SpinKitFadingCircle(
              color: borderColor,
              size: 50.0,
            ),
          ),
        );
      },
    );
  }

  void _dismissLoadingIndicator() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Channel> filteredChannels = widget.category.channels
        .where((channel) => channel.url.isNotEmpty)
        .toList();

    return filteredChannels.isNotEmpty
        ? Container(
            color: cardColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.category.text.toUpperCase(),
                  style: TextStyle(
                    color: hintColor,
                    fontSize: Headingtextsz,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.4,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: filteredChannels.length > 5
                        ? 6
                        : filteredChannels.length,
                    itemBuilder: (context, index) {
                      if (index == 5 && filteredChannels.length > 5) {
                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: ViewAllWidget(
                            onTap: () {
                              _dismissLoadingIndicator();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CategoryGridView(
                                    category: widget.category,
                                    filteredChannels: filteredChannels,
                                  ),
                                ),
                              );
                            },
                            categoryText: widget.category.text.toUpperCase(),
                          ),
                        );
                      }
                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: 0),
                        child: ChannelWidget(
                          channel: filteredChannels[index],
                          onTap: () async {
                            _showLoadingIndicator(context);
                            await _playVideo(context, filteredChannels, index);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          )
        : const SizedBox.shrink();
  }

  Future<void> _playVideo(
      BuildContext context, List<Channel> channels, int index) async {
    if (_isNavigating) return;
    _isNavigating = true;
    _shouldContinueLoading = true;

    try {
      await _updateChannelUrlIfNeeded(channels, index);
      if (_shouldContinueLoading) {
        _dismissLoadingIndicator();
        await _navigateToVideoScreen(context, channels, index);
      }
    } catch (e) {
      print("Error playing video: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Something Went Wrong')),
      );
    } finally {
      _isNavigating = false;
      if (mounted) {
        _dismissLoadingIndicator();
      }
    }
  }

  Future<void> _updateChannelUrlIfNeeded(
      List<Channel> channels, int index) async {
    if (channels[index].streamType == 'YoutubeLive') {
      for (int i = 0; i < _maxRetries; i++) {
        if (!_shouldContinueLoading) break;
        try {
          String updatedUrl =
              await _socketService.getUpdatedUrl(channels[index].url);
          channels[index].url = updatedUrl;
          channels[index].streamType = 'M3u8';
          break;
        } catch (e) {
          if (i == _maxRetries - 1) {
            await Future.delayed(Duration(seconds: 10)); // Retry after delay
            continue;
          }
          await Future.delayed(Duration(seconds: _retryDelay));
        }
      }
    }
  }

  Future<void> _navigateToVideoScreen(
      BuildContext context, List<Channel> channels, int index) async {
    if (_shouldContinueLoading) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PopScope(
            canPop: false,
            onPopInvoked: (didPop) {
              if (didPop) return;
              Navigator.of(context).pop();
            },
            child: VideoScreen(
              channels: channels,
              initialIndex: index,
              videoTitle: channels[index].name,
              videoUrl: channels[index].url,
              genres: channels[index].genres,
              channelList: [],
              bannerImageUrl: '',
              startAtPosition: Duration.zero,
            ),
          ),
        ),
      );

      // Handle any result returned from VideoScreen if needed
      if (result != null) {
        // Process the result
      }
    }
  }
}

class CategoryGridView extends StatefulWidget {
  final Category category;
  final List<Channel> filteredChannels;

  CategoryGridView({required this.category, required this.filteredChannels});

  @override
  _CategoryGridViewState createState() => _CategoryGridViewState();
}

class _CategoryGridViewState extends State<CategoryGridView> {
  final SocketService _socketService = SocketService();
  final int _maxRetries = 3;
  final int _retryDelay = 5; // seconds
  bool _shouldContinueLoading = true;
  bool _isLoading = false; // State to manage loading indicator

  Future<void> _updateChannelUrlIfNeeded(
      List<Channel> channels, int index) async {
    if (channels[index].streamType == 'YoutubeLive') {
      for (int i = 0; i < _maxRetries; i++) {
        if (!_shouldContinueLoading) break;
        try {
          String updatedUrl =
              await _socketService.getUpdatedUrl(channels[index].url);
          channels[index].url = updatedUrl;
          channels[index].streamType = 'M3u8';
          break;
        } catch (e) {
          if (i == _maxRetries - 1) {
            await Future.delayed(Duration(seconds: 10)); // Retry after delay
            continue;
          }
          // if (i == _maxRetries - 1) rethrow;
          await Future.delayed(Duration(seconds: _retryDelay));
        }
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (_isLoading) {
      setState(() {
        _isLoading = false; // Hide the loading indicator
        _shouldContinueLoading = false; // Stop ongoing loading
      });
      return false; // Prevent back navigation when loading
    }
    return true; // Allow navigation if not loading
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop, // Handle back button press
      child: Scaffold(
        backgroundColor: cardColor,
        body: Stack(
          children: [
            GridView.builder(
              padding: EdgeInsets.all(20),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
              ),
              itemCount: widget.filteredChannels.length,
              itemBuilder: (context, index) {
                return ChannelWidget(
                  channel: widget.filteredChannels[index],
                  onTap: () async {
                    setState(() {
                      _isLoading = true; // Show loading indicator
                    });
                    _shouldContinueLoading = true;

                    await _updateChannelUrlIfNeeded(
                        widget.filteredChannels, index);
                    if (_shouldContinueLoading) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VideoScreen(
                            channels: widget.filteredChannels,
                            initialIndex: index,
                            videoUrl: widget.filteredChannels[index].url,
                            videoTitle: widget.filteredChannels[index].name,
                            channelList: [],
                            genres: widget.filteredChannels[index].genres,
                            bannerImageUrl: '',
                            startAtPosition: Duration.zero,
                          ),
                        ),
                      ).then((_) {
                        setState(() {
                          _isLoading =
                              false; // Hide loading indicator after navigation
                        });
                      });
                    }
                  },
                );
              },
            ),
            if (_isLoading)
              Center(
                child: SpinKitFadingCircle(
                  color: borderColor,
                  size: 50.0,
                ), // Circular loading indicator
              ),
          ],
        ),
      ),
    );
  }
}

class ChannelWidget extends StatefulWidget {
  final Channel channel;
  final VoidCallback onTap;

  ChannelWidget({required this.channel, required this.onTap});

  @override
  _ChannelWidgetState createState() => _ChannelWidgetState();
}

class _ChannelWidgetState extends State<ChannelWidget> {
  bool isFocused = false;
  Color secondaryColor = Colors.grey; // Default color
  final PaletteColorService _paletteColorService = PaletteColorService();
  @override
  void initState() {
    super.initState();
    _updateSecondaryColor();
  }

  Future<void> _updateSecondaryColor() async {
    // if (widget.channel.status == '1') {
    Color color =
        await _paletteColorService.getSecondaryColor(widget.channel.banner);
    setState(() {
      secondaryColor = color;
    });
    // }
  }

  @override
  Widget build(BuildContext context) {
    bool showBanner = widget.channel.status == '1';

    return FocusableActionDetector(
      onFocusChange: (hasFocus) {
        setState(() {
          isFocused = hasFocus;
        });
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (ActivateIntent intent) {
            widget.onTap();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showBanner)
              Stack(
                children: [
                  AnimatedContainer(
                    width: screenwdt * 0.19,
                    height: isFocused ? screenhgt * 0.24 : screenhgt * 0.21,
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      border: isFocused
                          ? Border.all(
                              color: secondaryColor,
                              width: 4.0,
                            )
                          : Border.all(
                              color: Colors.transparent,
                              width: 4.0,
                            ),
                      borderRadius: BorderRadius.circular(0),
                      boxShadow: isFocused
                          ? [
                              BoxShadow(
                                color: secondaryColor
                                // .withOpacity(0.5)
                                ,
                                blurRadius: 25,
                                spreadRadius: 10,
                              )
                            ]
                          : [],
                    ),
                    child: CachedNetworkImage(
                      imageUrl: widget.channel.banner,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          Container(color: Colors.grey),
                      width: screenwdt * 0.19,
                      height: isFocused ? screenhgt * 0.24 : screenhgt * 0.21,
                    ),
                  ),
                ],
              ),
            SizedBox(height: 10),
            Container(
              width: screenwdt * 0.19,
              // height: isFocused ? screenhgt * 0.24 : screenhgt * 0.21,
              // height: screenhgt * 0.15,

              child: Column(
                children: [
                  Text(
                    (widget.channel.name).toUpperCase(),
                    style: TextStyle(
                      color: isFocused ? secondaryColor : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: nametextsz,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                  ),
                  // Text(
                  //   widget.channel.description,
                  //   style: TextStyle(
                  //     color: isFocused ? secondaryColor : Colors.grey,
                  //     fontWeight: FontWeight.bold,
                  //   ),
                  //   overflow: TextOverflow.ellipsis,
                  //   maxLines: 1,
                  //   textAlign: TextAlign.center,
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ViewAllWidget extends StatefulWidget {
  final VoidCallback onTap;
  final String categoryText;

  ViewAllWidget({required this.onTap, required this.categoryText});

  @override
  _ViewAllWidgetState createState() => _ViewAllWidgetState();
}

class _ViewAllWidgetState extends State<ViewAllWidget> {
  bool isFocused = false;
  Color focusColor = highlightColor;

  @override
  void initState() {
    super.initState();
    _updateFocusColor();
  }

  Future<void> _updateFocusColor() async {
    // Generate a random color
    Random random = Random();
    Color randomColor = Color.fromARGB(
      255, // Alpha value
      random.nextInt(256), // Red
      random.nextInt(256), // Green
      random.nextInt(256), // Blue
    );

    setState(() {
      focusColor = randomColor; // Use the random color
    });
  }

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onFocusChange: (hasFocus) {
        setState(() {
          isFocused = hasFocus;
        });
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (ActivateIntent intent) {
            widget.onTap();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              width: screenwdt * 0.19,
              height: isFocused ? screenhgt * 0.24 : screenhgt * 0.21,
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                border: isFocused
                    ? Border.all(
                        color: focusColor,
                        width: 4.0,
                      )
                    : Border.all(
                        color: Colors.transparent,
                        width: 4.0,
                      ),
                color: Colors.grey[800],
                boxShadow: isFocused
                    ? [
                        BoxShadow(
                          color: focusColor,
                          blurRadius: 25,
                          spreadRadius: 10,
                        )
                      ]
                    : [],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'View All',
                      style: TextStyle(
                        color: isFocused ? focusColor : hintColor,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      widget.categoryText,
                      style: TextStyle(
                        color: isFocused ? focusColor : hintColor,
                        fontWeight: FontWeight.bold,
                        fontSize: nametextsz,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'Channels',
                      style: TextStyle(
                        color: isFocused ? focusColor : hintColor,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10),
            Container(
              width: screenwdt * 0.17,
              // height: screenhgt * 0.15,
              child: Column(
                children: [
                  Text(
                    (widget.categoryText),
                    style: TextStyle(
                      color: isFocused ? focusColor : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                  ),
                  // Text(
                  //   '''See all ${(widget.categoryText).toLowerCase()} channels''',
                  //   style: TextStyle(
                  //     color: isFocused ? focusColor : Colors.grey,
                  //     fontWeight: FontWeight.bold,
                  //   ),
                  //   overflow: TextOverflow.ellipsis,
                  //   maxLines: 3,
                  //   textAlign: TextAlign.center,
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
