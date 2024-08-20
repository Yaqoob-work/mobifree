import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as https;
import 'package:mobi_tv_entertainment/main.dart';
import '../video_widget/video_movie_screen.dart';

class BannerSlider extends StatefulWidget {
  @override
  _BannerSliderState createState() => _BannerSliderState();
}

class _BannerSliderState extends State<BannerSlider> {
  List<dynamic> bannerList = [];
  bool isLoading = true;
  String errorMessage = '';
  late PageController _pageController;
  late Timer _timer;
  String? selectedContentId;
  FocusNode _bannerFocusNode = FocusNode();
  bool _isBannerFocused = false;
  bool _isPageViewBuilt = false;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    fetchBanners();
    setState(() {
      _isPageViewBuilt = true;
    });
    _startAutoSlide();
    _bannerFocusNode.addListener(_onBannerFocusNode);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer.cancel();
    _bannerFocusNode.dispose();
    super.dispose();
  }

  void _onBannerFocusNode() {
    setState(() {
      _isBannerFocused = _bannerFocusNode.hasFocus;
    });
  }




void _startAutoSlide() {
  if (_isPageViewBuilt) {
    _timer = Timer.periodic(Duration(seconds: 4), (Timer timer) {
      // Check if we're at the last page
      if (_pageController.page == bannerList.length - 1) {
        
          _pageController.jumpToPage(0); // Directly jump to the first page
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
    final response = await https.get(
      Uri.parse('https://api.ekomflix.com/android/getCustomImageSlider'),
      headers: {
        'x-api-key': 'vLQTuPZUxktl5mVW',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> responseData = json.decode(response.body);

      setState(() {
        // Filter banners based on the "status" field
        bannerList = responseData.where((banner) => banner['status'] == "1").map((banner) {
          return {
            'content_id': banner['content_id'] ?? '',
            'banner': banner['banner'] ?? localImage,
            'title': banner['title'] ?? 'No Title',
          };
        }).toList();

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
      final response = await https.get(
        Uri.parse('https://api.ekomflix.com/android/getFeaturedLiveTV'),
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
          if (_isNavigating) return; // Check if navigation is already in progress
          _isNavigating = true; // Set the flag to true

          final videoUrl = filteredData['url'] ?? '';
          if (filteredData['stream_type'] == 'YoutubeLive' ||
              filteredData['type'] == 'Youtube') {
            final response = await https.get(
              Uri.parse('https://test.gigabitcdn.net/yt-dlp.php?v=' +
                  filteredData['url']!),
              headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
            );
            if (response.statusCode == 200) {
              filteredData['url'] = json.decode(response.body)['url'];
              filteredData['stream_type'] = "M3u8";
            } else {
              throw Exception('Failed to load networks');
            }
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoMovieScreen(
                videoUrl: videoUrl,
                videoTitle: filteredData['title'] ?? 'No Title',
                channelList: [],
                videoType: '',
                videoBanner: '',
                onFabFocusChanged: (bool focused) {},
                genres: '',
                url: '',
                type: '',
              ),
            ),
          ).then((_) {
            // Reset the flag after the navigation is completed
            _isNavigating = false;
          });
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

  void _scrollToBanner(int index) {
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
      backgroundColor: cardColor,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('Something Went Wrong', style: TextStyle(fontSize: 20)),
                  ],
                )
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
                              alignment: AlignmentDirectional.topCenter,
                              children: [
                                Container(
                                  margin: EdgeInsets.only(top: 10),
                                  width: MediaQuery.of(context).size.width * 0.7,
                                  child: GestureDetector(
                                    onTap: () {
                                      if (selectedContentId != null) {
                                        fetchAndPlayVideo(selectedContentId!);
                                      }
                                    },
                                    child: Focus(
                                      focusNode: _bannerFocusNode,
                                      onFocusChange: (hasFocus) {
                                        setState(() {
                                          _isBannerFocused = hasFocus;
                                        });
                                      },
                                      onKeyEvent: (node, event) {
                                        if (event is KeyDownEvent &&
                                            event.logicalKey ==
                                                LogicalKeyboardKey.select) {
                                          if (selectedContentId != null) {
                                            fetchAndPlayVideo(selectedContentId!);
                                          }
                                          return KeyEventResult.handled;
                                        }
                                        return KeyEventResult.ignored;
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: _isBannerFocused
                                                ? borderColor
                                                : Colors.transparent,
                                            width: 3.0,
                                          ),
                                        ),
                                        child: CachedNetworkImage(
                                          imageUrl: banner['banner'] ?? localImage,
                                          fit: BoxFit.cover,
                                          // width: screenwdt,
                                          placeholder: (context, url) =>
                                              localImage,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // Positioned(
                                //   top: screenhgt * 0.11,
                                //   left: screenwdt * 0.1,
                                //   child: Container(
                                //     padding: const EdgeInsets.symmetric(
                                //         horizontal: 10.0, vertical: 5.0),
                                //     child: Text(
                                //       (banner['title'] ?? '')
                                //           .toString()
                                //           .toUpperCase(),
                                //       style: TextStyle(
                                //         color: hintColor,
                                //         fontSize: 30.0,
                                //         fontWeight: FontWeight.bold,
                                //       ),
                                //     ),
                                //   ),
                                // ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
    );
  }
}
