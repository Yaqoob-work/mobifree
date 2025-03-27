// banner_slider.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as https;
import 'package:mobi_tv_entertainment/main.dart';
import 'package:mobi_tv_entertainment/provider/color_provider.dart';
import 'package:mobi_tv_entertainment/provider/focus_provider.dart';
import 'package:mobi_tv_entertainment/provider/shared_data_provider.dart';
import 'package:mobi_tv_entertainment/video_widget/socket_service.dart';
import 'package:mobi_tv_entertainment/video_widget/video_screen.dart';
import 'package:mobi_tv_entertainment/widgets/models/news_item_model.dart';
import 'package:mobi_tv_entertainment/widgets/small_widgets/loading_indicator.dart';
import 'package:mobi_tv_entertainment/widgets/utils/color_service.dart';
import 'package:mobi_tv_entertainment/widgets/utils/random_light_color_widget.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Future<Map<String, String>> fetchLiveFeaturedTVById(String contentId) async {
//   final prefs = await SharedPreferences.getInstance();
//   final cachedData = prefs.getString('live_featured_tv');

//   List<dynamic> responseData;

//   // Use cached data if available
//   if (cachedData != null) {
//     responseData = json.decode(cachedData);
//   } else {
//     // Fetch from API if cache is not available
//     final response = await https.get(
//       Uri.parse('https://api.ekomflix.com/android/getFeaturedLiveTV'),
//       headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
//     );

//     if (response.statusCode == 200) {
//       responseData = json.decode(response.body);
//       // Cache the data
//       prefs.setString('live_featured_tv', json.encode(responseData));
//     } else {
//       throw Exception('Failed to load featured live TV');
//     }
//   }

//   // Find the matched item by id
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

  try {
    // Use cached data if available
    if (cachedData != null) {
      responseData = json.decode(cachedData);
    } else {
      // Fetch from API if cache is not available
      final response = await https.get(
        Uri.parse('https://api.ekomflix.com/android/getFeaturedLiveTV'),
        headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load featured live TV');
      }

      responseData = json.decode(response.body);
      // Cache the data
      await prefs.setString('live_featured_tv', response.body);
    }

    // Find the matched item by id
    final matchedItem = responseData.firstWhere(
      (channel) => channel['id'].toString() == contentId,
      orElse: () => null,
    );

    if (matchedItem == null) {
      throw Exception('No matching channel found for id $contentId');
    }

    return {
      'url': matchedItem['url'] ?? '',
      'type': matchedItem['type'] ?? '',
      'banner': matchedItem['banner'] ?? '',
      'name': matchedItem['name'] ?? '',
      'stream_type': matchedItem['stream_type'] ?? '',
    };
  } catch (e) {
    throw Exception('Error fetching video data: ${e.toString()}');
  }
}

class BannerSlider extends StatefulWidget {
  final Function(bool)? onFocusChange;
  const BannerSlider(
      {Key? key, this.onFocusChange, required FocusNode focusNode})
      : super(key: key);
  @override
  _BannerSliderState createState() => _BannerSliderState();
}

class _BannerSliderState extends State<BannerSlider> {
  List<Map<String, dynamic>> lastPlayedVideos = [];
  late SharedDataProvider sharedDataProvider;

  final SocketService _socketService = SocketService();
  List<NewsItemModel> bannerList = [];
  Map<String, Color> bannerColors = {};
  bool isLoading = true;
  String errorMessage = '';
  late PageController _pageController;
  late Timer _timer;
  String? selectedContentId;
  final FocusNode _buttonFocusNode = FocusNode();
  // late FocusNode _buttonFocusNode;
  bool _isNavigating = false;
  final int _maxRetries = 3;
  final int _retryDelay = 5;
  final PaletteColorService _paletteColorService = PaletteColorService();
  late StreamSubscription refreshSubscription;
  Key refreshKey = UniqueKey();
  late ScrollController _lastPlayedScrollController;
  double _itemWidth = 0;

  @override
  void initState() {
    super.initState();
    _lastPlayedScrollController = ScrollController();
    sharedDataProvider = context.read<SharedDataProvider>();
    sharedDataProvider.updateLastPlayedVideos(lastPlayedVideos);
    _socketService.initSocket();
    // printLastPlayedPositions();
    _pageController = PageController();
    // _loadLastPlayedVideoData();
    // _loadLastPlayedVideoProgress();
    // debugSaveTestData();

    _buttonFocusNode.addListener(() {
      if (_buttonFocusNode.hasFocus) {
        widget.onFocusChange?.call(true);
      }
    });

    refreshSubscription =
        GlobalEventBus.eventBus.on<RefreshPageEvent>().listen((event) {
      if (event.pageId == 'uniquePageId') {
        _loadLastPlayedVideos();
        Future.delayed(Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              refreshKey = UniqueKey();
            });
            _loadLastPlayedVideos();
          }
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FocusProvider>().setWatchNowFocusNode(_buttonFocusNode);

      if (lastPlayedVideos.isNotEmpty) {
        final firstBannerFocusNode =
            lastPlayedVideos[0]['focusNode'] as FocusNode;
        context
            .read<FocusProvider>()
            .setFirstLastPlayedFocusNode(firstBannerFocusNode);
        print("Registered first last played video's focus node");
      }
    });

