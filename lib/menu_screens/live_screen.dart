// import 'dart:async';
// import 'package:mobi_tv_entertainment/main.dart';
// import 'package:mobi_tv_entertainment/video_widget/socket_service.dart';
// import 'package:mobi_tv_entertainment/video_widget/video_screen.dart';
// import 'package:mobi_tv_entertainment/widgets/items/news_item.dart';
// import 'package:mobi_tv_entertainment/widgets/models/news_item_model.dart';
// import 'package:mobi_tv_entertainment/widgets/services/api_service.dart';
// import 'package:mobi_tv_entertainment/widgets/small_widgets/empty_state.dart';
// import 'package:mobi_tv_entertainment/widgets/small_widgets/error_message.dart';
// import 'package:mobi_tv_entertainment/widgets/small_widgets/loading_indicator.dart';
// import 'package:flutter/material.dart';

// import '../video_widget/vlc_player_screen.dart';

// class LiveScreen extends StatefulWidget {
//   List<NewsItemModel> get entertainmentList => [];

//   @override
//   _LiveScreenState createState() => _LiveScreenState();
// }

// class _LiveScreenState extends State<LiveScreen> {
//   final List<NewsItemModel> _musicList = [];
//   final SocketService _socketService = SocketService();
//   final ApiService _apiService = ApiService();
//   bool _isLoading = true;
//   String _errorMessage = '';
//   bool _isNavigating = false;
//   int _maxRetries = 3;
//   int _retryDelay = 5; // seconds

//   @override
//   void initState() {
//     super.initState();
//     _socketService.initSocket();
//     checkServerStatus();
//     fetchData();
//   }

//   void checkServerStatus() {
//     Timer.periodic(Duration(seconds: 10), (timer) {
//       // Check if the socket is connected, otherwise attempt to reconnect
//       if (!_socketService.socket.connected) {
//         print('YouTube server down, retrying...');
//         _socketService.initSocket(); // Re-establish the socket connection
//       }
//     });
//   }

//   Future<void> fetchData() async {
//     try {
//       await _apiService.fetchSettings();
//       await _apiService.fetchEntertainment();
//       setState(() {
//         _musicList.addAll(_apiService.allChannelList);
//         _isLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         _errorMessage = 'Something Went Wrong';
//         _isLoading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: cardColor,
//       body: Padding(
//         padding: EdgeInsets.symmetric(horizontal: screenwdt * 0.03),
//         child: _buildBody(),
//       ),
//     );
//   }

//   Widget _buildBody() {
//     if (_isLoading) {
//       return LoadingIndicator();
//     } else if (_errorMessage.isNotEmpty) {
//       return ErrorMessage(message: _errorMessage);
//     } else if (_musicList.isEmpty) {
//       return EmptyState(message: 'Something Went Wrong');
//     } else {
//       return _buildNewsList();
//     }
//   }

//   Widget _buildNewsList() {
//     return Padding(
//       padding: const EdgeInsets.all(8.0),
//       child: GridView.builder(
//         gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//           crossAxisCount: 5,
//           // childAspectRatio: 0.85,
//         ),
//         // scrollDirection: Axis.horizontal,
//         itemCount: _musicList.length,
//         itemBuilder: (context, index) {
//           return _buildNewsItem(_musicList[index]);
//         },
//       ),
//     );
//   }

//   Widget _buildNewsItem(NewsItemModel item) {
//     return NewsItem(
//       key: Key(item.id),
//       item: item,
//       hideDescription: true,
//       onTap: () => _navigateToVideoScreen(item),
//       onEnterPress: _handleEnterPress,
//     );
//   }

