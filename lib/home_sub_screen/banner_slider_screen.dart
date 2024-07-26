import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mobi_tv_entertainment/main.dart';

import '../screens/v_o_d.dart';

class BannerSliderPage extends StatefulWidget {
  @override
  _BannerSliderPageState createState() => _BannerSliderPageState();
}

class _BannerSliderPageState extends State<BannerSliderPage> {
  List<dynamic> bannerList = [];
  bool isLoading = true;
  String errorMessage = '';
  late PageController _pageController;
  late Timer _timer;
  String? selectedContentId;
  FocusNode _fabFocusNode = FocusNode();
  FocusNode _titleFocusNode = FocusNode();
  FocusNode _emptytextFocusNode = FocusNode();
  bool _isemptytextFocusNode = false;
  bool _isTitleFocused = false;
  List<FocusNode> _smallBannerFocusNodes = [];
  bool _isSmallBannerFocused = false;
  int _focusedSmallBannerIndex = 0;
  bool _isPageViewBuilt = false;

  // @override
  // void initState() {
  //   super.initState();
  //   _pageController = PageController();
  //   fetchBanners();
  //   _startAutoSlide();
  //   _titleFocusNode.addListener(_onTitleFocusChange);
  // }

  @override
  void dispose() {
    _pageController.dispose();
    _timer.cancel();
    _fabFocusNode.dispose();
    _titleFocusNode.dispose();
    _emptytextFocusNode.dispose();
    _smallBannerFocusNodes.forEach((node) => node.dispose());
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    fetchBanners();
    setState(() {
      _isPageViewBuilt = true;
    });
    _startAutoSlide();
    _titleFocusNode.addListener(_onTitleFocusChange);
    _emptytextFocusNode.addListener(_onTitleFocusChange);
    _smallBannerFocusNodes =
        List.generate(bannerList.length, (_) => FocusNode());
  }

  void _onemptytextFocusNode() {
    setState(() {
      _isemptytextFocusNode = _emptytextFocusNode.hasFocus;
    });
  }

  void _onTitleFocusChange() {
    setState(() {
      _isTitleFocused = _titleFocusNode.hasFocus;
    });
  }

  void _startAutoSlide() {
    if (_isPageViewBuilt) {
      _timer = Timer.periodic(Duration(seconds: 5), (Timer timer) {
        if (_pageController.page == bannerList.length - 1) {
          _pageController.animateToPage(
            0,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeIn,
          );
        } else {
          _pageController.nextPage(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeIn,
          );
        }
      });
    }
  }

