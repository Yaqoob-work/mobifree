import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as https;
import 'package:mobi_tv_entertainment/menu_screens/home_sub_screen/sub_vod.dart';
import 'package:mobi_tv_entertainment/provider/color_provider.dart';
import 'package:mobi_tv_entertainment/video_widget/socket_service.dart';
import 'package:mobi_tv_entertainment/widgets/small_widgets/loading_indicator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';
import '../../video_widget/video_screen.dart';
import '../../widgets/models/news_item_model.dart';
import '../../widgets/utils/color_service.dart';
import '../../widgets/utils/random_light_color_widget.dart';

Future<Map<String, String>> fetchLiveFeaturedTVById(String contentId) async {
  final prefs = await SharedPreferences.getInstance();
  final cachedData = prefs.getString('live_featured_tv');

  List<dynamic> responseData;

  // Use cached data if available
  if (cachedData != null) {
    responseData = json.decode(cachedData);
  } else {
    // Fetch from API if cache is not available
    final response = await https.get(
      Uri.parse('https://api.ekomflix.com/android/getFeaturedLiveTV'),
      headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
    );

    if (response.statusCode == 200) {
      responseData = json.decode(response.body);
      // Cache the data
      prefs.setString('live_featured_tv', json.encode(responseData));
    } else {
      throw Exception('Failed to load featured live TV');
    }
  }

  // Find the matched item by id
  final matchedItem = responseData.firstWhere(
    (channel) => channel['id'].toString() == contentId,
    orElse: () => null,
  );

  if (matchedItem != null) {
    return {
      'url': matchedItem['url'] ?? '',
      'type': matchedItem['type'] ?? '',
    };
  } else {
    throw Exception('No matching channel found for id $contentId');
  }
}

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
  // List<dynamic> bannerList = [];
  List<Map<String, dynamic>> lastPlayedVideos = [];
  final SocketService _socketService = SocketService();
  List<NewsItemModel> bannerList = [];
  Map<String, Color> bannerColors = {};
  bool isLoading = true;
  String errorMessage = '';
  late PageController _pageController;
  late Timer _timer;
  String? selectedContentId;
  FocusNode _buttonFocusNode = FocusNode();
  FocusNode _lastPlayedBannerFocusNode = FocusNode();
  bool _isButtonFocused = false;
  bool _islastPlayedBannerFocusNode = false;
  bool _isNavigating = false;
  Color? _currentFocusColor;
  final int _maxRetries = 3;
  final int _retryDelay = 5; // seconds
  final PaletteColorService _paletteColorService =
      PaletteColorService(); // PaletteColorService instance
  late double _currentHeight; // Initial height
  late double _currentWidth; // Initial height
  late StreamSubscription refreshSubscription;
  Key refreshKey = UniqueKey(); // Add a key

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _socketService.initSocket();
    // fetchBanners();
    // _startBackgroundApiFetch(); // Start periodic background fetch
    // _startAutoSlide();
    // _currentHeight = widget.initialHeight; // Set initial height
    // _currentHeight = widget.initialWidth; // Set initial width
    refreshSubscription =
        GlobalEventBus.eventBus.on<RefreshPageEvent>().listen((event) {
      if (event.pageId == 'uniquePageId') {
        // Immediate reload
        _loadLastPlayedVideos();

        // Delayed reload for smoother UI update
        Future.delayed(Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              refreshKey = UniqueKey();
            });
            _loadLastPlayedVideos(); // Double-check for latest data
          }
        });
      }
    });
    _buttonFocusNode.addListener(_onButtonFocusNode);
    _lastPlayedBannerFocusNode.addListener(_onlastPlayedBannerFocusNode);
    _loadLastPlayedVideos();
    _loadCachedData().then((_) {
      if (bannerList.isNotEmpty) {
        _startAutoSlide();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _socketService.dispose();
    _timer.cancel();
    _buttonFocusNode.dispose();
    _lastPlayedBannerFocusNode.dispose();
    refreshSubscription.cancel();
    super.dispose();
  }

  // Future<void> _loadLastPlayedVideos() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   List<String>? storedVideos = prefs.getStringList('last_played_videos');

  //   if (storedVideos != null && storedVideos.isNotEmpty) {
  //     setState(() {
  //       lastPlayedVideos = storedVideos.map((videoEntry) {
  //         List<String> details = videoEntry.split('|');
  //         print("Banner URL: ${details[2]}");

  //         return {
  //           'videoUrl': details[0], // Video URL
  //           'position': Duration(
  //               milliseconds: int.parse(details[1])), // Playback position
  //           'bannerImageUrl': details[2], // Banner image URL
  //         };
  //       }).toList();
  //     });
  //   }
  // }

// // BannerSlider में _loadLastPlayedVideos में सुधार
//   Future<void> _loadLastPlayedVideos() async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       List<String>? storedVideos = prefs.getStringList('last_played_videos');

//       if (storedVideos != null && storedVideos.isNotEmpty) {
//         setState(() {
//           lastPlayedVideos = storedVideos.map((videoEntry) {
//             List<String> details = videoEntry.split('|');
//             return {
//               'videoUrl': details[0],
//               'position': Duration(milliseconds: int.parse(details[1])),
//               'bannerImageUrl': details[2],
//               'videoName': details.length > 3 ? details[3] : 'Untitled Video',
//               'focusNode': FocusNode(),
//             };
//           }).toList();
//         });
//       }
//     } catch (e) {
//       print("Error loading last played videos: $e");
//     }
//   }

  // Future<void> _loadLastPlayedVideos() async {
  //   try {
  //     SharedPreferences prefs = await SharedPreferences.getInstance();
  //     List<String>? storedVideos = prefs.getStringList('last_played_videos');

  //     if (storedVideos != null && storedVideos.isNotEmpty) {
  //       setState(() {
  //         lastPlayedVideos = storedVideos.map((videoEntry) {
  //           List<String> details = videoEntry.split('|');
  //           return {
  //             'videoUrl': details[0],
  //             'position': Duration(milliseconds: int.parse(details[1])),
  //             'bannerImageUrl': details[2],
  //             'videoName': details.length > 3
  //                 ? details[3]
  //                 : '', // Extract video name or use default
  //             'focusNode': FocusNode(),
  //           };
  //         }).toList();
  //       });
  //     }
  //   } catch (e) {
  //     print("Error loading last played videos: $e");
  //   }
  // }

// // Helper method to compare video lists
// bool _areVideoListsEqual(List<Map<String, dynamic>> list1, List<Map<String, dynamic>> list2) {
//   if (list1.length != list2.length) return false;

//   for (int i = 0; i < list1.length; i++) {
//     if (list1[i]['videoUrl'] != list2[i]['videoUrl'] ||
//         list1[i]['position'] != list2[i]['position'] ||
//         list1[i]['bannerImageUrl'] != list2[i]['bannerImageUrl'] ||
//         list1[i]['videoName'] != list2[i]['videoName']) {
//       return false;
//     }
//   }
//   return true;
// }

// Update the addNewBannerOrVideo method to trigger a refresh
  void addNewBannerOrVideo(Map<String, dynamic> newVideo) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> storedVideos = prefs.getStringList('last_played_videos') ?? [];

    // Create the new video entry string
    String newVideoEntry =
        '${newVideo['videoUrl']}|${newVideo['position'].inMilliseconds}|${newVideo['bannerImageUrl']}|${newVideo['videoName']}';

    // Add to the beginning of the list
    storedVideos.insert(0, newVideoEntry);

    // Keep only the last 10 videos
    if (storedVideos.length > 10) {
      storedVideos = storedVideos.sublist(0, 10);
    }

    // Save back to SharedPreferences
    await prefs.setString('last_played_videos', json.encode(storedVideos));

    // Reload the data and refresh the UI
    await _loadLastPlayedVideos();
  }

// Future<void> _loadLastPlayedVideos() async {
//   SharedPreferences prefs = await SharedPreferences.getInstance();
//   List<String>? storedVideos = prefs.getStringList('last_played_videos');

//   if (storedVideos != null && storedVideos.isNotEmpty) {
//     setState(() {
//       lastPlayedVideos = storedVideos.map((videoEntry) {
//         List<String> details = videoEntry.split('|');
//         return {
//           'videoUrl': details[0],
//           'position': Duration(milliseconds: int.parse(details[1])),
//           'bannerImageUrl': details[2],
//           'videoName': details.length > 3 ? details[3] : 'Untitled Video', // Add name with fallback
//           'focusNode': FocusNode(),
//         };
//       }).toList();
//     });
//   }
// }

  Future<Map<String, String>> fetchLiveFeaturedTVById(String contentId) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('live_featured_tv');

    List<dynamic> responseData;

    // Use cached data if available
    if (cachedData != null) {
      responseData = json.decode(cachedData);
    } else {
      // Fetch from API if cache is not available
      final response = await https.get(
        Uri.parse('https://api.ekomflix.com/android/getFeaturedLiveTV'),
        headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
      );

      if (response.statusCode == 200) {
        responseData = json.decode(response.body);
        // Cache the data
        prefs.setString('live_featured_tv', json.encode(responseData));
      } else {
        throw Exception('Failed to load featured live TV');
      }
    }

    // Find the matched item by id
    final matchedItem = responseData.firstWhere(
      (channel) => channel['id'].toString() == contentId,
      orElse: () => null,
    );

    if (matchedItem != null) {
      return {
        'url': matchedItem['url'] ?? '',
        'type': matchedItem['type'] ?? '',
        'banner': matchedItem['banner'] ?? '',
      };
    } else {
      throw Exception('No matching channel found for id $contentId');
    }
  }

  Future<void> _loadCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedBanners = prefs.getString('banners');

    if (cachedBanners != null) {
      final List<dynamic> responseData = json.decode(cachedBanners);
      setState(() {
        bannerList = responseData
            .where((banner) => banner['status'] == "1")
            .map((banner) => NewsItemModel.fromJson(banner))
            .toList();

        selectedContentId = bannerList.isNotEmpty ? bannerList[0].id : null;
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

        // Check if cache and API data are the same
        if (cachedBanners != null) {
          final cachedData = json.decode(cachedBanners);
          if (json.encode(cachedData) == json.encode(responseData)) {
            return; // No need to update UI if data is the same
          }
        }

        setState(() {
          bannerList = responseData
              .where((banner) => banner['status'] == "1")
              .map((banner) => NewsItemModel.fromJson(banner))
              .toList();

          selectedContentId = bannerList.isNotEmpty ? bannerList[0].id : null;
          isLoading = false;
        });

        // Update cache
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
      final imageUrl = banner.banner ?? localImage;
      final secondaryColor =
          await _paletteColorService.getSecondaryColor(imageUrl);
      setState(() {
        bannerColors[banner.contentId] = secondaryColor;
      });
    }
  }

  // void _onButtonFocusNode() {
  //   setState(() {
  //     _isButtonFocused = _buttonFocusNode.hasFocus;
  //     if (_isButtonFocused) {
  //       _currentFocusColor = bannerColors[selectedContentId!];

  //       // _currentHeight = widget.initialHeight * 1.6; // Increase height
  //       // _currentWidth = widget.initialWidth * 1.6;
  //     }
  //     //   else {
  //     //     _currentHeight = widget.initialHeight; // Reset to original height
  //     //     _currentWidth = widget.initialWidth;
  //     //   }
  //     //   widget.onHeightChange(
  //     //     _currentHeight,
  //     //   ); // Call the callback to update HomeScreen height

  //     //   widget.onWidthChange(
  //     //       _currentWidth); // Call the callback to update HomeScreen height
  //   });
  // }

  void _onButtonFocusNode() {
    setState(() {
      _isButtonFocused = _buttonFocusNode.hasFocus;
      if (_isButtonFocused && selectedContentId != null) {
        // Focus आने पर एक बार random color set करें
        // Math.Random के through color generate करें
        final random = Random();
        final color = Color.fromRGBO(
          random.nextInt(256),
          random.nextInt(256),
          random.nextInt(256),
          1,
        );
        _currentFocusColor = color;
        context.read<ColorProvider>().updateColor(color, true);
      } else {
        context.read<ColorProvider>().resetColor();
      }
    });
  }

  void _onlastPlayedBannerFocusNode() {
    setState(() {
      _islastPlayedBannerFocusNode = _lastPlayedBannerFocusNode.hasFocus;
      if (_islastPlayedBannerFocusNode) {
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

// Future<List<dynamic>> fetchLiveFeaturedTV() async {
//   try {
//     final response = await https.get(
//       Uri.parse('https://api.ekomflix.com/android/getFeaturedLiveTV'),
//       headers: {
//         'x-api-key': 'vLQTuPZUxktl5mVW',
//       },
//     );

//     if (response.statusCode == 200) {
//       final List<dynamic> responseData = json.decode(response.body);
//       return responseData;
//     } else {
//       throw Exception('Failed to load featured live TV');
//     }
//   } catch (e) {
//     throw Exception('Error fetching live featured TV: $e');
//   }
// }

  Future<void> fetchAndPlayVideo(
      String contentId, List<NewsItemModel> channelList) async {
    if (_isNavigating) return; // Prevent duplicate navigation
    _isNavigating = true;

    bool shouldPlayVideo = true;
    bool shouldPop = true;

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
      final responseData = await fetchLiveFeaturedTVById(contentId);

      // final filteredData = responseData.firstWhere(
      //   (channel) => channel['id'].toString() == contentId,
      //   orElse: () => null,
      // );

      if (responseData != null) {
        String originalUrl = responseData['url'] ?? '';
        String videoUrl = responseData['url'] ?? '';

        if (responseData['stream_type'] == 'YoutubeLive' ||
            responseData['type'] == 'Youtube') {
          for (int i = 0; i < _maxRetries; i++) {
            try {
              videoUrl = await _socketService.getUpdatedUrl(videoUrl);
              responseData['url'] = videoUrl;
              responseData['stream_type'] = "M3u8";
              break;
            } catch (e) {
              if (i == _maxRetries - 1) rethrow;
              await Future.delayed(Duration(seconds: _retryDelay));
            }
          }
        }

        if (shouldPop) {
          Navigator.of(context, rootNavigator: true).pop();
        }

        if (shouldPlayVideo) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoScreen(
                videoUrl: responseData['url']!,
                channelList: channelList,
                videoId: int.parse(contentId),
                videoType: responseData['type']!,
                isLive: true,
                isVOD: false,
                bannerImageUrl: responseData['banner']!,
                startAtPosition: Duration.zero,
                isBannerSlider: true,
                source: 'isBannerSlider',
                isSearch: false,
                unUpdatedUrl: originalUrl,
              ),
            ),
          ).then((_) {
            _isNavigating = false;
          });
        }
      } else {
        throw Exception('Video not found');
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
      selectedContentId = bannerList[index].contentId.toString();
    });
  }

//   // In BannerSlider class (_loadLastPlayedVideos method):
// Future<void> _loadLastPlayedVideos() async {
//   try {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     List<String>? storedVideos = prefs.getStringList('last_played_videos');

//     if (storedVideos != null && storedVideos.isNotEmpty) {
//       setState(() {
//         lastPlayedVideos = storedVideos.map((videoEntry) {
//           List<String> details = videoEntry.split('|');
//           return {
//             'videoUrl': details[0],
//             'position': Duration(milliseconds: int.parse(details[1])),
//             'bannerImageUrl': details[2],
//             'videoName': details.length > 3 ? details[3] : '',
//             'source': details.length > 4 ? details[4] : '', // Load source
//             'focusNode': FocusNode(),
//           };
//         }).toList();
//       });
//     }
//   } catch (e) {
//     print("Error loading last played videos: $e");
//   }
// }

// // First update the _loadLastPlayedVideos method
//   Future<void> _loadLastPlayedVideos() async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       List<String>? storedVideos = prefs.getStringList('last_played_videos');

//       if (storedVideos != null && storedVideos.isNotEmpty) {
//         setState(() {
//           lastPlayedVideos = storedVideos.map((videoEntry) {
//             List<String> details = videoEntry.split('|');
//             return {
//               'videoUrl': details[0],
//               'position': Duration(milliseconds: int.parse(details[1])),
//               'bannerImageUrl': details[2],
//               'videoName': details.length > 3 ? details[3] : '',
//               'source': details.length > 4 ? details[4] : '',
//               'videoId': details.length > 5 ? details[5] : '', // Add video ID
//               'focusNode': FocusNode(),
//             };
//           }).toList();
//         });
//       }
//     } catch (e) {
//       print("Error loading last played videos: $e");
//     }
//   }

  // Future<void> _loadLastPlayedVideos() async {
  //   try {
  //     SharedPreferences prefs = await SharedPreferences.getInstance();
  //     List<String>? storedVideos = prefs.getStringList('last_played_videos');

  //     if (storedVideos != null && storedVideos.isNotEmpty) {
  //       setState(() {
  //         lastPlayedVideos = storedVideos.map((videoEntry) {
  //           List<String> details = videoEntry.split('|');

  //           // Safely parse the position value with error handling
  //           Duration position;
  //           try {
  //             position = Duration(milliseconds: int.tryParse(details[1]) ?? 0);
  //           } catch (e) {
  //             position = Duration.zero;
  //           }

  //           return {
  //             'videoUrl': details.isNotEmpty ? details[0] : '',
  //             'position': position,
  //             'bannerImageUrl': details.length > 2 ? details[2] : '',
  //             'videoName': details.length > 3 ? details[3] : '',
  //             'source': details.length > 4 ? details[4] : '',
  //             'videoId': details.length > 5 ? details[5] : '',
  //             'focusNode': FocusNode(),
  //           };
  //         }).toList();
  //       });
  //     }
  //   } catch (e) {
  //     print("Error loading last played videos: $e");
  //     // Reset to empty list in case of error
  //     setState(() {
  //       lastPlayedVideos = [];
  //     });
  //   }
  // }


  Future<void> _loadLastPlayedVideos() async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? storedVideos = prefs.getStringList('last_played_videos');

    if (storedVideos != null && storedVideos.isNotEmpty) {
      setState(() {
        lastPlayedVideos = storedVideos.map((videoEntry) {
          List<String> details = videoEntry.split('|');
          
          // Safely parse the position value with error handling
          Duration position;
          try {
            position = Duration(milliseconds: int.tryParse(details[1]) ?? 0);
          } catch (e) {
            position = Duration.zero;
          }

          // Safely handle videoId
          String videoId = '';
          if (details.length > 5) {
            videoId = details[5].trim(); // Remove any whitespace
            if (videoId == 'null' || videoId == '') {
              videoId = '0';
            }
          }

          return {
            'videoUrl': details.isNotEmpty ? details[0] : '',
            'position': position,
            'bannerImageUrl': details.length > 2 ? details[2] : '',
            'videoName': details.length > 3 ? details[3] : '',
            'source': details.length > 4 ? details[4] : '',
            'videoId': videoId,
            'focusNode': FocusNode(),
          };
        }).toList();
      });
    }
  } catch (e) {
    print("Error loading last played videos: $e");
    setState(() {
      lastPlayedVideos = [];
    });
  }
}

