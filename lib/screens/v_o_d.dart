import 'dart:async';
import 'package:container_gradient_border/container_gradient_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mobi_tv_entertainment/main.dart';
import 'dart:convert';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../video_widget/youtube_video_player.dart';

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
            focusNodes =
                List<FocusNode>.generate(data.length, (index) => FocusNode());
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
    }
  }

  Future<Map<String, dynamic>> fetchVideoDetails(String id) async {
    try {
      final response = await http.get(
        Uri.parse('https://mobifreetv.com/android/getMoviePlayLinks/$id/0'),
        headers: {
          'x-api-key': 'vLQTuPZUxktl5mVW',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is List && data.isNotEmpty) {
          return data[0];
        } else {
          throw Exception('No valid video details found');
        }
      } else {
        throw Exception('Failed to load video details');
      }
    } catch (e) {
      return {};
    }
  }

  void playVideo(String id) async {
    final videoDetails = await fetchVideoDetails(id);
    if (videoDetails.isNotEmpty) {
      String videoUrl = videoDetails['url'] ?? '';
      String videoType = videoDetails['type'] ?? 'video';

      List<dynamic> channelList = [
        {
          'banner': movies
              .firstWhere((movie) => movie['id'].toString() == id)['banner'] ?? '',
          'name': movies
              .firstWhere((movie) => movie['id'].toString() == id)['name'] ?? '',
        }
      ];

      if (videoType.toLowerCase() == 'youtube') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => YoutubeVideoPlayer(
              videoUrl: videoUrl,
              videoTitle: 'Video Title',
              channelList: channelList, url: '',
            ),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoScreen(
              videoUrl: videoUrl,
              videoTitle: 'Video Title',
              channelList: channelList,
              videoBanner: '',
              onFabFocusChanged: (bool focused) {},
              genres: '',
            ),
          ),
        );
      }
    }
  }

  Widget _buildMovieWidget(BuildContext context, int index) {
    final movie = movies[index];

    return Focus(
      focusNode: focusNodes[index],
      onFocusChange: (hasFocus) {
        setState(() {}); // Update the UI to reflect the focus state
      },
      onKeyEvent: (FocusNode node, KeyEvent event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter)) {
          playVideo(movie['id'].toString());
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: () => playVideo(movie['id'].toString()),
        child: Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: focusNodes[index].hasFocus ? 220 : 120,
                  height: focusNodes[index].hasFocus ? 170 : 120,
                  margin: EdgeInsets.all(5),
                  child: ContainerGradientBorder(
                    width: focusNodes[index].hasFocus ? 200 : 110,
                    height: focusNodes[index].hasFocus ? 150 : 110,
                    start: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    borderWidth: 7,
                    colorList: focusNodes[index].hasFocus
                        ? [
                            AppColors.primaryColor,
                            AppColors.highlightColor,
                            AppColors.primaryColor,
                            AppColors.highlightColor,
                            AppColors.primaryColor,
                            AppColors.highlightColor,
                            AppColors.primaryColor,
                            AppColors.highlightColor,
                            AppColors.primaryColor,
                            AppColors.highlightColor,
                            AppColors.primaryColor,
                            AppColors.highlightColor,
                            AppColors.primaryColor,
                            AppColors.highlightColor,
                            AppColors.primaryColor,
                            AppColors.highlightColor,
                            AppColors.primaryColor,
                            AppColors.highlightColor,
                            AppColors.primaryColor,
                            AppColors.highlightColor,
                            AppColors.primaryColor,
                            AppColors.highlightColor,
                            AppColors.primaryColor,
                            AppColors.highlightColor,
                            AppColors.primaryColor,
                            AppColors.highlightColor,
                            AppColors.primaryColor,
                            AppColors.highlightColor,
                            AppColors.primaryColor,
                            AppColors.highlightColor,
                          ]
                        : [AppColors.primaryColor, AppColors.highlightColor],
                    borderRadius: 10,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.0),
                      child: Image.network(
                        movie['banner'] ?? '',
                        fit: BoxFit.cover,
                        width: focusNodes[index].hasFocus ? 180 : 100,
                        height: focusNodes[index].hasFocus ? 130 : 100,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(child: Text('Image not available'));
                        },
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                width: focusNodes[index].hasFocus ? 180 : 100,
                child: Text(
                  movie['name'] ?? '',
                  style: TextStyle(
                    color: focusNodes[index].hasFocus
                        ? AppColors.highlightColor
                        : AppColors.hintColor,
                    fontSize: focusNodes[index].hasFocus ? 20 : 20,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
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
              ? Center(
                  child: Text('No movies found',
                      style: TextStyle(color: AppColors.hintColor)))
              : GridView.builder(
                  padding: EdgeInsets.all(10),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                  ),
                  itemCount: movies.length,
                  itemBuilder: (context, index) =>
                      _buildMovieWidget(context, index),
                ),
    );
  }
}

