import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobi_tv_entertainment/main.dart';
import 'package:mobi_tv_entertainment/menu_screens/home_sub_screen/news_grid_screen.dart';
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
import '../../widgets/utils/random_light_color_widget.dart';
import 'channels_category.dart';



class MusicScreen extends StatefulWidget {
  @override
  _MusicScreenState createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  // final List<NewsItemModel> _musicList = [];
  List<NewsItemModel> _musicList = [];
  final SocketService _socketService = SocketService();
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isNavigating = false;
  int _maxRetries = 3;
  int _retryDelay = 5; // seconds
  String _selectedCategory = 'Live'; // Default category

  final List<String> categories = [
    'Live',
    'Entertainment',
    'Music',
    'Movie',
    'News',
    'Sports',
    'Religious'
  ];

  Map<String, FocusNode> categoryFocusNodes = {};
  late FocusNode moreFocusNode;

  @override
  void initState() {
    super.initState();
    _socketService.initSocket();
    fetchData();
    checkServerStatus();
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

        _loadCachedDataAndFetchMusic();
    _apiService.updateStream.listen((hasChanges) {
      if (hasChanges) {
        _loadCachedDataAndFetchMusic(); // Refetch data if changes occur
      }
    });

    // Initialize focus nodes for each category
    for (var category in categories) {
      categoryFocusNodes[category] = FocusNode();
    }
    moreFocusNode = FocusNode();
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

  void checkServerStatus() {
    Timer.periodic(Duration(seconds: 10), (timer) {
      // Check if the socket is connected, otherwise attempt to reconnect
      if (!_socketService.socket.connected) {
        // print('YouTube server down, retrying...');
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
        _musicList.clear();
        // Use the selected category to determine which list to add
        switch (_selectedCategory.toLowerCase()) {
          case 'live':
            _musicList.addAll(_apiService.allChannelList);
            break;
          case 'entertainment':
            _musicList.addAll(_apiService.entertainmentList);
            break;
          case 'music':
            _musicList.addAll(_apiService.musicList);
            break;
          case 'movie':
            _musicList.addAll(_apiService.movieList);
            break;
          case 'news':
            _musicList.addAll(_apiService.newsList);
            break;
          case 'sports':
            _musicList.addAll(_apiService.sportsList);
            break;
          case 'religious':
            _musicList.addAll(_apiService.religiousList);
            break;
          default:
            _musicList.addAll(_apiService.musicList);
        }
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
      body: Column(
        children: [
          // SizedBox(height: screenhgt * 0.03),
          _buildCategoryButtons(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }





  Widget _buildCategoryButtons() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: screenhgt * 0.01),
      height: screenhgt * 0.1, // Parent container height
      child: Row(
        children: [
          ...categories.asMap().entries.map((entry) {
            int index = entry.key;
            String category = entry.value;

            return Focus(
              focusNode: categoryFocusNodes[category],
              onKey: (FocusNode node, RawKeyEvent event) {
                if (event is RawKeyDownEvent) {
                  if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                    if (index == categories.length - 1) {
                      FocusScope.of(context).requestFocus(moreFocusNode);
                    } else {
                      FocusScope.of(context).requestFocus(
                          categoryFocusNodes[categories[index + 1]]);
                    }
                    return KeyEventResult.handled;
                  } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                    if (index == 0) {
                      FocusScope.of(context).requestFocus(moreFocusNode);
                    } else {
                      FocusScope.of(context).requestFocus(
                          categoryFocusNodes[categories[index - 1]]);
                    }
                    return KeyEventResult.handled;
                  } else if (event.logicalKey == LogicalKeyboardKey.enter ||
                      event.logicalKey == LogicalKeyboardKey.select) {
                    _selectCategory(category);
                    return KeyEventResult.handled;
                  }
                }
                return KeyEventResult.ignored;
              },
              child: Builder(
                builder: (BuildContext context) {
                  final bool hasFocus = Focus.of(context).hasFocus;

                  return RandomLightColorWidget(
                    hasFocus: hasFocus,
                    childBuilder: (Color randomColor) {
                      return Container(
                        margin: EdgeInsets.all(
                            screenwdt * 0.001), // Reduced padding
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: hasFocus ? randomColor : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: TextButton(
                          onPressed: () => _selectCategory(category),
                          style: ButtonStyle(
                            padding: MaterialStateProperty.all(EdgeInsets.zero),
                          ),
                          child: Center(
                            child: Text(
                              category,
                              style: TextStyle(
                                fontSize: menutextsz,
                                color: _selectedCategory == category
                                    ? borderColor
                                    : (hasFocus ? randomColor : hintColor),
                                fontWeight:
                                    _selectedCategory == category || hasFocus
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            );
          }).toList(),

          // Add the "More" button but keep it aligned to the left and sized according to the text

          Expanded(
            child: Focus(
              focusNode: moreFocusNode,
              onKey: (FocusNode node, RawKeyEvent event) {
                if (event is RawKeyDownEvent) {
                  if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                    FocusScope.of(context)
                        .requestFocus(categoryFocusNodes[categories.first]);
                    return KeyEventResult.handled;
                  } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                    FocusScope.of(context)
                        .requestFocus(categoryFocusNodes[categories.last]);
                    return KeyEventResult.handled;
                  } else if (event.logicalKey == LogicalKeyboardKey.enter ||
                      event.logicalKey == LogicalKeyboardKey.select) {
                    _navigateToChannelsCategory();
                    return KeyEventResult.handled;
                  }
                }
                return KeyEventResult.ignored;
              },
              child: Builder(
                builder: (BuildContext context) {
                  final bool hasFocus = Focus.of(context).hasFocus;

                  return Align(
                    alignment: Alignment.centerLeft,
                    child: RandomLightColorWidget(
                      hasFocus: hasFocus,
                      childBuilder: (Color randomColor) {
                        return Container(
                          margin: EdgeInsets.all(
                              screenwdt * 0.001), // Reduced padding
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color:
                                  hasFocus ? randomColor : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: TextButton(
                            onPressed: _navigateToChannelsCategory,
                            style: ButtonStyle(
                              padding:
                                  MaterialStateProperty.all(EdgeInsets.zero),
                            ),
                            child: Text(
                              'More',
                              style: TextStyle(
                                fontSize: menutextsz,
                                color: hasFocus ? randomColor : hintColor,
                                fontWeight: hasFocus
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToChannelsCategory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChannelsCategory(),
      ),
    );
  }

  

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });
    fetchData();
  }

  Widget _buildBody() {
    if (_isLoading) {
      return LoadingIndicator();
    } else if (_errorMessage.isNotEmpty) {
      return ErrorMessage(message: _errorMessage);
    } else if (_musicList.isEmpty) {
      return EmptyState(message: 'No items found for $_selectedCategory');
    } else {
      return _buildNewsList();
    }
  }

  Widget _buildNewsList() {
    int totalItems = _musicList.length;
    bool showViewAll = totalItems > 10;

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: showViewAll ? 11 : totalItems,
      itemBuilder: (context, index) {
        if (showViewAll && index == 10) {
          return _buildViewAllItem();
        }
        return _buildNewsItem(_musicList[index]);
      },
    );
  }

  Widget _buildViewAllItem() {
    return Focus(
      onKey: (FocusNode node, RawKeyEvent event) {
        if (event is RawKeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            // Prevent moving focus beyond "View All"
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: NewsItem(
        key: Key('view_all'),
        item: NewsItemModel(
          id: 'view_all',
          name: _selectedCategory.toUpperCase(),
          description: ' $_selectedCategory ',
          banner: '',
          url: '',
          streamType: '',
          genres: '',
          status: '',
        ),
        onTap: _navigateToViewAllScreen,
        onEnterPress: _handleEnterPress,
      ),
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
    if (itemId == 'view_all') {
      _navigateToViewAllScreen();
    } else {
      final selectedItem =
          _musicList.firstWhere((item) => item.id == itemId);
      _navigateToVideoScreen(selectedItem);
    }
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
                // onFabFocusChanged: (bool) {},
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
                // videoTitle: newsItem.name,
                // channelList: _musicList,
                // genres: newsItem.genres,
                // channels: [],
                // initialIndex: 1,
                bannerImageUrl: newsItem.banner,
                startAtPosition: Duration.zero,
                videoType: newsItem.streamType,
                channelList: _musicList,
                isLive: true,isVOD: false,isBannerSlider: false,
                source: 'isLiveScreen',isSearch: false,
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

  void _navigateToViewAllScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewsGridScreen( newsList: _musicList,),
      ),
    );
  }

  



  @override
  void dispose() {
    _socketService.dispose();
    categoryFocusNodes.values.forEach((node) => node.dispose());
    moreFocusNode.dispose();
    super.dispose();
  }
}