//   void _playVideo(Map<String, dynamic> videoData, Duration position) async {
//     if (videoData == null) return;

//     try {
//       // Convert lastPlayedVideos to a list of NewsItemModel objects
//       List<NewsItemModel> channelList = lastPlayedVideos
//           .map((video) => NewsItemModel(
//               id: video['videoId'] ?? '',
//               url: video['videoUrl'] ?? '',
//               banner: video['bannerImageUrl'] ?? '',
//               name: video['videoName'] ?? '',
//               contentId: video['videoId'] ?? '',
//               status: '1',
//               // type: '',
//               streamType: 'M3u8',
//               contentType: '1',
//               genres: ''))
//           .toList();

//       String source = videoData['source'] ?? '';
//       String videoId = videoData['videoId'] ?? '';
//       // String url = videoData['videoUrl'];
//       // if (source == 'isContentScreenViaDetailsPageChannelLIst') {
//       //   url = await _socketService.getUpdatedUrl(url);
//       // }
//       print('asdfghfdhkf:$source');
//       // print('asdfgh:$url');

//     var selectedChannel = videoData['videoUrl'];
// String updatedUrl = videoData['videoUrl'];

//  if (source == 'isHomeCategory') {
//         final playLink =
//             await fetchLiveFeaturedTVById(videoId);

