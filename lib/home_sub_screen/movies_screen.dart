import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

class MoviesScreen extends StatefulWidget {
  @override
  _MoviesScreenState createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen> {
  List<dynamic> entertainmentList = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchEntertainment();
  }

  Future<void> fetchEntertainment() async {
    try {
      final response = await http.get(
        Uri.parse('https://mobifreetv.com/android/getAllContentsOfNetwork/0'),
        headers: {
          'x-api-key': 'vLQTuPZUxktl5mVW',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);

        setState(() {
          entertainmentList = responseData
              .where((channel) =>
                  channel['genres'] != null &&
                  channel['genres'].contains('movies'))
              .map((channel) {
                channel['isFocused'] = false; // Add isFocused field
                return channel;
              })
              .toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text('Error: $errorMessage'))
              : entertainmentList.isEmpty
                  ? const Center(child: Text('No entertainment channels found'))
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: entertainmentList.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () => _navigateToVideoScreen(context, entertainmentList[index]),
                          child: _buildGridViewItem(index),
                        );
                      },
                    ),
    );
  }

  Widget _buildGridViewItem(int index) {
    return Focus(
      onKey: (FocusNode node, RawKeyEvent event) {
        if (event is RawKeyDownEvent && event.logicalKey == LogicalKeyboardKey.select) {
          _navigateToVideoScreen(context, entertainmentList[index]);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      onFocusChange: (hasFocus) {
        setState(() {
          entertainmentList[index]['isFocused'] = hasFocus;
        });
      },
      child: Container(
        margin: const EdgeInsets.all(8.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: entertainmentList[index]['isFocused'] ? const Color.fromARGB(255, 136, 51, 122) : Colors.transparent,
                    width: 5.0,
                  ),
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: Image.network(
                    entertainmentList[index]['banner'],
                    width: entertainmentList[index]['isFocused'] ? 110 : 90,
                    height: entertainmentList[index]['isFocused'] ? 90 : 70,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 8.0),
              Container(
                constraints: BoxConstraints(maxWidth: entertainmentList[index]['isFocused'] ? 110 : 90),
                child: Text(
                  entertainmentList[index]['name'] ?? 'Unknown',
                  style: const TextStyle(
                    color: Colors.white,
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

  void _navigateToVideoScreen(BuildContext context, dynamic entertainmentItem) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoScreen(
          videoUrl: entertainmentItem['url'],
          videoTitle: entertainmentItem['name'],
          channelList: entertainmentList,
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
  late Future<void> _initializeVideoPlayerFuture;
  bool isGridVisible = false;
  int selectedIndex = -1;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl);
    _initializeVideoPlayerFuture = _controller.initialize();
    _controller.setLooping(true);
    _controller.play();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void toggleGridVisibility() {
    setState(() {
      isGridVisible = !isGridVisible;
    });
  }

  void _onItemFocus(int index, bool hasFocus) {
    setState(() {
      widget.channelList[index]['isFocused'] = hasFocus;
    });
  }

  void _onItemTap(int index) {
    setState(() {
      selectedIndex = index;
      _controller.pause();
      _controller = VideoPlayerController.network(widget.channelList[index]['url']);
      _initializeVideoPlayerFuture = _controller.initialize().then((_) {
        _controller.play();
        setState(() {});
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FutureBuilder(
            future: _initializeVideoPlayerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return Center(
                  child: AspectRatio(
                    aspectRatio: 16/9,
                    // aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  ),
                );
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
          Positioned(
            bottom: isGridVisible ? 150 : 16.0,
            right: 16.0,
            child: FloatingActionButton(
              onPressed: toggleGridVisibility,
              child: Icon(isGridVisible ? Icons.close : Icons.grid_view),
            ),
          ),
          if (isGridVisible)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 150,
                color: Colors.black87,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: List.generate(
                    widget.channelList.length,
                    (index) {
                      return GestureDetector(
                        onTap: () => _onItemTap(index),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(50.0),
                          child: Focus(
                            onKey: (FocusNode node, RawKeyEvent event) {
                              if (event is RawKeyDownEvent &&
                                  event.logicalKey == LogicalKeyboardKey.select) {
                                _onItemTap(index);
                                return KeyEventResult.handled;
                              }
                              return KeyEventResult.ignored;
                            },
                            onFocusChange: (hasFocus) =>
                                _onItemFocus(index, hasFocus),
                            child: Container(
                              width: 150,
                              margin: const EdgeInsets.all(8.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(15.0),
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 1000),
                                        curve: Curves.easeInOut,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: widget.channelList[index]
                                                    ['isFocused']
                                                ? const Color.fromARGB(255, 136, 51, 122)
                                                : Colors.transparent,
                                            width: 5.0,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(25.0),
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          child: Image.network(
                                            widget.channelList[index]
                                                ['banner'],
                                            fit: widget.channelList[index]
                                                    ['isFocused']
                                                ? BoxFit.cover
                                                : BoxFit.contain,
                                            width: widget.channelList[index]
                                                    ['isFocused']
                                                ? 100
                                                : 80,
                                            height: widget.channelList[index]
                                                    ['isFocused']
                                                ? 90
                                                : 60,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4.0),
                                    Container(
                                      constraints: const BoxConstraints(maxWidth: 150),
                                      child: Text(
                                        widget.channelList[index]['name'] ??
                                            'Unknown',
                                        style: TextStyle(
                                          color: widget.channelList[index]
                                                  ['isFocused']
                                              ? const Color.fromARGB(255, 136, 51, 122)
                                              : Colors.white,
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
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: MoviesScreen(),
  ));
}
