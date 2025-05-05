import 'dart:async';
import 'dart:convert';
import 'package:mobi_tv_entertainment/main.dart';
import 'package:mobi_tv_entertainment/provider/focus_provider.dart';
import 'package:mobi_tv_entertainment/video_widget/socket_service.dart';
import 'package:mobi_tv_entertainment/video_widget/video_screen.dart';
import 'package:mobi_tv_entertainment/widgets/items/live_grid_item.dart';
import 'package:mobi_tv_entertainment/widgets/items/news_item.dart';
import 'package:mobi_tv_entertainment/widgets/models/news_item_model.dart';
import 'package:mobi_tv_entertainment/widgets/services/api_service.dart';
import 'package:mobi_tv_entertainment/widgets/small_widgets/empty_state.dart';
import 'package:mobi_tv_entertainment/widgets/small_widgets/error_message.dart';
import 'package:mobi_tv_entertainment/widgets/small_widgets/loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LiveScreen extends StatefulWidget {
  @override
  _LiveScreenState createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  List<NewsItemModel> _musicList = [];

  final SocketService _socketService = SocketService();
  final ApiService _apiService = ApiService();
  // final FocusNode firstItemFocusNode = FocusNode();
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isNavigating = false;
  int _maxRetries = 3;
  int _retryDelay = 5; // seconds
  Timer? _timer;

  // Track current focus position
  int _currentRow = 0;
  int _currentCol = 0;
  final int _crossAxisCount = 5;
  final List<List<FocusNode>> _focusNodes = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _socketService.initSocket();
    checkServerStatus();
    _loadCachedDataAndFetchLive();

    _apiService.updateStream.listen((hasChanges) {
      if (hasChanges) {
        _loadCachedDataAndFetchLive();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (var row in _focusNodes) {
      for (var node in row) {
        node.dispose();
      }
    }
    _socketService.dispose();
    _timer?.cancel();
    super.dispose();
  }

  final List<GlobalKey> _itemKeys = [];

  void _initializeKeys() {
    _itemKeys.clear();
    for (var i = 0; i < _musicList.length; i++) {
      _itemKeys.add(GlobalKey());
    }
    print('Initialized ${_itemKeys.length} keys');
  }

  // void _initializeFocusNodes() {
  //   _focusNodes.clear();
  //   final rowCount = (_musicList.length / _crossAxisCount).ceil();

  //   for (int i = 0; i < rowCount; i++) {
  //     List<FocusNode> row = [];
  //     for (int j = 0; j < _crossAxisCount; j++) {
  //       if (i * _crossAxisCount + j < _musicList.length) {
  //         row.add(FocusNode());
  //       }
  //     }
  //     _focusNodes.add(row);
  //   }

  //   // // Set initial focus
  //   // if (_focusNodes.isNotEmpty && _focusNodes[0].isNotEmpty) {
  //   //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //   //     _focusNodes[0][0].requestFocus();
  //   //   });
  //   // }
  //     if (_focusNodes.isNotEmpty && _focusNodes[0].isNotEmpty) {
  //   context.read<FocusProvider>().setLiveScreenFocusNode(_focusNodes[0][0]);
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     _focusNodes[0][0].requestFocus();
  //   });
  // }
  // }

// void _initializeFocusNodes() {
//   _initializeKeys(); // Initialize keys for all items
//   _focusNodes.clear();
//   final rowCount = (_musicList.length / _crossAxisCount).ceil();

//   for (int i = 0; i < rowCount; i++) {
//     List<FocusNode> row = [];
//     for (int j = 0; j < _crossAxisCount; j++) {
//       if (i * _crossAxisCount + j < _musicList.length) {
//         row.add(FocusNode());
//         final identifier = 'item_${i}_${j}';
//         context.read<FocusProvider>().registerElementKey(
//           identifier,
//           _itemKeys[i * _crossAxisCount + j],
//         );
//       }
//     }
//     _focusNodes.add(row);
//   }

//   if (_focusNodes.isNotEmpty && _focusNodes[0].isNotEmpty) {
//     context.read<FocusProvider>().setLiveScreenFocusNode(_focusNodes[0][0]);
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _focusNodes[0][0].requestFocus();
//     });
//   }
// }

  void _initializeFocusNodes() {
    _initializeKeys(); // Initialize keys for all items
    _focusNodes.clear();
    final rowCount = (_musicList.length / _crossAxisCount).ceil();

    for (int i = 0; i < rowCount; i++) {
      List<FocusNode> row = [];
      for (int j = 0; j < _crossAxisCount; j++) {
        if (i * _crossAxisCount + j < _musicList.length) {
          row.add(FocusNode());
          final identifier = 'item_${i}_${j}';
          context.read<FocusProvider>().registerElementKey(
                identifier,
                _itemKeys[i * _crossAxisCount + j],
              );
        }
      }
      _focusNodes.add(row);
    }

    if (_focusNodes.isNotEmpty && _focusNodes[0].isNotEmpty) {
      context.read<FocusProvider>().setLiveScreenFocusNode(_focusNodes[0][0]);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNodes[0][0].requestFocus();
      });
    }
  }

