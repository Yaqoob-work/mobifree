


// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:http/http.dart' as http;

// import '../video_widget/video_screen.dart';

// class Network extends StatefulWidget {
//   @override
//   _NetworkState createState() => _NetworkState();
// }

// class _NetworkState extends State<Network> {
//   List<dynamic> entertainmentList = [];
//   bool isLoading = true;
//   String errorMessage = '';

//   @override
//   void initState() {
//     super.initState();
//     fetchEntertainment();
//   }

//   Future<void> fetchEntertainment() async {
//     try {
//       final response = await http.get(
//         Uri.parse('https://mobifreetv.com/android/getAllWebSeries'),
//         // Uri.parse('https://mobifreetv.com/android/getAllContentsOfNetwork/0'),
//         headers: {
//           'x-api-key': 'vLQTuPZUxktl5mVW',
//         },
//       );

//       if (response.statusCode == 200) {
//         final List<dynamic> responseData = json.decode(response.body);

//         setState(() {
//           entertainmentList = responseData
//               .where((channel) =>
//                   channel['genres'] != null &&
//                   channel['genres'].contains('web Series'))
//               .map((channel) {
//             channel['isFocused'] = false; // Add isFocused field
//             return channel;
//           }).toList();
//           isLoading = false;
//         });
//       } else {
//         throw Exception('Failed to load data');
//       }
//     } catch (e) {
//       print('Error fetching data: $e');
//       setState(() {
//         errorMessage = e.toString();
//         isLoading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.cardColor,
//       body: isLoading
//           ? Center(child: CircularProgressIndicator())
//           : errorMessage.isNotEmpty
//               ? Center(child: Text('Error: $errorMessage'))
//               : entertainmentList.isEmpty
//                   ? Center(child: Text('No entertainment channels found'))
//                   : GridView.builder(
//                       gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                         crossAxisCount: 5,
//                         childAspectRatio: 0.75,
//                       ),
//                       itemCount: entertainmentList.length,
//                       itemBuilder: (context, index) {
//                         return GestureDetector(
//                           onTap: () =>
//                               _navigateToVideoScreen(context, entertainmentList[index]),
//                           child: _buildGridViewItem(index),
//                         );
//                       },
//                     ),
//     );
//   }

//   Widget _buildGridViewItem(int index) {
//     return Focus(
//       onKey: (FocusNode node, RawKeyEvent event) {
//         if (event is RawKeyDownEvent &&
//             (event.logicalKey == LogicalKeyboardKey.select ||
//                 event.logicalKey == LogicalKeyboardKey.enter)) {
//           _navigateToVideoScreen(context, entertainmentList[index]);
//           return KeyEventResult.handled;
//         }
//         return KeyEventResult.ignored;
//       },
//       onFocusChange: (hasFocus) {
//         setState(() {
//           entertainmentList[index]['isFocused'] = hasFocus;
//         });
//       },
//       child: Container(
//         margin: EdgeInsets.all(8.0),
//         child: ClipRRect(
//           borderRadius: BorderRadius.circular(15.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Container(
//                 decoration: BoxDecoration(
//                   border: Border.all(
//                     color: entertainmentList[index]['isFocused']
//                         ? AppColors.primaryColor
//                         : Colors.transparent,
//                     width: 5.0,
//                   ),
//                   borderRadius: BorderRadius.circular(15.0),
//                 ),
//                 child: ClipRRect(
//                   borderRadius: BorderRadius.circular(12.0),
//                   child: Image.network(
//                     entertainmentList[index]['banner'] ?? 'https://example.com/default_banner.png',
//                     width: entertainmentList[index]['isFocused'] ? 110 : 90,
//                     height: entertainmentList[index]['isFocused'] ? 90 : 70,
//                     fit: BoxFit.cover,
//                   ),
//                 ),
//               ),
//               SizedBox(height: 8.0),
//               LayoutBuilder(
//                 builder: (context, constraints) {
//                   return FittedBox(
//                     fit: BoxFit.scaleDown,
//                     child: Container(
//                       constraints: BoxConstraints(maxWidth: constraints.maxWidth),
//                       child: Text(
//                         entertainmentList[index]['name'] ?? 'Unknown',
//                         style: TextStyle(
//                           color:entertainmentList[index]['isFocused'] ? AppColors.highlightColor: AppColors.hintColor,
//                         ),
//                         textAlign: TextAlign.center,
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   void _navigateToVideoScreen(BuildContext context, dynamic entertainmentItem) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => VideoScreen(
//           videoUrl: entertainmentItem['url'] ?? '',
//           videoTitle: entertainmentItem['name'] ?? 'Unknown',
//           channelList: entertainmentList,
//           onFabFocusChanged: _handleFabFocusChanged, genres: '',url: '',playUrl: '',playVideo: (String id) {  },
//         ),
//       ),
//     );
//   }

//   void _handleFabFocusChanged(bool hasFocus) {
//     setState(() {
//       // Update FAB focus state
//       // This method can be called from VideoScreen to update FAB focus state
//     });
//   }
// }



import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobi_tv_entertainment/main.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MaterialApp(
    home: Network(),
  ));
}

