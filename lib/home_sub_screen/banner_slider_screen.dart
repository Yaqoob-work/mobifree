// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:http/http.dart' as http;
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:video_player/video_player.dart';

// class BannerSliderPage extends StatefulWidget {
//   @override
//   _BannerSliderPageState createState() => _BannerSliderPageState();
// }

// class _BannerSliderPageState extends State<BannerSliderPage> {
//   List<String> _imageUrls = [];
//   List<String> _videoUrls = [];
//   List<String> _titles = [];
//   int _currentIndex = 0;
//   PageController _pageController = PageController();
//   VideoPlayerController? _controller;
//   FocusNode _bigBannerFocusNode = FocusNode();
//   List<FocusNode> _smallBannerFocusNodes = [];
//   FocusNode _fabFocusNode = FocusNode();

//   @override
//   void initState() {
//     super.initState();
//     _fetchSliderData();
//   }

//   void _fetchSliderData() async {
//     String apiUrl = 'https://mobifreetv.com/android/getCustomImageSlider';

//     try {
//       var response = await http.get(
//         Uri.parse(apiUrl),
//         headers: {
//           'x-api-key': 'vLQTuPZUxktl5mVW', // Replace with your actual API key
//         },
//       );

//       if (response.statusCode == 200) {
//         var jsonData = json.decode(response.body);
//         List<String> imageUrls = [];
//         List<String> videoUrls = [];
//         List<String> titles = [];

//         for (var item in jsonData) {
//           imageUrls.add(item['banner']);
//           videoUrls.add(item['url']);
//           titles.add(item['title']); // Assuming 'title' is the key for the title field
//         }

//         setState(() {
//           _imageUrls = imageUrls;
//           _videoUrls = videoUrls;
//           _titles = titles;
//           _smallBannerFocusNodes = List.generate(_imageUrls.length, (_) => FocusNode());
//         });

//         _startAutoSliding();
//       } else {
//         print('Failed to load slider data: ${response.statusCode}');
//         // Print response body for more details if needed
//         print(response.body);
//       }
//     } catch (e) {
//       print('Error loading slider data: $e');
//     }
//   }

//   void _startAutoSliding() {
//     Timer.periodic(Duration(seconds: 5), (timer) {
//       if (_currentIndex < _imageUrls.length - 1) {
//         _currentIndex++;
//       } else {
//         _currentIndex = 0;
//       }
//       _pageController.animateToPage(
//         _currentIndex,
//         duration: Duration(milliseconds: 500),
//         curve: Curves.easeInOut,
//       );
//     });
//   }

//   @override
//   void dispose() {
//     _pageController.dispose();
//     _controller?.dispose();
//     _bigBannerFocusNode.dispose();
//     _smallBannerFocusNodes.forEach((node) => node.dispose());
//     _fabFocusNode.dispose();
//     super.dispose();
//   }

//   void _scrollToIndex(int index) {
//     _pageController.animateToPage(
//       index,
//       duration: Duration(milliseconds: 500),
//       curve: Curves.easeInOut,
//     );

//     // Center the selected banner in the small banner list
//     final screenWidth = MediaQuery.of(context).size.width;
//     final itemWidth = screenWidth * 0.3;
//     final scrollOffset = index * itemWidth;
//     final maxScrollExtent = _pageController.position.maxScrollExtent;

//     if (scrollOffset > maxScrollExtent) {
//       _pageController.jumpTo(maxScrollExtent);
//     } else {
//       _pageController.jumpTo(scrollOffset);
//     }
//   }