//   void _scrollToFocusedItem(int row, int col) {
//   final itemHeight = screenhgt * 0.1; // Approximate height of each grid item
//   final itemWidth = screenwdt / _crossAxisCount; // Width of each grid item

//   final targetOffset = row * itemHeight; // Calculate vertical offset

//   if (_scrollController.hasClients) {
//     _scrollController.animateTo(
//       targetOffset.toDouble(),
//       duration: Duration(milliseconds: 300),
//       curve: Curves.easeInOut,
//     );
//   }
// }

  // void _handleUpPress(int row, int col) {
  //   if (row > 0 && _focusNodes[row - 1].length > col) {
  //     _focusNodes[row - 1][col].requestFocus();
  //     setState(() {
  //       _currentRow = row - 1;
  //       _currentCol = col;
  //     });
  //   }
  // }

//   Widget _buildNewsList() {
//   return Padding(
//     padding: const EdgeInsets.all(8.0),
//     child: GridView.builder(
//       controller: _scrollController,
//       clipBehavior: Clip.none,
//       physics: const AlwaysScrollableScrollPhysics(), // Enable scrolling
//       gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: _crossAxisCount,
//         mainAxisSpacing: 10.0,
//         crossAxisSpacing: 10.0,
//         // Add suitable aspect ratio for your items
//         // childAspectRatio: 16 / 9, // Adjust this value based on your item dimensions
//       ),
//       itemCount: _musicList.length,
//       itemBuilder: (context, index) {
//         final row = index ~/ _crossAxisCount;
//         final col = index % _crossAxisCount;
//         return _buildNewsItem(_musicList[index], row, col);
//       },
//     ),
//   );
// }

  Widget _buildNewsList() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate item height based on aspect ratio
          final itemWidth = constraints.maxWidth / _crossAxisCount;
          final itemHeight = itemWidth * 0.00001; // 16:9 aspect ratio

          // Add extra padding for focus effect
          final focusPadding =
              itemHeight * 0.0; // 15% of item height for focus effect

          return Container(
            // Add padding at top and bottom to prevent cutoff
            padding: EdgeInsets.only(top: focusPadding, bottom: focusPadding),
            child: GridView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              clipBehavior: Clip.none, // Allow items to overflow their bounds
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _crossAxisCount,
                mainAxisSpacing: 20.0, // Increased spacing between rows
                crossAxisSpacing: 10.0,
                // childAspectRatio: 16/9,
              ),
              itemCount: _musicList.length,
              itemBuilder: (context, index) {
                final row = index ~/ _crossAxisCount;
                final col = index % _crossAxisCount;
                return LiveGridItem(
                  key: _itemKeys[row * _crossAxisCount + col],
                  item: _musicList[index],
                  hideDescription: true,
                  onTap: () => _navigateToVideoScreen(_musicList[index]),
                  onEnterPress: _handleEnterPress,
                  focusNode: _focusNodes[row][col],
                  onUpPress: () => _handleUpPress(row, col),
                  onDownPress: () => _handleDownPress(row, col),

                  onLeftPress: () =>
                      _handleLeftPress(row, col), // Add Left Navigation
                  onRightPress: () =>
                      _handleRightPress(row, col), // Add Right Navigation
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _handleLeftPress(int row, int col) {
    if (col > 0) {
      // Ensure it's not the first column
      _focusNodes[row][col - 1].requestFocus();
      setState(() {
        _currentCol = col - 1;
      });
    }
  }

  void _handleRightPress(int row, int col) {
    if (col < _crossAxisCount - 1 && col + 1 < _focusNodes[row].length) {
      // Ensure it's not the last column
      _focusNodes[row][col + 1].requestFocus();
      setState(() {
        _currentCol = col + 1;
      });
    }
  }

// Update the scroll method to handle scrolling properly
  void _scrollToFocusedItem(int row, int col) {
    final itemIndex = row * _crossAxisCount + col;
    final viewportHeight = _scrollController.position.viewportDimension;
    final itemHeight =
        viewportHeight / (_crossAxisCount / 2); // Approximate height

    final targetOffset = (itemIndex ~/ _crossAxisCount) * itemHeight;

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(seconds: 1),
        curve: Curves.easeInOut,
      );
    }
  }

