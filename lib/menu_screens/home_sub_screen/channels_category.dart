

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobi_tv_entertainment/main.dart';
import 'package:mobi_tv_entertainment/video_widget/socket_service.dart';
import 'package:mobi_tv_entertainment/video_widget/video_screen.dart';
import 'package:mobi_tv_entertainment/widgets/items/news_item.dart';
import 'package:mobi_tv_entertainment/widgets/models/news_item_model.dart';
import 'package:mobi_tv_entertainment/widgets/services/api_service.dart';
import 'package:mobi_tv_entertainment/widgets/small_widgets/empty_state.dart';
import 'package:mobi_tv_entertainment/widgets/small_widgets/error_message.dart';
import 'package:mobi_tv_entertainment/widgets/small_widgets/loading_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../video_widget/vlc_player_screen.dart';

class ChannelsCategory extends StatefulWidget {
  @override
  _ChannelsCategoryState createState() => _ChannelsCategoryState();
}

class _ChannelsCategoryState extends State<ChannelsCategory> {
  // final List<NewsItemModel> _musicList = [];
  List<NewsItemModel> _musicList = [];

  final Map<String, List<NewsItemModel>> _groupedByGenre =
      {}; // Group by genres
  final SocketService _socketService = SocketService();
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isNavigating = false;
  int _maxRetries = 3;
  int _retryDelay = 5; // seconds
  bool _isAttemptingReconnect =
      false; // To avoid repeated reconnection attempts

  @override
  void initState() {
    super.initState();
    _socketService.initSocket();
    checkServerStatus();
    // fetchData();
        // Update cache when the page is entered
    // _apiService.updateCacheOnPageEnter();
    // // Listen to updates from the ApiService stream
    // _apiService.updateStream.listen((hasChanges) {
    //   if (hasChanges) {
    //     setState(() {
    //       _isLoading = true;
    //     });
    //     fetchData(); // Refetch the data only when changes occur
    //   }
    // });
    _loadCachedData();
    _fetchDataInBackground();
        _apiService.updateStream.listen((hasChanges) {
      if (hasChanges) {
        setState(() {
          _isLoading = true;
        });
        _fetchDataInBackground();
      }
    });

  }



  Future<void> _loadCachedData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedEntertainment = prefs.getString('channels_category_data');

      if (cachedEntertainment != null) {
        final List<dynamic> cachedData = json.decode(cachedEntertainment);
        setState(() {
          _musicList.clear();
          _musicList.addAll(cachedData.map((item) => NewsItemModel.fromJson(item)).toList());
          _groupByGenre(_musicList);
          _isLoading = false;
        });
        print('Loaded cached data successfully');
      } else {
        print('No cached data found');
        setState(() {
          _isLoading = true;
        });
      }
    } catch (e) {
      print('Error loading cached data: $e');
      setState(() {
        _errorMessage = 'Error loading cached data';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchDataInBackground() async {
    try {
      await _apiService.fetchSettings();
      await _apiService.fetchEntertainment();

      final prefs = await SharedPreferences.getInstance();
      final newEntertainmentData = json.encode(_apiService.allChannelList);

      final cachedEntertainment = prefs.getString('channels_category_data');
      if (cachedEntertainment != newEntertainmentData) {
        prefs.setString('channels_category_data', newEntertainmentData);
        setState(() {
          _musicList.clear();
          _musicList.addAll(_apiService.allChannelList);
          _groupByGenre(_musicList);
          _isLoading = false;
        });
        print('Fetched and updated data successfully');
      }
    } catch (e) {
      print('Error fetching new data: $e');
      setState(() {
        _errorMessage = 'Failed to load data';
        _isLoading = false;
      });
    }
  }

  void checkServerStatus() {
    Timer.periodic(Duration(seconds: 10), (timer) {
      // Check if the socket is connected, otherwise attempt to reconnect
      if (!_socketService.socket.connected && !_isAttemptingReconnect) {
        _isAttemptingReconnect = true;
        // print('YouTube server down, retrying...');
        _socketService.initSocket(); // Re-establish the socket connection
        _isAttemptingReconnect = false;
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

      // Grouping by genres
      setState(() {
        _musicList.clear();
        _musicList
            .addAll(_apiService.allChannelList); // Add fetched items

        // Grouping items by their genres
        _groupByGenre(_musicList);

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Something Went Wrong';
        _isLoading = false;
      });
    }
  }

  // Function to group items by genres
  void _groupByGenre(List<NewsItemModel> items) {
    _groupedByGenre.clear();
    for (var item in items) {
      final genres =
          item.genres.split(','); // Split by comma if multiple genres exist
      for (var genre in genres) {
        genre = genre.trim();
        if (genre.isNotEmpty) {
          if (!_groupedByGenre.containsKey(genre)) {
            _groupedByGenre[genre] = [];
          }
          _groupedByGenre[genre]?.add(item);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cardColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildBody(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: LoadingIndicator());
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
    } else if (_groupedByGenre.isEmpty) {
      return EmptyState(message: 'No items found');
    } else {
      return _buildGenreRows();
    }
  }

  // Building genre rows with horizontal ListView for each genre
  Widget _buildGenreRows() {
    return Expanded(
      child: ListView(
        children: _groupedByGenre.keys.map((genre) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  genre.toUpperCase(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(
                height: 200, // Height for each horizontal list
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _groupedByGenre[genre]?.length ?? 0,
                  itemBuilder: (context, index) {
                    final item = _groupedByGenre[genre]?[index];
                    return _buildNewsItem(item!);
                  },
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNewsItem(NewsItemModel item) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: NewsItem(
        key: Key(item.id),
        item: item,
        hideDescription: true,
        onTap: () => _navigateToVideoScreen(item),
        onEnterPress: _handleEnterPress,
      ),
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
          child: Center(child: LoadingIndicator()),
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
