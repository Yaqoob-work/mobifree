import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as https;
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';
import '../../video_widget/socket_service.dart';
import '../../video_widget/video_screen.dart';
import '../../widgets/models/news_item_model.dart';
import '../../widgets/utils/color_service.dart';
import '../../widgets/utils/random_light_color_widget.dart';

// class NewsItemModel {
//   final String id;
//   final String content_id;
//   late final String url;
//   final String name;
//   final String banner;
//   late final String streamType;
//   final String genres;
//   final String status;

//   NewsItemModel({
//     required this.id,
//     required this.content_id,
//     required this.url,
//     required this.name,
//     required this.banner,
//     required this.streamType,
//     required this.genres,
//     required this.status,
//   });

//   factory NewsItemModel.fromJson(Map<String, dynamic> json) {
//     return NewsItemModel(
//       id: json['id'] ?? '',
//       content_id: json['content_id'] ?? '',
//       url: json['url'] ?? '',
//       name: json['name'] ?? '',
//       banner: json['banner'] ?? '',
//       streamType: json['stream_type'] ?? '',
//       genres: json['genres'] ?? '',
//       status: json['status'] ?? '',
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'content_id': content_id,
//       'url': url,
//       'name': name,
//       'banner': banner,
//       'stream_type': streamType,
//       'genres': genres,
//       'status': status,
//     };
//   }

//   NewsItemModel copyWith({
//     String? id,
//     String? content_id,
//     String? url,
//     String? name,
//     String? banner,
//     String? streamType,
//     String? genres,
//     String? status,
//   }) {
//     return NewsItemModel(
//       id: id ?? this.id,
//       content_id: content_id ?? this.content_id,
//       url: url ?? this.url,
//       name: name ?? this.name,
//       banner: banner ?? this.banner,
//       streamType: streamType ?? this.streamType,
//       genres: genres ?? this.genres,
//       status: status ?? this.status,
//     );
//   }
// }

//  Future<Map<String, String>> fetchLiveFeaturedTVById(int contentId) async {
//   final prefs = await SharedPreferences.getInstance();
//   final cachedData = prefs.getString('live_featured_tv');

//   List<dynamic> responseData;

//   if (cachedData != null) {
//     responseData = json.decode(cachedData);
//   } else {
//     final response = await https.get(
//       Uri.parse('https://api.ekomflix.com/android/getFeaturedLiveTV'),
//       headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
//     );

//     if (response.statusCode == 200) {
//       responseData = json.decode(response.body);
//       prefs.setString('live_featured_tv', json.encode(responseData));
//     } else {
//       throw Exception('Failed to load featured live TV');
//     }
//   }

//   final matchedItem = responseData.firstWhere(
//     (channel) => channel['id'].toString() == contentId,
//     orElse: () => null,
//   );

//   if (matchedItem != null) {
//     return {
//       'url': matchedItem['url'] ?? '',
//       'type': matchedItem['type'] ?? '',
//     };
//   } else {
//     throw Exception('No matching channel found for id $contentId');
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
  final SocketService _socketService = SocketService();
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
    _socketService.initSocket(); // Initialize SocketService
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
    _timer.cancel();
    _buttonFocusNode.dispose();
    _lastPlayedBannerFocusNode.dispose();
    _socketService.dispose(); // Dispose of the SocketService
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