    _buttonFocusNode.addListener(_onButtonFocusNode);
    _loadLastPlayedVideos();
    _loadCachedData().then((_) {
      if (bannerList.isNotEmpty) {
        _startAutoSlide();
      }
    });
  }

  @override
  void dispose() {
    for (int i = 0; i < lastPlayedVideos.length; i++) {
      context.read<FocusProvider>().unregisterElementKey('lastPlayed_$i');
    }
    _lastPlayedScrollController.dispose();
    _pageController.dispose();
    _socketService.dispose();
    _timer.cancel();
    _buttonFocusNode.dispose();
    refreshSubscription.cancel();
    super.dispose();
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

  Future<Map<String, dynamic>> _getLastPlayedVideo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? lastVideoDuration = prefs.getInt('last_video_duration');
    int? lastVideoPosition = prefs.getInt('last_video_position');

    return {
      "duration": lastVideoDuration ?? 0,
      "position": lastVideoPosition ?? 0,
    };
  }

  bool isYoutubeUrl(String? url) {
    if (url == null || url.isEmpty) {
      return false;
    }

    url = url.toLowerCase().trim();

    // First check if it's a YouTube ID (exactly 11 characters)
    bool isYoutubeId = RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(url);
    if (isYoutubeId) {
      // print("Matched YouTube ID pattern: $url");
      return true;
    }

    // Then check for regular YouTube URLs
    bool isYoutubeUrl = url.contains('youtube.com') ||
        url.contains('youtu.be') ||
        url.contains('youtube.com/shorts/');
    if (isYoutubeUrl) {
      // print("Matched YouTube URL pattern: $url");
      return true;
    }

    // print("Not a YouTube URL/ID: $url");
    return false;
  }

  String formatUrl(String url, {Map<String, String>? params}) {
    if (url.isEmpty) {
      // print("Warning: Empty URL provided");
      throw Exception("Empty URL provided");
    }

    // Handle YouTube ID by converting to full URL if needed
    if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(url)) {
      // print("Converting YouTube ID to full URL");
      url = "https://www.youtube.com/watch?v=$url";
    }

    // Remove any existing query parameters
    url = url.split('?')[0];

    // Add new query parameters
    if (params != null && params.isNotEmpty) {
      url += '?' + params.entries.map((e) => '${e.key}=${e.value}').join('&');
    }

    // print("Formatted URL: $url");
    return url;
  }

  void _onButtonFocusNode() {
    if (_buttonFocusNode.hasFocus) {
      final random = Random();
      final color = Color.fromRGBO(
        random.nextInt(256),
        random.nextInt(256),
        random.nextInt(256),
        1,
      );
      context.read<FocusProvider>().setButtonFocus(true, color: color);
      context.read<ColorProvider>().updateColor(color, true);
    } else {
      context.read<FocusProvider>().resetFocus();
      context.read<ColorProvider>().resetColor();
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

    if (bannerList.isNotEmpty) {
      await _fetchBannerColors();
    }
  } else {
    setState(() => isLoading = false);
  }

  // Background mein data fetch karne ke liye
  fetchBanners(isBackgroundFetch: true);
}






  // Future<void> _loadCachedData() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final cachedBanners = prefs.getString('banners');

  //   if (cachedBanners != null) {
  //     final List<dynamic> responseData = json.decode(cachedBanners);
  //     setState(() {
  //       bannerList = responseData
  //           .where((banner) => banner['status'] == "1")
  //           .map((banner) => NewsItemModel.fromJson(banner))
  //           .toList();

  //       selectedContentId = bannerList.isNotEmpty ? bannerList[0].id : null;
  //       isLoading = false;
  //     });

  //     if (bannerList.isNotEmpty) {
  //       await _fetchBannerColors();
  //     }
  //   } else {
  //     setState(() => isLoading = false);
  //   }

  //   fetchBanners(isBackgroundFetch: true);
  // }


  
