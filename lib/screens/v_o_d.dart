import 'dart:async';

import 'package:container_gradient_border/container_gradient_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mobi_tv_entertainment/main.dart';
import 'dart:convert';

import 'package:video_player/video_player.dart';

import 'dart:io';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
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
          return data[0]['url']??'';
        } else {
          throw Exception('No valid URL found');
        }
      } else {
        throw Exception('Failed to load video URL');
      }
    } catch (e) {
      return '';
    }
  }

  void playVideo(String id) async {
    String videoUrl = await fetchVideoUrl(id);
    if (videoUrl.isNotEmpty) {
      List<dynamic> channelList = [
        {
          'banner': movies
              .firstWhere((movie) => movie['id'].toString() == id)['banner']??'',
          'name': movies
              .firstWhere((movie) => movie['id'].toString() == id)['name']??'',
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
      child: 
        
             GestureDetector(
              onTap: () => playVideo(movie['id'].toString()),
              child: Container(
                child: Column(
                  // mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                      
                        width: focusNodes[index].hasFocus ? 200 : 120,
                        height: focusNodes[index].hasFocus ? 150 : 120,
                        margin: EdgeInsets.all(5),
                        // decoration: BoxDecoration(
                        //   border: Border.all(
                        //     color: focusNodes[index].hasFocus ?AppColors.primaryColor : Colors.transparent,
                        //     width: 5.0,
                        //   ),
                        //   borderRadius: BorderRadius.circular(18),
                        // ),
                        child: ContainerGradientBorder(
                          width: focusNodes[index].hasFocus ? 190 : 110,
                          height: focusNodes[index].hasFocus ? 140 : 110,
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
                                ]
                              : [AppColors.primaryColor, AppColors.highlightColor],
                          borderRadius: 10,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12.0),
                            child: Image.network(
                              movie['banner']??'',
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
                    // SizedBox(height: 5),
                    Container(
                      width: focusNodes[index].hasFocus ? 180 : 100,
                      child: Text(
                        movie['name']??'',
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
                    // crossAxisSpacing: 10,
                    // mainAxisSpacing: 10,
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

  VideoScreen(
      {required this.videoUrl,
      required this.videoTitle,
      required this.channelList});

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
  final FocusNode forwardFocusNode = FocusNode();
  final FocusNode backFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() {
          _totalDuration = _controller.value.duration;
        });
        _controller.play();
        _startPositionUpdater();
      });

    _startHideControlsTimer();
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(screenFocusNode);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _hideControlsTimer.cancel();
    screenFocusNode.dispose();
    playPauseFocusNode.dispose();
    rewindFocusNode.dispose();
    forwardFocusNode.dispose();
    backFocusNode.dispose();
    super.dispose();
  }

  void _startHideControlsTimer() {
    _hideControlsTimer = Timer(Duration(seconds: 10), () {
      setState(() {
        _controlsVisible = false;
      });
    });
  }

  void _resetHideControlsTimer() {
    _hideControlsTimer.cancel();
    setState(() {
      _controlsVisible = true;
    });
    _startHideControlsTimer();
  }

  void _startPositionUpdater() {
    Timer.periodic(Duration(seconds: 1), (_) {
      setState(() {
        _currentPosition = _controller.value.position;
      });
    });
  }

  void _onRewind() {
    _controller.seekTo(_controller.value.position - Duration(minutes: 1));
    _resetHideControlsTimer();
  }

  void _onForward() {
    _controller.seekTo(_controller.value.position + Duration(minutes: 1));
    _resetHideControlsTimer();
  }

  void _togglePlayPause() {
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
    _resetHideControlsTimer();
  }

  void _navigateBack() {
    Navigator.pop(context);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        focusNode: screenFocusNode,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.mediaPlayPause) {
              _togglePlayPause();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              _onRewind();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              _onForward();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
                event.logicalKey == LogicalKeyboardKey.arrowDown) {
              _resetHideControlsTimer();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.escape) {
              _navigateBack(); // Use 'escape' key for back navigation
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: GestureDetector(
          onTap: _resetHideControlsTimer,
          child: Stack(
            children: [
              Center(
                child: _controller.value.isInitialized
                    ? AspectRatio(
                        aspectRatio: 16 / 9,
                        child: VideoPlayer(_controller),
                      )
                    : CircularProgressIndicator(),
              ),
              if (_controlsVisible)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 1,
                              child: Center(
                                child: IconButton(
                                  icon: Icon(
                                    _controller.value.isPlaying
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                    color: AppColors.highlightColor,
                                  ),
                                  onPressed: _togglePlayPause,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Center(
                                child: Text(
                                  _formatDuration(_currentPosition),
                                  style: TextStyle(
                                      color: AppColors.highlightColor,
                                      fontSize: 20),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 6,
                              child: Center(
                                child: VideoProgressIndicator(
                                  _controller,
                                  allowScrubbing: true,
                                  colors: VideoProgressColors(
                                      playedColor: AppColors.primaryColor,
                                      bufferedColor: Colors.grey,
                                      backgroundColor:
                                          AppColors.highlightColor),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Center(
                                child: Text(
                                  _formatDuration(_totalDuration),
                                  style: TextStyle(
                                      color: AppColors.highlightColor,
                                      fontSize: 20),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