// Update the focus handlers to include scrolling
  void _handleUpPress(int row, int col) {
    if (row == 0) {
      context.read<FocusProvider>().requestLiveTvFocus();
    } else if (row > 0 && _focusNodes[row - 1].length > col) {
      _scrollToFocusedItem(row - 1, col);
      _focusNodes[row - 1][col].requestFocus();
      setState(() {
        _currentRow = row - 1;
        _currentCol = col;
      });
    }
  }

  void _handleDownPress(int row, int col) {
    if (row < _focusNodes.length - 1 && _focusNodes[row + 1].length > col) {
      _scrollToFocusedItem(row + 1, col);
      _focusNodes[row + 1][col].requestFocus();
      setState(() {
        _currentRow = row + 1;
        _currentCol = col;
      });
    }
  }

//   void _handleUpPress(int row, int col) {
//   if (row == 0) {
//     // First row से ऊपर जाने पर Live TV button पर focus करें
//     context.read<FocusProvider>().requestLiveTvFocus();
//   } else if (row > 0 && _focusNodes[row - 1].length > col) {
//     // _scrollToFocusedItem(row - 1, col);
//     _focusNodes[row - 1][col].requestFocus();
//     setState(() {
//       _currentRow = row - 1;
//       _currentCol = col;
//     });
//   }
// }

//   void _handleDownPress(int row, int col) {
//     if (row < _focusNodes.length - 1 && _focusNodes[row + 1].length > col) {

//       _focusNodes[row + 1][col].requestFocus();
//       // _scrollToFocusedItem(row + 1, col);
//       setState(() {
//         _currentRow = row + 1;
//         _currentCol = col;
//       });
//     }
//   }

  // @override
  // void initState() {
  //   super.initState();
  //   _socketService.initSocket();
  //   checkServerStatus();
  //   // fetchData();

  //   _loadCachedDataAndFetchLive(); // Load cached data and fetch in the background
  //   _apiService.updateStream.listen((hasChanges) {
  //     if (hasChanges) {
  //       _loadCachedDataAndFetchLive(); // Refetch data if changes occur
  //     }
  //   });
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     // Request focus on the first item after the screen is built
  //     if (firstItemFocusNode.canRequestFocus) {
  //       firstItemFocusNode.requestFocus();
  //     }
  //   });
  // }

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
          _musicList =
              cachedData.map((item) => NewsItemModel.fromJson(item)).toList();
          _isLoading = false; // Show cached data immediately
        });

        _initializeFocusNodes();
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

      _initializeFocusNodes();

      setState(() {
        _isLoading =
            false; // Stop the loading indicator after live data is fetched
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching live data';
        _isLoading = false;
      });
    }
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
            onPressed:
                _loadCachedDataAndFetchLive, // Retry fetching data on button press
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

  // Widget _buildNewsList() {
  //   return Padding(
  //     padding: const EdgeInsets.all(8.0),
  //     child: GridView.builder(
  //       gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
  //         crossAxisCount: 5,
  //       ),
  //       itemCount: _musicList.length,
  //       itemBuilder: (context, index) {
  //         return _buildNewsItem(_musicList[index], index);
  //       },
  //     ),
  //   );
  // }

  // Widget _buildNewsItem(NewsItemModel item, index) {
  //   return NewsItem(
  //     key: Key(item.id),
  //     item: item,
  //     hideDescription: true,
  //     onTap: () => _navigateToVideoScreen(item),
  //     onEnterPress: _handleEnterPress,
  //     focusNode: index == 0 ? firstItemFocusNode : FocusNode(),
  //   );
  // }

  //  Widget _buildNewsList() {
  //   return Padding(
  //     padding: const EdgeInsets.all(8.0),
  //     child: GridView.builder(
  //       controller: _scrollController,
  //       gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
  //         crossAxisCount: _crossAxisCount,
  //       ),
  //       itemCount: _musicList.length,
  //       itemBuilder: (context, index) {
  //         final row = index ~/ _crossAxisCount;
  //         final col = index % _crossAxisCount;
  //         return _buildNewsItem(_musicList[index], row, col);
  //       },
  //     ),
  //   );
  // }