  Future<void> fetchBanners() async {
    try {
      final response = await http.get(
        Uri.parse('https://mobifreetv.com/android/getCustomImageSlider'),
        headers: {
          'x-api-key': 'vLQTuPZUxktl5mVW',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);

        setState(() {
          bannerList = responseData.map((banner) {
            return {
              'content_id': banner['content_id'] ?? '',
              'banner': banner['banner'] ?? '',
              'title': banner['title'] ?? 'No Title',
            };
          }).toList();

          _smallBannerFocusNodes =
              List.generate(bannerList.length, (_) => FocusNode());

          selectedContentId = bannerList.isNotEmpty
              ? bannerList[0]['content_id'].toString()
              : null;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load banners');
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> fetchAndPlayVideo(String contentId) async {
    try {
      final response = await http.get(
        Uri.parse('https://mobifreetv.com/android/getFeaturedLiveTV'),
        headers: {
          'x-api-key': 'vLQTuPZUxktl5mVW',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        final filteredData = responseData.firstWhere(
          (channel) => channel['id'].toString() == contentId,
          orElse: () => null,
        );

        if (filteredData != null) {
          final videoUrl = filteredData['url'] ?? '';
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoScreen(
                videoUrl: videoUrl,
                videoTitle: filteredData['title'] ?? 'No Title',
                channelList: [],
                onFabFocusChanged: (bool focused) {},
                genres: '',
                videoBanner: '',
              ),
            ),
          );
        } else {
          throw Exception('Video not found');
        }
      } else {
        throw Exception('Failed to load featured live TV');
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    }
  }

  void _scrollToSmallBanner(int index) {
    _pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeIn,
    );
    setState(() {
      selectedContentId = bannerList[index]['content_id'].toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text('Error: $errorMessage'))
              : bannerList.isEmpty
                  ? const Center(child: Text('No banners found'))
                  : Stack(
                      children: [
                        PageView.builder(
                          controller: _pageController,
                          itemCount: bannerList.length,
                          onPageChanged: (index) {
                            setState(() {
                              selectedContentId =
                                  bannerList[index]['content_id'].toString();
                            });
                          },
                          itemBuilder: (context, index) {
                            final banner = bannerList[index];
                            return Stack(
                              children: [
                                Container(
                                  width: MediaQuery.of(context).size.width,
                                  height:
                                      MediaQuery.of(context).size.height * 0.9,
                                  child: GestureDetector(
                                    onTap: () {
                                      if (selectedContentId != null) {
                                        fetchAndPlayVideo(selectedContentId!);
                                      }
                                    },
                                    child: Image.network(
                                      banner['banner'] ?? '',
                                      fit: BoxFit.cover,
                                      width: MediaQuery.of(context).size.width,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  child: Focus(
                                    focusNode: _titleFocusNode,
                                    onFocusChange: (hasFocus) {
                                      setState(() {
                                        _isemptytextFocusNode = hasFocus;
                                      });
                                    },
                                    child: Container(
                                      child: Text(''),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 30.0,
                                  left: 30.0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10.0, vertical: 5.0),
                                    child: Text(
                                      banner['title'] ??
                                          'No Title', // Handle null title here
                                      style: const TextStyle(
                                        color: AppColors.highlightColor,
                                        fontSize: 40.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        Positioned(
                          bottom: 30.0,
                          left: 0.0,
                          right: 0.0,
                          child: Container(
                            height: MediaQuery.of(context).size.height * 0.1,
                            child: GridView.builder(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: bannerList.length,
                                childAspectRatio: 16 / 9,
                              ),
                              itemCount: bannerList.length,
                              itemBuilder: (context, index) {
                                final smallBanner = bannerList[index] ?? '';
                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Focus(
                                    focusNode: _smallBannerFocusNodes[index],
                                    onFocusChange: (hasFocus) {
                                      if (hasFocus) {
                                        setState(() {
                                          _isSmallBannerFocused = true;
                                          _focusedSmallBannerIndex = index;
                                          _scrollToSmallBanner(index);
                                        });
                                      } else {
                                        setState(() {
                                          _isSmallBannerFocused = false;
                                        });
                                      }
                                    },
                                    onKeyEvent: (node, event) {
                                      if (event is KeyDownEvent &&
                                          event.logicalKey ==
                                              LogicalKeyboardKey.select) {
                                        // _navigateToVideoScreen(context, entertainmentList[index]);
                                        fetchAndPlayVideo(
                                            smallBanner['content_id'] ?? '');

                                        return KeyEventResult.handled;
                                      }
                                      return KeyEventResult.ignored;
                                    },
                                    child: GestureDetector(
                                      onTap: () {
                                        fetchAndPlayVideo(
                                            smallBanner['content_id'] ?? '');
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: _isSmallBannerFocused &&
                                                    _focusedSmallBannerIndex ==
                                                        index
                                                ? AppColors.primaryColor
                                                : Colors.transparent,
                                            width: 5.0,
                                          ),
                                        ),
                                        child: Image.network(
                                          smallBanner['banner'] ?? '',
                                          fit: BoxFit.cover,
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

// class VideoScreen extends StatefulWidget {
//   final String videoUrl;
//   final String videoTitle;
//   final List<dynamic> channelList;
//   final Function(bool) onFabFocusChanged; // Callback to notify FAB focus change

//   VideoScreen({
//     required this.videoUrl,
//     required this.videoTitle,
//     required this.channelList,
//     required this.onFabFocusChanged,
//     required String genres,
//   });

//   @override
//   _VideoScreenState createState() => _VideoScreenState();
// }

// class _VideoScreenState extends State<VideoScreen> {
//   late VideoPlayerController _controller;
//   late Future<void> _initializeVideoPlayerFuture;
//   bool isGridVisible = false;
//   int selectedIndex = -1;
//   bool isFullScreen = false;
//   double volume = 0.5;
//   bool isVolumeControlVisible = false;
//   Timer? _hideVolumeControlTimer;
//   Timer? _inactivityTimer; // Timer to track inactivity
//   List<FocusNode> focusNodes = [];

//   @override
//   void initState() {
//     super.initState();
//     _controller = VideoPlayerController.network(widget.videoUrl);
//     _initializeVideoPlayerFuture = _controller.initialize();
//     _controller.setLooping(true);
//     _controller.play();
//     _controller.setVolume(volume);

//     // Initialize focus nodes for each channel item
//     focusNodes =
//         List.generate(widget.channelList.length, (index) => FocusNode());

//     // Initialize isFocused to false for each channel
//     widget.channelList.forEach((channel) {
//       if (channel['isFocused'] == null) {
//         channel['isFocused'] = false;
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     _hideVolumeControlTimer?.cancel();
//     _inactivityTimer?.cancel(); // Cancel the inactivity timer
//     for (var node in focusNodes) {
//       node.dispose();
//     }
//     super.dispose();
//   }

//   void toggleGridVisibility() {
//     setState(() {
//       isGridVisible = !isGridVisible;
//       if (isGridVisible) {
//         _resetInactivityTimer(); // Start the inactivity timer when grid is visible
//       }
//     });
//   }

//   void toggleFullScreen() {
//     setState(() {
//       isFullScreen = !isFullScreen;
//     });
//   }

//   void _onItemFocus(int index, bool hasFocus) {
//     setState(() {
//       widget.channelList[index]['isFocused'] = hasFocus;
//       if (hasFocus) {
//         selectedIndex = index;
//         _resetInactivityTimer(); // Reset inactivity timer on focus change
//       } else if (selectedIndex == index) {
//         selectedIndex = -1;
//       }
//     });
//   }

//   void _onItemTap(int index) {
//     setState(() {
//       selectedIndex = index;
//     });

//     String selectedUrl = widget.channelList[index]['url'] ?? '';
//     _controller.pause();
//     _controller = VideoPlayerController.network(selectedUrl);
//     _initializeVideoPlayerFuture = _controller.initialize().then((_) {
//       setState(() {});
//       _controller.play();
//       _controller.setVolume(volume);
//     });
//   }

//   void _showVolumeControl() {
//     setState(() {
//       isVolumeControlVisible = true;
//     });

//     _hideVolumeControlTimer?.cancel();
//     _hideVolumeControlTimer = Timer(const Duration(seconds: 3), () {
//       setState(() {
//         isVolumeControlVisible = false;
//       });
//     });
//   }

//   void _resetInactivityTimer() {
//     _inactivityTimer?.cancel();
//     _inactivityTimer = Timer(const Duration(seconds: 10), () {
//       setState(() {
//         isGridVisible = false;
//       });
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Stack(
//         children: [
//           FutureBuilder(
//             future: _initializeVideoPlayerFuture,
//             builder: (context, snapshot) {
//               if (snapshot.connectionState == ConnectionState.done) {
//                 return Center(
//                   child: AspectRatio(
//                     aspectRatio: 16 / 9,
//                     child: Stack(
//                       alignment: Alignment.bottomCenter,
//                       children: [
//                         VideoPlayer(_controller),
//                         Positioned(
//                           left: 0,
//                           right: 0,
//                           bottom: 0,
//                           child: LinearProgressIndicator(
//                             value: _controller.value.position.inSeconds /
//                                 _controller.value.duration.inSeconds,
//                             backgroundColor: Colors.transparent,
//                             valueColor: const AlwaysStoppedAnimation<Color>(
//                                 Colors.grey),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               } else {
//                 return const Center(child: CircularProgressIndicator());
//               }
//             },
//           ),
//           if (!isFullScreen)
//             Positioned(
//               bottom: 30,
//               left: 20,
//               right: 20,
//               child: Column(
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       IconButton(
//                         icon: Icon(
//                           _controller.value.isPlaying
//                               ? Icons.pause
//                               : Icons.play_arrow,
//                         ),
//                         onPressed: () {
//                           setState(() {
//                             if (_controller.value.isPlaying) {
//                               _controller.pause();
//                             } else {
//                               _controller.play();
//                             }
//                           });
//                         },
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 20),
//                   if (isVolumeControlVisible)
//                     Row(
//                       children: [
//                         const Icon(Icons.volume_up),
//                         Expanded(
//                           child: Slider(
//                             value: volume,
//                             min: 0,
//                             max: 1,
//                             onChanged: (value) {
//                               setState(() {
//                                 volume = value;
//                                 _controller.setVolume(volume);
//                                 _showVolumeControl();
//                               });
//                             },
//                           ),
//                         ),
//                       ],
//                     ),
//                 ],
//               ),
//             ),
//           // AnimatedPositioned(
//           //   duration: const Duration(milliseconds: 300),
//           //   bottom: isGridVisible ? 230 : 20,
//           //   right: 20,
//           //   child: FloatingActionButton(
//           //     onPressed: toggleGridVisibility,
//           //     child: Icon(isGridVisible ? Icons.close : Icons.grid_view),
//           //   ),
//           // ),
//           // if (isGridVisible)
//           //   Positioned(
//           //     bottom: 0,
//           //     left: 0,
//           //     right: 0,
//           //     child: Container(
//           //       height: 220,
//           //       color: Colors.black87,
//           //       child: ListView.builder(
//           //         scrollDirection: Axis.horizontal,
//           //         itemCount: widget.channelList.length,
//           //         itemBuilder: (context, index) {
//           //           return GestureDetector(
//           //             onTap: () => _onItemTap(index),
//           //             child: ClipRRect(
//           //               borderRadius: BorderRadius.circular(50.0),
//           //               child: Focus(
//           //                 focusNode: focusNodes[index],
//           //                 onKey: (FocusNode node, RawKeyEvent event) {
//           //                   if (event is RawKeyDownEvent &&
//           //                       (event.logicalKey ==
//           //                               LogicalKeyboardKey.select ||
//           //                           event.logicalKey ==
//           //                               LogicalKeyboardKey.enter)) {
//           //                     _onItemTap(index);
//           //                     return KeyEventResult.handled;
//           //                   }
//           //                   _resetInactivityTimer(); // Reset inactivity timer on key event
//           //                   return KeyEventResult.ignored;
//           //                 },
//           //                 onFocusChange: (hasFocus) {
//           //                   _onItemFocus(index, hasFocus);
//           //                 },
//           //                 child: Column(
//           //                   mainAxisAlignment: MainAxisAlignment.center,
//           //                   crossAxisAlignment: CrossAxisAlignment.center,
//           //                   children: [
//           //                     Padding(
//           //                       padding: const EdgeInsets.symmetric(
//           //                           horizontal: 20.0),
//           //                       child: Container(
//           //                         width: widget.channelList[index]['isFocused']
//           //                             ? 210
//           //                             : 140,
//           //                         height: widget.channelList[index]['isFocused']
//           //                             ? 160
//           //                             : 140,
//           //                         child: AnimatedContainer(
//           //                           width: widget.channelList[index]
//           //                                   ['isFocused']
//           //                               ? 200
//           //                               : 100,
//           //                           height: widget.channelList[index]
//           //                                   ['isFocused']
//           //                               ? 150
//           //                               : 100,
//           //                           duration: const Duration(milliseconds: 300),
//           //                           curve: Curves.easeInOut,
//           //                           // decoration: BoxDecoration(
//           //                           //   border: Border.all(
//           //                           //     color: widget.channelList[index]['isFocused']
//           //                           //         ? Color.fromARGB(255, 106, 235, 20)
//           //                           //         : Colors.transparent,
//           //                           //     width: 5.0,
//           //                           //   ),
//           //                           //   borderRadius: BorderRadius.circular(25.0),
//           //                           // ),
//           //                           child: ContainerGradientBorder(
//           //                             width: widget.channelList[index]
//           //                                     ['isFocused']
//           //                                 ? 190
//           //                                 : 110,
//           //                             height: widget.channelList[index]
//           //                                     ['isFocused']
//           //                                 ? 140
//           //                                 : 110,
//           //                             start: Alignment.topLeft,
//           //                             end: Alignment.bottomRight,
//           //                             borderWidth: 7,
//           //                             colorList: widget.channelList[index]
//           //                                     ['isFocused']
//           //                                 ? [
//           //                                     AppColors.primaryColor,
//           //                                     AppColors.highlightColor,
//           //                                     AppColors.primaryColor,
//           //                                     AppColors.highlightColor,
//           //                                     AppColors.primaryColor,
//           //                                     AppColors.highlightColor,
//           //                                     AppColors.primaryColor,
//           //                                     AppColors.highlightColor,
//           //                                     AppColors.primaryColor,
//           //                                     AppColors.highlightColor,
//           //                                     AppColors.primaryColor,
//           //                                     AppColors.highlightColor,
//           //                                     AppColors.primaryColor,
//           //                                     AppColors.highlightColor,
//           //                                     AppColors.primaryColor,
//           //                                     AppColors.highlightColor,
//           //                                   ]
//           //                                 : [
//           //                                     AppColors.primaryColor,
//           //                                     AppColors.highlightColor
//           //                                   ],
//           //                             borderRadius: 14,
//           //                             child: ClipRRect(
//           //                               borderRadius: BorderRadius.circular(10),
//           //                               child: Image.network(
//           //                                 widget.channelList[index]['banner'] ??
//           //                                     '',
//           //                                 fit: BoxFit.cover,
//           //                                 width: widget.channelList[index]
//           //                                         ['isFocused']
//           //                                     ? 180
//           //                                     : 100,
//           //                                 height: widget.channelList[index]
//           //                                         ['isFocused']
//           //                                     ? 130
//           //                                     : 100,
//           //                               ),
//           //                             ),
//           //                           ),
//           //                         ),
//           //                       ),
//           //                     ),
//           //                     Container(
//           //                       width: widget.channelList[index]['isFocused']
//           //                           ? 180
//           //                           : 100,
//           //                       child: Text(
//           //                         widget.channelList[index]['name'] ??
//           //                             'Unknown',
//           //                         style: TextStyle(
//           //                           color: widget.channelList[index]
//           //                                   ['isFocused']
//           //                               ? Color.fromARGB(255, 106, 235, 20)
//           //                               : Colors.white.withOpacity(0.6),
//           //                           fontSize: 20.0,
//           //                         ),
//           //                         maxLines: 1,
//           //                         textAlign: TextAlign.center,
//           //                         overflow: TextOverflow.ellipsis,
//           //                       ),
//           //                     ),
//           //                   ],
//           //                 ),
//           //               ),
//           //             ),
//           //           );
//           //         },
//           //       ),
//           //     ),
//           //   ),
//         ],
//       ),
//     );
//   }
// }