//         if (playLink['url'] != null && playLink['url']!.isNotEmpty) {
//           updatedUrl = playLink['url']!;
//           if (playLink['stream_type'] == 'YoutubeLive') {
//             updatedUrl = await _socketService.getUpdatedUrl(updatedUrl);
//           }
//         } else {
//           throw Exception("Invalid play link for VOD");
//         }
//       } else if (selectedChannel.streamType == 'YoutubeLive' ||
//           selectedChannel.streamType == 'Youtube') {
//         updatedUrl = await _fetchUpdatedUrl(selectedChannel.url);
//         if (updatedUrl.isEmpty) throw Exception("Failed to fetch updated URL");
//       }

//       if (source == 'isBannerSlider' || source == 'isLiveScreen') {
//         final playLink =
//             await fetchLiveFeaturedTVById(videoId);

//         if (playLink['url'] != null && playLink['url']!.isNotEmpty) {
//           updatedUrl = playLink['url']!;
//           if (playLink['stream_type'] == 'YoutubeLive') {
//             updatedUrl = await _socketService.getUpdatedUrl(playLink['url']!);
//           }
//         } else {
//           throw Exception("Invalid play link for VOD");
//         }
//       } else if (selectedChannel.streamType == 'YoutubeLive' ||
//           selectedChannel.streamType == 'Youtube') {
//         updatedUrl = await _fetchUpdatedUrl(selectedChannel.url);
//         if (updatedUrl.isEmpty) throw Exception("Failed to fetch updated URL");
//       }

