import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MaterialApp(
    home: VOD(),
  ));
}

class VOD extends StatefulWidget {
  @override
  _VODState createState() => _VODState();
}

class _VODState extends State<VOD> {
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
        Uri.parse('https://mobifreetv.com/android/getAllMovies'),
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
        Uri.parse('https://mobifreetv.com/android/getMoviePlayLinks/$id/0'),
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
      backgroundColor: Colors.black,
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
                                  color: isFocused ? const Color.fromARGB(255, 136, 51, 122) : Colors.transparent,
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
                                      color: isFocused ? Color.fromARGB(255, 106, 235, 20) : Colors.white,
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
