// import 'dart:async';
// import 'dart:convert';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_spinkit/flutter_spinkit.dart';
// import 'package:http/http.dart' as https;
// import 'package:shared_preferences/shared_preferences.dart';
// import '../../main.dart';
// import '../../video_widget/video_movie_screen.dart';
// import '../../video_widget/socket_service.dart';
// import '../../video_widget/vlc_player_screen.dart';
// import '../../widgets/utils/color_service.dart';
// import '../../widgets/utils/random_light_color_widget.dart';

// class BannerSlider extends StatefulWidget {
//   // final double initialHeight;
//   // final double initialWidth;
//   // final Function(double) onHeightChange; // Add a callback for height change
//   // final Function(double) onWidthChange; // Add a callback for height change

//   // BannerSlider(
//   //     {required this.initialHeight,
//   //     required this.onHeightChange,
//   //     required this.initialWidth,
//   //     required this.onWidthChange}); // Modify constructor
//   @override
//   _BannerSliderState createState() => _BannerSliderState();
// }

// class _BannerSliderState extends State<BannerSlider> with WidgetsBindingObserver{
//   List<dynamic> bannerList = [];
//   Map<String, Color> bannerColors = {};
//   bool isLoading = true;
//   String errorMessage = '';
//   late PageController _pageController;
//     Timer? _timer;
//   String? selectedContentId;
//   FocusNode _buttonFocusNode = FocusNode();
//   bool _isButtonFocused = false;
//   bool _isNavigating = false;
//   Color? _currentFocusColor;
//   final SocketService _socketService = SocketService();
//   final int _maxRetries = 3;
//   final int _retryDelay = 5; // seconds
//   final PaletteColorService _paletteColorService =
//       PaletteColorService(); // PaletteColorService instance
//   // late double _currentHeight; // Initial height
//   // late double _currentWidth; // Initial height

//   @override
//   void initState() {
//     super.initState();
//     _pageController = PageController();
//     _socketService.initSocket(); // Initialize SocketService
//     _buttonFocusNode.addListener(_onButtonFocusNode);
//     WidgetsBinding.instance.addObserver(this); // Add observer for app lifecycle changes
//     _initializeData();
//   }

//   @override
//   void dispose() {
//      WidgetsBinding.instance.removeObserver(this); // Remove observer when the widget is disposed

//     _pageController.dispose();
//       if (_timer != null && _timer!.isActive) {
//     _timer?.cancel();
//   }
//     _buttonFocusNode.dispose();
//     _socketService.dispose(); // Dispose of the SocketService
//     super.dispose();
//   }

//     @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.resumed) {
//       // When the app returns to the foreground, ensure banner initialization
//       _loadCachedDataAndFetchBanners(); // Re-fetch the banners
//     }
//   }

// Future<void> _initializeData() async {
//     try {
//       await _loadCachedDataAndFetchBanners();
//     } catch (e) {
//       print('Error initializing data: $e');
//       setState(() {
//         isLoading = false;
//         errorMessage = 'Failed to initialize data';
//       });
//     }
//   }

//   Future<void> _loadCachedDataAndFetchBanners() async {
//     setState(() {
//       isLoading = true;
//       errorMessage = ''; // Clear any previous errors
//     });

//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final cachedData = prefs.getString('banners');

//       // First try to load cached data
//       if (cachedData != null) {
//         final decodedData = json.decode(cachedData);
//         _updateBannerList(decodedData);
//       }

//       // Then fetch fresh data from API
//       final response = await https.get(
//         Uri.parse('https://api.ekomflix.com/android/getCustomImageSlider'),
//         headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
//       );

//       if (response.statusCode == 200) {
//         final freshData = json.decode(response.body);

//         // Update cache with new data
//         await prefs.setString('banners', json.encode(freshData));