//       if (selectedChannel.contentType == '1' ||
//           selectedChannel.contentType == 1 &&
//               source == 'isSearchScreen') {
//         // final playLink =
//         //     await fetchLiveFeaturedTVById(selectedChannel.id);
//         final playLink = await fetchMoviePlayLink(videoId as int);

//         print('hellow isSearchScreen$playLink');
//         if (playLink['url'] != null && playLink['url']!.isNotEmpty) {
//           updatedUrl = playLink['url']!;
//           if (playLink['type'] == 'Youtube' ||
//               playLink['type'] == 'YoutubeLive' ||
//               playLink['content_type'] == '1' ||
//               playLink['content_type'] == 1) {
//             updatedUrl = await _socketService.getUpdatedUrl(playLink['url']!);
//             print('hellow isSearchScreen$updatedUrl');
//           }
//         }
//       }

//       if (source == 'isContentScreenViaDetailsPageChannelLIst' ||
//               source == 'isSearchScreenViaDetailsPageChannelList'
//           //|| widget.source == 'isSearchScreen'
//           ) {
//         print('hellow isVOD');

//         if (selectedChannel.contentType == '1' ||
//             selectedChannel.contentType == 1) {
//           // final playLink =
//           //     await fetchLiveFeaturedTVById(selectedChannel.id);
//           final playLink = await fetchMoviePlayLink(videoId as int);

//           print('hellow isVOD$playLink');
//           if (playLink['url'] != null && playLink['url']!.isNotEmpty) {
//             updatedUrl = playLink['url']!;
//             if (playLink['type'] == 'Youtube' ||
//                 playLink['type'] == 'YoutubeLive' ||
//                 playLink['content_type'] == '1' ||
//                 playLink['content_type'] == 1) {
//               updatedUrl = await _socketService.getUpdatedUrl(playLink['url']!);
//               print('hellow isVOD$updatedUrl');
//             }
//           }
//         }
//       }

//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => VideoScreen(
//             videoUrl:
//                 // videoData['videoUrl'],
//                 updatedUrl,
//             unUpdatedUrl: videoData['videoUrl'],
//             channelList: channelList,
//             bannerImageUrl: videoData['bannerImageUrl'],
//             startAtPosition: videoData['position'],
//             videoType: '',
//             isLive: false,
//             isVOD: source == 'isVOD',
//             isSearch: false,
//             isHomeCategory: source == 'isHomeCategory',
//             isBannerSlider: source == 'isBannerSlider',
//             videoId: videoId.isNotEmpty ? int.parse(videoId) : null,
//             source: source,
//           ),
//         ),
//       );
//     } catch (e) {
//       print("Error playing video: $e");
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Unable to play this content')),
//       );
//     }
//   }


bool isYoutubeUrl(String? url) {
  if (url == null || url.isEmpty) {
    return false;
  }
  
  url = url.toLowerCase().trim();
  
  // First check if it's a YouTube ID (exactly 11 characters)
  bool isYoutubeId = RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(url);
  if (isYoutubeId) {
    print("Matched YouTube ID pattern: $url");
    return true;
  }
  
  // Then check for regular YouTube URLs
  bool isYoutubeUrl = url.contains('youtube.com') || 
                      url.contains('youtu.be') ||
                      url.contains('youtube.com/shorts/');
  if (isYoutubeUrl) {
    print("Matched YouTube URL pattern: $url");
    return true;
  }
  
  print("Not a YouTube URL/ID: $url");
  return false;
}

