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
  List<FocusNode> _smallBannerFocusNodes = [];
  bool _isSmallBannerFocused = false;
  int _focusedSmallBannerIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    fetchBanners();
    _startAutoSlide();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer.cancel();
    _smallBannerFocusNodes.forEach((node) => node.dispose());
    super.dispose();
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
              'title': banner['title'] ?? 'No Title',
            };
          }).toList();

          _smallBannerFocusNodes = List.generate(bannerList.length, (_) => FocusNode());

          fabTitle = bannerList.isNotEmpty ? bannerList[0]['title'] : null;
          selectedContentId = bannerList.isNotEmpty ? bannerList[0]['content_id'].toString() : null;
          isLoading = false;

          WidgetsBinding.instance!.addPostFrameCallback((_) {
            if (mounted) {
              FocusScope.of(context).requestFocus(_smallBannerFocusNodes[0]);
            }
          });
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
          final videoUrl = filteredData['url'];
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoScreen(
                url: videoUrl,
                videoUrl: videoUrl,
                videoTitle: filteredData['title'] ?? 'No Title',
                channelList: [],
                onFabFocusChanged: (bool focused) {},
                genres: '',
                playUrl: '',
                playVideo: (String id) {},
                id: '', channels: [], initialIndex: 1, 
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
          ? Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text('Error: $errorMessage'))
              : bannerList.isEmpty
                  ? Center(child: Text('No banners found'))
                  : Stack(
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (selectedContentId != null) {
                              fetchAndPlayVideo(selectedContentId!);
                            }
                          },
                          child: PageView.builder(
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
                                    child: Image.network(
                                      banner['banner'],
                                      fit: BoxFit.cover,
                                      width: MediaQuery.of(context).size.width,
                                    ),
                                  ),
                                  Positioned(
                                    top: 30.0,
                                    left: 30.0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                                      child: Text(
                                        banner['title'] ?? 'No Title',
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
                                  onKeyEvent: (FocusNode node, KeyEvent event) {
                                    if (event is KeyDownEvent) {
                                      if (event.logicalKey == LogicalKeyboardKey.select) {
                                        fetchAndPlayVideo(banner['content_id'].toString()); // Play video on center button press
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
                                    child: Container(
                                      margin: const EdgeInsets.all(8.0),
                                      width: MediaQuery.of(context).size.width * 0.1,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: _isSmallBannerFocused && _focusedSmallBannerIndex == index
                                              ? const Color.fromARGB(255, 136, 51, 122)
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
