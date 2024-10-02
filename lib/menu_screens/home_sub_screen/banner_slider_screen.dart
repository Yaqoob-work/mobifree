// import 'dart:async';
// import 'dart:convert';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_spinkit/flutter_spinkit.dart';
// import 'package:http/http.dart' as https;
// import '../../main.dart';
// import '../../menu_two_items/music_screen.dart';
// import '../../video_widget/video_movie_screen.dart';

// class BannerSlider extends StatefulWidget {
//   @override
//   _BannerSliderState createState() => _BannerSliderState();
// }

// class _BannerSliderState extends State<BannerSlider> {
//   List<dynamic> bannerList = [];
//   bool isLoading = true;
//   String errorMessage = '';
//   late PageController _pageController;
//   late Timer _timer;
//   String? selectedContentId;
//   FocusNode _buttonFocusNode = FocusNode();
//   bool _isButtonFocused = false;
//   bool _isPageViewBuilt = false;
//   bool _isNavigating = false;
//   FocusNode _emptytextFocusNode = FocusNode();
//   bool _isemptytextFocusNode = false;

//   @override
//   void initState() {
//     super.initState();
//     _pageController = PageController();
//     fetchBanners();
//     _emptytextFocusNode.addListener(_onemptytextFocusNode);
//     setState(() {
//       _isPageViewBuilt = true;
//     });
//     _startAutoSlide();
//     _buttonFocusNode.addListener(_onButtonFocusNode);
//   }

//   @override
//   void dispose() {
//     _pageController.dispose();
//     _timer.cancel();
//     _emptytextFocusNode.dispose();
//     _buttonFocusNode.dispose();
//     super.dispose();
//   }

//   void _onemptytextFocusNode() {
//     setState(() {
//       _isemptytextFocusNode = _emptytextFocusNode.hasFocus;
//     });
//   }

//   void _onButtonFocusNode() {
//     setState(() {
//       _isButtonFocused = _buttonFocusNode.hasFocus;
//     });
//   }

//   void _startAutoSlide() {
//     // Only start the auto-slide if there are banners
//     if (bannerList.isNotEmpty) {
//       _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
//         // Check if we're at the last page
//         if (_pageController.page == bannerList.length - 1) {
//           _pageController.jumpToPage(0); // Directly jump to the first page
//         } else {
//           _pageController.nextPage(
//             duration: const Duration(milliseconds: 300),
//             curve: Curves.easeIn,
//           );
//         }
//       });
//     }
//   }

//   Future<void> fetchBanners() async {
//     try {
//       final response = await https.get(
//         Uri.parse('https://api.ekomflix.com/android/getCustomImageSlider'),
//         headers: {
//           'x-api-key': 'vLQTuPZUxktl5mVW',
//         },
//       );

//       if (response.statusCode == 200) {
//         final List<dynamic> responseData = json.decode(response.body);

//         setState(() {
//           // Filter banners based on the "status" field
//           bannerList = responseData
//               .where((banner) => banner['status'] == "1")
//               .map((banner) {
//             return {
//               'content_id': banner['content_id'] ?? '',
//               'banner': banner['banner'] ?? localImage,
//               'title': banner['title'] ?? 'No Title',
//             };
//           }).toList();

//           selectedContentId = bannerList.isNotEmpty
//               ? bannerList[0]['content_id'].toString()
//               : null;
//           isLoading = false;
//         });

//         // Start auto-slide after banners are fetched
//         _startAutoSlide();
//       } else {
//         throw Exception('Failed to load banners');
//       }
//     } catch (e) {
//       setState(() {
//         errorMessage = e.toString();
//         isLoading = false;
//       });
//     }
//   }

//   Future<void> fetchAndPlayVideo(String contentId) async {
//     try {
//       final response = await https.get(
//         Uri.parse('https://api.ekomflix.com/android/getFeaturedLiveTV'),
//         headers: {
//           'x-api-key': 'vLQTuPZUxktl5mVW',
//         },
//       );

//       if (response.statusCode == 200) {
//         final List<dynamic> responseData = json.decode(response.body);
//         final filteredData = responseData.firstWhere(
//           (channel) => channel['id'].toString() == contentId,
//           orElse: () => null,
//         );

//         if (filteredData != null) {
//           if (_isNavigating) return;
//           _isNavigating = true;

