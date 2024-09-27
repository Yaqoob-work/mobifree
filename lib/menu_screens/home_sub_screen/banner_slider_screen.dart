import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as https;
import '../../main.dart';
import '../../video_widget/video_movie_screen.dart';

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
  FocusNode _buttonFocusNode = FocusNode();
  bool _isButtonFocused = false;
  bool _isPageViewBuilt = false;
  bool _isNavigating = false;
    FocusNode _emptytextFocusNode = FocusNode();
  bool _isemptytextFocusNode = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    fetchBanners();
    _emptytextFocusNode.addListener(_onemptytextFocusNode);
    setState(() {
      _isPageViewBuilt = true;
    });
    _startAutoSlide();
    _buttonFocusNode.addListener(_onButtonFocusNode);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer.cancel();
    _emptytextFocusNode.dispose();
    _buttonFocusNode.dispose();
    super.dispose();
  }

    void _onemptytextFocusNode() {
    setState(() {
      _isemptytextFocusNode = _emptytextFocusNode.hasFocus;
    });
  }

  void _onButtonFocusNode() {
    setState(() {
      _isButtonFocused = _buttonFocusNode.hasFocus;
    });
  }
void _startAutoSlide() {
  // Only start the auto-slide if there are banners
  if (bannerList.isNotEmpty) {
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      // Check if we're at the last page
      if (_pageController.page == bannerList.length - 1) {
        _pageController.jumpToPage(0); // Directly jump to the first page
      } else {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
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
        bannerList = responseData
            .where((banner) => banner['status'] == "1")
            .map((banner) {
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

      // Start auto-slide after banners are fetched
      _startAutoSlide();
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
          if (_isNavigating) return;
          _isNavigating = true; 

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
      duration: const Duration(milliseconds: 300),
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
          ? Center(
              child: SpinKitFadingCircle(
                color: borderColor,
                size: 50.0,
              ),
            )
          : errorMessage.isNotEmpty
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('Something Went Wrong',
                        style: TextStyle(fontSize: 20)),
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
                              
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 1),
                                  width:
                                      MediaQuery.of(context).size.width,
                                  child: CachedNetworkImage(
                                    imageUrl: banner['banner'] ?? localImage,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) =>
                                        localImage ,
                                  ),
                                ),
                                 Positioned(
                                  top: 0,
                                  child: Focus(
                                    focusNode: _emptytextFocusNode,
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
                                  top: MediaQuery.of(context).size.height * 0.3,
                                  left: MediaQuery.of(context).size.width * 0.1,
                                  child: Focus(
                                    focusNode: _buttonFocusNode,
                                    onFocusChange: (hasFocus) {
                                      setState(() {
                                        _isButtonFocused = hasFocus;
                                      });
                                    },
                                    onKeyEvent: (node, event) {
                                      if (event is KeyDownEvent &&
                                          event.logicalKey ==
                                              LogicalKeyboardKey.select) {
                                        if (selectedContentId != null) {
                                          fetchAndPlayVideo(
                                              selectedContentId!);
                                        }
                                        return KeyEventResult.handled;
                                      }
                                      return KeyEventResult.ignored;
                                    },
                                    child: ElevatedButton(
                                      onPressed: () {
                                        if (selectedContentId != null) {
                                          fetchAndPlayVideo(
                                              selectedContentId!);
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _isButtonFocused
                                            ? borderColor
                                            : hintColor,
                                      ),
                                      child: const Text(
                                        'Watch Now',
                                        style: TextStyle(
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
    );
  }
}
