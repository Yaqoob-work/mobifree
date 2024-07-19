import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mobi_tv_entertainment/main.dart';
import 'dart:convert';

import 'package:video_player/video_player.dart';

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
  List<FocusNode> focusNodes = [];

  @override
  void initState() {
    super.initState();
    fetchMovies();
  }

  @override
  void dispose() {
    for (FocusNode focusNode in focusNodes) {
      focusNode.dispose();
    }
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
            focusNodes = List<FocusNode>.generate(data.length, (index) => FocusNode());
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
          'banner': movies.firstWhere((movie) => movie['id'].toString() == id)['banner'],
          'name': movies.firstWhere((movie) => movie['id'].toString() == id)['name'],
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

  Widget _buildMovieWidget(BuildContext context, int index) {
    final movie = movies[index];

    return Focus(
      focusNode: focusNodes[index],
      onFocusChange: (hasFocus) {
        setState(() {}); // Update the UI to reflect the focus state
      },
      onKey: (FocusNode node, RawKeyEvent event) {
        if (event is RawKeyDownEvent && (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter)) {
          playVideo(movie['id'].toString());
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: TweenAnimationBuilder<double>(
        duration: Duration(milliseconds: 500),
        tween: Tween<double>(begin: 1.0, end: focusNodes[index].hasFocus ? 1 : 0.8),
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: GestureDetector(
              onTap: () => playVideo(movie['id'].toString()),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    
                    margin: EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: focusNodes[index].hasFocus ?AppColors.primaryColor : Colors.transparent,
                        width: 5.0,
                      ),
                      borderRadius: BorderRadius.circular(18),
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
                  SizedBox(height: 5),
                  Text(
                    movie['name'],
                    style: TextStyle(
                      color: focusNodes[index].hasFocus ? AppColors.highlightColor:AppColors.hintColor,
                      fontSize: focusNodes[index].hasFocus ? 16 : 14,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                  overflow: TextOverflow.ellipsis,

                    
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : movies.isEmpty
              ? Center(child: Text('No movies found', style: TextStyle(color:AppColors.hintColor)))
              : GridView.builder(
                  padding: EdgeInsets.all(10),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: movies.length,
                  itemBuilder: (context, index) => _buildMovieWidget(context, index),
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
        setState(() {
          _controller.play();
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
      appBar: AppBar(
        title: Text(widget.videoTitle),
      ),
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