class VideoScreen extends StatefulWidget {
  final String videoUrl;
  final String videoTitle;
  final List<dynamic> channelList;

  VideoScreen({
    required this.videoUrl,
    required this.videoTitle,
    required this.channelList,
    required String videoBanner,
    required Null Function(bool focused) onFabFocusChanged,
    required String genres,
  });

  @override
  _VideoScreenState createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  late VideoPlayerController _controller;
  bool _controlsVisible = true;
  late Timer _hideControlsTimer;
  Duration _totalDuration = Duration.zero;
  Duration _currentPosition = Duration.zero;

  final FocusNode screenFocusNode = FocusNode();
  final FocusNode playPauseFocusNode = FocusNode();
  final FocusNode rewindFocusNode = FocusNode();
  final FocusNode fastForwardFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {
          _totalDuration = _controller.value.duration;
        });
        _controller.play();
      });

    _controller.addListener(() {
      setState(() {
        _currentPosition = _controller.value.position;
      });
    });

    _hideControlsTimer = Timer(Duration(seconds: 3), () {
      setState(() {
        _controlsVisible = false;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    screenFocusNode.dispose();
    playPauseFocusNode.dispose();
    rewindFocusNode.dispose();
    fastForwardFocusNode.dispose();
    _hideControlsTimer.cancel();
    super.dispose();
  }

  void _toggleControlsVisibility() {
    setState(() {
      _controlsVisible = !_controlsVisible;
    });

    if (_controlsVisible) {
      _hideControlsTimer.cancel();
      _hideControlsTimer = Timer(Duration(seconds: 3), () {
        setState(() {
          _controlsVisible = false;
        });
      });
    }
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  void _rewind() {
    final newPosition = _currentPosition - Duration(seconds: 10);
    _controller.seekTo(newPosition < Duration.zero ? Duration.zero : newPosition);
  }

  void _fastForward() {
    final newPosition = _currentPosition + Duration(seconds: 10);
    _controller.seekTo(
      newPosition > _totalDuration ? _totalDuration : newPosition,
    );
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowLeft:
          _rewind();
          break;
        case LogicalKeyboardKey.arrowRight:
          _fastForward();
          break;
        case LogicalKeyboardKey.select:
        case LogicalKeyboardKey.enter:
          _togglePlayPause();
          break;
        default:
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RawKeyboardListener(
        focusNode: screenFocusNode,
        onKey: _handleKeyEvent,
        child: GestureDetector(
          onTap: _toggleControlsVisibility,
          child: Stack(
            children: [
              Center(
                child: _controller.value.isInitialized
                    ? AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: VideoPlayer(_controller),
                      )
                    : CircularProgressIndicator(),
              ),
              if (_controlsVisible)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    color: Colors.black54,
                    padding: EdgeInsets.all(10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              focusNode: rewindFocusNode,
                              icon: Icon(Icons.replay_10),
                              color: Colors.white,
                              onPressed: _rewind,
                            ),
                            IconButton(
                              focusNode: playPauseFocusNode,
                              icon: Icon(
                                _controller.value.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                              ),
                              color: Colors.white,
                              onPressed: _togglePlayPause,
                            ),
                            IconButton(
                              focusNode: fastForwardFocusNode,
                              icon: Icon(Icons.forward_10),
                              color: Colors.white,
                              onPressed: _fastForward,
                            ),
                          ],
                        ),
                        VideoProgressIndicator(
                          _controller,
                          allowScrubbing: true,
                          colors: VideoProgressColors(
                            playedColor: Colors.red,
                            bufferedColor: Colors.white,
                            backgroundColor: Colors.grey,
                          ),
                        ),
                        Text(
                          '${_currentPosition.toString().split('.').first} / ${_totalDuration.toString().split('.').first}',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

