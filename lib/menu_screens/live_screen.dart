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
//   final List<NewsItemModel> _entertainmentList = [];
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
//         _entertainmentList.addAll(_apiService.allChannelList);
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
//     } else if (_entertainmentList.isEmpty) {
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
//         itemCount: _entertainmentList.length,
//         itemBuilder: (context, index) {
//           return _buildNewsItem(_entertainmentList[index]);
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
//         _entertainmentList.firstWhere((item) => item.id == itemId);
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
//                 channelList: _entertainmentList,
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
//                 // channelList: _entertainmentList,
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

import '../video_widget/vlc_player_screen.dart';

class LiveScreen extends StatefulWidget {
  List<NewsItemModel> get entertainmentList => [];

  @override
  _LiveScreenState createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  final List<NewsItemModel> _entertainmentList = [];
  final SocketService _socketService = SocketService();
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isNavigating = false;
  int _maxRetries = 3;
  int _retryDelay = 5; // seconds

  @override
  void initState() {
    super.initState();
    _socketService.initSocket();
    checkServerStatus();
    fetchData();

    // Update cache when the page is entered
    _apiService.updateCacheOnPageEnter();
    // Listen to updates from the ApiService stream
    _apiService.updateStream.listen((hasChanges) {
      if (hasChanges) {
        setState(() {
          _isLoading = true;
        });
        fetchData(); // Refetch the data only when changes occur
      }
    });
  }

  void checkServerStatus() {
    Timer.periodic(Duration(seconds: 10), (timer) {
      // Check if the socket is connected, otherwise attempt to reconnect
      if (!_socketService.socket.connected) {
        print('YouTube server down, retrying...');
        _socketService.initSocket(); // Re-establish the socket connection
      }
    });
  }

  Future<void> fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await _apiService.fetchSettings();
      await _apiService.fetchEntertainment();
      setState(() {
        _entertainmentList.addAll(_apiService.allChannelList);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Something Went Wrong';
        _isLoading = false;
      });
    }
  }

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
            onPressed: fetchData, // Retry fetching data on button press
            child: Text('Retry'),
          ),
        ],
      );
    } else if (_entertainmentList.isEmpty) {
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
        itemCount: _entertainmentList.length,
        itemBuilder: (context, index) {
          return _buildNewsItem(_entertainmentList[index]);
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
        _entertainmentList.firstWhere((item) => item.id == itemId);
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
                channelList: _entertainmentList,
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
    super.dispose();
  }
}
