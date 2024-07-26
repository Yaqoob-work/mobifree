import 'dart:async';
import 'package:container_gradient_border/container_gradient_border.dart';
import 'package:flutter/foundation.dart';
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

// Model class for Content
class Content {
  final String id;
  final String title;
  final String description;
  final String poster;
  final String banner;
  final String genres;

  Content({
    required this.id,
    required this.title,
    required this.description,
    required this.poster,
    required this.banner,
    required this.genres,
  });

  factory Content.fromJson(Map<String, dynamic> json) {
    return Content(
      id: json['id'] ?? 'N/A',
      title: json['name'] ?? 'No title',
      description: json['description'] ?? 'No description',
      poster: json['poster'] ?? '',
      banner: json['banner'] ?? '',
      genres: json['genres'] ?? 'Unknown',
    );
  }
}

// Network Page
class NetworkCategory extends StatefulWidget {
  @override
  _NetworkCategoryState createState() => _NetworkCategoryState();
}

class _NetworkCategoryState extends State<NetworkCategory> {
  Map<String, List<Content>> categorizedContents = {};
  bool isLoading = false;
  bool hasMoreIds = true;
  final Map<String, FocusNode> focusNodes = {};

  @override
  void initState() {
    super.initState();
    fetchAllIds();
  }

  Future<void> fetchAllIds() async {
    setState(() {
      isLoading = true;
    });

    int id = 0;

    while (hasMoreIds) {
      try {
        final headers = {
          'x-api-key': 'vLQTuPZUxktl5mVW',
        };

        final response = await http.get(
          Uri.parse(
              'https://mobifreetv.com/android/getAllContentsOfNetwork/$id'),
          headers: headers,
        );

        print('Response body: ${response.body}');

        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);

          if (data.isEmpty) {
            setState(() {
              hasMoreIds = false;
            });
          } else {
            final newContents =
                data.map((item) => Content.fromJson(item)).toList();

            for (var content in newContents) {
              if (content.genres.isNotEmpty) {
                if (categorizedContents.containsKey(content.genres)) {
                  categorizedContents[content.genres]!.add(content);
                } else {
                  categorizedContents[content.genres] = [content];
                  focusNodes[content.genres] =
                      FocusNode(); // Initialize focus nodes
                }
              }
            }

            setState(() {
              id++;
            });
          }
        } else {
          print('Error: ${response.statusCode}');
          setState(() {
            hasMoreIds = false;
          });
        }
      } catch (e) {
        print('Error fetching data: $e');
        setState(() {
          hasMoreIds = false;
        });
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  void _onCategoryTap(String genre) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryContentPage(
          genre: genre,
          contents: categorizedContents[genre] ?? [],
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
          : GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
              ),
              itemCount: categorizedContents.keys.length,
              itemBuilder: (context, index) {
                final genre = categorizedContents.keys.elementAt(index);
                final focusNode = focusNodes[genre]!;

                return Focus(
                  focusNode: focusNode,
                  onFocusChange: (hasFocus) {
                    setState(() {}); // Update the UI to reflect the focus state
                  },
                  onKeyEvent: (FocusNode node, KeyEvent event) {
                    if (event is KeyDownEvent &&
                        (event.logicalKey == LogicalKeyboardKey.select ||
                            event.logicalKey == LogicalKeyboardKey.enter)) {
                      _onCategoryTap(genre);
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  child: GestureDetector(
                    onTap: () => _onCategoryTap(genre),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        
                        children: [
                          AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: focusNode.hasFocus ? 200 : 120,
                height: focusNode.hasFocus ? 150 : 110,
                            // decoration: BoxDecoration(
                            //   border: Border.all(
                            //     color: focusNode.hasFocus
                            //         ? AppColors.primaryColor
                            //         : Colors.transparent,
                            //     width: 5.0,
                            //   ),
                            //   borderRadius: BorderRadius.circular(17.0),
                            // ),
                             child: ContainerGradientBorder(
                  width: focusNode.hasFocus ? 190 : 110,
                  height: focusNode.hasFocus ? 140 : 110,
                  start: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  borderWidth: 7,
                  colorList:  focusNode.hasFocus ? [
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
                  :
                  [
                    AppColors.primaryColor,
                    AppColors.highlightColor
                  ],
                  borderRadius: 10,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12.0),
                              child: Image.network(
                                categorizedContents[genre]!.isNotEmpty
                                    ? categorizedContents[genre]![0].banner
                                    : '',
                                fit: BoxFit.cover,
                                width: focusNode.hasFocus ? 180 : 100,
                                height: focusNode.hasFocus ? 130 : 100,
                              ),
                            ),
                          ),
                          ),
                          Text(
                            genre,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              color: focusNode.hasFocus
                                  ? AppColors.highlightColor
                                  : AppColors.hintColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          // ),
                          // ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// CategoryContentPage
class CategoryContentPage extends StatefulWidget {
  final String genre;
  final List<Content> contents;

  CategoryContentPage({required this.genre, required this.contents});

  @override
  _CategoryContentPageState createState() => _CategoryContentPageState();
}

class _CategoryContentPageState extends State<CategoryContentPage> {
  final Map<String, FocusNode> focusNodes = {};

  @override
  void initState() {
    super.initState();
    // Initialize focus nodes for each content item
    for (var content in widget.contents) {
      focusNodes[content.id] = FocusNode();
    }
  }

  @override
  void dispose() {
    // Dispose all focus nodes to avoid memory leaks
    for (var node in focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  void _onBannerTap(BuildContext context, String id) async {
    final playUrl = await _fetchPlayUrl(id);

    if (playUrl != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlayVideoPage(url: playUrl, videoUrl: '', videoTitle: '', channelList: [],),
        ),
      );
    } else {
      print('No URL found for this content');
    }
  }

  Future<String?> _fetchPlayUrl(String id) async {
    try {
      final headers = {
        'x-api-key': 'vLQTuPZUxktl5mVW',
      };

      final response = await http.get(
        Uri.parse('https://mobifreetv.com/android/getMoviePlayLinks/$id/0'),
        headers: headers,
      );

      print('Play URL response: ${response.body}');

      if (response.statusCode == 200) {
        if (response.body.contains('No Data Avaliable')) {
          print('No Data Available for this content');
          return null;
        }

        try {
          final List<dynamic> data = jsonDecode(response.body);

          if (data.isNotEmpty && data[0] is Map<String, dynamic>) {
            final url = data[0]['url'] as String?;
            return url;
          } else {
            print('Invalid data format');
            return null;
          }
        } catch (e) {
          print('Error parsing JSON response: $e');
          return null;
        }
      } else {
        print('Error fetching play URL: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching play URL: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:AppColors.cardColor,
      body: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
        ),
        itemCount: widget.contents.length,
        itemBuilder: (context, index) {
          final content = widget.contents[index];
          final focusNode = focusNodes[content.id]!;

          return Focus(
            focusNode: focusNode,
            onFocusChange: (hasFocus) {
              setState(() {}); // Update the UI to reflect the focus state
            },
            onKeyEvent: (FocusNode node, Diagnosticable event) {
              if (event is KeyDownEvent &&
                  (event.logicalKey == LogicalKeyboardKey.select ||
                      event.logicalKey == LogicalKeyboardKey.enter)) {
                _onBannerTap(context, content.id);
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: GestureDetector(
              onTap: () => _onBannerTap(context, content.id),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: focusNode.hasFocus ? 200 : 120,
                height: focusNode.hasFocus ? 150 : 110,
                      // decoration: BoxDecoration(
                      //   border: Border.all(
                      //     color: focusNode.hasFocus
                      //         ? AppColors.primaryColor
                      //         : Colors.transparent,
                      //     width: 5.0,
                      //   ),
                      //   borderRadius: BorderRadius.circular(17.0),
                      // ),
                                  child: ContainerGradientBorder(
                  width: focusNode.hasFocus ? 190 : 110,
                  height: focusNode.hasFocus ? 140 : 110,
                  start: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  borderWidth: 7,
                  colorList:  focusNode.hasFocus ? [
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
                  :
                  [
                    AppColors.primaryColor,
                    AppColors.highlightColor
                  ],
                  borderRadius: 10,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.0),
                        child: Image.network(
                          content.banner,
                          fit: BoxFit.cover,
                          width: focusNode.hasFocus ? 180 : 100,
                          height: focusNode.hasFocus ? 130 : 100,
                        ),
                      ),
                    ),
                    ),
                    Text(
                      '${content.id} - ${content.title}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        color: focusNode.hasFocus
                            ? AppColors.highlightColor
                            : AppColors.hintColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // ),
                    // ),
                  ],
                ),
              ),
            ),
            // ),
          );
        },
      ),
    );
  }
}






class PlayVideoPage extends StatefulWidget {
  final String url;

  PlayVideoPage({required this.url, required String videoUrl, required String videoTitle, required List channelList});

  @override
  _PlayVideoPageState createState() => _PlayVideoPageState();
}

class _PlayVideoPageState extends State<PlayVideoPage> {
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
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        setState(() {
          _totalDuration = _controller.value.duration;
        });
        _controller.play();
        _startPositionUpdater();
      });

    _startHideControlsTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
                        aspectRatio: _controller.value.aspectRatio,
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
                                    color:AppColors.highlightColor,
                                    
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
                                  style: TextStyle(color:AppColors.highlightColor,fontSize: 20,),
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
                                    backgroundColor: AppColors.highlightColor,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Center(
                                child: Text(
                                  _formatDuration(_totalDuration),
                                  style: TextStyle(color:AppColors.highlightColor,fontSize: 20,),
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