//   Widget _buildSmallBannerList() {
//     return Positioned(
//       bottom: MediaQuery.of(context).size.height * 0.19,
//       left: MediaQuery.of(context).size.width * 0.054,
//       child: Container(
//         height: MediaQuery.of(context).size.height * 0.08,
//         width: MediaQuery.of(context).size.width * 0.29,
//         child: ListView.builder(
//           scrollDirection: Axis.horizontal,
//           itemCount: _imageUrls.length,
//           itemBuilder: (context, index) {
//             return Padding(
//               padding: EdgeInsets.symmetric(horizontal: 4.0),
//               child: Focus(
//                 focusNode: _smallBannerFocusNodes[index],
//                 child: GestureDetector(
//                   onTap: () {
//                     setState(() {
//                       _currentIndex = index;
//                     });
//                     _scrollToIndex(index);
//                     FocusScope.of(context).requestFocus(_bigBannerFocusNode);
//                   },
//                   child: Container(
//                     decoration: BoxDecoration(
//                       border: Border.all(
//                         color: _currentIndex == index ? const Color.fromARGB(255, 136, 51, 122) : Colors.transparent,
//                         width: 3.0,
//                       ),
//                     ),
//                     child: CachedNetworkImage(
//                       imageUrl: _imageUrls[index],
//                       fit: BoxFit.cover,
//                       width: 80,
//                       height: 20,
//                     ),
//                   ),
//                 ),
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }

//   void _playVideo(String videoUrl) {
//     _controller?.dispose();
//     _controller = VideoPlayerController.network(videoUrl)
//       ..initialize().then((_) {
//         setState(() {});
//         _controller?.play();
//       });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: _imageUrls.isEmpty
//           ? Center(child: CircularProgressIndicator())
//           : Stack(
//               fit: StackFit.expand,
//               children: <Widget>[
//                 Positioned.fill(
//                   child: Focus(
//                     focusNode: _bigBannerFocusNode,
//                     onKey: (FocusNode node, RawKeyEvent event) {
//                       if (event is RawKeyDownEvent &&
//                           (event.logicalKey == LogicalKeyboardKey.select ||
//                               event.logicalKey == LogicalKeyboardKey.enter)) {
//                         _playVideo(_videoUrls[_currentIndex]);
//                         return KeyEventResult.handled;
//                       }
//                       return KeyEventResult.ignored;
//                     },
//                     child: PageView.builder(
//                       controller: _pageController,
//                       itemCount: _imageUrls.length,
//                       onPageChanged: (index) {
//                         setState(() {
//                           _currentIndex = index;
//                         });
//                       },
//                       itemBuilder: (context, index) {
//                         return Stack(
//                           fit: StackFit.expand,
//                           children: <Widget>[
//                             Container(
                              
//                               child: CachedNetworkImage(
//                                 imageUrl: _imageUrls[index],
//                                 fit: BoxFit.cover,
//                               ),
//                             ),
//                             if (_videoUrls.isNotEmpty &&
//                                 _controller != null &&
//                                 _controller!.value.isInitialized)
//                               AspectRatio(
//                                 aspectRatio: 16 / 9,
//                                 child: VideoPlayer(_controller!),
//                               ),
//                           ],
//                         );
//                       },
//                     ),
//                   ),
//                 ),
//                 _buildSmallBannerList(),
//                 Positioned(
//                   left: 16.0,
//                   bottom: 0,
//                   top: 0,
//                   child: Container(
//                     height: MediaQuery.of(context).size.height,
//                     alignment: Alignment.centerLeft,
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           _titles.isNotEmpty ? _titles[_currentIndex] : 'Banner Title',
//                           style: TextStyle(
//                             fontSize: 35.0,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.orange,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 Positioned(
//                   left: MediaQuery.of(context).size.width * 0.01,
//                   bottom: MediaQuery.of(context).size.height * 0.18,
//                   child: IconButton(
//                     icon: Icon(Icons.arrow_back_ios),
//                     onPressed: () {
//                       if (_currentIndex > 0) {
//                         _pageController.previousPage(
//                           duration: Duration(milliseconds: 500),
//                           curve: Curves.easeInOut,
//                         );
//                       }
//                     },
//                   ),
//                 ),
//                 Positioned(
//                   left: MediaQuery.of(context).size.width * 0.34,
//                   bottom: MediaQuery.of(context).size.height * 0.18,
//                   child: IconButton(
//                     icon: Icon(Icons.arrow_forward_ios),
//                     onPressed: () {
//                       if (_currentIndex < _imageUrls.length - 1) {
//                         _pageController.nextPage(
//                           duration: Duration(milliseconds: 500),
//                           curve: Curves.easeInOut,
//                         );
//                       }
//                     },
//                   ),
//                 ),
//                 Positioned(
//                   left: 50.0,
//                   // right: 50.0,
//                   bottom: MediaQuery.of(context).size.height * 0.01,
//                   child: IntrinsicWidth(
//                     child: Focus(
//                       focusNode: _fabFocusNode,
//                       onFocusChange: (hasFocus) {
//                         setState(() {});
//                       },
//                       child: FloatingActionButton.extended(
//                         backgroundColor: _fabFocusNode.hasFocus ? Color.fromARGB(188, 136, 51, 122) : Colors.white,
//                         onPressed: () {
//                           _playVideo(_videoUrls[_currentIndex]);
//                         },
//                         label: Text(
//                           _titles.isNotEmpty ? _titles[_currentIndex] : 'Banner Title',
//                           style: TextStyle(color: Colors.black),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//     );
//   }
// }