String formatUrl(String url, {Map<String, String>? params}) {
  if (url.isEmpty) {
    print("Warning: Empty URL provided");
    throw Exception("Empty URL provided");
  }
  
  // Handle YouTube ID by converting to full URL if needed
  if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(url)) {
    print("Converting YouTube ID to full URL");
    url = "https://www.youtube.com/watch?v=$url";
  }

  // Remove any existing query parameters
  url = url.split('?')[0];

  // Add new query parameters
  if (params != null && params.isNotEmpty) {
    url += '?' + params.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
  }

  print("Formatted URL: $url");
  return url;
}

  // void _playVideo(Map<String, dynamic> videoData, Duration position) async {
  //   if (videoData == null) return;

  //   if (_isNavigating) return;
  //   _isNavigating = true;

  //   bool shouldPlayVideo = true;
  //   bool shouldPop = true;

  //   // Show loading indicator while video is loading
  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (BuildContext context) {
  //       return WillPopScope(
  //         onWillPop: () async {
  //           shouldPlayVideo = false;
  //           shouldPop = false;
  //           return true;
  //         },
  //         child: LoadingIndicator(),
  //       );
  //     },
  //   );

  //   Timer(Duration(seconds: 10), () {
  //     _isNavigating = false;
  //   });

  //   try {
  //     // Convert lastPlayedVideos to a list of NewsItemModel objects
  //     List<NewsItemModel> channelList = lastPlayedVideos
  //         .map((video) => NewsItemModel(
  //             id: video['videoId'] ?? '',
  //             url: video['videoUrl'] ?? '',
  //             banner: video['bannerImageUrl'] ?? '',
  //             name: video['videoName'] ?? '',
  //             contentId: video['videoId'] ?? '',
  //             status: '1',
  //             streamType: 'M3u8',
  //             contentType: '1',
  //             genres: ''))
  //         .toList();

  //     String source = videoData['source'] ?? '';
  //     String videoId = videoData['videoId'] ?? '';
  //     String updatedUrl = videoData['videoUrl'];


  //         if (isYoutubeUrl(updatedUrl)) {
  //     print("Processing as YouTube content");
  //     updatedUrl = await _socketService.getUpdatedUrl(updatedUrl);
  //     print("Socket service returned URL: $updatedUrl");
  //   }

  //     // // Handle different video sources
  //     // if (source == 'isHomeCategory' ||
  //     //     source == 'isBannerSlider' ||
  //     //     source == 'isLiveScreen') {
  //     //   final playLink = await fetchLiveFeaturedTVById(videoId);
  //     //   print('testing:$videoId');
  //     //   if (playLink['url'] != null && playLink['url']!.isNotEmpty) {
  //     //     updatedUrl = playLink['url']!;
  //     //     if (playLink['stream_type'] == 'YoutubeLive' ||
  //     //         playLink['type'] == 'YoutubeLive') {
  //     //       updatedUrl = await _socketService.getUpdatedUrl(updatedUrl);
  //     //     }
  //     //   } else {
  //     //     throw Exception("Invalid play link");
  //     //   }
  //     // }
  //     // // Handle VOD content
  //     // else if (source == 'isContentScreenViaDetailsPageChannelLIst' ||
  //     //     source == 'isSearchScreenViaDetailsPageChannelList' ||
  //     //     source == 'isSearchScreen') {
  //     //   try {
  //     //     final playLink = await fetchMoviePlayLink(int.parse(videoId));
  //     //     if (playLink['url'] != null && playLink['url']!.isNotEmpty) {
  //     //       updatedUrl = playLink['url']!;
  //     //       if (playLink['type'] == 'Youtube' ||
  //     //           playLink['type'] == 'YoutubeLive' ||
  //     //           playLink['content_type'] == '1') {
  //     //         updatedUrl = await _socketService.getUpdatedUrl(playLink['url']!);
  //     //       }
  //     //     }
  //     //   } catch (e) {
  //     //     print("Error fetching movie play link: $e");
  //     //     throw Exception("Failed to fetch video URL");
  //     //   }
  //     // }

  //     if (shouldPop) {
  //       Navigator.of(context, rootNavigator: true).pop();
  //     }

  //         // Check if URL/ID is YouTube


  //     if (shouldPlayVideo) {
  //       Navigator.push(
  //         context,
  //         MaterialPageRoute(
  //           builder: (context) => VideoScreen(
  //             videoUrl: updatedUrl,
  //             unUpdatedUrl: videoData['videoUrl'],
  //             channelList: lastPlayedVideos,
  //             bannerImageUrl: videoData['bannerImageUrl'],
  //             startAtPosition: position,
  //             videoType: '',
  //             isLive: source == 'isLiveScreen',
  //             isVOD: source == 'isVOD',
  //             isSearch: source == 'isSearchScreen',
  //             isHomeCategory: source == 'isHomeCategory',
  //             isBannerSlider: source == 'isBannerSlider',
  //             videoId: 
  //             videoId.isNotEmpty ? int.parse(videoId) : null
  //             ,
  //             source: source,
  //           ),
  //         ),
  //       );
  //     }
  //   } catch (e) {
  //     print("Error playing video: $e");
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(content: Text('Unable to play this content')));
  //     }
  //   }
  // }