//   void _handleEnterPress(String itemId) {
//     final selectedItem =
//         _musicList.firstWhere((item) => item.id == itemId);
//     _navigateToVideoScreen(selectedItem);
//   }

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
//         if (newsItem.streamType == 'VLC') {
//           //   // Navigate to VLC Player screen when stream type is VLC
//           await Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => VlcPlayerScreen(
//                 videoUrl: newsItem.url,
//                 // videoTitle: newsItem.name,
//                 channelList: _musicList,
//                 genres: newsItem.genres,
//                 // channels: [],
//                 // initialIndex: 1,
//                 bannerImageUrl: newsItem.banner,
//                 startAtPosition: Duration.zero,
//                 // onFabFocusChanged: (bool) {},
//                 isLive: true,
//               ),
//             ),
//           );
//         } else {
//           await Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => VideoScreen(
//                 videoUrl: newsItem.url,
//                 // videoTitle: newsItem.name,
//                 // channelList: _musicList,
//                 // genres: newsItem.genres,
//                 // channels: [],
//                 // initialIndex: 1,
//                 bannerImageUrl: newsItem.banner,
//                 startAtPosition: Duration.zero,
//               ),
//             ),
//           );
//         }
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

//   @override
//   void dispose() {
//     _socketService.dispose();
//     super.dispose();
//   }
// }





import 'dart:async';
import 'dart:convert';
import 'package:mobi_tv_entertainment/main.dart';
import 'package:mobi_tv_entertainment/video_widget/socket_service.dart';
import 'package:mobi_tv_entertainment/video_widget/video_screen.dart';
import 'package:mobi_tv_entertainment/widgets/items/news_item.dart';
import 'package:mobi_tv_entertainment/widgets/models/news_item_model.dart';
import 'package:mobi_tv_entertainment/widgets/services/api_service.dart';
import 'package:mobi_tv_entertainment/widgets/small_widgets/empty_state.dart';
import 'package:mobi_tv_entertainment/widgets/small_widgets/error_message.dart';
import 'package:mobi_tv_entertainment/widgets/small_widgets/loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../video_widget/vlc_player_screen.dart';

class LiveScreen extends StatefulWidget {
  // List<NewsItemModel> get entertainmentList => [];

  @override
  _LiveScreenState createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  // final List<NewsItemModel> _musicList = [];
  List<NewsItemModel> _musicList = [];

  final SocketService _socketService = SocketService();
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isNavigating = false;
  int _maxRetries = 3;
  int _retryDelay = 5; // seconds
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _socketService.initSocket();
    checkServerStatus();
    // fetchData();

    _loadCachedDataAndFetchLive(); // Load cached data and fetch in the background
    _apiService.updateStream.listen((hasChanges) {
      if (hasChanges) {
        _loadCachedDataAndFetchLive(); // Refetch data if changes occur
      }
    });
  }


  Future<void> _loadCachedDataAndFetchLive() async {
  setState(() {
    _isLoading = true;
    _errorMessage = '';
  });

  try {
    // Step 1: Load cached data
    final cachedDataAvailable = await _loadCachedLiveData();

    // Step 2: Fetch live data immediately if no cache is available
    if (!cachedDataAvailable) {
      await _fetchLiveDataInBackground();
    }
  } catch (e) {
    setState(() {
      _errorMessage = 'Failed to load live data';
      _isLoading = false;
    });
  }
}

Future<bool> _loadCachedLiveData() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final cachedLive = prefs.getString('live_list');

    if (cachedLive != null) {
      final List<dynamic> cachedData = json.decode(cachedLive);
      setState(() {
        _musicList = cachedData.map((item) => NewsItemModel.fromJson(item)).toList();
        _isLoading = false; // Show cached data immediately
      });
      return true; // Cache was found and loaded
    }
  } catch (e) {
    print('Error loading cached live data: $e');
  }
  return false; // No cache found
}

