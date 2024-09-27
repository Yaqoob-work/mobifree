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

// class NewsGridScreen extends StatefulWidget {
//   List<NewsItemModel> get entertainmentList => [];

//   @override
//   _NewsGridScreenState createState() => _NewsGridScreenState();
// }

// class _NewsGridScreenState extends State<NewsGridScreen> {
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
//     fetchData();
//   }

//   Future<void> fetchData() async {
//     try {
//       await _apiService.fetchSettings();
//       await _apiService.fetchEntertainment();
//       setState(() {
//         _entertainmentList.addAll(_apiService.newsList);
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
//       body: _buildBody(),
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
//     return GridView.builder(
//       gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 5,
//         ),
//       // scrollDirection: Axis.horizontal,
//       itemCount: _entertainmentList.length ,
//       itemBuilder: (context, index) {
//         return _buildNewsItem(_entertainmentList[index]);
//       },
//     );
//   }

//   Widget _buildNewsItem(NewsItemModel item) {
//     return NewsItem(
//       key: Key(item.id),
//       item: item,
//       onTap: () => _navigateToVideoScreen(item),
//       onEnterPress: _handleEnterPress,
//     );
//   }

//   void _handleEnterPress(String itemId) {
//       final selectedItem = _entertainmentList.firstWhere((item) => item.id == itemId);
//       _navigateToVideoScreen(selectedItem);
//   }

//   void _navigateToVideoScreen(NewsItemModel newsItem) async {
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
//           child: LoadingIndicator(),
//         );
//       },
//     );

//     Timer(Duration(seconds: 5), () {
//       _isNavigating = false;
//     });

//     try {
//       if (newsItem.streamType == 'YoutubeLive') {
//         for (int i = 0; i < _maxRetries; i++) {
//           try {
//             String updatedUrl = await _socketService.getUpdatedUrl(newsItem.url);
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
//             break;
//           } catch (e) {
//             if (i == _maxRetries - 1) rethrow;
//             await Future.delayed(Duration(seconds: _retryDelay));
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
//               channelList: _entertainmentList,
//               onFabFocusChanged: (bool) {},
//               genres: newsItem.genres,
//               channels: [],
//               initialIndex: 1,
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
import 'package:mobi_tv_entertainment/widgets/small_widgets/empty_state.dart';
import 'package:mobi_tv_entertainment/widgets/small_widgets/error_message.dart';
import 'package:mobi_tv_entertainment/widgets/small_widgets/loading_indicator.dart';
import 'package:flutter/material.dart';

class NewsGridScreen extends StatefulWidget {
  final List<NewsItemModel> newsList;

  const NewsGridScreen({Key? key, required this.newsList}) : super(key: key);

  @override
  _NewsGridScreenState createState() => _NewsGridScreenState();
}

class _NewsGridScreenState extends State<NewsGridScreen> {
  final List<NewsItemModel> _entertainmentList = [];
  final SocketService _socketService = SocketService();
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isNavigating = false;
  int _maxRetries = 3;
  int _retryDelay = 5; // seconds

  @override
  void initState() {
    super.initState();
    _socketService.initSocket();
    _entertainmentList.addAll(widget.newsList);
  }

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
    } else if (_entertainmentList.isEmpty) {
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
            childAspectRatio: 0.7,
          ),
          itemCount: _entertainmentList.length,
          itemBuilder: (context, index) {
            return _buildNewsItem(_entertainmentList[index]);
          },
        ),
      ],
    );
  }

  Widget _buildNewsItem(NewsItemModel item) {
    return NewsItem(
      key: Key(item.id),
      item: item,
      onTap: () => _navigateToVideoScreen(item),
      onEnterPress: _handleEnterPress,
    );
  }

  void _handleEnterPress(String itemId) {
    final selectedItem =
        _entertainmentList.firstWhere((item) => item.id == itemId);
    _navigateToVideoScreen(selectedItem);
  }

  void _navigateToVideoScreen(NewsItemModel newsItem) async {
    if (_isNavigating) return;
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
          child: LoadingIndicator(),
        );
      },
    );

    Timer(Duration(seconds: 5), () {
      _isNavigating = false;
    });

    try {
      if (newsItem.streamType == 'YoutubeLive') {
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
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoScreen(
              videoUrl: newsItem.url,
              videoTitle: newsItem.name,
              channelList: _entertainmentList,
              // onFabFocusChanged: (bool) {},
              genres: newsItem.genres,
              channels: [],
              initialIndex: 1,
            ),
          ),
        );
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
