import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobi_tv_entertainment/home_sub_screen/home_category.dart';
import 'package:mobi_tv_entertainment/main.dart';
import 'package:video_player/video_player.dart';

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
    required String genres,
    required List<Channel> channels,
    required int initialIndex,
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
  bool isVolumeControlVisible = false;
  Timer? _hideVolumeControlTimer;
  Timer? _inactivityTimer; // Timer to track inactivity
  List<FocusNode> focusNodes = [];
  FocusNode fabFocusNode = FocusNode();
   FocusNode _focusNode = FocusNode();
  Color _backgroundColor = Colors.transparent; // Default background color

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl);
    _initializeVideoPlayerFuture = _controller.initialize();
    _controller.setLooping(true);
    _controller.play();
    _controller.setVolume(volume);
_focusNode.addListener(() {
      setState(() {
        _backgroundColor = _focusNode.hasFocus ? borderColor : Colors.transparent;
      });
    });
    // Initialize focus nodes for each channel item
    focusNodes =
        List.generate(widget.channelList.length, (index) => FocusNode());

    // Initialize isFocused to false for each channel
    widget.channelList.forEach((channel) {
      if (channel['isFocused'] == null) {
        channel['isFocused'] = false;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _hideVolumeControlTimer?.cancel();
    _inactivityTimer?.cancel(); // Cancel the inactivity timer
    for (var node in focusNodes) {
      node.dispose();
    }
    // fabFocusNode.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void toggleGridVisibility() {
    setState(() {
      isGridVisible = !isGridVisible;
      if (isGridVisible) {
        _resetInactivityTimer(); // Start the inactivity timer when grid is visible
      }
    });
  }

  void toggleFullScreen() {
    setState(() {
      isFullScreen = !isFullScreen;
    });
  }

  void _onItemFocus(int index, bool hasFocus) {
    setState(() {
      widget.channelList[index]['isFocused'] = hasFocus;
      if (hasFocus) {
        selectedIndex = index;
        _resetInactivityTimer(); // Reset inactivity timer on focus change
      } else if (selectedIndex == index) {
        selectedIndex = -1;
      }
    });
  }

  void _onItemTap(int index) {
    setState(() {
      selectedIndex = index;
    });

    String selectedUrl = widget.channelList[index]['url'] ?? '';
    _controller.pause();
    _controller = VideoPlayerController.network(selectedUrl);
    _initializeVideoPlayerFuture = _controller.initialize().then((_) {
      setState(() {});
      _controller.play();
      _controller.setVolume(volume);
    });
  }

  // void _showVolumeControl() {
  //   setState(() {
  //     isVolumeControlVisible = true;
  //   });

  //   _hideVolumeControlTimer?.cancel();
  //   _hideVolumeControlTimer = Timer(const Duration(seconds: 3), () {
  //     setState(() {
  //       isVolumeControlVisible = false;
  //     });
  //   });
  // }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(seconds: 10), () {
      setState(() {
        isGridVisible = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          FutureBuilder(
            future: _initializeVideoPlayerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return Center(
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        VideoPlayer(_controller),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: LinearProgressIndicator(
                            value: _controller.value.position.inSeconds /
                                _controller.value.duration.inSeconds,
                            backgroundColor: Colors.transparent,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
          // if (!isFullScreen)
          //   Positioned(
          //     bottom: 30,
          //     left: 20,
          //     right: 20,
          //     child: Column(
          //       children: [
          //         Row(
          //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //           children: [
          //             IconButton(
          //               icon: Icon(
          //                 _controller.value.isPlaying
          //                     ? Icons.pause
          //                     : Icons.play_arrow,
          //               ),
          //               onPressed: () {
          //                 setState(() {
          //                   if (_controller.value.isPlaying) {
          //                     _controller.pause();
          //                   } else {
          //                     _controller.play();
          //                   }
          //                 });
          //               },
          //             ),
          //           ],
          //         ),
          //         // const SizedBox(height: 20),
          //         // if (isVolumeControlVisible)
          //         //   Row(
          //         //     children: [
          //         //       const Icon(Icons.volume_up),
          //         //       Expanded(
          //         //         child: Slider(
          //         //           value: volume,
          //         //           min: 0,
          //         //           max: 1,
          //         //           onChanged: (value) {
          //         //             setState(() {
          //         //               volume = value;
          //         //               _controller.setVolume(volume);
          //         //               _showVolumeControl();
          //         //             });
          //         //           },
          //         //         ),
          //         //       ),
          //         //     ],
          //         //   ),
          //       ],
          //     ),
          //   ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            bottom: isGridVisible ? 210 : 20,
            right: 20,
            
              child: Focus(
focusNode: _focusNode,
                child: Container(
                  decoration: BoxDecoration(
                    color: _backgroundColor,
                  ),
                  child: IconButton(
                    focusColor: borderColor ,
                    onPressed: toggleGridVisibility,
                    icon: Icon(isGridVisible ? Icons.close : Icons.grid_view),
                  ),
                ),
              ),
          ),
          if (isGridVisible)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 200,
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
                          onKeyEvent: (FocusNode node, KeyEvent event) {
                            if (event is KeyDownEvent &&
                                (event.logicalKey ==
                                        LogicalKeyboardKey.select ||
                                    event.logicalKey ==
                                        LogicalKeyboardKey.enter)) {
                              _onItemTap(index);
                              return KeyEventResult.handled;
                            } 
                            _resetInactivityTimer(); // Reset inactivity timer on key event
                            return KeyEventResult.ignored;
                          },
                          onFocusChange: (hasFocus) {
                            _onItemFocus(index, hasFocus);
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.all(5),

                                child: AnimatedContainer(
                                  width: widget.channelList[index]['isFocused']
                                      ? screenwdt * 0.35
                                      : screenwdt * 0.27,
                                  height: widget.channelList[index]['isFocused']
                                      ? screenhgt * 0.23
                                      : screenhgt * 0.2,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: widget.channelList[index]['isFocused']
                                          ? borderColor
                                          : Colors.transparent,
                                          
                                      width: 5.0,
                                    ),
                                    borderRadius: BorderRadius.circular(10)
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(5),
                                    child: Image.network(
                                      widget.channelList[index]['banner'] ?? '',
                                      fit: BoxFit.cover,
                                      width: widget.channelList[index]['isFocused']
                                          ? screenwdt * 0.3
                                          : screenwdt * 0.27,
                                      height: widget.channelList[index]['isFocused']
                                          ? screenhgt * 0.23
                                          : screenhgt * 0.2,
                                    ),
                                  ),
                                ),
                              ),
                              // const SizedBox(height: 8.0),
                              // Text(
                              //   widget.channelList[index]['name'] ?? '',
                              //   style: TextStyle(
                              //     color: widget.channelList[index]['isFocused']
                              //         ? Colors.yellow
                              //         : Colors.white,
                              //     fontSize: widget.channelList[index]
                              //             ['isFocused']
                              //         ? 20.0
                              //         : 16.0,
                              //     fontWeight: widget.channelList[index]
                              //             ['isFocused']
                              //         ? FontWeight.bold
                              //         : FontWeight.normal,
                              //   ),
                              // ),
                            ],
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