//         // Update UI with new data
//         _updateBannerList(freshData);
//       } else {
//         throw Exception('Failed to fetch banners: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('Error loading banners: $e');
//       // Only show error if we have no cached data
//       if (bannerList.isEmpty) {
//         setState(() {
//           errorMessage = 'Failed to load banners';
//         });
//       }
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   void _updateBannerList(List<dynamic> data) {
//     setState(() {
//       bannerList = data.where((banner) => banner['status'] == "1").map((banner) {
//         return {
//           'content_id': banner['content_id'] ?? '',
//           'banner': banner['banner'] ?? localImage,
//           'title': banner['title'] ?? 'No Title',
//         };
//       }).toList();

//       if (bannerList.isNotEmpty) {
//         selectedContentId = bannerList[0]['content_id'].toString();
//         _fetchBannerColors();
//         _startAutoSlide();
//       }
//     });
//   }

//   Future<void> _fetchBannerColors() async {
//     for (var banner in bannerList) {
//       final imageUrl = banner['banner'] ?? localImage;
//       final secondaryColor =
//           await _paletteColorService.getSecondaryColor(imageUrl);
//       setState(() {
//         bannerColors[banner['content_id']] = secondaryColor;
//       });
//     }
//   }

//   void _onButtonFocusNode() {
//     setState(() {
//       _isButtonFocused = _buttonFocusNode.hasFocus;
//       if (_isButtonFocused) {
//         _currentFocusColor = bannerColors[selectedContentId!];

//         // _currentHeight = widget.initialHeight * 1.6; // Increase height
//         // _currentWidth = widget.initialWidth * 1.6;
//       }
//     //   else {
//     //     _currentHeight = widget.initialHeight; // Reset to original height
//     //     _currentWidth = widget.initialWidth;
//     //   }
//     //   widget.onHeightChange(
//     //     _currentHeight,
//     //   ); // Call the callback to update HomeScreen height

//     //   widget.onWidthChange(
//     //       _currentWidth); // Call the callback to update HomeScreen height
//     });
//   }

// //   void _startBackgroundApiFetch() {
// //   Timer.periodic(Duration(minutes: 10), (Timer timer) async {
// //     await fetchBanners(isBackgroundFetch: true);
// //   });
// // }

//   void _startAutoSlide() {
//     _timer?.cancel(); // Cancel any existing timer
//     if (bannerList.isNotEmpty) {
//       _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
//         if (_pageController.hasClients) {
//           final nextPage = (_pageController.page?.round() ?? 0) + 1;
//           if (nextPage >= bannerList.length) {
//             _pageController.jumpToPage(0);
//           } else {
//             _pageController.animateToPage(
//               nextPage,
//               duration: const Duration(milliseconds: 300),
//               curve: Curves.easeIn,
//             );
//           }
//         }
//       });
//     }
//   }

// // Future<void> fetchBanners({bool isBackgroundFetch = false}) async {
// //   final prefs = await SharedPreferences.getInstance();
// //   final cachedBanners = prefs.getString('banners');

// //   if (cachedBanners != null && !isBackgroundFetch) {
// //     // Load banners from cache (only if not in background fetch)
// //     final List<dynamic> responseData = json.decode(cachedBanners);
// //     setState(() {
// //       bannerList = responseData
// //           .where((banner) => banner['status'] == "1")
// //           .map((banner) {
// //         return {
// //           'content_id': banner['content_id'] ?? '',
// //           'banner': banner['banner'] ?? localImage,
// //           'title': banner['title'] ?? 'No Title',
// //         };
// //       }).toList();

// //       selectedContentId = bannerList.isNotEmpty
// //           ? bannerList[0]['content_id'].toString()
// //           : null;
// //       isLoading = false;
// //     });

// //     _fetchBannerColors();
// //     _startAutoSlide();

// //     // Preload cached banner images
// //     // _precacheBannerImages();
// //   }

// //   // Fetch banners from API
// //   try {
// //     final response = await https.get(
// //       Uri.parse('https://api.ekomflix.com/android/getCustomImageSlider'),
// //       headers: {
// //         'x-api-key': 'vLQTuPZUxktl5mVW',
// //       },
// //     );

// //     if (response.statusCode == 200) {
// //       final List<dynamic> responseData = json.decode(response.body);

// //       if (cachedBanners != null) {
// //         final cachedData = json.decode(cachedBanners);
// //         if (json.encode(cachedData) == json.encode(responseData)) {
// //           // No change in API data, skip UI update
// //           return;
// //         }
// //       }

// //       setState(() {
// //         bannerList = responseData
// //             .where((banner) => banner['status'] == "1")
// //             .map((banner) {
// //           return {
// //             'content_id': banner['content_id'] ?? '',
// //             'banner': banner['banner'] ?? localImage,
// //             'title': banner['title'] ?? 'No Title',
// //           };
// //         }).toList();

// //         selectedContentId = bannerList.isNotEmpty
// //             ? bannerList[0]['content_id'].toString()
// //             : null;
// //         isLoading = false;
// //       });

// //       // Cache the new data
// //       prefs.setString('banners', response.body);

// //       _fetchBannerColors();
// //       _startAutoSlide();

// //       // Preload new banner images
// //       // _precacheBannerImages();
// //     } else {
// //       throw Exception('Failed to load banners');
// //     }
// //   } catch (e) {
// //     setState(() {
// //       errorMessage = e.toString();
// //       isLoading = false;
// //     });
// //   }
// // }

// // void _precacheBannerImages() {
// //   for (var banner in bannerList) {
// //     if (banner['banner'] != null && banner['banner'].isNotEmpty) {
// //       precacheImage(
// //         CachedNetworkImageProvider(banner['banner']), // Preload the banner image
// //         context,
// //       );
// //     }
// //   }
// // }

//   Future<void> fetchAndPlayVideo(String contentId) async {
//     if (_isNavigating) return; // Prevent duplicate navigation
//     _isNavigating = true;

//     bool shouldPlayVideo = true;
//     bool shouldPop = true;

//     // Show loading indicator while video is loading
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return WillPopScope(
//           onWillPop: () async {
//             shouldPlayVideo = false;
//             shouldPop = false;
//             return true;
//           },
//           child: SpinKitFadingCircle(
//             color: borderColor,
//             size: 50.0,
//           ),
//         );
//       },
//     );

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
//           String videoUrl = filteredData['url'] ?? '';

//           // Check if it's a YouTube video
//           if (filteredData['stream_type'] == 'YoutubeLive' ||
//               filteredData['type'] == 'Youtube') {
//             for (int i = 0; i < _maxRetries; i++) {
//               try {
//                 videoUrl = await _socketService.getUpdatedUrl(videoUrl);
//                 filteredData['url'] = videoUrl;
//                 filteredData['stream_type'] = "M3u8";
//                 break; // Exit loop when URL is successfully updated
//               } catch (e) {
//                 if (i == _maxRetries - 1)
//                   rethrow; // Rethrow error on last retry
//                 await Future.delayed(
//                     Duration(seconds: _retryDelay)); // Delay before next retry
//               }
//             }
//           }

//           if (shouldPop) {
//             Navigator.of(context, rootNavigator: true)
//                 .pop(); // Close the loading dialog
//           }

//           if (shouldPlayVideo) {
//             // Navigate to VideoPlayer Screen

//             if (filteredData['stream_type'] == 'VLC' ||
//                 filteredData['type'] == 'VLC') {
//               //   // Navigate to VLC Player screen when stream type is VLC
//               await Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => VlcPlayerScreen(
//                     videoUrl: filteredData['url'],
//                     // videoTitle: filteredData['title'] ?? 'No Title',
//                     channelList: [],
//                     genres: '',
//                     // channels: [],
//                     // initialIndex: 1,
//                     bannerImageUrl: filteredData['banner'],
//                     startAtPosition: Duration.zero,
//                     // onFabFocusChanged: (bool) {},
//                     isLive: true,
//                   ),
//                 ),
//               );
//             } else {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => VideoMovieScreen(
//                     videoUrl: filteredData['url'],
//                     videoTitle: filteredData['title'] ?? 'No Title',
//                     channelList: [],
//                     videoType: '',
//                     videoBanner: '',
//                     onFabFocusChanged: (bool focused) {},
//                     genres: '',
//                     url: '',
//                     type: '',
//                   ),
//                 ),
//               ).then((_) {
//                 _isNavigating = false;
//               });
//             }
//           }
//         } else {
//           throw Exception('Video not found');
//         }
//       } else {
//         throw Exception('Failed to load featured live TV');
//       }
//     } catch (e) {
//       if (shouldPop) {
//         Navigator.of(context, rootNavigator: true).pop();
//       }
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Something Went Wrong: ${e.toString()}')),
//       );
//     } finally {
//       _isNavigating = false;
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
//                                   child:
//                                       // CachedNetworkImage(
//                                       //   imageUrl: banner['banner'] ?? localImage,
//                                       //   fit: BoxFit.fill,
//                                       //   placeholder: (context, url) => localImage,
//                                       // ),
//                                       CachedNetworkImage(
//                                     imageUrl: banner['banner'] ?? localImage,
//                                     fit: BoxFit.fill,
//                                     placeholder: (context, url) => localImage,
//                                     errorWidget: (context, url, error) =>
//                                         Icon(Icons.error),
//                                     cacheKey: banner[
//                                         'content_id'], // Ensure cache key is unique per banner
//                                     fadeInDuration: Duration(
//                                         milliseconds:
//                                             500), // Reduce fade-in time
//                                     memCacheHeight:
//                                         800, // Limit the memory cache to save resources
//                                     memCacheWidth: 1200,
//                                   ),
//                                 ),
//                               ],
//                             );
//                           },
//                         ),
//                         // Watch Now button positioned at the left with some top spacing
//                         // Left alignment
//                         Positioned(
//                           top: screenhgt *
//                               0.01, // Space from the top of the image
//                           left: screenwdt * 0.02, // Left alignment
//                           child: Container(
//                             width: _isButtonFocused
//                                 ? null
//                                 : screenwdt, // Full width to capture focus
//                             child: Focus(
//                               focusNode: _buttonFocusNode,
//                               onFocusChange: (hasFocus) {
//                                 setState(() {
//                                   _isButtonFocused = hasFocus;
//                                   // _currentFocusColor =
//                                   _currentFocusColor;
//                                 });
//                               },
//                               onKeyEvent: (node, event) {
//                                 if (event is KeyDownEvent &&
//                                     event.logicalKey ==
//                                         LogicalKeyboardKey.select) {
//                                   if (selectedContentId != null) {
//                                     fetchAndPlayVideo(selectedContentId!);
//                                   }
//                                   return KeyEventResult.handled;
//                                 }
//                                 return KeyEventResult.ignored;
//                               },
//                               child: GestureDetector(
//                                 onTap: () {
//                                   if (selectedContentId != null) {
//                                     fetchAndPlayVideo(selectedContentId!);
//                                   }
//                                 },
//                                 child: Align(
//                                   alignment: Alignment
//                                       .centerLeft, // Align button to the left
//                                   child: Column(
//                                     children: [
//                                       SizedBox(
//                                         height: screenhgt * 0.1,
//                                       ),
//                                       RandomLightColorWidget(
//                                         hasFocus: _isButtonFocused,
//                                         childBuilder: (Color randomColor) {
//                                           return Container(
//                                             margin: EdgeInsets.all(screenwdt *
//                                                 0.001), // Reduced padding

//                                             padding: EdgeInsets.symmetric(
//                                                 vertical: screenhgt * 0.02,
//                                                 horizontal: screenwdt * 0.02),
//                                             decoration: BoxDecoration(
//                                               color: Colors.black,
//                                               borderRadius:
//                                                   BorderRadius.circular(8),
//                                               border: _isButtonFocused
//                                                   ? Border.all(
//                                                       color: randomColor,
//                                                       width: 2.0,
//                                                     )
//                                                   : Border.all(
//                                                       color: Colors.transparent,
//                                                       width: 2.0,
//                                                     ),
//                                               boxShadow: _isButtonFocused
//                                                   ? [
//                                                       BoxShadow(
//                                                         color: randomColor,
//                                                         blurRadius: 15.0,
//                                                         spreadRadius: 5.0,
//                                                       ),
//                                                     ]
//                                                   : [],
//                                             ),
//                                             child: Text(
//                                               'Watch Now',
//                                               style: TextStyle(
//                                                 fontSize: menutextsz,
//                                                 color: _isButtonFocused
//                                                     ? randomColor
//                                                     : hintColor,
//                                                 fontWeight: FontWeight.bold,
//                                               ),
//                                             ),
//                                           );
//                                         },
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//     );
//   }
// }




// import 'dart:async';
// import 'dart:convert';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_spinkit/flutter_spinkit.dart';
// import 'package:http/http.dart' as https;
// import 'package:shared_preferences/shared_preferences.dart';
// import '../../main.dart';
// import '../../video_widget/video_movie_screen.dart';
// import '../../video_widget/socket_service.dart';
// import '../../video_widget/vlc_player_screen.dart';
// import '../../widgets/utils/color_service.dart';
// import '../../widgets/utils/random_light_color_widget.dart';

// class BannerSlider extends StatefulWidget {
//   // final double initialHeight;
//   // final double initialWidth;
//   // final Function(double) onHeightChange;
//   // final Function(double) onWidthChange;

//   // BannerSlider({
//   //   required this.initialHeight,
//   //   required this.onHeightChange,
//   //   required this.initialWidth,
//   //   required this.onWidthChange,
//   // });

//   @override
//   _BannerSliderState createState() => _BannerSliderState();
// }

// class _BannerSliderState extends State<BannerSlider>
//     with WidgetsBindingObserver {
//   List<dynamic> bannerList = [];
//   Map<String, Color> bannerColors = {};
//   bool isLoading = true;
//   String errorMessage = '';
//   late PageController _pageController;
//   Timer? _timer;
//   String? selectedContentId;
//   FocusNode _buttonFocusNode = FocusNode();
//   bool _isButtonFocused = false;
//   bool _isNavigating = false;
//   Color? _currentFocusColor;
//   final SocketService _socketService = SocketService();
//   final int _maxRetries = 3;
//   final int _retryDelay = 5;
//   final PaletteColorService _paletteColorService = PaletteColorService();
//   late double _currentHeight;
//   late double _currentWidth;

//   @override
//   void initState() {
//     super.initState();

//     _pageController = PageController();
//     _socketService.initSocket();
//     _buttonFocusNode.addListener(_onButtonFocusNode);
//     WidgetsBinding.instance.addObserver(this);
//     // _currentHeight = widget.initialHeight;
//     // _currentWidth = widget.initialWidth;
//     // // Use Future.microtask to avoid initialization issues
//     // Future.microtask(() {
//     //   if (mounted) {
//     //     _initializeData();
//     //   }
//     // });
//   // Ensure initialization happens after widget is mounted
//   WidgetsBinding.instance.addPostFrameCallback((_) {
//     if (mounted) {
//       _initializeData();
//     }
//   });

//   }

//   Future<void> _initializeData() async {
//     try {
//       await _loadCachedDataAndFetchBanners();
//     } catch (e) {
//       print('Error initializing data: $e');
//       setState(() {
//         isLoading = false;
//         errorMessage = 'Failed to initialize data';
//       });
//     }
//   }



//   @override
// void didChangeAppLifecycleState(AppLifecycleState state) {
//   if (state == AppLifecycleState.resumed) {
//     if (mounted && bannerList.isEmpty) {
//       _initializeData();
//     } else {
//       _fetchFreshData(); // Just update in background if we already have data
//     }
//   }
// }

// Future<void> _loadCachedDataAndFetchBanners() async {
//   if (!mounted) return;

//   setState(() {
//     isLoading = true;
//     errorMessage = '';
//   });

//   try {
//     // Load cached data first
//     await _loadCachedData();
    
//     // Start showing cached content if available
//     if (bannerList.isNotEmpty) {
//       _startAutoSlide();
//     }

//     // Then fetch fresh data in background
//     await _fetchFreshData();
    
//   } catch (e) {
//     print('Error in _loadCachedDataAndFetchBanners: $e');
//     if (mounted && bannerList.isEmpty) {
//       setState(() {
//         errorMessage = 'Failed to load banners';
//       });
//     }
//   } finally {
//     if (mounted) {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }
// }

// Future<void> _loadCachedData() async {
//   try {
//     final prefs = await SharedPreferences.getInstance();
//     final cachedBanners = prefs.getString('banners');

//     if (cachedBanners != null) {
//       final List<dynamic> cachedData = json.decode(cachedBanners);
//       if (mounted) {
//         _updateBannerList(cachedData);
//       }
//     }
//   } catch (e) {
//     print('Error loading cached data: $e');
//   }
// }

// Future<void> _fetchFreshData() async {
//   try {
//     final response = await https.get(
//       Uri.parse('https://api.ekomflix.com/android/getCustomImageSlider'),
//       headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
//     );

//     if (response.statusCode == 200) {
//       final List<dynamic> freshData = json.decode(response.body);
      
//       // Save to cache
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setString('banners', json.encode(freshData));

//       // Update UI if data is different
//       if (mounted) {
//         final currentIds = bannerList.map((b) => b['content_id']).toSet();
//         final newIds = freshData.map((b) => b['content_id']).toSet();
        
//         if (!setEquals(currentIds, newIds)) {
//           _updateBannerList(freshData);
//         }
//       }
//     }
//   } catch (e) {
//     print('Error fetching fresh data: $e');
//   }
// }

// void _updateBannerList(List<dynamic> data) {
//   if (!mounted) return;
  
//   setState(() {
//     try {
//       bannerList = data
//           .where((banner) => 
//               banner['status'] == "1" && 
//               banner['banner'] != null && 
//               banner['banner'].toString().isNotEmpty)
//           .map((banner) => {
//                 'content_id': banner['content_id']?.toString() ?? '',
//                 'banner': banner['banner']?.toString() ?? localImage,
//                 'title': banner['title']?.toString() ?? 'No Title',
//               })
//           .toList();

//       if (bannerList.isNotEmpty) {
//         selectedContentId = bannerList[0]['content_id'].toString();
//         _fetchBannerColors();
//       }
//     } catch (e) {
//       print('Error updating banner list: $e');
//       bannerList = [];
//     }
//   });
// }

//   Future<void> fetchAndUpdateIfChanged() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final response = await https.get(
//         Uri.parse('https://api.ekomflix.com/android/getCustomImageSlider'),
//         headers: {
//           'x-api-key': 'vLQTuPZUxktl5mVW',
//         },
//       );

//       if (response.statusCode == 200) {
//         final List<dynamic> freshData = json.decode(response.body);

//         // Get the cached data
//         final cachedBanners = prefs.getString('banners');
//         if (cachedBanners != null) {
//           final List<dynamic> cachedData = json.decode(cachedBanners);

//           // Compare fresh API data with cached data
//           if (!listEquals(freshData, cachedData)) {
//             // Step 3: If data is different, update cache and UI
//             await prefs.setString('banners', json.encode(freshData));
//             _updateBannerList(freshData);
//           }
//         } else {
//           // If there's no cached data, store fresh data in cache
//           await prefs.setString('banners', json.encode(freshData));
//           _updateBannerList(freshData);
//         }
//       } else {
//         throw Exception('Failed to fetch banners: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('Error fetching banners: $e');
//     }
//   }



//   @override
//   void dispose() {
//     _timer?.cancel();
//     _pageController.dispose();
//     _buttonFocusNode.dispose();
//     _socketService.dispose();
//     WidgetsBinding.instance.removeObserver(this);
//     super.dispose();
//   }

//   Future<void> _fetchBannerColors() async {
//     for (var banner in bannerList) {
//       final imageUrl = banner['banner'] ?? localImage;
//       final secondaryColor =
//           await _paletteColorService.getSecondaryColor(imageUrl);
//       setState(() {
//         bannerColors[banner['content_id']] = secondaryColor;
//       });
//     }
//   }

//   void _onButtonFocusNode() {
//     setState(() {
//       _isButtonFocused = _buttonFocusNode.hasFocus;
//       if (_isButtonFocused) {
//         _currentFocusColor = bannerColors[selectedContentId!];
//         // _currentHeight = widget.initialHeight * 1.6;
//         // _currentWidth = widget.initialWidth * 1.6;
//       } 
//       // else {
//       //   _currentHeight = widget.initialHeight;
//       //   _currentWidth = widget.initialWidth;
//       // }
//       // widget.onHeightChange(_currentHeight);
//       // widget.onWidthChange(_currentWidth);
//     });
//   }

//   // void _startAutoSlide() {
//   //   if (bannerList.isNotEmpty) {
//   //     _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
//   //       if (_pageController.hasClients) {
//   //         final nextPage = (_pageController.page?.round() ?? 0) + 1;
//   //         if (nextPage >= bannerList.length) {
//   //           _pageController.jumpToPage(0);
//   //         } else {
//   //           _pageController.animateToPage(
//   //             nextPage,
//   //             duration: const Duration(milliseconds: 300),
//   //             curve: Curves.easeIn,
//   //           );
//   //         }
//   //       }
//   //     });
//   //   }
//   // }


//   void _startAutoSlide() {
//   _timer?.cancel(); // Cancel existing timer if any
//   if (bannerList.isNotEmpty) {
//     _timer = Timer(const Duration(seconds: 8), () {
//       _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
//         if (_pageController.hasClients) {
//           final nextPage = (_pageController.page?.round() ?? 0) + 1;
//           if (nextPage >= bannerList.length) {
//             _pageController.jumpToPage(0);
//           } else {
//             _pageController.animateToPage(
//               nextPage,
//               duration: const Duration(milliseconds: 300),
//               curve: Curves.easeIn,
//             );
//           }
//         }
//       });
//     });
//   }
// }


//   // void _startAutoSlide() {
//   //   _timer?.cancel(); // Cancel existing timer
//   //   if (bannerList.isNotEmpty) {
//   //     _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
//   //       if (_pageController.hasClients) {
//   //         final nextPage = (_pageController.page?.round() ?? 0) + 1;
//   //         if (nextPage >= bannerList.length) {
//   //           _pageController.jumpToPage(0);
//   //         } else {
//   //           _pageController.animateToPage(
//   //             nextPage,
//   //             duration: const Duration(milliseconds: 300),
//   //             curve: Curves.easeIn,
//   //           );
//   //         }
//   //       }
//   //     });
//   //   }
//   // }

//   Future<void> fetchBanners() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final response = await https.get(
//         Uri.parse('https://api.ekomflix.com/android/getCustomImageSlider'),
//         headers: {
//           'x-api-key': 'vLQTuPZUxktl5mVW',
//         },
//       );

//       if (response.statusCode == 200) {
//         final List<dynamic> responseData = json.decode(response.body);
//         await prefs.setString('banners', json.encode(responseData));
//         _updateBannerList(responseData);
//       } else {
//         throw Exception('Failed to fetch banners: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('Error fetching banners: $e');
//       rethrow;
//     }
//   }

//   Future<void> fetchAndPlayVideo(String contentId) async {
//     if (_isNavigating) return;
//     _isNavigating = true;

//     bool shouldPlayVideo = true;
//     bool shouldPop = true;

//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return WillPopScope(
//           onWillPop: () async {
//             shouldPlayVideo = false;
//             shouldPop = false;
//             return true;
//           },
//           child: SpinKitFadingCircle(
//             color: borderColor,
//             size: 50.0,
//           ),
//         );
//       },
//     );

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
//           // orElse: () => null,
//         );

//         if (filteredData != null) {
//           String videoUrl = filteredData['url'] ?? '';

//           if (filteredData['stream_type'] == 'YoutubeLive' ||
//               filteredData['type'] == 'Youtube') {
//             for (int i = 0; i < _maxRetries; i++) {
//               try {
//                 videoUrl = await _socketService.getUpdatedUrl(videoUrl);
//                 filteredData['url'] = videoUrl;
//                 filteredData['stream_type'] = "M3u8";
//                 break;
//               } catch (e) {
//                 if (i == _maxRetries - 1) rethrow;
//                 await Future.delayed(Duration(seconds: _retryDelay));
//               }
//             }
//           }

//           if (shouldPop) {
//             Navigator.of(context, rootNavigator: true).pop();
//           }

//           if (shouldPlayVideo) {
//             if (filteredData['stream_type'] == 'VLC' ||
//                 filteredData['type'] == 'VLC') {
//               await Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => VlcPlayerScreen(
//                     videoUrl: filteredData['url'],
//                     channelList: [],
//                     genres: '',
//                     bannerImageUrl: filteredData['banner'],
//                     startAtPosition: Duration.zero,
//                     isLive: true,
//                   ),
//                 ),
//               );
//             } else {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => VideoMovieScreen(
//                     videoUrl: filteredData['url'],
//                     videoTitle: filteredData['title'] ?? 'No Title',
//                     channelList: [],
//                     videoType: '',
//                     videoBanner: '',
//                     onFabFocusChanged: (bool focused) {},
//                     genres: '',
//                     url: '',
//                     type: '',
//                   ),
//                 ),
//               ).then((_) {
//                 _isNavigating = false;
//               });
//             }
//           }
//         } else {
//           throw Exception('Video not found');
//         }
//       } else {
//         throw Exception('Failed to load featured live TV');
//       }
//     } catch (e) {
//       if (shouldPop) {
//         Navigator.of(context, rootNavigator: true).pop();
//       }
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Something Went Wrong: ${e.toString()}')),
//       );
//     } finally {
//       _isNavigating = false;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: cardColor,
//       body: AnimatedSwitcher(
//         duration: const Duration(milliseconds: 300),
//         child: _buildContent(),
//       ),
//     );
//   }

//   Widget _buildContent() {
//     if (isLoading && bannerList.isEmpty) {
//       return Center(
//         child: SpinKitFadingCircle(
//           color: borderColor,
//           size: 50.0,
//         ),
//       );
//     }

//     if (errorMessage.isNotEmpty && bannerList.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(errorMessage, style: TextStyle(fontSize: 16)),
//             SizedBox(height: 16),
//             ElevatedButton(
//               onPressed: _initializeData,
//               child: Text('Retry'),
//             ),
//           ],
//         ),
//       );
//     }

//     if (bannerList.isEmpty) {
//       return const Center(child: Text('No banners available'));
//     }

//     return Stack(
//       children: [
//         PageView.builder(
//           controller: _pageController,
//           itemCount: bannerList.length,
//           onPageChanged: (index) {
//             setState(() {
//               selectedContentId = bannerList[index]['content_id'].toString();
//             });
//           },
//           itemBuilder: (context, index) {
//             final banner = bannerList[index];
//             return Stack(
//               alignment: AlignmentDirectional.topCenter,
//               children: [
//                 Container(
//                   margin: const EdgeInsets.only(top: 1),
//                   width: screenwdt,
//                   height: screenhgt,
//                   child: CachedNetworkImage(
//                     imageUrl: banner['banner'] ?? localImage,
//                     fit: BoxFit.fill,
//                     placeholder: (context, url) => localImage,
//                     errorWidget: (context, url, error) => localImage,
//                     cacheKey: banner['content_id'],
//                     fadeInDuration: Duration(milliseconds: 300),
//                     memCacheHeight: 800,
//                     memCacheWidth: 1200,
//                   ),
//                 ),
//               ],
//             );
//           },
//         ),
//         Positioned(
//           top: screenhgt * 0.01,
//           left: screenwdt * 0.02,
//           child: Container(
//             width: _isButtonFocused ? null : screenwdt,
//             child: Focus(
//               focusNode: _buttonFocusNode,
//               onFocusChange: (hasFocus) {
//                 setState(() {
//                   _isButtonFocused = hasFocus;
//                 });
//               },
//               onKeyEvent: (node, event) {
//                 if (event is KeyDownEvent &&
//                     event.logicalKey == LogicalKeyboardKey.select) {
//                   if (selectedContentId != null) {
//                     fetchAndPlayVideo(selectedContentId!);
//                   }
//                   return KeyEventResult.handled;
//                 }
//                 return KeyEventResult.ignored;
//               },
//               child: GestureDetector(
//                 onTap: () {
//                   if (selectedContentId != null) {
//                     fetchAndPlayVideo(selectedContentId!);
//                   }
//                 },
//                 child: Align(
//                   alignment: Alignment.centerLeft,
//                   child: Column(
//                     children: [
//                       SizedBox(
//                         height: screenhgt * 0.1,
//                       ),
//                       RandomLightColorWidget(
//                         hasFocus: _isButtonFocused,
//                         childBuilder: (Color randomColor) {
//                           return Container(
//                             margin: EdgeInsets.all(screenwdt * 0.001),
//                             // ... Previous code remains the same ...

//                             padding: EdgeInsets.symmetric(
//                               vertical: screenhgt * 0.02,
//                               horizontal: screenwdt * 0.02,
//                             ),
//                             decoration: BoxDecoration(
//                               color: Colors.black,
//                               borderRadius: BorderRadius.circular(8),
//                               border: _isButtonFocused
//                                   ? Border.all(
//                                       color: randomColor,
//                                       width: 2.0,
//                                     )
//                                   : Border.all(
//                                       color: Colors.transparent,
//                                       width: 2.0,
//                                     ),
//                               boxShadow: _isButtonFocused
//                                   ? [
//                                       BoxShadow(
//                                         color: randomColor,
//                                         blurRadius: 15.0,
//                                         spreadRadius: 5.0,
//                                       ),
//                                     ]
//                                   : [],
//                             ),
//                             child: Text(
//                               'Watch Now',
//                               style: TextStyle(
//                                 fontSize: menutextsz,
//                                 color:
//                                     _isButtonFocused ? randomColor : hintColor,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }



import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as https;
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';
import '../../video_widget/video_movie_screen.dart';
import '../../video_widget/socket_service.dart';
import '../../video_widget/vlc_player_screen.dart';
import '../../widgets/utils/color_service.dart';
import '../../widgets/utils/random_light_color_widget.dart';

class BannerSlider extends StatefulWidget {
  // final double initialHeight;
  // final double initialWidth;
  // final Function(double) onHeightChange; // Add a callback for height change
  // final Function(double) onWidthChange; // Add a callback for height change

  // BannerSlider(
  //     {required this.initialHeight,
  //     required this.onHeightChange,
  //     required this.initialWidth,
  //     required this.onWidthChange}); // Modify constructor
  @override
  _BannerSliderState createState() => _BannerSliderState();
}

class _BannerSliderState extends State<BannerSlider> {
  List<dynamic> bannerList = [];
  Map<String, Color> bannerColors = {};
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
  final PaletteColorService _paletteColorService =
      PaletteColorService(); // PaletteColorService instance
  late double _currentHeight; // Initial height
  late double _currentWidth; // Initial height

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _socketService.initSocket(); // Initialize SocketService
    // fetchBanners();
    // _startBackgroundApiFetch(); // Start periodic background fetch
    // _startAutoSlide();
    // _currentHeight = widget.initialHeight; // Set initial height
    // _currentHeight = widget.initialWidth; // Set initial width
    _buttonFocusNode.addListener(_onButtonFocusNode);
      _loadCachedData().then((_) {
    if (bannerList.isNotEmpty) {
      _startAutoSlide();
    }
  });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer.cancel();
    _buttonFocusNode.dispose();
    _socketService.dispose(); // Dispose of the SocketService
    super.dispose();
  }


Future<void> _loadCachedData() async {
  final prefs = await SharedPreferences.getInstance();
  final cachedBanners = prefs.getString('banners');

  if (cachedBanners != null) {
    final List<dynamic> responseData = json.decode(cachedBanners);
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

    // Fetch banner colors only if banners exist
    if (bannerList.isNotEmpty) {
      await _fetchBannerColors();
    }
  } else {
    // No cache found, show error or proceed with loading from API
    setState(() {
      isLoading = false;
    });
  }

  // Background API fetch to update cache
  fetchBanners(isBackgroundFetch: true);
}

  // Fetch data from API and check if there's any difference with cache
  Future<void> fetchBanners({bool isBackgroundFetch = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedBanners = prefs.getString('banners');

    try {
      final response = await https.get(
        Uri.parse('https://api.ekomflix.com/android/getCustomImageSlider'),
        headers: {
          'x-api-key': 'vLQTuPZUxktl5mVW',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);

        // Cache aur API data check karo
        if (cachedBanners != null) {
          final cachedData = json.decode(cachedBanners);
          if (json.encode(cachedData) == json.encode(responseData)) {
            return; // Agar data same hai to UI ko update nahi karna
          }
        }

        // Naya data cache mein store karo aur UI ko update karo
        setState(() {
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

        // Cache update karo
        prefs.setString('banners', response.body);

        _fetchBannerColors();
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


  Future<void> _fetchBannerColors() async {
    for (var banner in bannerList) {
      final imageUrl = banner['banner'] ?? localImage;
      final secondaryColor =
          await _paletteColorService.getSecondaryColor(imageUrl);
      setState(() {
        bannerColors[banner['content_id']] = secondaryColor;
      });
    }
  }



  void _onButtonFocusNode() {
    setState(() {
      _isButtonFocused = _buttonFocusNode.hasFocus;
      if (_isButtonFocused) {
        _currentFocusColor = bannerColors[selectedContentId!];

        // _currentHeight = widget.initialHeight * 1.6; // Increase height
        // _currentWidth = widget.initialWidth * 1.6;
      } 
    //   else {
    //     _currentHeight = widget.initialHeight; // Reset to original height
    //     _currentWidth = widget.initialWidth;
    //   }
    //   widget.onHeightChange(
    //     _currentHeight,
    //   ); // Call the callback to update HomeScreen height

    //   widget.onWidthChange(
    //       _currentWidth); // Call the callback to update HomeScreen height
    });
  }

//   void _startBackgroundApiFetch() {
//   Timer.periodic(Duration(minutes: 10), (Timer timer) async {
//     await fetchBanners(isBackgroundFetch: true);
//   });
// }

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



// Future<void> fetchBanners({bool isBackgroundFetch = false}) async {
//   final prefs = await SharedPreferences.getInstance();
//   final cachedBanners = prefs.getString('banners');

//   if (cachedBanners != null && !isBackgroundFetch) {
//     // Load banners from cache (only if not in background fetch)
//     final List<dynamic> responseData = json.decode(cachedBanners);
//     setState(() {
//       bannerList = responseData
//           .where((banner) => banner['status'] == "1")
//           .map((banner) {
//         return {
//           'content_id': banner['content_id'] ?? '',
//           'banner': banner['banner'] ?? localImage,
//           'title': banner['title'] ?? 'No Title',
//         };
//       }).toList();

//       selectedContentId = bannerList.isNotEmpty
//           ? bannerList[0]['content_id'].toString()
//           : null;
//       isLoading = false;
//     });

//     _fetchBannerColors();
//     _startAutoSlide();

//     // Preload cached banner images
//     // _precacheBannerImages();
//   }

//   // Fetch banners from API
//   try {
//     final response = await https.get(
//       Uri.parse('https://api.ekomflix.com/android/getCustomImageSlider'),
//       headers: {
//         'x-api-key': 'vLQTuPZUxktl5mVW',
//       },
//     );

//     if (response.statusCode == 200) {
//       final List<dynamic> responseData = json.decode(response.body);

//       if (cachedBanners != null) {
//         final cachedData = json.decode(cachedBanners);
//         if (json.encode(cachedData) == json.encode(responseData)) {
//           // No change in API data, skip UI update
//           return;
//         }
//       }

//       setState(() {
//         bannerList = responseData
//             .where((banner) => banner['status'] == "1")
//             .map((banner) {
//           return {
//             'content_id': banner['content_id'] ?? '',
//             'banner': banner['banner'] ?? localImage,
//             'title': banner['title'] ?? 'No Title',
//           };
//         }).toList();

//         selectedContentId = bannerList.isNotEmpty
//             ? bannerList[0]['content_id'].toString()
//             : null;
//         isLoading = false;
//       });

//       // Cache the new data
//       prefs.setString('banners', response.body);

//       _fetchBannerColors();
//       _startAutoSlide();

//       // Preload new banner images
//       // _precacheBannerImages();
//     } else {
//       throw Exception('Failed to load banners');
//     }
//   } catch (e) {
//     setState(() {
//       errorMessage = e.toString();
//       isLoading = false;
//     });
//   }
// }


// void _precacheBannerImages() {
//   for (var banner in bannerList) {
//     if (banner['banner'] != null && banner['banner'].isNotEmpty) {
//       precacheImage(
//         CachedNetworkImageProvider(banner['banner']), // Preload the banner image
//         context,
//       );
//     }
//   }
// }



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

            if (filteredData['stream_type'] == 'VLC' ||
                filteredData['type'] == 'VLC') {
              //   // Navigate to VLC Player screen when stream type is VLC
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VlcPlayerScreen(
                    videoUrl: filteredData['url'],
                    // videoTitle: filteredData['title'] ?? 'No Title',
                    channelList: [],
                    genres: '',
                    // channels: [],
                    // initialIndex: 1,
                    bannerImageUrl: filteredData['banner'],
                    startAtPosition: Duration.zero,
                    // onFabFocusChanged: (bool) {},
                    isLive: true,
                  ),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VideoMovieScreen(
                    videoUrl: filteredData['url'],
                    videoTitle: filteredData['title'] ?? 'No Title',
                    channelList: [],
                    videoType: filteredData['type']!,
                    videoBanner: '',
                    onFabFocusChanged: (bool focused) {},
                    genres: '',
                    url: '',
                    // type: '',
                  ),
                ),
              ).then((_) {
                _isNavigating = false;
              });
            }
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
                                  child:
                                      // CachedNetworkImage(
                                      //   imageUrl: banner['banner'] ?? localImage,
                                      //   fit: BoxFit.fill,
                                      //   placeholder: (context, url) => localImage,
                                      // ),
                                      CachedNetworkImage(
                                    imageUrl: banner['banner'] ?? localImage,
                                    fit: BoxFit.fill,
                                    placeholder: (context, url) => localImage,
                                    errorWidget: (context, url, error) =>
                                        Icon(Icons.error),
                                    cacheKey: banner[
                                        'content_id'], // Ensure cache key is unique per banner
                                    fadeInDuration: Duration(
                                        milliseconds:
                                            500), // Reduce fade-in time
                                    memCacheHeight:
                                        800, // Limit the memory cache to save resources
                                    memCacheWidth: 1200,
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
                              0.001, // Space from the top of the image
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
                                  // _currentFocusColor =
                                  _currentFocusColor;
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
                                        height: screenhgt * 0.03,
                                      ),
                                      RandomLightColorWidget(
                                        hasFocus: _isButtonFocused,
                                        childBuilder: (Color randomColor) {
                                          return Container(
                                            margin: EdgeInsets.all(screenwdt *
                                                0.001), // Reduced padding

                                            padding: EdgeInsets.symmetric(
                                                vertical: screenhgt * 0.02,
                                                horizontal: screenwdt * 0.02),
                                            decoration: BoxDecoration(
                                              color:_isButtonFocused? Colors.black87 :Colors.black38 ,
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

