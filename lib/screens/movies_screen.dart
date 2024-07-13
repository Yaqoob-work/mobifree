import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;




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
          }).toList();
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
          ? Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text('Error: $errorMessage'))
              : entertainmentList.isEmpty
                  ? Center(child: Text('No entertainment channels found'))
                  : GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: entertainmentList.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () =>
                              _navigateToVideoScreen(context, entertainmentList[index]),
                          child: _buildGridViewItem(index),
                        );
                      },
                    ),
    );
  }

  Widget _buildGridViewItem(int index) {
    return Focus(
      onKey: (FocusNode node, RawKeyEvent event) {
        if (event is RawKeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter)) {
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
        margin: EdgeInsets.all(8.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: entertainmentList[index]['isFocused']
                        ? const Color.fromARGB(255, 136, 51, 122)
                        : Colors.transparent,
                    width: 3.0,
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
              SizedBox(height: 8.0),
              LayoutBuilder(
                builder: (context, constraints) {
                  return FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Container(
                      constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                      child: Text(
                        entertainmentList[index]['name'] ?? 'Unknown',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                },
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
          onFabFocusChanged: _handleFabFocusChanged,
        ),
      ),
    );
  }

  void _handleFabFocusChanged(bool hasFocus) {
    setState(() {
      // Update FAB focus state
      // This method can be called from VideoScreen to update FAB focus state
    });
  }
}




class VideoScreen extends StatefulWidget {
  final String videoUrl;
  final String videoTitle;
  final List<dynamic> channelList;
  final Function(bool) onFabFocusChanged; // Callback to notify FAB focus change

  VideoScreen({
    required this.videoUrl,
    required this.videoTitle,
    required this.channelList,
    required this.onFabFocusChanged,
  });

  @override
  _VideoScreenState createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;
  bool isGridVisible = false;
  int selectedIndex = -1;
  bool isFullScreen = false;
  double volume = 0.5;
  bool isVolumeControlVisible = false; // Add this flag
  Timer? _hideVolumeControlTimer; // Timer to hide the volume control
  List<FocusNode> focusNodes = [];

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl);
    _initializeVideoPlayerFuture = _controller.initialize();
    _controller.setLooping(true);
    _controller.play();
    _controller.setVolume(volume);

    // Initialize focus nodes for each channel item
    focusNodes = List.generate(widget.channelList.length, (index) => FocusNode());
  }

  @override
  void dispose() {
    _controller.dispose();
    _hideVolumeControlTimer?.cancel(); // Cancel the timer if it's active
    for (var node in focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void toggleGridVisibility() {
    setState(() {
      isGridVisible = !isGridVisible;
    });
  }

  void toggleFullScreen() {
    setState(() {
      isFullScreen = !isFullScreen;
    });
  }

  void _onItemFocus(int index, bool hasFocus) {
    setState(() {
      widget.channelList[index]['isFocused'] = hasFocus; // Update channel focus state
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

  void _showVolumeControl() {
    setState(() {
      isVolumeControlVisible = true;
    });

    // Cancel any existing timer and start a new one to hide the volume control
    _hideVolumeControlTimer?.cancel();
    _hideVolumeControlTimer = Timer(Duration(seconds: 3), () {
      setState(() {
        isVolumeControlVisible = false;
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
                    aspectRatio: _controller.value.aspectRatio,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        VideoPlayer(_controller),
                        // Progress bar
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: LinearProgressIndicator(
                            value: _controller.value.position.inSeconds /
                                _controller.value.duration.inSeconds,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                return Center(child: CircularProgressIndicator());
              }
            },
          ),
          if (!isFullScreen)
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(
                          _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                        ),
                        onPressed: () {
                          setState(() {
                            if (_controller.value.isPlaying) {
                              _controller.pause();
                            } else {
                              _controller.play();
                            }
                          });
                        },
                      ),
                      IconButton(
                        icon: Icon(isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen),
                        onPressed: toggleFullScreen,
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  if (isVolumeControlVisible)
                    Row(
                      children: [
                        Icon(Icons.volume_up),
                        Expanded(
                          child: Slider(
                            value: volume,
                            min: 0,
                            max: 1,
                            onChanged: (value) {
                              setState(() {
                                volume = value;
                                _controller.setVolume(volume);
                                _showVolumeControl(); // Show the volume control
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          AnimatedPositioned(
            duration: Duration(milliseconds: 300),
            bottom: isGridVisible ? 150 : 150,
            right: 20,
            child: IconButton(
              onPressed: toggleGridVisibility,
              icon: Icon(isGridVisible ? Icons.close : Icons.grid_view),
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
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.channelList.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => _onItemTap(index),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(50.0),
                        child: Focus(
                          focusNode: focusNodes[index],
                          onKey: (FocusNode node, RawKeyEvent event) {
                            if (event is RawKeyDownEvent &&
                                (event.logicalKey == LogicalKeyboardKey.select ||
                                    event.logicalKey == LogicalKeyboardKey.enter)) {
                              _onItemTap(index);
                              return KeyEventResult.handled;
                            }
                            return KeyEventResult.ignored;
                          },
                          onFocusChange: (hasFocus) {
                            _onItemFocus(index, hasFocus);
                          },
                          child: Container(
                            width: 150,
                            margin: EdgeInsets.all(8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15.0),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: AnimatedContainer(
                                      duration: Duration(milliseconds: 1000),
                                      curve: Curves.easeInOut,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: widget.channelList[index]['isFocused']
                                              ? Colors.yellow
                                              : Colors.transparent,
                                          width: 5.0,
                                        ),
                                        borderRadius: BorderRadius.circular(25.0),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
                                        child: Image.network(
                                          widget.channelList[index]['banner'],
                                          fit: widget.channelList[index]['isFocused']
                                              ? BoxFit.cover
                                              : BoxFit.contain,
                                          width: widget.channelList[index]['isFocused']
                                              ? 100
                                              : 80,
                                          height: widget.channelList[index]['isFocused']
                                              ? 90
                                              : 60,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 4.0),
                                  Text(
                                    widget.channelList[index]['name'] ?? 'Unknown',
                                    style: TextStyle(
                                      color: widget.channelList[index]['isFocused']
                                          ? Colors.white
                                          : Colors.white.withOpacity(0.6),
                                      fontSize: 12.0,
                                    ),
                                    maxLines: 2,
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
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
        ],
      ),
    );
  }
}