//           final videoUrl = filteredData['url'] ?? '';
//           if (filteredData['stream_type'] == 'YoutubeLive' ||
//               filteredData['type'] == 'Youtube') {
//             final response = await https.get(
//               Uri.parse('https://test.gigabitcdn.net/yt-dlp.php?v=' +
//                   filteredData['url']!),
//               headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
//             );
//             if (response.statusCode == 200) {
//               filteredData['url'] = json.decode(response.body)['url'];
//               filteredData['stream_type'] = "M3u8";
//             } else {
//               throw Exception('Failed to load networks');
//             }
//           }
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => VideoMovieScreen(
//                 videoUrl: videoUrl,
//                 videoTitle: filteredData['title'] ?? 'No Title',
//                 channelList: [],
//                 videoType: '',
//                 videoBanner: '',
//                 onFabFocusChanged: (bool focused) {},
//                 genres: '',
//                 url: '',
//                 type: '',
//               ),
//             ),
//           ).then((_) {
//             _isNavigating = false;
//           });
//         } else {
//           throw Exception('Video not found');
//         }
//       } else {
//         throw Exception('Failed to load featured live TV');
//       }
//     } catch (e) {
//       setState(() {
//         errorMessage = e.toString();
//       });
//     }
//   }

//   void _scrollToBanner(int index) {
//     _pageController.animateToPage(
//       index,
//       duration: const Duration(milliseconds: 300),
//       curve: Curves.easeIn,
//     );
//     setState(() {
//       selectedContentId = bannerList[index]['content_id'].toString();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: cardColor,
//       body: isLoading
//           ? Center(
//               child: SpinKitFadingCircle(
//                 color: borderColor,
//                 size: 50.0,
//               ),
//             )
//           : errorMessage.isNotEmpty
//               ? const Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: [
//                     Text('Something Went Wrong',
//                         style: TextStyle(fontSize: 20)),
//                   ],
//                 )
//               : bannerList.isEmpty
//                   ? const Center(child: Text('No banners found'))
//                   : Stack(
//                       children: [
//                         PageView.builder(
//                           controller: _pageController,
//                           itemCount: bannerList.length,
//                           onPageChanged: (index) {
//                             setState(() {
//                               selectedContentId =
//                                   bannerList[index]['content_id'].toString();
//                             });
//                           },
//                           itemBuilder: (context, index) {
//                             final banner = bannerList[index];
//                             return Stack(
//                               alignment: AlignmentDirectional.topCenter,
//                               children: [
//                                 Container(
//                                   margin: const EdgeInsets.only(top: 1),
//                                   width: screenwdt,
//                                   height: screenhgt,
//                                   child: CachedNetworkImage(
//                                     imageUrl: banner['banner'] ?? localImage,
//                                     fit: BoxFit.cover,
//                                     placeholder: (context, url) => localImage,
//                                   ),
//                                 ),
//                               ],
//                             );
//                           },
//                         ),

//                         Positioned(
//                           top: 0,
//                           child: Focus(
//                             focusNode: _emptytextFocusNode,
//                             onFocusChange: (hasFocus) {
//                               setState(() {
//                                 _isemptytextFocusNode = hasFocus;
//                               });
//                             },
//                             child: Container(
//                               child: Text(''),
//                             ),
//                           ),
//                         ),
//                         Positioned(
//                           top: screenhgt * 0.1,
//                           left: screenwdt *  0.05,
//                           child: Focus(
//                             focusNode: _buttonFocusNode,
//                             onFocusChange: (hasFocus) {
//                               setState(() {
//                                 _isButtonFocused = hasFocus;
//                               });
//                             },
//                             onKeyEvent: (node, event) {
//                               if (event is KeyDownEvent &&
//                                   event.logicalKey ==
//                                       LogicalKeyboardKey.select) {
//                                 if (selectedContentId != null) {
//                                   fetchAndPlayVideo(selectedContentId!);
//                                 }
//                                 return KeyEventResult.handled;
//                               }
//                               return KeyEventResult.ignored;
//                             },
//                             child: ElevatedButton(
//                               onPressed: () {
//                                 if (selectedContentId != null) {
//                                   fetchAndPlayVideo(selectedContentId!);
//                                 }
//                               },
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor:
//                                     _isButtonFocused ? borderColor : Colors.black,
//                               ),
//                               child:  Text(
//                                 'Watch Now',
//                                 style: TextStyle(
//                                   color: hintColor ,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                         // Positioned(
//                         //   top: screenhgt * 0.45, // Adjust this value as needed
//                         //   left: 0,
//                         //   right: 0,
//                         //   child: Container(
//                         //     color: Colors.transparent,
//                         //     child: SizedBox(
//                         //       height: screenhgt * 0.45,
//                         //       child: MusicScreen(),
//                         //     ),
//                         //   ),
//                         // ),
//                       ],
//                     ),
//     );
//   }
// }






import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as https;
import '../../main.dart';
import '../../menu_two_items/music_screen.dart';
import '../../video_widget/video_movie_screen.dart';

// Helper function to generate random light colors (reuse from the navigation bar)
Color generateRandomLightColor() {
  Random random = Random();
  int red = random.nextInt(156) + 100;   // Red values between 100 and 255
  int green = random.nextInt(156) + 100; // Green values between 100 and 255
  int blue = random.nextInt(156) + 100;  // Blue values between 100 and 255

  return Color.fromRGBO(red, green, blue, 1.0); // Full opacity for vibrant colors
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
                          top: screenhgt * 0.1,
                          left: screenwdt * 0.02,
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
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 20),
                                decoration: BoxDecoration(
                                  color:  Colors.black, // Black when not focused
                                  borderRadius: BorderRadius.circular(8),
                                  border: _isButtonFocused? Border.all(
                                    color: generateRandomLightColor(),
                                    width:2.0,)
                                        : 
                                        Border.all(
                                    color:_isButtonFocused?Colors.black:const Color.fromARGB(0, 0, 0, 0) ,
                                    width: 2.0,
                                  ),
                                  boxShadow: _isButtonFocused
                                      ? [
                                          BoxShadow(
                                            color: generateRandomLightColor()
                                                .withOpacity(0.8),
                                            blurRadius: 15.0,
                                            spreadRadius: 5.0,
                                          ),
                                        ]
                                      : [],
                                ),
                                child:  Text(
                                  'Watch Now',
                                  style: TextStyle(
                                    fontSize: menutextsz,
                                    color: _isButtonFocused
                                      ? generateRandomLightColor()
                                      : hintColor, 
                                    fontWeight: FontWeight.bold,
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