void _playVideo(Map<String, dynamic> videoData, Duration position) async {
  if (videoData == null) return;

  if (_isNavigating) return;
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
        child: LoadingIndicator(),
      );
    },
  );

  Timer(Duration(seconds: 10), () {
    _isNavigating = false;
  });

  try {
    // Find the index of the current video in lastPlayedVideos
    final currentIndex = lastPlayedVideos.indexWhere(
      (video) => video['videoUrl'] == videoData['videoUrl']
    );

    // Create channelList with only video URLs based on index
    List<NewsItemModel> channelList = [];
    for (int i = 0; i < lastPlayedVideos.length; i++) {
      String videoUrl = lastPlayedVideos[i]['videoUrl'] ?? '';
      String videoIdString = lastPlayedVideos[i]['videoId'] ?? '0';
      String contentIdString = lastPlayedVideos[i]['videoId'] ?? '0';
      String streamType = isYoutubeUrl(videoUrl) ? 'YoutubeLive' : 'M3u8';
      
      channelList.add(NewsItemModel(
        id: videoIdString,
        url: videoUrl,
        banner: lastPlayedVideos[i]['bannerImageUrl'] ?? '',
        name: lastPlayedVideos[i]['videoName'] ?? '',
        contentId: contentIdString,
        status: '1',
        streamType: streamType,
        contentType: '1',
        genres: ''
      ));
    }

    String source = videoData['source'] ?? '';
    // String videoId = videoData['videoId'] ?? '';
        int videoId = 0;
    if (videoData['videoId'] != null && videoData['videoId'].toString().isNotEmpty) {
      videoId = int.tryParse(videoData['videoId'].toString()) ?? 0;
    }
    String originalUrl = videoData['videoUrl'];
    String updatedUrl = videoData['videoUrl'];

      print("YouTubeUrl: $updatedUrl");


    if (isYoutubeUrl(updatedUrl)) {
      print("Processing as YouTube content");
      updatedUrl = await _socketService.getUpdatedUrl(updatedUrl);
      print("Socket service returned URL: $updatedUrl");
    }

      print("YouTubeUrl1: $updatedUrl");


    if (shouldPop) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    if (shouldPlayVideo) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoScreen(
            videoUrl: updatedUrl,
            unUpdatedUrl: originalUrl,
            channelList: channelList,  // Pass the index-based channel list
            bannerImageUrl: videoData['bannerImageUrl'],
            startAtPosition: position,
            videoType: '',
            isLive: source == 'isLiveScreen',
            isVOD: source == 'isVOD',
            isSearch: source == 'isSearchScreen',
            isHomeCategory: source == 'isHomeCategory',
            isBannerSlider: source == 'isBannerSlider',
            videoId: 
            videoId,
            // videoId.isNotEmpty ? int.parse(videoId) : 0,
            source: 'isLastPlayedVideos',
          ),
        ),
      );
    }
  } catch (e) {
    print("Error playing video: $e");
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to play this content'))
      );
    }
  } finally {
    _isNavigating = false;
  }
}

// Helper method to fetch updated URL with retries
  Future<String> _fetchUpdatedUrl(String originalUrl) async {
    for (int i = 0; i < _maxRetries; i++) {
      try {
        final updatedUrl = await _socketService.getUpdatedUrl(originalUrl);
        print("Updated URL on retry $i: $updatedUrl");
        return updatedUrl;
      } catch (e) {
        print("Retry ${i + 1} failed: $e");
        if (i == _maxRetries - 1) rethrow;
        await Future.delayed(Duration(seconds: _retryDelay));
      }
    }
    return '';
  }

  //   Future<String> _fetchUpdatedUrl(String originalUrl) async {
  //   for (int i = 0; i < _maxRetries; i++) {
  //     try {
  //       final updatedUrl = await SocketService().getUpdatedUrl(originalUrl);
  //       print("Updated URL on retry $i: $updatedUrl");
  //       return updatedUrl;
  //     } catch (e) {
  //       print("Retry ${i + 1} failed: $e");
  //       if (i == _maxRetries - 1) rethrow; // Rethrow on final failure
  //       await Future.delayed(Duration(seconds: _retryDelay));
  //     }
  //   }
  //   return ''; // Return empty string if all retries fail
  // }

// void _playVideo(Map<String, dynamic> videoData,Duration position) {
//   if (videoData == null) return;