// void main() {
//   runApp(MaterialApp(
//     home: BannerSliderPage(),
//   ));
// }





import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../video_widget/video_screen.dart';

class BannerSliderPage extends StatefulWidget {
  @override
  _BannerSliderPageState createState() => _BannerSliderPageState();
}

class _BannerSliderPageState extends State<BannerSliderPage> {
  List<dynamic> bannerList = [];
  bool isLoading = true;
  String errorMessage = '';
  String? fabTitle;
  late PageController _pageController;
  late Timer _timer;
  String? selectedContentId;
  FocusNode _fabFocusNode = FocusNode();
  bool _isFabFocused = false;
  List<FocusNode> _smallBannerFocusNodes = [];
  bool _isSmallBannerFocused = false;
  int _focusedSmallBannerIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    fetchBanners();
    _startAutoSlide();
    _fabFocusNode.addListener(_onFabFocusChange);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer.cancel();
    _fabFocusNode.dispose();
    _smallBannerFocusNodes.forEach((node) => node.dispose());
    super.dispose();
  }

  void _onFabFocusChange() {
    setState(() {
      _isFabFocused = _fabFocusNode.hasFocus;
    });
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(Duration(seconds: 3), (Timer timer) {
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
              'content_id': banner['content_id'],
              'banner': banner['banner'],
              'title': banner['title'] ?? 'No Title', // Handle null title here
            };
          }).toList();

          // Create focus nodes for small banners
          _smallBannerFocusNodes = List.generate(bannerList.length, (_) => FocusNode());

          // Set the initial FAB title
          fabTitle = bannerList.isNotEmpty ? bannerList[0]['title'] : null;
          selectedContentId = bannerList.isNotEmpty ? bannerList[0]['content_id'].toString() : null;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load banners');
      }
    } catch (e) {
      print('Error fetching banners: $e');
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
          final videoUrl = filteredData['url']; // Replace 'url' with the actual field name for the video URL
          // Navigate to the video player screen and play the video
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoScreen(
                url: videoUrl,
                videoUrl: videoUrl,
                videoTitle: filteredData['title'] ?? 'No Title',
                channelList: [], // Pass the channel list if needed
                onFabFocusChanged: (bool focused) {},
                genres: '', 
                playUrl: '', // Pass the appropriate genres if needed
                playVideo: (String id) {  },
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
      print('Error fetching video: $e');
      setState(() {
        errorMessage = e.toString();
      });
    }
  }

  double _calculateTextWidth(String text, TextStyle style) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    return textPainter.size.width;
  }

  void _scrollToSmallBanner(int index) {
    _pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeIn,
    );
    setState(() {
      fabTitle = bannerList[index]['title'];
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
                              fabTitle = bannerList[index]['title'];
                              selectedContentId = bannerList[index]['content_id'].toString();
                            });
                          },
                          itemBuilder: (context, index) {
                            final banner = bannerList[index];
                            return Stack(
                              children: [
                                Container(
                                  width: MediaQuery.of(context).size.width,
                                  height: MediaQuery.of(context).size.height * 0.8,
                                  child: InkWell(
                                    onTap: () {
                                      if (selectedContentId != null) {
                                        fetchAndPlayVideo(selectedContentId!);
                                      }
                                    },
                                    child: Image.network(
                                      banner['banner'],
                                      fit: BoxFit.cover,
                                      width: MediaQuery.of(context).size.width,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 30.0,
                                  left: 30.0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                                    child: Text(
                                      banner['title'] ?? 'No Title', // Handle null title here
                                      style: const TextStyle(
                                        color: Color.fromARGB(255, 106, 235, 20),
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
                          bottom: MediaQuery.of(context).size.height * 0.15,
                          left: 40.0,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              double fabWidth = _calculateTextWidth(
                                      fabTitle ?? '', TextStyle(fontSize: 18.0)) +
                                  32.0; // Adding some padding

                              return Container(
                                width: fabWidth,
                                child: Focus(
                                  focusNode: _fabFocusNode,
                                  onKey: (FocusNode node, RawKeyEvent event) {
                                    if (event is RawKeyDownEvent) {
                                      if (event.logicalKey == LogicalKeyboardKey.select) {
                                        if (selectedContentId != null) {
                                          fetchAndPlayVideo(selectedContentId!);
                                        }
                                        return KeyEventResult.handled;
                                      }
                                    }
                                    return KeyEventResult.ignored;
                                  },
                                  child: GestureDetector(
                                    onTap: () {
                                      if (selectedContentId != null) {
                                        fetchAndPlayVideo(selectedContentId!);
                                      }
                                    },
                                    child: AnimatedContainer(
                                      duration: Duration(milliseconds: 200),
                                      
                                      child: FloatingActionButton(
                                        onPressed: () {
                                          if (selectedContentId != null) {
                                            fetchAndPlayVideo(selectedContentId!);
                                          }
                                        },
                                        backgroundColor: Colors.black54,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Center(
                                              child: Text(
                                                fabTitle ?? '',
                                                style: TextStyle(
                                                  color: _isFabFocused
                                                      ? Color.fromARGB(255, 106, 235, 20)
                                                      : Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18.0,
                                                ),
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
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: MediaQuery.of(context).size.height * 0.1,
                            color: Colors.black.withOpacity(0.5),
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: bannerList.length,
                              itemBuilder: (context, index) {
                                final banner = bannerList[index];
                                return Focus(
                                  focusNode: _smallBannerFocusNodes[index],
                                  onKey: (FocusNode node, RawKeyEvent event) {
                                    if (event is RawKeyDownEvent) {
                                      if (event.logicalKey == LogicalKeyboardKey.select) {
                                        _scrollToSmallBanner(index); // Scroll to the selected small banner
                                        return KeyEventResult.handled;
                                      }
                                    }
                                    return KeyEventResult.ignored;
                                  },
                                  onFocusChange: (bool focused) {
                                    setState(() {
                                      _isSmallBannerFocused = focused;
                                      if (focused) {
                                        _focusedSmallBannerIndex = index;
                                      }
                                    });
                                  },
                                  child: GestureDetector(
                                    onTap: () {
                                      _scrollToSmallBanner(index); // Scroll to the selected small banner
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.all(8.0),
                                      width: MediaQuery.of(context).size.width * 0.1,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: _isSmallBannerFocused && _focusedSmallBannerIndex == index
                                              ? const Color.fromARGB(255, 136, 51, 122)// Change border color to red when focused
                                              : Colors.transparent,
                                          width: _pageController.page?.round() == index ? 1.0 : 6.0,
                                        ),
                                      ),
                                      child: Image.network(
                                        banner['banner'],
                                        fit: BoxFit.cover,
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
