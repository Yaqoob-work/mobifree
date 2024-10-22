import 'dart:async';
import 'dart:convert';
import 'package:mobi_tv_entertainment/main.dart';
import 'package:mobi_tv_entertainment/video_widget/socket_service.dart';
import 'package:mobi_tv_entertainment/video_widget/video_screen.dart';
import 'package:mobi_tv_entertainment/widgets/items/news_item.dart';
import 'package:mobi_tv_entertainment/widgets/models/news_item_model.dart';
import 'package:mobi_tv_entertainment/widgets/small_widgets/empty_state.dart';
import 'package:mobi_tv_entertainment/widgets/small_widgets/error_message.dart';
import 'package:mobi_tv_entertainment/widgets/small_widgets/loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../video_widget/vlc_player_screen.dart';
import '../../widgets/services/api_service.dart';

class NewsGridScreen extends StatefulWidget {
  final List<NewsItemModel> musicList;

  const NewsGridScreen({Key? key, required this.musicList}) : super(key: key);

  @override
  _NewsGridScreenState createState() => _NewsGridScreenState();
}

class _NewsGridScreenState extends State<NewsGridScreen> {
  // final List<NewsItemModel> _musicList = [];
  List<NewsItemModel> _musicList = [];

  final SocketService _socketService = SocketService();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isNavigating = false;
  int _maxRetries = 3;
  int _retryDelay = 5; // seconds

  @override
  void initState() {
    super.initState();
    _socketService.initSocket();
    checkServerStatus();
    
    // _musicList.addAll(widget.newsList);
        _loadCachedDataAndFetchMusic();
    _apiService.updateStream.listen((hasChanges) {
      if (hasChanges) {
        _loadCachedDataAndFetchMusic(); // Refetch data if changes occur
      }
    }); // Fetch updated news data in background
  }

  void checkServerStatus() {
    Timer.periodic(Duration(seconds: 10), (timer) {
      // Check if the socket is connected, otherwise attempt to reconnect
      if (!_socketService.socket.connected) {
        // print('YouTube server down, retrying...');
        _socketService.initSocket(); // Re-establish the socket connection
      }
    });
  }


   Future<void> _loadCachedDataAndFetchMusic() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Step 1: Load cached music data first
      await _loadCachedMusicData();

      // Step 2: Fetch new data in the background and update UI if needed
      await _fetchMusicInBackground();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load music data';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCachedMusicData() async {
    try {
      // Fetch cached music data from SharedPreferences (similar to VOD)
      final prefs = await SharedPreferences.getInstance();
      final cachedMusic = prefs.getString('music_list');

      if (cachedMusic != null) {
        // Parse and load cached data
        final List<dynamic> cachedData = json.decode(cachedMusic);
        setState(() {
          _musicList = cachedData.map((item) => NewsItemModel.fromJson(item)).toList();
          _isLoading = false; // Show cached data immediately
        });
      }
    } catch (e) {
      print('Error loading cached music data: $e');
    }
  }

  Future<void> _fetchMusicInBackground() async {
    try {
      // Fetch new music data from API and cache it (similar to VOD)
      final newMusicList = await _apiService.fetchMusicData();

      // Compare cached data with new data
      final prefs = await SharedPreferences.getInstance();
      final cachedMusic = prefs.getString('music_list');
      if (cachedMusic != json.encode(newMusicList)) {
        // Update cache if data is different
        prefs.setString('music_list', json.encode(newMusicList));

        // Update UI with new data
        setState(() {
          _musicList = newMusicList;
        });
      }
    } catch (e) {
      print('Error fetching music data: $e');
    }
  }

// Future<void> _loadCachedNewsData() async {
//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       // Step 1: Load cached news data
//       final prefs = await SharedPreferences.getInstance();
//       final cachedNews = prefs.getString('news_list');

//       if (cachedNews != null) {
//         final List<dynamic> cachedData = json.decode(cachedNews);
//         setState(() {
//           _musicList = cachedData.map((item) => NewsItemModel.fromJson(item)).toList();
//           _isLoading = false;  // Stop loading once cache is shown
//         });
//       } else {
//         // No cached data, just keep loading state
//         setState(() {
//           _isLoading = true;
//         });
//       }
//     } catch (e) {
//       print('Error loading cached news data: $e');
//     }
//   }

//   Future<void> _fetchNewsInBackground() async {
//     try {
//       // Step 2: Fetch new news data from the API
//       final newNewsList = await _apiService.fetchNewsData();

//       // Compare cached data with new data
//       final prefs = await SharedPreferences.getInstance();
//       final cachedNews = prefs.getString('news_list');
//       if (cachedNews != json.encode(newNewsList)) {
//         // If data is different, update cache and UI
//         prefs.setString('news_list', json.encode(newNewsList));

