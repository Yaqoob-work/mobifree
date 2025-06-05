import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobi_tv_entertainment/main.dart';
import 'package:mobi_tv_entertainment/menu_screens/home_sub_screen/news_grid_screen.dart';
import 'package:mobi_tv_entertainment/provider/color_provider.dart';
import 'package:mobi_tv_entertainment/provider/focus_provider.dart';
import 'package:mobi_tv_entertainment/provider/shared_data_provider.dart';
import 'package:mobi_tv_entertainment/video_widget/socket_service.dart';
import 'package:mobi_tv_entertainment/video_widget/video_screen.dart';
import 'package:mobi_tv_entertainment/widgets/items/news_item.dart';
import 'package:mobi_tv_entertainment/widgets/models/news_item_model.dart';
import 'package:mobi_tv_entertainment/widgets/services/api_service.dart';
import 'package:mobi_tv_entertainment/widgets/small_widgets/empty_state.dart';
import 'package:mobi_tv_entertainment/widgets/small_widgets/error_message.dart';
import 'package:mobi_tv_entertainment/widgets/small_widgets/loading_indicator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/utils/random_light_color_widget.dart';
import 'channels_category.dart';

class MusicScreen extends StatefulWidget {
  final Function(bool)? onFocusChange; // Add this

  const MusicScreen(
      {Key? key, this.onFocusChange, required FocusNode focusNode})
      : super(key: key);
  @override
  _MusicScreenState createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  // final List<NewsItemModel> _musicList = [];
  Map<int, Color> _nodeColors = {};
  Map<String, FocusNode> newsItemFocusNodes = {};
  List<NewsItemModel> _musicList = [];
  final SocketService _socketService = SocketService();
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isNavigating = false;
  String _selectedCategory = 'Live'; // Default category
  int _maxRetries = 3;
  int _retryDelay = 5; // seconds
  final ScrollController _scrollController = ScrollController();

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

    // // Add listeners to first category focus node
    // for (var category in categories) {
    //   categoryFocusNodes[category] = FocusNode()
    //     ..addListener(() {
    //       if (categoryFocusNodes[category]!.hasFocus) {
    //         widget.onFocusChange?.call(true);
    //       }
    //     });
    // }