Future<void> fetchBanners({bool isBackgroundFetch = false}) async {
  final prefs = await SharedPreferences.getInstance();
  final cachedBanners = prefs.getString('banners');

  try {
    final response = await https.get(
      Uri.parse('https://api.ekomflix.com/android/getCustomImageSlider'),
      headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> responseData = json.decode(response.body);

      // **Check if API response is different from cached data**
      if (cachedBanners != null &&
          json.encode(json.decode(cachedBanners)) == json.encode(responseData)) {
        return; // No update needed
      }

      setState(() {
        bannerList = responseData
            .where((banner) => banner['status'] == "1")
            .map((banner) => NewsItemModel.fromJson(banner))
            .toList();

        selectedContentId = bannerList.isNotEmpty ? bannerList[0].id : null;
        isLoading = false;
      });

      await prefs.setString('banners', response.body);
      await _fetchBannerColors();
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

  // Future<void> fetchBanners({bool isBackgroundFetch = false}) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final cachedBanners = prefs.getString('banners');

  //   try {
  //     final response = await https.get(
  //       Uri.parse('https://api.ekomflix.com/android/getCustomImageSlider'),
  //       headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
  //     );

  //     if (response.statusCode == 200) {
  //       final List<dynamic> responseData = json.decode(response.body);

  //       if (cachedBanners != null &&
  //           json.encode(json.decode(cachedBanners)) ==
  //               json.encode(responseData)) {
  //         return;
  //       }

  //       setState(() {
  //         bannerList = responseData
  //             .where((banner) => banner['status'] == "1")
  //             .map((banner) => NewsItemModel.fromJson(banner))
  //             .toList();

  //         selectedContentId = bannerList.isNotEmpty ? bannerList[0].id : null;
  //         isLoading = false;
  //       });

  //       await prefs.setString('banners', response.body);
  //       await _fetchBannerColors();
  //       _startAutoSlide();
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
  //     final responseData = await fetchLiveFeaturedTVById(contentId);

  //     // final filteredData = responseData.firstWhere(
  //     //   (channel) => channel['id'].toString() == contentId,
  //     //   orElse: () => null,
  //     // );

  //     if (responseData != null) {
  //       String originalUrl = responseData['url'] ?? '';
  //       String videoUrl = responseData['url'] ?? '';

  //       if (responseData['stream_type'] == 'YoutubeLive' ||
  //           responseData['type'] == 'Youtube') {
  //         for (int i = 0; i < _maxRetries; i++) {
  //           try {
  //             videoUrl = await _socketService.getUpdatedUrl(videoUrl);
  //             responseData['url'] = videoUrl;
  //             responseData['stream_type'] = "M3u8";
  //             break;
  //           } catch (e) {
  //             if (i == _maxRetries - 1) rethrow;
  //             await Future.delayed(Duration(seconds: _retryDelay));
  //           }
  //         }
  //       }
  //       bool liveStatus = false;
  //       if (responseData['stream_type'] == 'YoutubeLive' ||
  //           responseData['type'] == 'Youtube') {
  //         setState(() {
  //           liveStatus = true;
  //         });
  //       }
  //       {
  //         setState(() {
  //           liveStatus = false;
  //         });
  //       }

  //       if (shouldPop) {
  //         Navigator.of(context, rootNavigator: true).pop();
  //       }

  //       if (shouldPlayVideo) {
  //         Navigator.push(
  //           context,
  //           MaterialPageRoute(
  //             builder: (context) => VideoScreen(
  //               videoUrl: responseData['url']!,
  //               channelList: channelList,
  //               videoId: int.parse(contentId),
  //               videoType: responseData['type']!,
  //               isLive: true,
  //               isVOD: false,
  //               bannerImageUrl: responseData['banner']!,
  //               startAtPosition: Duration.zero,
  //               isBannerSlider: true,
  //               source: 'isBannerSlider',
  //               isSearch: false,
  //               unUpdatedUrl: originalUrl,
  //               name: responseData['name']!,
  //               liveStatus: liveStatus,
  //             ),
  //           ),
  //         ).then((_) {
  //           _isNavigating = false;
  //         });
  //       }
  //     } else {
  //       throw Exception('Video not found');
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

  Future<void> fetchAndPlayVideo(
      String contentId, List<NewsItemModel> channelList) async {
    if (_isNavigating) return;
    _isNavigating = true;

    bool shouldPlayVideo = true;
    bool shouldPop = true;

    try {
      // Show loading indicator
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

      // Fetch video data with null safety
      final responseData = await fetchLiveFeaturedTVById(contentId);
      if (responseData == null || responseData['url'] == null) {
        throw Exception('Invalid video data received');
      }

      String originalUrl = responseData['url'] ?? '';
      String videoUrl = responseData['url'] ?? '';
      String videoType = responseData['type'] ?? '';

      // Handle YouTube videos
      bool isYoutube = videoType.toLowerCase() == 'youtube' ||
          responseData['stream_type']?.toLowerCase() == 'youtubelive';

      if (isYoutube) {
        for (int i = 0; i < _maxRetries; i++) {
          try {
            videoUrl = await _socketService.getUpdatedUrl(videoUrl);
            if (videoUrl.isEmpty) throw Exception('Failed to get updated URL');
            break;
          } catch (e) {
            if (i == _maxRetries - 1) rethrow;
            await Future.delayed(Duration(seconds: _retryDelay));
          }
        }
      }

      // Determine live status
      bool liveStatus = isYoutube ||
          responseData['stream_type']?.toLowerCase() == 'youtubelive';

      if (shouldPop && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (shouldPlayVideo && context.mounted) {
        // Create video screen with null-safe parameters
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoScreen(
              videoUrl: videoUrl,
              channelList: channelList,
              videoId: int.tryParse(contentId) ?? 0,
              videoType: videoType,
              isLive: true,
              isVOD: false,
              bannerImageUrl: responseData['banner'] ?? '',
              startAtPosition: Duration.zero,
              isBannerSlider: true,
              source: 'isBannerSlider',
              isSearch: false,
              unUpdatedUrl: originalUrl,
              name: responseData['name'] ?? '',
              liveStatus: liveStatus,
            ),
          ),
        );
      }
    } catch (e) {
      if (shouldPop && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to play video: ${e.toString()}'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      _isNavigating = false;
    }
  }

  void _scrollToFocusedItem(int index) {
    if (!_lastPlayedScrollController.hasClients) return;

    _itemWidth = screenwdt * 0.15 + 10;
    double targetOffset = index * _itemWidth;
    double currentOffset = _lastPlayedScrollController.offset;
    double viewportWidth =
        _lastPlayedScrollController.position.viewportDimension;

    if (targetOffset < currentOffset ||
        targetOffset + _itemWidth > currentOffset + viewportWidth) {
      _lastPlayedScrollController.animateTo(
        targetOffset,
        duration: Duration(milliseconds: 1000),
        curve: Curves.linear ,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FocusProvider>(
      builder: (context, focusProvider, child) {
        return Scaffold(
          backgroundColor: cardColor,
          body: isLoading
              ? Center(
                  child: SpinKitFadingCircle(color: borderColor, size: 50.0))
              : errorMessage.isNotEmpty
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
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
                                      child: CachedNetworkImage(
                                        imageUrl: banner.banner ?? localImage,
                                        fit: BoxFit.fill,
                                        placeholder: (context, url) =>
                                            localImage,
                                        errorWidget: (context, url, error) =>
                                            Icon(Icons.error),
                                        cacheKey: banner.contentId,
                                        fadeInDuration:
                                            Duration(milliseconds: 500),
                                        memCacheHeight: 800,
                                        memCacheWidth: 1200,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),

                            // Watch Now button
                            Positioned(
                              top: screenhgt * 0.03,
                              left: screenwdt * 0.02,
                              child: Focus(
                                // key: context.read<FocusProvider>().watchNowKey,
                                focusNode: _buttonFocusNode,
                                onKeyEvent: (node, event) {
                                  if (event.logicalKey ==
                                      LogicalKeyboardKey.arrowRight) {
                                    // Move to the next banner
                                    if (_pageController.page != null &&
                                        _pageController.page! <
                                            bannerList.length - 1) {
                                      _pageController.nextPage(
                                        duration: Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                      );
                                      return KeyEventResult.handled;
                                    }
                                  } else if (event.logicalKey ==
                                      LogicalKeyboardKey.arrowLeft) {
                                    // Move to the previous banner
                                    if (_pageController.page != null &&
                                        _pageController.page! > 0) {
                                      _pageController.previousPage(
                                        duration: Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                      );
                                      return KeyEventResult.handled;
                                    }
                                  } else if (event is KeyDownEvent) {
                                    if (event.logicalKey ==
                                        LogicalKeyboardKey.arrowDown) {
                                      if (lastPlayedVideos.isNotEmpty) {
                                        context
                                            .read<FocusProvider>()
                                            .requestLastPlayedFocus();

                                        FocusScope.of(context).requestFocus(
                                            lastPlayedVideos[0]['focusNode']);
                                        // context
                                        //     .read<FocusProvider>()
                                        //     .setLastPlayedFocus(0);
                                        // WidgetsBinding.instance
                                        //     .addPostFrameCallback((_) {
                                        //   _scrollToFocusedItem(0);
                                        // });
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
                                child: Column(
                                  children: [
                                    RandomLightColorWidget(
                                      hasFocus: focusProvider.isButtonFocused,
                                      childBuilder: (Color randomColor) {
                                        return Container(
                                          margin:
                                              EdgeInsets.all(screenwdt * 0.001),
                                          padding: EdgeInsets.symmetric(
                                              vertical: screenhgt * 0.02,
                                              horizontal: screenwdt * 0.02),
                                          decoration: BoxDecoration(
                                            color: focusProvider.isButtonFocused
                                                ? Colors.black87
                                                : Colors.black38,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                              color: focusProvider
                                                      .isButtonFocused
                                                  ? focusProvider
                                                          .currentFocusColor ??
                                                      Colors.transparent
                                                  : Colors.transparent,
                                              width: 2.0,
                                            ),
                                            boxShadow: focusProvider
                                                    .isButtonFocused
                                                ? [
                                                    BoxShadow(
                                                      color: focusProvider
                                                              .currentFocusColor ??
                                                          Colors.transparent,
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
                                              color: focusProvider
                                                      .isButtonFocused
                                                  ? focusProvider
                                                          .currentFocusColor ??
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

                            // Continue Watching Section
                            if (lastPlayedVideos.isNotEmpty)
                              Positioned(
                                bottom: screenhgt * 0.03,
                                left: 0,
                                right: 0,
                                child: Container(
                                  child: Column(
                                    key: refreshKey,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10.0),
                                        child: Text(
                                          'Continue Watching',
                                          style: TextStyle(
                                            fontSize: Headingtextsz,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: screenhgt * 0.02),
                                      SizedBox(
                                        height: screenhgt * 0.35,
                                        child: ListView.builder(
                                            controller:
                                                _lastPlayedScrollController,
                                            scrollDirection: Axis.horizontal,
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 10),
                                            itemCount:
                                                lastPlayedVideos.length > 10
                                                    ? 10
                                                    : lastPlayedVideos.length,
                                            itemBuilder: (context, index) {
                                              Map<String, dynamic> videoData =
                                                  lastPlayedVideos[index];
                                              FocusNode focusNode =
                                                  videoData['focusNode'] ??
                                                      FocusNode();
                                              lastPlayedVideos[index]
                                                  ['focusNode'] = focusNode;
                                              final bool isBase64 =
                                                  videoData['bannerImageUrl']
                                                          ?.startsWith(
                                                              'data:image') ??
                                                      false;
                                              // print('videoData bannerImageUrl: ${videoData['bannerImageUrl']}');

                                              // Generate a unique key for each item
                                              final GlobalKey itemKey =
                                                  GlobalKey();
                                              context
                                                  .read<FocusProvider>()
                                                  .registerElementKey(
                                                      'lastPlayed_$index',
                                                      itemKey);

                                              // First item special handling for focus
                                              if (index == 0) {
                                                WidgetsBinding.instance
                                                    .addPostFrameCallback((_) {
                                                  context
                                                      .read<FocusProvider>()
                                                      .setFirstLastPlayedFocusNode(
                                                          focusNode);
                                                });
                                              }

                                              return Container(
                                                // key: ValueKey(
                                                //     'last_played_$index'),
                                                key: itemKey,
                                                child: Focus(
                                                  focusNode: focusNode,
                                                  onFocusChange: (hasFocus) {
                                                    if (hasFocus) {
                                                      WidgetsBinding.instance
                                                          .addPostFrameCallback(
                                                              (_) {
                                                        // _scrollToFocusedItem(
                                                        //     index);
                                                        setState(() {
                                                          _scrollToFocusedItem(
                                                              index);
                                                        });
                                                        context
                                                            .read<
                                                                FocusProvider>()
                                                            .scrollToElement(
                                                                'lastPlayed_$index');
                                                        context
                                                            .read<
                                                                FocusProvider>()
                                                            .setLastPlayedFocus(
                                                                index);
                                                      });
                                                    }
                                                  },
                                                  onKey: (node, event) {
                                                    if (event
                                                        is RawKeyDownEvent) {
                                                      if (event.logicalKey ==
                                                          LogicalKeyboardKey
                                                              .arrowUp) {
                                                        // if (index == 0) { // Only first item can navigate to music list
                                                        print(
                                                            "Up arrow pressed in last played"); // Debug log
                                                        // context
                                                        //     .read<
                                                        //         FocusProvider>()
                                                        //     .requestMusicItemFocus();
                                                        //                                                         WidgetsBinding.instance.addPostFrameCallback((_) {
                                                        //   context.read<FocusProvider>().setWatchNowFocusNode(_buttonFocusNode);
                                                        // });

                                                        // General HomeScreen focus handling (Watch Now button)
                                                        Future.delayed(
                                                            Duration(
                                                                milliseconds:
                                                                    100), () {
                                                          context
                                                              .read<
                                                                  FocusProvider>()
                                                              .requestWatchNowFocus();
                                                        });

                                                        return KeyEventResult
                                                            .handled;
                                                        // }
                                                      } else if (event
                                                              .logicalKey ==
                                                          LogicalKeyboardKey
                                                              .arrowDown) {
                                                        // if (index == 0) { // Only first item can navigate to music list
                                                        print(
                                                            "Down arrow pressed in last played"); // Debug log
                                                        context
                                                            .read<
                                                                FocusProvider>()
                                                            .requestMusicItemFocus(
                                                                context);
                                                        return KeyEventResult
                                                            .handled;
                                                        // }
                                                      } else if (event
                                                              .logicalKey ==
                                                          LogicalKeyboardKey
                                                              .arrowRight) {
                                                        if (index <
                                                            lastPlayedVideos
                                                                    .length -
                                                                1) {
                                                          FocusScope.of(context)
                                                              .requestFocus(
                                                                  lastPlayedVideos[
                                                                          index +
                                                                              1]
                                                                      [
                                                                      'focusNode']);
                                                          return KeyEventResult
                                                              .handled;
                                                        }
                                                      } else if (event
                                                              .logicalKey ==
                                                          LogicalKeyboardKey
                                                              .arrowLeft) {
                                                        if (index > 0) {
                                                          FocusScope.of(context)
                                                              .requestFocus(
                                                                  lastPlayedVideos[
                                                                          index -
                                                                              1]
                                                                      [
                                                                      'focusNode']);
                                                          return KeyEventResult
                                                              .handled;
                                                        }
                                                      } else if (event
                                                              .logicalKey ==
                                                          LogicalKeyboardKey
                                                              .arrowUp) {
                                                        FocusScope.of(context)
                                                            .requestFocus(
                                                                _buttonFocusNode);
                                                        context
                                                            .read<
                                                                FocusProvider>()
                                                            .resetFocus();
                                                        return KeyEventResult
                                                            .handled;
                                                      } else if (event
                                                                  .logicalKey ==
                                                              LogicalKeyboardKey
                                                                  .select ||
                                                          event.logicalKey ==
                                                              LogicalKeyboardKey
                                                                  .enter) {
                                                        _playVideo(
                                                            videoData,
                                                            videoData[
                                                                'position']);
                                                        return KeyEventResult
                                                            .handled;
                                                      }
                                                    }
                                                    return KeyEventResult
                                                        .ignored;
                                                  },
                                                  child: Container(
                                                    width: screenwdt * 0.18,
                                                    height: screenhgt * 0.15,
                                                    margin:
                                                        EdgeInsets.symmetric(
                                                            horizontal: 5),
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              15),
                                                      color: focusNode.hasFocus
                                                          ? Colors.black87
                                                          : Colors.transparent,
                                                      border: Border.all(
                                                        color: focusNode
                                                                .hasFocus
                                                            ? Colors.blue
                                                            : Colors
                                                                .transparent,
                                                        width: 5,
                                                      ),
                                                      boxShadow: focusNode
                                                              .hasFocus
                                                          ? [
                                                              BoxShadow(
                                                                color: Colors
                                                                    .blue
                                                                    .withOpacity(
                                                                        0.5),
                                                                blurRadius: 8,
                                                                spreadRadius: 2,
                                                              )
                                                            ]
                                                          : [],
                                                    ),
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              8.0),
                                                      child: Column(
                                                        children: [
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        5),
                                                            child: Text(
                                                              videoData[
                                                                      'name'] ??
                                                                  '',
                                                              style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize:
                                                                    nametextsz,
                                                                color: focusNode
                                                                        .hasFocus
                                                                    ? Colors
                                                                        .white
                                                                    : Colors
                                                                        .transparent,
                                                              ),
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ),
                                                          SizedBox(
                                                              height:
                                                                  screenhgt *
                                                                      0.02),
                                                          Stack(
                                                            children: [
                                                              ClipRRect(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            8),
                                                                child: Opacity(
                                                                  opacity: focusNode
                                                                          .hasFocus
                                                                      ? 1
                                                                      : 0.7,
                                                                  child: videoData[
                                                                              'bannerImageUrl']
                                                                          ?.startsWith(
                                                                              'data:image')
                                                                      ? Image
                                                                          .memory(
                                                                          _getCachedImage(videoData['bannerImageUrl'] ??
                                                                              ''),
                                                                          fit: BoxFit
                                                                              .cover,
                                                                          width:
                                                                              double.infinity,
                                                                          height:
                                                                              screenhgt * 0.15,
                                                                          errorBuilder: (context, error, stackTrace) =>
                                                                              Image.asset(
                                                                            localImage,
                                                                            fit:
                                                                                BoxFit.cover,
                                                                            width:
                                                                                double.infinity,
                                                                            height:
                                                                                screenhgt * 0.15,
                                                                          ),
                                                                        )
                                                                      : Image
                                                                          .network(
                                                                          videoData['bannerImageUrl'] ??
                                                                              localImage,
                                                                          fit: BoxFit
                                                                              .cover,
                                                                          width:
                                                                              double.infinity,
                                                                          height:
                                                                              screenhgt * 0.15,
                                                                          errorBuilder: (context,
                                                                              error,
                                                                              stackTrace) {
                                                                            return Image.asset('assets/logo.png',
                                                                                fit: BoxFit.cover,
                                                                                width: double.infinity,
                                                                                height: screenhgt * 0.15);
                                                                          },
                                                                        ),
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                  height:
                                                                      screenhgt *
                                                                          0.02),
                                                            ],
                                                          ),
                                                          SizedBox(
                                                              height:
                                                                  screenhgt *
                                                                      0.02),
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        5),
                                                            child: _buildProgressDisplay(
                                                                videoData,
                                                                focusNode
                                                                    .hasFocus),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }
                                            // },
                                            ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
        );
      },
    );
  }

  Map<String, Uint8List> _bannerCache = {};

  Uint8List _getCachedImage(String base64String) {
    try {
      if (!_bannerCache.containsKey(base64String)) {
        // Decode only the base64 content after "data:image/..." prefix
        final base64Content = base64String.split(',').last;
        _bannerCache[base64String] = base64Decode(base64Content);
      }
      return _bannerCache[base64String]!;
    } catch (e) {
      // Return a 1x1 transparent pixel as fallback
      return Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG header
        0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR chunk
        0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, // 1x1 dimensions
        0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, // 8-bit RGB
        0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41, // IDAT chunk
        0x54, 0x78, 0x01, 0x63, 0x00, 0x01, 0x00, 0x05, // Compressed data
        0x00, 0x01, 0xE2, 0x26, 0x05, 0x9B, 0x00, 0x00, // Checksum
        0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, // IEND chunk
        0x60, 0x82
      ]);
    }
  }

  bool isLiveVideoUrl(String url) {
    // Normalize the URL for case-insensitive checks
    String lowerUrl = url.toLowerCase().trim();
    if (RegExp(r'^[a-zA-Z0-9_-]{10,15}$').hasMatch(lowerUrl)) {
      // Match custom IDs (10-15 alphanumeric characters)
      return false; // Non-live URL
    }
    // If it's a random string without protocol or invalid pattern
    if (!lowerUrl.startsWith('http://') && !lowerUrl.startsWith('https://')) {
      return false; // Invalid URL, non-live
    }

    // Check if the URL contains live stream patterns
    if (lowerUrl.contains(".m3u8") || // Common live stream file extension
        lowerUrl.contains("live") ||
        lowerUrl.contains("stream") ||
        lowerUrl.contains("broadcast") ||
        lowerUrl.contains("playlist")) {
      return true; // It's a live video
    }

    // Check for common video file extensions (not live)
    List<String> videoExtensions = [".mp4", ".mov", ".avi", ".flv", ".mkv"];
    for (String ext in videoExtensions) {
      if (lowerUrl.endsWith(ext)) {
        return false; // Recorded video
      }
    }

    // If no patterns match, assume it's not a live video
    return false;
  }

  List<bool> checkLiveVideoList(List<String> urls) {
    return urls.map(isYoutubeUrl).toList();
  }

  Widget _buildProgressDisplay(Map<String, dynamic> videoData, bool hasFocus) {
    // displayLiveStatusForVideos();
    // printLiveStatusForAllVideos();
    // printLastPlayedVideoNames();
    Duration totalDuration = videoData['duration'] ?? Duration.zero;
    Duration currentPosition = videoData['position'] ?? Duration.zero;
    String url = videoData['videoUrl'] ?? '';
    bool liveStatus = videoData['liveStatus'];
    bool isLive = isLiveVideoUrl(url);
    bool isYoutube = isYoutubeUrl(url);

    // Calculate progress percentage
    double playedProgress = (totalDuration.inMilliseconds > 0)
        ? (currentPosition.inMilliseconds / totalDuration.inMilliseconds)
            .clamp(0.0, 1.0)
        : 0.0;

    String formatDuration(Duration duration) {
      // Function to convert single digit to double digit string (e.g., 5 -> "05")
      String twoDigits(int n) => n.toString().padLeft(2, '0');

      // Get hours string only if hours > 0
      String hours =
          duration.inHours > 0 ? '${twoDigits(duration.inHours)}:' : '';

      // Get minutes (00-59)
      String minutes = twoDigits(duration.inMinutes.remainder(60));

      // Get seconds (00-59)
      String seconds = twoDigits(duration.inSeconds.remainder(60));

      // Combine everything into final time string
      return '$hours$minutes:$seconds';
    }

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: hasFocus
                ? const Color.fromARGB(200, 16, 62, 99)
                : Colors.transparent,
            borderRadius: hasFocus ? BorderRadius.circular(4.0) : null,
          ),
          child: Stack(
            children: [
              LinearProgressIndicator(
                minHeight: 4,
                value: playedProgress,
                color: Colors.red.withOpacity(0.8),
                backgroundColor: Colors.grey[800],
              ),
            ],
          ),
        ),
        SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              formatDuration(currentPosition),
              style: TextStyle(
                color: hasFocus ? Colors.blue : Colors.green,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (!liveStatus)
              Text(
                formatDuration(totalDuration),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            if (liveStatus)
              Text(
                'LIVE', // Show "LIVE" for live videos
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ],
    );
  }

  void addNewBannerOrVideo(Map<String, dynamic> newVideo) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> storedVideos = prefs.getStringList('last_played_videos') ?? [];

    // String newVideoEntry =
    //     '${newVideo['videoUrl']}|${newVideo['position'].inMilliseconds}|${newVideo['bannerImageUrl']}|${newVideo['videoName']}|${newVideo['videoId']}|${newVideo['duration'].inMilliseconds}';

    String newVideoEntry =
        '${newVideo['videoUrl']}|${newVideo['position'].inMilliseconds}|${newVideo['duration'].inMilliseconds}|${newVideo['liveStatus']}|${newVideo['bannerImageUrl']}|${newVideo['videoId']}|${newVideo['name']}';
    print('Newvideoadded: $newVideoEntry');

    storedVideos.insert(0, newVideoEntry);
    await prefs.setStringList('last_played_videos', storedVideos);
    print('Newvideoadded: $storedVideos');
  }

  Future<void> _loadLastPlayedVideos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedVideos = prefs.getStringList('last_played_videos');

      if (storedVideos != null && storedVideos.isNotEmpty) {
        setState(() {
          lastPlayedVideos = storedVideos
              .map((videoEntry) {
                List<String> details = videoEntry.split('|');
                if (details.length >= 7) {
                  try {
                    Duration duration =
                        Duration(milliseconds: int.tryParse(details[2]) ?? 0);
                    Duration position =
                        Duration(milliseconds: int.tryParse(details[1]) ?? 0);

                    // Ensure liveStatus is a bool
                    bool liveStatus = details[3].toLowerCase() == 'true';

                    return {
                      'videoUrl': details[0],
                      'position': position,
                      'duration': duration,
                      'liveStatus': liveStatus,
                      'bannerImageUrl': details[4],
                      'videoId': details[5],
                      'name': details[6],
                      'focusNode': FocusNode(), // Add focusNode for UI
                    };
                  } catch (e) {
                    return null;
                  }
                } else {
                  return null;
                }
              })
              .where((video) => video != null)
              .cast<Map<String, dynamic>>()
              .toList();
        });
        printLastPlayedPositions();
        print("LoadedlastPlayedVideos: $lastPlayedVideos");
        sharedDataProvider.updateLastPlayedVideos(lastPlayedVideos);
        // WidgetsBinding.instance.addPostFrameCallback((_) {
        //   if (lastPlayedVideos.isNotEmpty) {
        //     context.read<FocusProvider>().setFirstLastPlayedFocusNode(
        //         lastPlayedVideos[0]['focusNode'] as FocusNode);
        //   }
        // });
      }
    } catch (e) {
      setState(() {
        lastPlayedVideos = [];
      });
    }
  }

  void printLastPlayedPositions() {
    for (int i = 0; i < lastPlayedVideos.length; i++) {
      final video = lastPlayedVideos[i];
      final position =
          video['position'] ?? Duration.zero; // Safely handle null values
      print('Video $i: Positionnnnnn - $position');
    }
  }

  void _playVideo(Map<String, dynamic> videoData, Duration position) async {
    print("liveStatus received in _playVideo: ${videoData['liveStatus']}");
    if (_isNavigating) return;
    _isNavigating = true;

    bool shouldPlayVideo = true;
    bool shouldPop = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => WillPopScope(
        onWillPop: () async {
          shouldPlayVideo = false;
          shouldPop = false;
          return true;
        },
        child: LoadingIndicator(),
      ),
    );

    Timer(Duration(seconds: 10), () {
      _isNavigating = false;
    });

    try {
      final currentIndex = lastPlayedVideos
          .indexWhere((video) => video['videoUrl'] == videoData['videoUrl']);

      List<NewsItemModel> channelList =
          lastPlayedVideos.asMap().entries.map((entry) {
        final video = entry.value;
        final index = entry.key;

        String videoUrl = video['videoUrl'] ?? '';
        String videoIdString = video['videoId'] ?? '0';
        String contentIdString = video['videoId'] ?? '0';
        String streamType = isYoutubeUrl(videoUrl) ? 'YoutubeLive' : 'M3u8';
        String type = isYoutubeUrl(videoUrl) ? 'YoutubeLive' : 'M3u8';

        return NewsItemModel(
          videoId: '',
          id: videoIdString,
          url: videoUrl,
          banner: video['bannerImageUrl'] ?? '',
          name: video['videoName'] ?? '',
          contentId: contentIdString,
          status: '1',
          streamType: streamType,
          type: type,
          contentType: '1',
          genres: '',
          position: video['position'], // Include position as Duration
          liveStatus: video['liveStatus'], index: '', // Include position as Duration
        );
      }).toList();

      print("Final liveStatus: ${videoData['liveStatus']}");

      String source = videoData['source'] ?? '';
      int videoId = 0;
      if (videoData['videoId'] != null &&
          videoData['videoId'].toString().isNotEmpty) {
        videoId = int.tryParse(videoData['videoId'].toString()) ?? 0;
      }

      String originalUrl = videoData['videoUrl'];
      String updatedUrl = videoData['videoUrl'];

      if (isYoutubeUrl(updatedUrl)) {
        updatedUrl = await _socketService.getUpdatedUrl(updatedUrl);
      }

      if (shouldPop) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      Duration startAtPosition =
          videoData['position'] as Duration ?? Duration.zero;

      if (shouldPlayVideo) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoScreen(
              videoUrl: updatedUrl,
              unUpdatedUrl: originalUrl,
              channelList: channelList,
              bannerImageUrl: videoData['bannerImageUrl'] ?? '',
              startAtPosition: startAtPosition, // Pass position as Duration
              totalDuration: videoData['duration'], // Pass the total duration
              videoType: '',
              isLive: source == 'isLiveScreen',
              isVOD: source == 'isVOD',
              isSearch: source == 'isSearchScreen',
              isHomeCategory: source == 'isHomeCategory',
              isBannerSlider: source == 'isBannerSlider',
              videoId: videoId,
              source: 'isLastPlayedVideos', name: videoData['videoName'] ?? '',
              liveStatus: videoData['liveStatus'] ,
            ),
          ),
        );
      }
    } catch (e) {
      // if (mounted) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //       SnackBar(content: Text('Unable to play this content')));
      // }
    } finally {
      _isNavigating = false;
    }
  }
}