//         // Update UI with new data
//         setState(() {
//           _musicList = newNewsList;
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       print('Error fetching news data: $e');
//       setState(() {
//         _errorMessage = 'Failed to load news data';
//         _isLoading = false;
//       });
//     }
//   }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cardColor,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return LoadingIndicator();
    } else if (_errorMessage.isNotEmpty) {
      return ErrorMessage(message: _errorMessage);
    } else if (_musicList.isEmpty) {
      return EmptyState(message: 'No news items available');
    } else {
      return _buildNewsList();
    }
  }

  Widget _buildNewsList() {
    return Stack(
      children: [
        GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            // childAspectRatio: 0.7,
          ),
          itemCount: _musicList.length,
          itemBuilder: (context, index) {
            return _buildNewsItem(_musicList[index]);
          },
        ),
      ],
    );
  }

  Widget _buildNewsItem(NewsItemModel item) {
    return NewsItem(
      key: Key(item.id),
      hideDescription: true,
      item: item,
      onTap: () => _navigateToVideoScreen(item),
      onEnterPress: _handleEnterPress,
    );
  }

  void _handleEnterPress(String itemId) {
    final selectedItem =
        _musicList.firstWhere((item) => item.id == itemId);
    _navigateToVideoScreen(selectedItem);
  }




//   Future<void> _navigateToVideoScreen(NewsItemModel newsItem) async {
//     if (_isNavigating) return;
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
//           child: LoadingIndicator(),
//         );
//       },
//     );

//     Timer(Duration(seconds: 10), () {
//       _isNavigating = false;
//     });

//     try {
//       if (newsItem.streamType == 'YoutubeLive') {
//         // Retry fetching the updated URL if stream type is YouTube Live
//         for (int i = 0; i < _maxRetries; i++) {
//           try {
//             String updatedUrl =
//                 await _socketService.getUpdatedUrl(newsItem.url);
//             newsItem = NewsItemModel(
//               id: newsItem.id,
//               name: newsItem.name,
//               description: newsItem.description,
//               banner: newsItem.banner,
//               url: updatedUrl,
//               streamType: 'M3u8',
//               genres: newsItem.genres,
//               status: newsItem.status,
//             );
//             break; // Exit loop when URL is successfully updated
//           } catch (e) {
//             if (i == _maxRetries - 1) rethrow; // Rethrow error on last retry
//             await Future.delayed(
//                 Duration(seconds: _retryDelay)); // Delay before next retry
//           }
//         }
//       }

//       if (shouldPop) {
//         Navigator.of(context, rootNavigator: true).pop();
//       }

//       if (shouldPlayVideo) {
//         await Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => VideoScreen(
//               videoUrl: newsItem.url,
//               videoTitle: newsItem.name,
//               channelList: _musicList,
//               genres: newsItem.genres,
//               channels: [],
//               initialIndex: 1,
//               bannerImageUrl: newsItem.banner,
//               startAtPosition: Duration.zero,
//             ),
//           ),
//         );
//       }
//     } catch (e) {
//       if (shouldPop) {
//         Navigator.of(context, rootNavigator: true).pop();
//       }
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Something Went Wrong')),
//       );
//     } finally {
//       _isNavigating = false;
//     }
//   }
// }





Future<void> _navigateToVideoScreen(NewsItemModel newsItem) async {
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
    if (newsItem.streamType == 'YoutubeLive') {
      // Retry fetching the updated URL if stream type is YouTube Live
      for (int i = 0; i < _maxRetries; i++) {
        try {
          String updatedUrl =
              await _socketService.getUpdatedUrl(newsItem.url);
          newsItem = NewsItemModel(
            id: newsItem.id,
            name: newsItem.name,
            description: newsItem.description,
            banner: newsItem.banner,
            url: updatedUrl,
            streamType: 'M3u8',
            genres: newsItem.genres,
            status: newsItem.status,
          );
          break; // Exit loop when URL is successfully updated
        } catch (e) {
          if (i == _maxRetries - 1) rethrow; // Rethrow error on last retry
          await Future.delayed(
              Duration(seconds: _retryDelay)); // Delay before next retry
        }
      }
    }

    if (shouldPop) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    if (shouldPlayVideo) {
      if (newsItem.streamType == 'VLC') {
      //   // Navigate to VLC Player screen when stream type is VLC
        await Navigator.push(
           context,
          MaterialPageRoute(
            builder: (context) => VlcPlayerScreen(
              videoUrl: newsItem.url,
              // videoTitle: newsItem.name,
              channelList: _musicList,
              genres: newsItem.genres,
              // channels: [],
              // initialIndex: 1,
              bannerImageUrl: newsItem.banner,
              startAtPosition: Duration.zero, 
              // onFabFocusChanged: (bool) {  }, 
              isLive: true,
            ),
          ),
        );
      } else {
        // Default case for other stream types
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoScreen(
              videoUrl: newsItem.url,
              // videoTitle: newsItem.name,
              // channelList: _musicList,
              // genres: newsItem.genres,
              // channels: [],
              // initialIndex: 1,
              bannerImageUrl: newsItem.banner,
              startAtPosition: Duration.zero,
            ),
          ),
        );
      }
    }
  } catch (e) {
    if (shouldPop) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Something Went Wrong')),
    );
  } finally {
    _isNavigating = false;
  }
}
}