    //     categories.forEach((category) {
    //   categoryFocusNodes[category] = FocusNode()
    //     ..addListener(() {
    //       if (categoryFocusNodes[category]!.hasFocus) {
    //         widget.onFocusChange?.call(true);
    //       }
    //     });
    // });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Agar koi banner available nahi hai, tab category button focus set karein
      final firstCategoryNode = categoryFocusNodes[categories.first];
      if (firstCategoryNode != null) {
        context
            .read<FocusProvider>()
            .setFirstMusicItemFocusNode(firstCategoryNode);
        print("✅ MusicScreen: First category focus node registered.");
      } else if (_musicList.isNotEmpty) {
        final firstItemId = _musicList[0].id;
        if (newsItemFocusNodes.containsKey(firstItemId)) {
          final focusNode = newsItemFocusNodes[firstItemId]!;
          context.read<FocusProvider>().setFirstMusicItemFocusNode(focusNode);
          print(
              "✅ MusicScreen: First music item focus node registered: $firstItemId");
        } else {
          print("⚠️ MusicScreen: First music item NOT registered!");
        }
      }
    });

    _loadCachedDataAndFetchMusic();
    _apiService.updateStream.listen((hasChanges) {
      if (hasChanges) {
        _loadCachedDataAndFetchMusic(); // Refetch data if changes occur
      }
    });

    // Initialize focus nodes for each category
    // for (var category in categories) {
    //   categoryFocusNodes[category] = FocusNode();
    // }
    // moreFocusNode = FocusNode();

    // Ensure category focus nodes are initialized
    for (var category in categories) {
      categoryFocusNodes.putIfAbsent(category, () => FocusNode());
    }

    // Ensure focus listener is added
    categoryFocusNodes[categories.first]!.addListener(() {
      if (categoryFocusNodes[categories.first]!.hasFocus) {
        widget.onFocusChange?.call(true);
      }
    });

    // Ensure more button focus node is initialized
    moreFocusNode = FocusNode();

    // Ensure news item focus nodes are properly initialized
    for (var item in _musicList) {
      newsItemFocusNodes.putIfAbsent(item.id, () => FocusNode());
    }
  }

  void _scrollToFocusedItem(String itemId) {
    if (newsItemFocusNodes[itemId] != null &&
        newsItemFocusNodes[itemId]!.hasFocus) {
      Scrollable.ensureVisible(
        newsItemFocusNodes[itemId]!.context!,
        alignment: 0.05, // Adjust alignment for better UX
        duration: Duration(milliseconds: 1000),
        curve: Curves.linear,
      );
    }
  }

  // Add color generator function
  Color _generateRandomColor() {
    final random = Random();
    return Color.fromRGBO(
      random.nextInt(256),
      random.nextInt(256),
      random.nextInt(256),
      1,
    );
  }

  Future<void> _loadCachedDataAndFetchMusic() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Step 1: Load cached data
      await _loadCachedMusicData();

      // Step 2: Fetch new data in the background and update UI if needed
      await _fetchMusicInBackground();
    } catch (e) {
      setState(() {
        // _errorMessage = 'Failed to load data';
        _isLoading = false;
      });
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      //   content: Text("_loadCachedDataAndFetch: $e"),
      //   backgroundColor: Colors.red,
      // ));
    }
  }

  Future<void> _loadCachedMusicData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedMusic = prefs.getString('music_list');

      if (cachedMusic != null) {
        final List<dynamic> cachedData = json.decode(cachedMusic);
        setState(() {
          _musicList =
              cachedData.map((item) => NewsItemModel.fromJson(item)).toList();
          _isLoading = false; // Show cached data immediately
        });
      }
    } catch (e) {
      print('Error loading cached music data: $e');
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      //   content: Text("_loadCachedData : $e"),
      //   backgroundColor: Colors.red,
      // ));
    }
  }

  Future<void> _fetchMusicInBackground() async {
    try {
      // Step 1: Fetch new data from API
      final newMusicList = await _apiService.fetchMusicData();

      // Step 2: Compare with cached data
      final prefs = await SharedPreferences.getInstance();
      final cachedMusic = prefs.getString('music_list');
      final String newMusicJson = json.encode(newMusicList);

      if (cachedMusic == null || cachedMusic != newMusicJson) {
        // Step 3: Update cache if new data is different
        await prefs.setString('music_list', newMusicJson);

        // Step 4: Update UI with new data
        setState(() {
          _musicList = newMusicList;
        });
      }
    } catch (e, stacktrace) {
      print('Error fetching music data: $e');

        print('❌ Detailed error: $e');
  print('📌 Stacktrace: $stacktrace');
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text("Music API fetch failed: $e"),
    backgroundColor: Colors.red,
  ));

    }
  }

  // Future<void> _loadCachedDataAndFetchMusic() async {
  //   setState(() {
  //     _isLoading = true;
  //     _errorMessage = '';
  //   });

  //   try {
  //     // Step 1: Load cached music data first
  //     await _loadCachedMusicData();

  //     // Step 2: Fetch new data in the background and update UI if needed
  //     await _fetchMusicInBackground();
  //   } catch (e) {
  //     setState(() {
  //       _errorMessage = 'Failed to load data';
  //       _isLoading = false;
  //     });
  //   }
  // }

  // Future<void> _loadCachedMusicData() async {
  //   try {
  //     // Fetch cached music data from SharedPreferences (similar to VOD)
  //     final prefs = await SharedPreferences.getInstance();
  //     final cachedMusic = prefs.getString('music_list');

  //     if (cachedMusic != null) {
  //       // Parse and load cached data
  //       final List<dynamic> cachedData = json.decode(cachedMusic);
  //       setState(() {
  //         _musicList =
  //             cachedData.map((item) => NewsItemModel.fromJson(item)).toList();
  //         _isLoading = false; // Show cached data immediately
  //       });
  //     }
  //   } catch (e) {
  //     print('Error loading cached music data: $e');
  //   }
  // }

  // Future<void> _fetchMusicInBackground() async {
  //   try {
  //     // Fetch new music data from API and cache it (similar to VOD)
  //     final newMusicList = await _apiService.fetchMusicData();

  //     // Compare cached data with new data
  //     final prefs = await SharedPreferences.getInstance();
  //     final cachedMusic = prefs.getString('music_list');
  //     if (cachedMusic != json.encode(newMusicList)) {
  //       // Update cache if data is different
  //       prefs.setString('music_list', json.encode(newMusicList));

  //       // Update UI with new data
  //       setState(() {
  //         _musicList = newMusicList;
  //       });
  //     }
  //   } catch (e) {
  //     print('Error fetching music data: $e');
  //   }
  // }

  void _initializeNewsItemFocusNodes() {
    newsItemFocusNodes.clear();
    for (var item in _musicList) {
      newsItemFocusNodes[item.id] = FocusNode()
        ..addListener(() {
          if (newsItemFocusNodes[item.id]!.hasFocus) {
            _scrollToFocusedItem(item.id);
          }
        });
    }
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
        _initializeNewsItemFocusNodes();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        // _errorMessage = 'Something Went Wrong';
        _isLoading = false;
      });

      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      //   content: Text("_fetchData : $e"),
      //   backgroundColor: Colors.red,
      // ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
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
            final focusNode = categoryFocusNodes[category]!;

            return Focus(
              focusNode: focusNode,
              onFocusChange: (hasFocus) {
                setState(() {
                  if (hasFocus) {
                    // Update color in the provider when category button is focused
                    final randomColor = _generateRandomColor();
                    context
                        .read<ColorProvider>()
                        .updateColor(randomColor, true);
                  } else {
                    // Reset color when focus is lost
                    context.read<ColorProvider>().resetColor();
                  }
                });
              },
              onKey: (FocusNode node, RawKeyEvent event) {
                if (event is RawKeyDownEvent) {
                  if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                    final sharedDataProvider =
                        context.read<SharedDataProvider>();
                    final lastPlayedVideos =
                        sharedDataProvider.lastPlayedVideos;

                    if (lastPlayedVideos.isNotEmpty) {
                      // Request focus for the first banner in lastPlayedVideos
                      context
                          .read<FocusProvider>()
                          .requestFirstLastPlayedFocus();
                      return KeyEventResult.handled;
                    }
                  }
                  // else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                  //   if (_musicList.isNotEmpty) {
                  //     // // Request focus for first news item
                  //     // final firstItemId = _musicList[0].id;
                  //     // if (newsItemFocusNodes.containsKey(firstItemId)) {
                  //     //   FocusScope.of(context)
                  //     //       .requestFocus(newsItemFocusNodes[firstItemId]);
                  //     //   return KeyEventResult.handled;
                  //     // }
                  //     final firstItemId = _musicList[0].id;
                  //     if (newsItemFocusNodes.containsKey(firstItemId)) {
                  //       // Use FocusProvider to request focus
                  //       context.read<FocusProvider>().requestNewsItemFocusNode(
                  //           newsItemFocusNodes[firstItemId]!);
                  //       return KeyEventResult.handled;
                  //     }
                  //   }
                  // }

                  else if (event is RawKeyDownEvent &&
                      event.logicalKey == LogicalKeyboardKey.arrowDown) {
                    if (_musicList.isNotEmpty) {
                      // पहला न्यूज़-आइटम लें
                      final firstId = _musicList[0].id;
                      final nextNode = newsItemFocusNodes[firstId];
                      if (nextNode != null) {
                        FocusScope.of(context).requestFocus(nextNode);
                        return KeyEventResult.handled;
                      }
                    }
                  } else if (event.logicalKey ==
                      LogicalKeyboardKey.arrowRight) {
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
                  final currentColor =
                      context.watch<ColorProvider>().dominantColor;
                  return RandomLightColorWidget(
                    hasFocus: hasFocus,
                    childBuilder: (Color randomColor) {
                      //                       // अगर पहले से color stored है तो वही use करें, नहीं तो नया store करें
                      // if (categoryFocusNodes[category]!.hasFocus && !_nodeColors.containsKey(index)) {
                      //   _nodeColors[index] = randomColor;
                      // }
                      // // हमेशा stored color का use करें
                      // final Color currentColor = _nodeColors[index] ?? randomColor;
                      return Container(
                        margin: EdgeInsets.all(
                            screenwdt * 0.001), // Reduced padding
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: hasFocus ? currentColor : Colors.transparent,
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
                                    : (hasFocus ? currentColor : hintColor),
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
              onFocusChange: (hasFocus) {
                setState(() {
                  if (hasFocus) {
                    // Update color in the provider when "More" button is focused
                    final randomColor = _generateRandomColor();
                    context
                        .read<ColorProvider>()
                        .updateColor(randomColor, true);
                  } else {
                    // Reset color when focus is lost
                    context.read<ColorProvider>().resetColor();
                  }
                });
              },
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
                  } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                    final sharedDataProvider =
                        context.read<SharedDataProvider>();
                    final lastPlayedVideos =
                        sharedDataProvider.lastPlayedVideos;

                    if (lastPlayedVideos.isNotEmpty) {
                      // Request focus for the first banner in lastPlayedVideos
                      context
                          .read<FocusProvider>()
                          .requestFirstLastPlayedFocus();
                      return KeyEventResult.handled;
                    }
                  }
                  // else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                  //   if (_musicList.isNotEmpty) {
                  //     // // Request focus for first news item
                  //     // final firstItemId = _musicList[0].id;
                  //     // if (newsItemFocusNodes.containsKey(firstItemId)) {
                  //     //   FocusScope.of(context)
                  //     //       .requestFocus(newsItemFocusNodes[firstItemId]);
                  //     //   return KeyEventResult.handled;
                  //     // }
                  //     final firstItemId = _musicList[0].id;
                  //     if (newsItemFocusNodes.containsKey(firstItemId)) {
                  //       // Use FocusProvider to request focus
                  //       context.read<FocusProvider>().requestNewsItemFocusNode(
                  //           newsItemFocusNodes[firstItemId]!);
                  //       return KeyEventResult.handled;
                  //     }
                  //   }
                  // }
                  else if (event.logicalKey == LogicalKeyboardKey.enter ||
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
                  final Color currentColor =
                      context.watch<ColorProvider>().dominantColor;
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
                                  hasFocus ? currentColor : Colors.transparent,
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
                                color: hasFocus ? currentColor : hintColor,
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

  // void _selectCategory(String category) {
  //   setState(() {
  //     _selectedCategory = category;
  //   });
  //   fetchData();
  // }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });

    fetchData().then((_) {
      if (_musicList.isNotEmpty) {
        final firstItemId = _musicList[0].id;
        if (newsItemFocusNodes.containsKey(firstItemId)) {
          // Request focus for the first item in the selected category
          context
              .read<FocusProvider>()
              .requestNewsItemFocusNode(newsItemFocusNodes[firstItemId]!);
        }
      }
    });
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
      controller: _scrollController,
      itemCount: showViewAll ? 11 : totalItems,
      itemBuilder: (context, index) {
        if (showViewAll && index == 10) {
          return _buildViewAllItem();
        }
        return _buildNewsItem(_musicList[index], index);
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
          poster: '',
          category: '',
          url: '',
          streamType: '',
          type: '',
          genres: '',
          status: '',
          videoId: '',
          index: '',
        ),
        onTap: _navigateToViewAllScreen,
        onEnterPress: _handleEnterPress,
      ),
    );
  }

  Widget _buildNewsItem(NewsItemModel item, int index) {
    // newsItemFocusNodes.putIfAbsent(item.id, () => FocusNode());
    newsItemFocusNodes.putIfAbsent(
        item.id,
        () => FocusNode()
          ..addListener(() {
            if (newsItemFocusNodes[item.id]!.hasFocus) {
              _scrollToFocusedItem(item.id);
            }
          }));
    return NewsItem(
      key: Key(item.id),
      hideDescription: true,
      item: item,
      focusNode: newsItemFocusNodes[item.id],
      onTap: () => _navigateToVideoScreen(item),
      onEnterPress: _handleEnterPress,
      onUpPress: () {
        // Request focus for current category
        FocusScope.of(context)
            .requestFocus(categoryFocusNodes[_selectedCategory]);
      },
      onDownPress: () {
        // Request focus for the first SubVod item
        print("onDownPress called for MusicScreen");
        context.read<FocusProvider>().requestSubVodFocus();
      },
    );
  }

  void _handleEnterPress(String itemId) {
    if (itemId == 'view_all') {
      _navigateToViewAllScreen();
    } else {
      final selectedItem = _musicList.firstWhere((item) => item.id == itemId);
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
      String originalUrl = newsItem.url;
      if (newsItem.streamType == 'YoutubeLive') {
        // Retry fetching the updated URL if stream type is YouTube Live
        for (int i = 0; i < _maxRetries; i++) {
          try {
            String updatedUrl =
                await _socketService.getUpdatedUrl(newsItem.url);
            // await  'https://www.youtube.com/watch?v=${newsItem.url}';
            print('updatedUrl:$updatedUrl');

            newsItem = NewsItemModel(
              id: newsItem.id,
              videoId: '',
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
      // }
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
        builder: (context) => NewsGridScreen(
          newsList: _musicList,
        ),
      ),
    );
  }

  // @override
  // void dispose() {
  //   _socketService.dispose();
  //   categoryFocusNodes.values.forEach((node) => node.dispose());
  //   moreFocusNode.dispose();
  //   super.dispose();
  // }

  @override
  void dispose() {
    _socketService.dispose();
    // categoryFocusNodes.values.forEach((node) {
    //   if (node.hasFocus) node.unfocus();
    //   node.dispose();
    // });
    // moreFocusNode.dispose();
    for (var node in categoryFocusNodes.values) {
      node.dispose();
    }

    for (var node in newsItemFocusNodes.values) {
      node.dispose();
    }

    moreFocusNode.dispose();
    super.dispose();
  }
}
