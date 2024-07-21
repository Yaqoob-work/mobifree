import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mobi_tv_entertainment/main.dart';
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
  FocusNode _bigBannerFocusNode = FocusNode();
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
    _bigBannerFocusNode.addListener(_onBigBannerFocusChange);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer.cancel();
    _fabFocusNode.dispose();
    _bigBannerFocusNode.dispose();
    _smallBannerFocusNodes.forEach((node) => node.dispose());
    super.dispose();
  }

  void _onFabFocusChange() {
    setState(() {
      _isFabFocused = _fabFocusNode.hasFocus;
    });
  }

  void _onBigBannerFocusChange() {
    setState(() {});
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
                  : FocusTraversalGroup(
                    policy: WidgetOrderTraversalPolicy(),
                    child: Stack(
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
                              return Focus(
                                focusNode: _bigBannerFocusNode,
                                onKeyEvent : (FocusNode node, KeyEvent event) {
                                  if (event is KeyDownEvent ) {
                                    if (event.logicalKey == LogicalKeyboardKey.select) {
                                      if (selectedContentId != null) {
                                        fetchAndPlayVideo(selectedContentId!);
                                      }
                                      return KeyEventResult.handled;
                                    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft || 
                                               event.logicalKey == LogicalKeyboardKey.arrowRight) {
                                      _smallBannerFocusNodes[_focusedSmallBannerIndex].requestFocus();
                                      return KeyEventResult.handled;
                                    }
                                  }
                                  return KeyEventResult.ignored;
                                },
                                child: AnimatedOpacity(
                                  opacity: _bigBannerFocusNode.hasFocus ? 0.8 : 1.0,
                                  duration: Duration(milliseconds: 300),
                                  child: Stack(
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
                                              color: AppColors.highlightColor,
                                              fontSize: 40.0,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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
                                    onKeyEvent : (FocusNode node, KeyEvent event) {
                                      if (event is KeyDownEvent ) {
                                        if (event.logicalKey == LogicalKeyboardKey.select) {
                                          if (selectedContentId != null) {
                                            fetchAndPlayVideo(selectedContentId!);
                                          }
                                          return KeyEventResult.handled;
                                        }
                                      }
                                      return KeyEventResult.ignored;
                                    },
                                    child: AnimatedContainer(
                                      duration: Duration(milliseconds: 200),
                                      decoration: BoxDecoration(
                                        color: _isFabFocused ? Colors.white :AppColors.hintColor,
                                        borderRadius: BorderRadius.circular(20.0),
                                      ),
                                      child: FloatingActionButton.extended(
                                        heroTag: 'playButton',
                                        onPressed: () {
                                          if (selectedContentId != null) {
                                            fetchAndPlayVideo(selectedContentId!);
                                          }
                                        },
                                        label: Text(
                                          fabTitle ?? '',
                                          style: TextStyle(
                                            color: _isFabFocused ?  AppColors.primaryColor: AppColors.highlightColor,
                                            fontSize: 20.0,
                                          ),
                                        ),
                                        backgroundColor: Colors.transparent,
                                        elevation: 0,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          Positioned(
                            bottom: MediaQuery.of(context).size.height * 0.02,
                            left: 0.0,
                            right: 0.0,
                            child: SizedBox(
                              height: 50,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: bannerList.length,
                                itemBuilder: (context, index) {
                                  final banner = bannerList[index];
                                  return Focus(
                                    focusNode: _smallBannerFocusNodes[index],
                                    onKeyEvent : (FocusNode node, KeyEvent event) {
                                      if (event is KeyDownEvent ) {
                                        if (event.logicalKey == LogicalKeyboardKey.select ||
                                            event.logicalKey == LogicalKeyboardKey.enter) {
                                          _scrollToSmallBanner(index);
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
                                        _scrollToSmallBanner(index);
                                      },
                                      child: AnimatedContainer(
                                        duration: Duration(milliseconds: 200),
                                        margin: EdgeInsets.symmetric(horizontal: 4.0),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: _focusedSmallBannerIndex == index
                                                ? AppColors.primaryColor
                                                : Colors.transparent,
                                            width: 3.0,
                                          ),
                                        ),
                                        child: Image.network(
                                          banner['banner'],
                                          fit: BoxFit.cover,
                                          width: 80,
                                          height: 50,
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
                  ),
    );
  }
}


