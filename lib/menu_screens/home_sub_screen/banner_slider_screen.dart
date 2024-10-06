import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as https;
import '../../main.dart';
import '../../video_widget/video_movie_screen.dart';
import '../../video_widget/socket_service.dart';
import '../../widgets/utils/random_light_color_widget.dart';

// Helper function to generate random light colors
Color generateRandomLightColor() {
  Random random = Random();
  int red = random.nextInt(156) + 100; // Red values between 100 and 255
  int green = random.nextInt(156) + 100; // Green values between 100 and 255
  int blue = random.nextInt(156) + 100; // Blue values between 100 and 255

  return Color.fromRGBO(
      red, green, blue, 1.0); // Full opacity for vibrant colors
}

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
  bool _isNavigating = false;
  Color? _currentFocusColor;
  final SocketService _socketService = SocketService();
  final int _maxRetries = 3;
  final int _retryDelay = 5; // seconds

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _socketService.initSocket(); // Initialize SocketService
    fetchBanners();
    _startAutoSlide();
    _buttonFocusNode.addListener(_onButtonFocusNode);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer.cancel();
    _buttonFocusNode.dispose();
    _socketService.dispose(); // Dispose of the SocketService
    super.dispose();
  }

  void _onButtonFocusNode() {
    setState(() {
      _isButtonFocused = _buttonFocusNode.hasFocus;
      if (_isButtonFocused) {
        _currentFocusColor =
            generateRandomLightColor(); // Generate the color once when focused
      }
    });
  }

  void _startAutoSlide() {
    if (bannerList.isNotEmpty) {
      _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
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
    if (_isNavigating) return; // Prevent duplicate navigation
    _isNavigating = true;

    bool shouldPlayVideo = true;
    bool shouldPop = true;

    // Show loading indicator while video is loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async {
            shouldPlayVideo = false;
            shouldPop = false;
            return true;
          },
          child: SpinKitFadingCircle(
            color: borderColor,
            size: 50.0,
          ),
        );
      },
    );

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
          String videoUrl = filteredData['url'] ?? '';

          // Check if it's a YouTube video
          if (filteredData['stream_type'] == 'YoutubeLive' ||
              filteredData['type'] == 'Youtube') {
            for (int i = 0; i < _maxRetries; i++) {
              try {
                videoUrl = await _socketService.getUpdatedUrl(videoUrl);
                filteredData['url'] = videoUrl;
                filteredData['stream_type'] = "M3u8";
                break; // Exit loop when URL is successfully updated
              } catch (e) {
                if (i == _maxRetries - 1)
                  rethrow; // Rethrow error on last retry
                await Future.delayed(
                    Duration(seconds: _retryDelay)); // Delay before next retry
              }
            }
          }

          if (shouldPop) {
            Navigator.of(context, rootNavigator: true)
                .pop(); // Close the loading dialog
          }

          if (shouldPlayVideo) {
            // Navigate to VideoPlayer Screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VideoMovieScreen(
                  videoUrl: filteredData['url'],
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
          }
        } else {
          throw Exception('Video not found');
        }
      } else {
        throw Exception('Failed to load featured live TV');
      }
    } catch (e) {
      if (shouldPop) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Something Went Wrong: ${e.toString()}')),
      );
    } finally {
      _isNavigating = false;
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
                              alignment: AlignmentDirectional.topCenter,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 1),
                                  width: screenwdt,
                                  height: screenhgt,
                                  child: CachedNetworkImage(
                                    imageUrl: banner['banner'] ?? localImage,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => localImage,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        // Watch Now button positioned at the left with some top spacing
                        // Left alignment
                        Positioned(
                          top: screenhgt *
                              0.01, // Space from the top of the image
                          left: screenwdt * 0.02, // Left alignment
                          child: Container(
                            width: _isButtonFocused
                                ? null
                                : screenwdt, // Full width to capture focus
                            child: Focus(
                              focusNode: _buttonFocusNode,
                              onFocusChange: (hasFocus) {
                                setState(() {
                                  _isButtonFocused = hasFocus;
                                  _currentFocusColor =
                                      generateRandomLightColor();
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
                              child: GestureDetector(
                                onTap: () {
                                  if (selectedContentId != null) {
                                    fetchAndPlayVideo(selectedContentId!);
                                  }
                                },
                                child: Align(
                                  alignment: Alignment
                                      .centerLeft, // Align button to the left
                                  child: Column(
                                    children: [
                                      SizedBox(
                                        height: screenhgt * 0.1,
                                      ),
                                      RandomLightColorWidget(
                                        hasFocus: _isButtonFocused,
                                        childBuilder: (Color randomColor) {
                                          return Container(
                                            padding: EdgeInsets.symmetric(
                                                vertical: screenhgt * 0.02,
                                                horizontal: screenwdt * 0.02),
                                            decoration: BoxDecoration(
                                              color: Colors.black,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: _isButtonFocused
                                                  ? Border.all(
                                                      color: randomColor,
                                                      width: 2.0,
                                                    )
                                                  : Border.all(
                                                      color: Colors.transparent,
                                                      width: 2.0,
                                                    ),
                                              boxShadow: _isButtonFocused
                                                  ? [
                                                      BoxShadow(
                                                        color: randomColor,
                                                        blurRadius: 15.0,
                                                        spreadRadius: 5.0,
                                                      ),
                                                    ]
                                                  : [],
                                            ),
                                            child: Text(
                                              'Watch Now',
                                              style: TextStyle(
                                                fontSize: menutextsz,
                                                color: _isButtonFocused
                                                    ? randomColor
                                                    : hintColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }
}