//   Navigator.push(
//     context,
//     MaterialPageRoute(
//       builder: (context) => VideoScreen(
//         videoUrl: videoData['videoUrl'] ?? '',
//         channelList: [],
//         bannerImageUrl: videoData['bannerImageUrl'] ?? '',
//         startAtPosition: videoData['position'] ?? Duration.zero,
//         videoType: '',
//         isLive: false,
//         isVOD: true,
//         isSearch: false,
//         isBannerSlider: false,
//         source: videoData['source'] ?? '',
//         videoId: null,
//         unUpdatedUrl: videoData['videoUrl'] ?? '',
//       ),
//     ),
//   );
// }

  // void _playVideo(String videoUrl, Duration position) {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => VideoScreen(
  //         videoUrl: videoUrl,
  //         // videoTitle: 'Last Played Video',
  //         channelList: [],
  //         bannerImageUrl: '',
  //         startAtPosition: position,
  //         // genres: '',
  //         // channels: [],
  //         // initialIndex: 1,
  //         videoType: '', isLive: false, isVOD: true, isSearch: false,
  //         isBannerSlider: false, source: '', videoId: null,
  //         unUpdatedUrl: videoUrl,
  //       ),
  //     ),
  //   );
  // }

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
                                  bannerList[index].contentId.toString();
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
                                    imageUrl: banner.banner ?? localImage,
                                    fit: BoxFit.fill,
                                    placeholder: (context, url) => localImage,
                                    errorWidget: (context, url, error) =>
                                        Icon(Icons.error),
                                    cacheKey: banner
                                        .contentId, // Ensure cache key is unique per banner
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
                              // onKeyEvent: (node, event) {
                              //   if (event is KeyDownEvent &&
                              //       event.logicalKey ==
                              //           LogicalKeyboardKey.select) {
                              //     if (selectedContentId != null) {
                              //       fetchAndPlayVideo(
                              //           selectedContentId!, bannerList);
                              //     }
                              //     return KeyEventResult.handled;
                              //   }
                              //   return KeyEventResult.ignored;
                              // },
                              onKeyEvent: (node, event) {
                                if (event is KeyDownEvent) {
                                  if (event.logicalKey ==
                                      LogicalKeyboardKey.arrowDown) {
                                    // Move focus to the first banner in Last Played Video list
                                    if (lastPlayedVideos.length != 0) {
                                      if (lastPlayedVideos.isNotEmpty) {
                                        FocusScope.of(context).requestFocus(
                                            lastPlayedVideos[0]['focusNode']);
                                      }
                                      return KeyEventResult.handled;
                                    }
                                  } else if (event.logicalKey ==
                                      LogicalKeyboardKey.select) {
                                    if (selectedContentId != null) {
                                      fetchAndPlayVideo(
                                          selectedContentId!, bannerList);
                                    }
                                    return KeyEventResult.handled;
                                  }
                                }
                                return KeyEventResult.ignored;
                              },
                              child: GestureDetector(
                                onTap: () {
                                  if (selectedContentId != null) {
                                    fetchAndPlayVideo(
                                        selectedContentId!, bannerList);
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
// RandomLightColorWidget में stored color use करें
                                      RandomLightColorWidget(
                                        hasFocus: _isButtonFocused,
                                        childBuilder: (Color randomColor) {
                                          return Container(
                                            margin: EdgeInsets.all(
                                                screenwdt * 0.001),
                                            padding: EdgeInsets.symmetric(
                                                vertical: screenhgt * 0.02,
                                                horizontal: screenwdt * 0.02),
                                            decoration: BoxDecoration(
                                              color: _isButtonFocused
                                                  ? Colors.black87
                                                  : Colors.black38,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: _isButtonFocused
                                                    ? _currentFocusColor ??
                                                        Colors.transparent
                                                    : Colors.transparent,
                                                width: 2.0,
                                              ),
                                              boxShadow: _isButtonFocused
                                                  ? [
                                                      BoxShadow(
                                                        color:
                                                            _currentFocusColor ??
                                                                Colors
                                                                    .transparent,
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
                                                    ? _currentFocusColor ??
                                                        hintColor
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

                        Positioned(
                          bottom: screenhgt * 0.03,
                          left: 0,
                          right: 0,
                          child: Column(
                            key: refreshKey,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (lastPlayedVideos.length != 0)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10.0),
                                  child: Text(
                                    'Continue Watching',
                                    style: TextStyle(
                                      fontSize:
                                          Headingtextsz, // Adjust the font size as needed
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Colors.white, // Customize the color
                                    ),
                                  ),
                                ),
                              SizedBox(
                                  height: screenhgt *
                                      0.02), // Add some spacing between the heading and the list
                              SizedBox(
                                  height: screenhgt *
                                      0.25, // Fixed height for horizontal ListView
                                  // child: ListView.builder(
                                  //   scrollDirection: Axis.horizontal,
                                  //   padding: EdgeInsets.symmetric(horizontal: 10),
                                  //   itemCount: lastPlayedVideos.length > 10
                                  //       ? 10
                                  //       : lastPlayedVideos.length,
                                  //   itemBuilder: (context, index) {
                                  //     Map<String, dynamic> videoData =
                                  //         lastPlayedVideos[index];
                                  //     FocusNode focusNode =
                                  //         videoData['focusNode'] ?? FocusNode();
                                  //     lastPlayedVideos[index]['focusNode'] =
                                  //         focusNode;

                                  //     return Focus(
                                  //       focusNode: focusNode,
                                  //       onKey: (node, event) {
                                  //         if (event is RawKeyDownEvent) {
                                  //           if (event.logicalKey ==
                                  //                   LogicalKeyboardKey
                                  //                       .arrowRight &&
                                  //               index <
                                  //                   lastPlayedVideos.length - 1) {
                                  //             FocusScope.of(context).requestFocus(
                                  //                 lastPlayedVideos[index + 1]
                                  //                     ['focusNode']);
                                  //             return KeyEventResult.handled;
                                  //           } else if (event.logicalKey ==
                                  //                   LogicalKeyboardKey
                                  //                       .arrowLeft &&
                                  //               index > 0) {
                                  //             FocusScope.of(context).requestFocus(
                                  //                 lastPlayedVideos[index - 1]
                                  //                     ['focusNode']);
                                  //             return KeyEventResult.handled;
                                  //           } else if (event.logicalKey ==
                                  //                   LogicalKeyboardKey.enter ||
                                  //               event.logicalKey ==
                                  //                   LogicalKeyboardKey.select) {
                                  //             _playVideo(videoData,
                                  //                 videoData['position']);
                                  //             return KeyEventResult.handled;
                                  //           }
                                  //         }
                                  //         return KeyEventResult.ignored;
                                  //       },
                                  //       child: GestureDetector(
                                  //         onTap: () {
                                  //           _playVideo(videoData['videoUrl'],
                                  //               videoData['position']);
                                  //         },
                                  //         child: Container(
                                  //           width: screenwdt * 0.15,
                                  //           margin: EdgeInsets.symmetric(
                                  //               horizontal: 5),
                                  //           decoration: BoxDecoration(
                                  //             borderRadius:
                                  //                 BorderRadius.circular(8),
                                  //             color: focusNode.hasFocus
                                  //                 ? Colors.black87
                                  //                 : Colors.black26,
                                  //           ),
                                  //           child: Column(
                                  //             crossAxisAlignment:
                                  //                 CrossAxisAlignment.start,
                                  //             children: [
                                  //               ClipRRect(
                                  //                 borderRadius:
                                  //                     BorderRadius.circular(8),
                                  //                 child: Image.network(
                                  //                   videoData['bannerImageUrl'] ??
                                  //                       localImage,
                                  //                   fit: BoxFit.cover,
                                  //                   width: double.infinity,
                                  //                   height: screenhgt * 0.15,
                                  //                   errorBuilder: (context, error,
                                  //                       stackTrace) {
                                  //                     return Image.asset(
                                  //                         'assets/logo.png',
                                  //                         fit: BoxFit.cover,
                                  //                         width: double.infinity,
                                  //                         height:
                                  //                             screenhgt * 0.15);
                                  //                   },
                                  //                 ),
                                  //               ),
                                  //               SizedBox(
                                  //                   height: screenhgt * 0.02),
                                  //               Padding(
                                  //                 padding:
                                  //                     const EdgeInsets.symmetric(
                                  //                         horizontal: 5),
                                  //                 child: LinearProgressIndicator(
                                  //                   value: videoData['position']
                                  //                           .inMilliseconds /
                                  //                       (Duration(minutes: 60)
                                  //                           .inMilliseconds),
                                  //                   backgroundColor:
                                  //                       Colors.grey.shade300,
                                  //                   valueColor:
                                  //                       AlwaysStoppedAnimation<
                                  //                               Color>(
                                  //                           focusNode.hasFocus
                                  //                               ? Colors.blue
                                  //                               : Colors.green),
                                  //                 ),
                                  //               ),
                                  //               SizedBox(
                                  //                   height: screenhgt * 0.02),
                                  //               Padding(
                                  //                 padding:
                                  //                     const EdgeInsets.symmetric(
                                  //                         horizontal: 5),
                                  //                 child: Text(
                                  //                   videoData['videoName'] ?? '',
                                  //                   style: TextStyle(
                                  //                     fontSize: nametextsz,
                                  //                     color: focusNode.hasFocus
                                  //                         ? Colors.white
                                  //                         : Colors.grey,
                                  //                   ),
                                  //                   overflow:
                                  //                       TextOverflow.ellipsis,
                                  //                 ),
                                  //               ),
                                  //             ],
                                  //           ),
                                  //         ),
                                  //       ),
                                  //     );
                                  //   },
                                  // ),

                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 10),
                                    itemCount: lastPlayedVideos.length > 10
                                        ? 10
                                        : lastPlayedVideos.length,
                                    itemBuilder: (context, index) {
                                      Map<String, dynamic> videoData =
                                          lastPlayedVideos[index];
                                      FocusNode focusNode =
                                          videoData['focusNode'] ?? FocusNode();
                                      lastPlayedVideos[index]['focusNode'] =
                                          focusNode;

                                      return Focus(
                                        focusNode: focusNode,
                                        onKey: (node, event) {
                                          if (event is RawKeyDownEvent) {
                                            if (event.logicalKey ==
                                                    LogicalKeyboardKey
                                                        .arrowRight &&
                                                index <
                                                    lastPlayedVideos.length -
                                                        1) {
                                              FocusScope.of(context)
                                                  .requestFocus(
                                                      lastPlayedVideos[index +
                                                          1]['focusNode']);
                                              return KeyEventResult.handled;
                                            } else if (event.logicalKey ==
                                                    LogicalKeyboardKey
                                                        .arrowLeft &&
                                                index > 0) {
                                              FocusScope.of(context)
                                                  .requestFocus(
                                                      lastPlayedVideos[index -
                                                          1]['focusNode']);
                                              return KeyEventResult.handled;
                                            } else if (event.logicalKey ==
                                                    LogicalKeyboardKey.enter ||
                                                event.logicalKey ==
                                                    LogicalKeyboardKey.select) {
                                              _playVideo(videoData,
                                                  videoData['position']);
                                              return KeyEventResult.handled;
                                            }
                                          }
                                          return KeyEventResult.ignored;
                                        },
                                        child: GestureDetector(
                                          onTap: () => _playVideo(
                                              videoData, videoData['position']),
                                          child: Container(
                                            width: screenwdt * 0.15,
                                            margin: EdgeInsets.symmetric(
                                                horizontal: 5),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              color: focusNode.hasFocus
                                                  ? Colors.black87
                                                  : Colors.black26,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  child: Image.network(
                                                    videoData[
                                                            'bannerImageUrl'] ??
                                                        localImage,
                                                    fit: BoxFit.cover,
                                                    width: double.infinity,
                                                    height: screenhgt * 0.15,
                                                    errorBuilder: (context,
                                                        error, stackTrace) {
                                                      return Image.asset(
                                                          'assets/logo.png',
                                                          fit: BoxFit.cover,
                                                          width:
                                                              double.infinity,
                                                          height:
                                                              screenhgt * 0.15);
                                                    },
                                                  ),
                                                ),
                                                SizedBox(
                                                    height: screenhgt * 0.02),
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(horizontal: 5),
                                                  child:
                                                      LinearProgressIndicator(
                                                    value: videoData['position']
                                                            .inMilliseconds /
                                                        (Duration(minutes: 60)
                                                            .inMilliseconds),
                                                    backgroundColor:
                                                        Colors.grey.shade300,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                                Color>(
                                                            focusNode.hasFocus
                                                                ? Colors.blue
                                                                : Colors.green),
                                                  ),
                                                ),
                                                SizedBox(
                                                    height: screenhgt * 0.02),
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(horizontal: 5),
                                                  child: Text(
                                                    videoData['videoName'] ??
                                                        '',
                                                    style: TextStyle(
                                                      fontSize: nametextsz,
                                                      color: focusNode.hasFocus
                                                          ? Colors.white
                                                          : Colors.grey,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ))
                            ],
                          ),
                        ),
                      ],
                    ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:mobi_tv_entertainment/main.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../video_widget/video_screen.dart';

// class LastPlayedVideoScreen extends StatefulWidget {
//   @override
//   _LastPlayedVideoScreenState createState() => _LastPlayedVideoScreenState();
// }

// class _LastPlayedVideoScreenState extends State<LastPlayedVideoScreen> {
//   List<Map<String, dynamic>> lastPlayedVideos = [];

//   @override
//   void initState() {
//     super.initState();
//     _loadLastPlayedVideos();
//   }

// Future<void> _loadLastPlayedVideos() async {
//   SharedPreferences prefs = await SharedPreferences.getInstance();
//   List<String>? storedVideos = prefs.getStringList('last_played_videos');

//   if (storedVideos != null && storedVideos.isNotEmpty) {
//     setState(() {
//       lastPlayedVideos = storedVideos.map((videoEntry) {
//         List<String> details = videoEntry.split('|');
//         print("Banner URL: ${details[2]}");

//         return {
//           'videoUrl': details[0], // Video URL
//           'position': Duration(milliseconds: int.parse(details[1])), // Playback position
//           'bannerImageUrl': details[2],  // Banner image URL

//         };

//       }).toList();
//     });

//   }
// }

// void _playVideo(String videoUrl, Duration position) {
//   Navigator.push(
//     context,
//     MaterialPageRoute(
//       builder: (context) => VideoScreen(
//         videoUrl: videoUrl,
//         videoTitle: 'Last Played Video',
//         channelList: [],
//         bannerImageUrl: '',
//         startAtPosition: position,
//         genres: '',
//         channels: [],
//         initialIndex: 1,
//       ),
//     ),
//   );
// }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(

//       body: lastPlayedVideos.isEmpty
//           ? Center(child: Text('No last played videos available'))
//           : GridView.builder(
//   gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//     crossAxisCount: 3,  // 3 videos per row
//     crossAxisSpacing: 10,
//     mainAxisSpacing: 10,
//     childAspectRatio: 16 / 9,
//   ),
//   itemCount: lastPlayedVideos.length,
//   itemBuilder: (context, index) {
//     Map<String, dynamic> videoData = lastPlayedVideos[index];
//     String bannerUrl = videoData['bannerImageUrl']??localImage;

//     return GestureDetector(
//       onTap: () => _playVideo(videoData['videoUrl'], videoData['position']),
//       child: GridTile(
//         child: Stack(
//           children: [
//             // Display the image using the banner URL
//             Image.network(
//               bannerUrl,
//               fit: BoxFit.cover,
//               width: double.infinity,
//               height: double.infinity,
//               errorBuilder: (context, error, stackTrace) {
//                 // Fallback image if the banner URL is invalid
//                 return Image.asset(
//                   'assets/logo.png',  // Use a valid path to your default image
//                   fit: BoxFit.cover,
//                   width: double.infinity,
//                   height: double.infinity,
//                 );
//               },
//             ),
//             Align(
//               alignment: Alignment.bottomCenter,
//               child: Container(
//                 color: Colors.black.withOpacity(0.5),
//                 padding: EdgeInsets.all(4),
//                 child: Text(
//                   'Last Played: ${videoData['position'].inMinutes} min',
//                   style: TextStyle(color: Colors.white),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   },
// )

//     );
//   }
// }