class Network extends StatefulWidget {
  @override
  _NetworkState createState() => _NetworkState();
}

class _NetworkState extends State<Network> {
  List<dynamic> movies = [];
  bool isLoading = true;
  int focusedIndex = -1;
  FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    fetchMovies();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> fetchMovies() async {
    try {
      final response = await http.get(
        Uri.parse('https://mobifreetv.com/android/getNetworks'),
        headers: {
          'x-api-key': 'vLQTuPZUxktl5mVW',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is List) {
          setState(() {
            movies = data;
            isLoading = false;
          });
        } else {
          throw Exception('Invalid data structure');
        }
      } else {
        throw Exception('Failed to load movies');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching movies: $e');
    }
  }

  Future<String> fetchVideoUrl(String id) async {
    try {
      final response = await http.get(
        Uri.parse('https://mobifreetv.com/android/getAllContentsOfNetwork/1'),
        headers: {
          'x-api-key': 'vLQTuPZUxktl5mVW',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is List && data.isNotEmpty && data[0].containsKey('url')) {
          return data[0]['url'];
        } else {
          throw Exception('No valid URL found');
        }
      } else {
        throw Exception('Failed to load video URL');
      }
    } catch (e) {
      print('Error fetching video URL: $e');
      return '';
    }
  }

  void playVideo(String id) async {
    String videoUrl = await fetchVideoUrl(id);
    if (videoUrl.isNotEmpty) {
      List<dynamic> channelList = [
        {
          'banner': movies[focusedIndex]['banner'],
          'name': movies[focusedIndex]['name'],
        }
      ];

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoScreen(
            videoUrl: videoUrl,
            videoTitle: 'Video Title', // Set appropriate title
            channelList: channelList, // Pass your channel list data here
          ),
        ),
      );
    } else {
      print('No video URL found for ID: $id');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cardColor,
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : movies.isEmpty
              ? Center(child: Text('No movies found'))
              : RawKeyboardListener(
                  focusNode: _focusNode,
                  onKey: (RawKeyEvent event) {
                    if (event is RawKeyDownEvent) {
                      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                        setState(() {
                          focusedIndex = (focusedIndex - 1).clamp(0, movies.length - 1);
                        });
                      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                        setState(() {
                          focusedIndex = (focusedIndex + 1).clamp(0, movies.length - 1);
                        });
                      } else if (event.logicalKey == LogicalKeyboardKey.select) {
                        if (focusedIndex != -1 && focusedIndex < movies.length) {
                          playVideo(movies[focusedIndex]['id'].toString());
                        }
                      }
                    }
                  },
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      childAspectRatio: 0.7,
                    ),
                    itemCount: movies.length,
                    itemBuilder: (context, index) {
                      final movie = movies[index];
                      bool isFocused = focusedIndex == index;

                      return GestureDetector(
                        onTap: () => playVideo(movie['id'].toString()),
                        onTapDown: (_) {
                          setState(() {
                            focusedIndex = index;
                          });
                        },
                        child: Focus(
                          onFocusChange: (hasFocus) {
                            if (hasFocus) {
                              setState(() {
                                focusedIndex = index;
                              });
                            }
                          },
                          
                            child: Padding(
                              padding: EdgeInsets.all(10) ,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Container(
                                    height: isFocused?110:100,
                                     decoration: BoxDecoration(
                                border: Border.all(
                                  color: isFocused ? AppColors.primaryColor : Colors.transparent,
                                  width: 5.0,
                                ),
                                borderRadius: BorderRadius.circular(17)
                              ),
                                    child: ClipRRect(

                                      borderRadius: BorderRadius.circular(12.0),
                                      child: Image.network(
                                        movie['banner'],
                                        fit: BoxFit.cover,
                                        
                                        errorBuilder: (context, error, stackTrace) {
                                          return Center(child: Text('Image not available'));
                                        },
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 8.0),
                                  Text(
                                    movie['name'],
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isFocused ? AppColors.highlightColor : AppColors.hintColor,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class VideoScreen extends StatefulWidget {
  final String videoUrl;
  final String videoTitle;
  final List<dynamic> channelList;

  VideoScreen({required this.videoUrl, required this.videoTitle, required this.channelList});

  @override
  _VideoScreenState createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized
        setState(() {
          _controller.play(); // Start playing the video automatically
        });
      });
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: Center(
        child: _controller.value.isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : CircularProgressIndicator(),
      ),
      
    );
  }
}