//   Widget _buildNewsList() {
//   return Padding(
//     padding: const EdgeInsets.all(8.0),
//     child: GridView.builder(
//       gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: _crossAxisCount,
//         mainAxisSpacing: 10.0,
//         crossAxisSpacing: 10.0,
//       ),
//       itemCount: _musicList.length,
//       itemBuilder: (context, index) {
//         final row = index ~/ _crossAxisCount;
//         final col = index % _crossAxisCount;
//         return _buildNewsItem(_musicList[index], row, col);
//       },
//     ),
//   );
// }

// Widget _buildNewsList() {
//   return Padding(
//     padding: const EdgeInsets.all(8.0),
//     child: SingleChildScrollView(
//       controller: _scrollController, // Use the correct ScrollController
//       child: GridView.builder(
//         shrinkWrap: true, // Allow GridView to size within the Scrollable
//         gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//           crossAxisCount: _crossAxisCount,
//           mainAxisSpacing: 10.0,
//           crossAxisSpacing: 10.0,
//         ),
//         itemCount: _musicList.length,
//         itemBuilder: (context, index) {
//           final row = index ~/ _crossAxisCount;
//           final col = index % _crossAxisCount;
//           return _buildNewsItem(_musicList[index], row, col);
//         },
//       ),
//     ),
//   );
// }

  // Widget _buildNewsItem(NewsItemModel item, int row, int col) {
  //   return NewsItem(
  //     key: Key(item.id),
  //     item: item,
  //     hideDescription: true,
  //     onTap: () => _navigateToVideoScreen(item),
  //     onEnterPress: _handleEnterPress,
  //     focusNode: _focusNodes[row][col],
  //     onUpPress: () => _handleUpPress(row, col),
  //     onDownPress: () => _handleDownPress(row, col),
  //   );
  // }

  Widget _buildNewsItem(NewsItemModel item, int row, int col) {
    final identifier = 'item_${row}_${col}';
    return NewsItem(
      key: _itemKeys[row * _crossAxisCount + col],
      item: item,
      hideDescription: true,
      onTap: () => _navigateToVideoScreen(item),
      onEnterPress: _handleEnterPress,
      focusNode: _focusNodes[row][col],
      onUpPress: () => _handleUpPress(row, col),
      onDownPress: () => _handleDownPress(row, col),
      onFocusChange: (hasFocus) {
        if (hasFocus) {
          print('Focus gained for $identifier');
          context.read<FocusProvider>().scrollToElement(identifier);
        }
      },
    );
  }

  void _handleEnterPress(String itemId) {
    final selectedItem = _musicList.firstWhere((item) => item.id == itemId);
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
      String originalUrl = newsItem.url;
      if (newsItem.streamType == 'YoutubeLive') {
        // Retry fetching the updated URL if stream type is YouTube Live
        for (int i = 0; i < _maxRetries; i++) {
          try {
            String updatedUrl =
                await _socketService.getUpdatedUrl(newsItem.url);
            newsItem = NewsItemModel(
              id: newsItem.id,videoId: '',
              name: newsItem.name,
              description: newsItem.description,
              banner: newsItem.banner,
              poster: newsItem.poster,
              category: newsItem.category,
              url: updatedUrl,
              streamType: 'M3u8',
              type: 'M3u8',
              genres: newsItem.genres,
              status: newsItem.status, 
              index: newsItem.index,
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

      bool liveStatus = true;

      if (shouldPlayVideo) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoScreen(
              videoUrl: newsItem.url,
              bannerImageUrl: newsItem.banner,
              startAtPosition: Duration.zero,
              videoType: newsItem.streamType,
              channelList: _musicList,
              isLive: true,
              isVOD: false,
              isBannerSlider: false,
              source: 'isLiveScreen',
              isSearch: false,
              videoId: int.tryParse(newsItem.id),
              unUpdatedUrl: originalUrl,
              name: newsItem.name,
              liveStatus: liveStatus,
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

  // @override
  // void dispose() {
  //   _socketService.dispose();
  //   firstItemFocusNode.dispose();
  //   _timer?.cancel();
  //   super.dispose();
  // }
}