// BannerSlider में _loadLastPlayedVideos में सुधार
  Future<void> _loadLastPlayedVideos() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String>? storedVideos = prefs.getStringList('last_played_videos');

      if (storedVideos != null && storedVideos.isNotEmpty) {
        setState(() {
          lastPlayedVideos = storedVideos.map((videoEntry) {
            List<String> details = videoEntry.split('|');
            return {
              'videoUrl': details[0],
              'position': Duration(milliseconds: int.parse(details[1])),
              'bannerImageUrl': details[2],
              'videoName': details.length > 3 ? details[3] : 'Untitled Video',
              'focusNode': FocusNode(),
            };
          }).toList();
        });
      }
    } catch (e) {
      print("Error loading last played videos: $e");
    }
  }

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
                videoType: responseData['type']!,
                isLive: true,
                isVOD: false,
                bannerImageUrl: responseData['banner']!,
                startAtPosition: Duration.zero,
                isBannerSlider: true,
                source: 'isBannerSlider',
                isSearch: false,
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

  // Future<void> fetchAndPlayVideo(
  //     String contentId, List<NewsItemModel> channelList) async {
  //   if (_isNavigating) return; // Prevent duplicate navigation
  //   _isNavigating = true;

  //   bool shouldPlayVideo = true;
  //   bool shouldPop = true;

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
  //         child: SpinKitFadingCircle(
  //           color: borderColor,
  //           size: 50.0,
  //         ),
  //       );
  //     },
  //   );

  //   try {
  //     final response = await https.get(
  //       Uri.parse('https://api.ekomflix.com/android/getFeaturedLiveTV'),
  //       headers: {
  //         'x-api-key': 'vLQTuPZUxktl5mVW',
  //       },
  //     );

  //     if (response.statusCode == 200) {
  //       final List<dynamic> responseData = json.decode(response.body);
  //       final filteredData = responseData.firstWhere(
  //         (channel) => channel['id'].toString() == contentId,
  //         orElse: () => null,
  //       );

  //       if (filteredData != null) {
  //         String videoUrl = filteredData['url'] ?? '';

  //         if (filteredData['stream_type'] == 'YoutubeLive' ||
  //             filteredData['type'] == 'Youtube') {
  //           for (int i = 0; i < _maxRetries; i++) {
  //             try {
  //               videoUrl = await _socketService.getUpdatedUrl(videoUrl);
  //               filteredData['url'] = videoUrl;
  //               filteredData['stream_type'] = "M3u8";
  //               break;
  //             } catch (e) {
  //               if (i == _maxRetries - 1) rethrow;
  //               await Future.delayed(Duration(seconds: _retryDelay));
  //             }
  //           }
  //         }

  //         if (shouldPop) {
  //           Navigator.of(context, rootNavigator: true).pop();
  //         }

  //         if (shouldPlayVideo) {
  //           Navigator.push(
  //             context,
  //             MaterialPageRoute(
  //               builder: (context) => VideoScreen(
  //                 videoUrl: filteredData['url'],
  //                 channelList: channelList,
  //                 videoType: filteredData['type']!,
  //                 isLive: true,
  //                 isVOD: false,
  //                 bannerImageUrl: filteredData['banner'] ?? localImage,
  //                 startAtPosition: Duration.zero,
  //               ),
  //             ),
  //           ).then((_) {
  //             _isNavigating = false;
  //           });
  //         }
  //       } else {
  //         throw Exception('Video not found');
  //       }
  //     } else {
  //       throw Exception('Failed to load featured live TV');
  //     }
  //   } catch (e) {
  //     if (shouldPop) {
  //       Navigator.of(context, rootNavigator: true).pop();
  //     }
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Something Went Wrong: ${e.toString()}')),
  //     );
  //   } finally {
  //     _isNavigating = false;
  //   }
  // }

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

  void _playVideo(String videoUrl, Duration position) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoScreen(
          videoUrl: videoUrl,
          // videoTitle: 'Last Played Video',
          channelList: [],
          bannerImageUrl: '',
          startAtPosition: position,
          // genres: '',
          // channels: [],
          // initialIndex: 1,
          videoType: '', isLive: false, isVOD: true, isSearch: false,
          isBannerSlider: false, source: '',
        ),
      ),
    );
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
                                              color: _isButtonFocused
                                                  ? Colors.black87
                                                  : Colors.black38,
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
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: EdgeInsets.symmetric(horizontal: 10),
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
                                                  lastPlayedVideos.length - 1) {
                                            FocusScope.of(context).requestFocus(
                                                lastPlayedVideos[index + 1]
                                                    ['focusNode']);
                                            return KeyEventResult.handled;
                                          } else if (event.logicalKey ==
                                                  LogicalKeyboardKey
                                                      .arrowLeft &&
                                              index > 0) {
                                            FocusScope.of(context).requestFocus(
                                                lastPlayedVideos[index - 1]
                                                    ['focusNode']);
                                            return KeyEventResult.handled;
                                          } else if (event.logicalKey ==
                                                  LogicalKeyboardKey.enter ||
                                              event.logicalKey ==
                                                  LogicalKeyboardKey.select) {
                                            _playVideo(videoData['videoUrl'],
                                                videoData['position']);
                                            return KeyEventResult.handled;
                                          }
                                        }
                                        return KeyEventResult.ignored;
                                      },
                                      child: GestureDetector(
                                        onTap: () {
                                          _playVideo(videoData['videoUrl'],
                                              videoData['position']);
                                        },
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
                                                  videoData['bannerImageUrl'] ??
                                                      localImage,
                                                  fit: BoxFit.cover,
                                                  width: double.infinity,
                                                  height: screenhgt * 0.15,
                                                  errorBuilder: (context, error,
                                                      stackTrace) {
                                                    return Image.asset(
                                                        'assets/logo.png',
                                                        fit: BoxFit.cover,
                                                        width: double.infinity,
                                                        height: screenhgt * 0.15);
                                                  },
                                                ),
                                              ),
                                              SizedBox(
                                                  height: screenhgt * 0.02),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 5),
                                                child: LinearProgressIndicator(
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
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 5),
                                                child: Text(
                                                  videoData['videoName'] ?? '',
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
                                ),
                              )
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