Future<void> _fetchLiveDataInBackground() async {
  try {
    // Fetch new live data
    final newLiveList = await _apiService.fetchMusicData(); 

    final prefs = await SharedPreferences.getInstance();
    final cachedLive = prefs.getString('live_list');

    if (cachedLive != json.encode(newLiveList)) {
      // Update cache if the live data is different
      prefs.setString('live_list', json.encode(newLiveList));

      // Update UI with new data
      setState(() {
        _musicList = newLiveList;
      });
    }

    setState(() {
      _isLoading = false; // Stop the loading indicator after live data is fetched
    });
  } catch (e) {
    setState(() {
      _errorMessage = 'Error fetching live data';
      _isLoading = false;
    });
  }
}


  //    Future<void> _loadCachedDataAndFetchLive() async {
  //   setState(() {
  //     _isLoading = true;
  //     _errorMessage = '';
  //   });

  //   try {
  //     // Step 1: Load cached live data
  //     await _loadCachedLiveData();

  //     // Step 2: Fetch new live data in the background and update if necessary
  //     await _fetchLiveDataInBackground();
  //   } catch (e) {
  //     setState(() {
  //       _errorMessage = 'Failed to load live data';
  //       _isLoading = false;
  //     });
  //   }
  // }

  // Future<void> _loadCachedLiveData() async {
  //   try {
  //     final prefs = await SharedPreferences.getInstance();
  //     final cachedLive = prefs.getString('live_list');

  //     if (cachedLive != null) {
  //       final List<dynamic> cachedData = json.decode(cachedLive);
  //       setState(() {
  //         _musicList = cachedData.map((item) => NewsItemModel.fromJson(item)).toList();
  //         _isLoading = false; // Show cached data immediately
  //       });
  //     }
  //   } catch (e) {
  //     print('Error loading cached live data: $e');
  //   }
  // }

  // Future<void> _fetchLiveDataInBackground() async {
  //   try {
  //     final newLiveList = await _apiService.fetchMusicData(); // Fetch live data

  //     final prefs = await SharedPreferences.getInstance();
  //     final cachedLive = prefs.getString('live_list');

  //     if (cachedLive != json.encode(newLiveList)) {
  //       // Update cache if data is different
  //       prefs.setString('live_list', json.encode(newLiveList));

  //       // Update UI with new data
  //       setState(() {
  //         _musicList = newLiveList;
  //       });
  //     }
  //   } catch (e) {
  //     print('Error fetching live data: $e');
  //   }
  // }

  void checkServerStatus() {
    Timer.periodic(Duration(seconds: 10), (timer) {
      // Check if the socket is connected, otherwise attempt to reconnect
      if (!_socketService.socket.connected) {
        // print('YouTube server down, retrying...');
        _socketService.initSocket(); // Re-establish the socket connection
      }
    });
  }

  // Future<void> fetchData() async {
  //   setState(() {
  //     _isLoading = true;
  //     _errorMessage = '';
  //   });

  //   try {
  //     await _apiService.fetchSettings();
  //     await _apiService.fetchEntertainment();
  //     setState(() {
  //       _musicList.addAll(_apiService.allChannelList);
  //       _isLoading = false;
  //     });
  //   } catch (e) {
  //     setState(() {
  //       _errorMessage = 'Something Went Wrong';
  //       _isLoading = false;
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cardColor,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenwdt * 0.03),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return LoadingIndicator();
    } else if (_errorMessage.isNotEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ErrorMessage(message: _errorMessage),
          ElevatedButton(
            onPressed: _loadCachedDataAndFetchLive, // Retry fetching data on button press
            child: Text('Retry'),
          ),
        ],
      );
    } else if (_musicList.isEmpty) {
      return EmptyState(message: 'Something Went Wrong');
    } else {
      return _buildNewsList();
    }
  }

  Widget _buildNewsList() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
        ),
        itemCount: _musicList.length,
        itemBuilder: (context, index) {
          return _buildNewsItem(_musicList[index]);
        },
      ),
    );
  }

  Widget _buildNewsItem(NewsItemModel item) {
    return NewsItem(
      key: Key(item.id),
      item: item,
      hideDescription: true,
      onTap: () => _navigateToVideoScreen(item),
      onEnterPress: _handleEnterPress,
    );
  }

  void _handleEnterPress(String itemId) {
    final selectedItem =
        _musicList.firstWhere((item) => item.id == itemId);
    _navigateToVideoScreen(selectedItem);
  }

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
          // Navigate to VLC Player screen when stream type is VLC
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VlcPlayerScreen(
                videoUrl: newsItem.url,
                channelList: _musicList,
                genres: newsItem.genres,
                bannerImageUrl: newsItem.banner,
                startAtPosition: Duration.zero,
                isLive: true,
              ),
            ),
          );
        } else {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoScreen(
                videoUrl: newsItem.url,
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

  @override
  void dispose() {
    _socketService.dispose();
    _timer?.cancel();
    super.dispose();
  }
}
