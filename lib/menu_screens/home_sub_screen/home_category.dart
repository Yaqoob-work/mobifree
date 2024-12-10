import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as https;
import 'package:mobi_tv_entertainment/widgets/small_widgets/loading_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';
import '../../video_widget/socket_service.dart';
import '../../video_widget/video_screen.dart';
import '../../video_widget/vlc_player_screen.dart';
import '../../widgets/focussable_item_widget.dart';
import '../../widgets/utils/color_service.dart';

class CategoryService {
  List<Category> categories = [];
  Map<String, dynamic> settings = {};

  final _updateController = StreamController<bool>.broadcast();
  Stream<bool> get updateStream => _updateController.stream;

  Future<void> fetchSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedSettings = prefs.getString('settings');

    if (cachedSettings != null) {
      settings = json.decode(cachedSettings);
    } else {
      await _fetchAndCacheSettings();
    }
  }

  Future<void> _fetchAndCacheSettings() async {
    final response = await https.get(
      Uri.parse('https://api.ekomflix.com/android/getSettings'),
      headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
    );

    if (response.statusCode == 200) {
      settings = json.decode(response.body);
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('settings', response.body);
    } else {
      throw Exception('Failed to load settings');
    }
  }

  Future<List<Category>> fetchCategories() async {
    await fetchSettings();

    final prefs = await SharedPreferences.getInstance();
    final cachedCategories = prefs.getString('categories');

    if (cachedCategories != null) {
      categories = _processCategories(json.decode(cachedCategories));
      return categories;
    } else {
      await _fetchAndCacheCategories();
      return categories;
    }
  }

  Future<void> _fetchAndCacheCategories() async {
    final response = await https.get(
      Uri.parse('https://api.ekomflix.com/android/getSelectHomeCategory'),
      headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
    );

    if (response.statusCode == 200) {
      categories = _processCategories(json.decode(response.body));
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('categories', response.body);
    } else {
      throw Exception('Failed to load categories');
    }
  }

  List<Category> _processCategories(List<dynamic> jsonResponse) {
    List<Category> categories =
        jsonResponse.map((category) => Category.fromJson(category)).toList();
    if (settings['tvenableAll'] == 0) {
      for (var category in categories) {
        category.channels.retainWhere(
          (channel) => settings['channels'].contains(int.parse(channel.id)),
        );
      }
    }
    return categories;
  }

  Future<void> _updateCacheInBackground() async {
    try {
      bool hasChanges = false;

      final oldSettings = await SharedPreferences.getInstance()
          .then((prefs) => prefs.getString('settings'));
      await _fetchAndCacheSettings();
      final newSettings = await SharedPreferences.getInstance()
          .then((prefs) => prefs.getString('settings'));
      if (oldSettings != newSettings) hasChanges = true;

      final oldCategories = await SharedPreferences.getInstance()
          .then((prefs) => prefs.getString('categories'));
      await _fetchAndCacheCategories();
      final newCategories = await SharedPreferences.getInstance()
          .then((prefs) => prefs.getString('categories'));
      if (oldCategories != newCategories) hasChanges = true;

      if (hasChanges) {
        _updateController.add(true);
      }
    } catch (e) {
      print('Error updating cache in background: $e');
    }
  }

  void dispose() {
    _updateController.close();
  }
}

class HomeCategory extends StatefulWidget {
  @override
  _HomeCategoryState createState() => _HomeCategoryState();
}

class _HomeCategoryState extends State<HomeCategory> {
  late Future<List<Category>> _categories;
  late CategoryService _categoryService;

  @override
  void initState() {
    super.initState();
    // _categories = fetchCategories(context);
    // _categoryService = CategoryService();  // Initialize the service here
    // _categories = _categoryService.fetchCategories();
    // Trigger cache update when the page is entered
    // _categoryService._updateCacheInBackground();
    // _categoryService.updateStream.listen((hasChanges) {
    //   if (hasChanges) {
    //     setState(() {
    //       _categories = _categoryService.fetchCategories();
    //     });
    //   }
    // });

    _categoryService = CategoryService();
    _loadCachedCategories(); // Load cached categories immediately
    _fetchCategoriesInBackground(); // Fetch new categories in background

    _categoryService.updateStream.listen((hasChanges) {
      if (hasChanges) {
        setState(() {
          _fetchCategoriesInBackground();
        });
      }
    });
    checkServerStatus(); // Check server status for reconnection
  }

  void checkServerStatus() {
    Timer.periodic(Duration(seconds: 10), (timer) {
      // Check if the socket is connected, otherwise attempt to reconnect
      if (!SocketService().socket.connected) {
        // print('YouTube server down, retrying...');
        SocketService().initSocket(); // Re-establish the socket connection
      }
    });
  }

  Future<void> _loadCachedCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('categories');

    if (cachedData != null) {
      setState(() {
        _categories = Future.value(
            _categoryService._processCategories(json.decode(cachedData)));
      });
    }
  }

  Future<void> _fetchCategoriesInBackground() async {
    _categories = _categoryService.fetchCategories();
  }

  @override
  void dispose() {
    _categoryService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cardColor,
      body: FutureBuilder<List<Category>>(
        future: _categories,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List<Category> categories = snapshot.data!;
            return ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                return CategoryWidget(category: categories[index]);
              },
            );
          } else if (snapshot.hasError) {
            return Center(child: Text("Something went Wrong"));
          }

          return Container(
              color: Colors.black,
              child: Center(
                  child: SpinKitFadingCircle(
                color: borderColor,
                size: 50.0,
              )));
        },
      ),
    );
  }
}

class Category {
  final String id;
  final String text;
  List<Channel> channels;

  Category({
    required this.id,
    required this.text,
    required this.channels,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    var list = json['channels'] as List;
    List<Channel> channelsList = list.map((i) => Channel.fromJson(i)).toList();

    return Category(
      id: json['id'],
      text: json['text'],
      channels: channelsList,
    );
  }
}

class Channel {
  final String id;
  final String name;
  final String description;
  final String banner;
  final String genres;
  String url;
  String streamType;
  String type;
  String status;

  Channel({
    required this.id,
    required this.name,
    required this.description,
    required this.banner,
    required this.genres,
    required this.url,
    required this.streamType,
    required this.type,
    required this.status,
  });

  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(
      id: json['id'],
      name: json['name'],
      banner: json['banner'] ?? localImage,
      genres: json['genres'],
      url: json['url'] ?? '',
      streamType: json['stream_type'] ?? '',
      type: json['Type'] ?? '',
      status: json['status'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

class CategoryWidget extends StatefulWidget {
  final Category category;

  CategoryWidget({required this.category});

  @override
  State<CategoryWidget> createState() => _CategoryWidgetState();
}

class _CategoryWidgetState extends State<CategoryWidget> {
  bool _isNavigating = false;
  final SocketService _socketService = SocketService();
  int _maxRetries = 3;
  int _retryDelay = 5; // seconds
  final int timeoutDuration = 10; // seconds
  bool _shouldContinueLoading = true;
  late Future<List<Category>> _categories;
  late CategoryService _categoryService;

  @override
  void initState() {
    super.initState();
    _socketService.initSocket();
    _categoryService = CategoryService(); // Initialize the service here
    _categories = _categoryService.fetchCategories();
    _categoryService.updateStream.listen((hasChanges) {
      if (hasChanges) {
        setState(() {
          _categories = _categoryService.fetchCategories();
        });
      }
    });
  }

  @override
  void dispose() {
    _socketService.dispose();
    super.dispose();
  }

  void _showLoadingIndicator(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          onPopInvoked: (didPop) {
            if (didPop) return;
            _shouldContinueLoading = false;
            Navigator.of(context).pop();
          },
          child: Center(
            child: SpinKitFadingCircle(
              color: borderColor,
              size: 50.0,
            ),
          ),
        );
      },
    );
  }

  void _dismissLoadingIndicator() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Channel> filteredChannels = widget.category.channels
        .where((channel) => channel.url.isNotEmpty)
        .toList();

    return filteredChannels.isNotEmpty
        ? Container(
            color: cardColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.category.text.toUpperCase(),
                  style: TextStyle(
                    color: hintColor,
                    fontSize: Headingtextsz,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.4,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: filteredChannels.length > 5
                        ? 6
                        : filteredChannels.length,
                    itemBuilder: (context, index) {
                      if (index == 5 && filteredChannels.length > 5) {
                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: ViewAllWidget(
                            onTap: () {
                              _dismissLoadingIndicator();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CategoryGridView(
                                    category: widget.category,
                                    filteredChannels: filteredChannels,
                                  ),
                                ),
                              );
                            },
                            categoryText: widget.category.text.toUpperCase(),
                          ),
                        );
                      }
                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: 0),
                        child: FocusableItemWidget(
                          imageUrl: filteredChannels[index].banner,
                          name: filteredChannels[index].name,
                          onTap: () async {
                            _showLoadingIndicator(context);
                            await _playVideo(context, filteredChannels, index);
                          },
                          fetchPaletteColor: (String imageUrl) {
                            return PaletteColorService()
                                .getSecondaryColor(imageUrl);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          )
        : const SizedBox.shrink();
  }

  Future<void> _playVideo(
      BuildContext context, List<Channel> channels, int index) async {
    if (_isNavigating) return;
    _isNavigating = true;
    _shouldContinueLoading = true;

    try {
      await _updateChannelUrlIfNeeded(channels, index);
      if (_shouldContinueLoading) {
        _dismissLoadingIndicator();
        await _navigateToVideoScreen(context, channels, index);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Something Went Wrong')),
      );
    } finally {
      _isNavigating = false;
      if (mounted) {
        _dismissLoadingIndicator();
      }
    }
  }

  Future<void> _updateChannelUrlIfNeeded(
      List<Channel> channels, int index) async {
    if (channels[index].streamType == 'YoutubeLive') {
      for (int i = 0; i < _maxRetries; i++) {
        if (!_shouldContinueLoading) break;
        try {
          String updatedUrl =
              await _socketService.getUpdatedUrl(channels[index].url);
          channels[index].url = updatedUrl;
          channels[index].streamType = 'M3u8';
          break;
        } catch (e) {
          if (i == _maxRetries - 1) {
            await Future.delayed(Duration(seconds: 10)); // Retry after delay
            continue;
          }
          await Future.delayed(Duration(seconds: _retryDelay));
        }
      }
    }
  }

  Future<void> _navigateToVideoScreen(
      BuildContext context, List<Channel> channels, int index) async {
    if (_shouldContinueLoading) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PopScope(
            canPop: false,
            onPopInvoked: (didPop) {
              if (didPop) return;
              Navigator.of(context).pop();
            },
            child: VideoScreen(
              videoUrl: channels[index].url,
              bannerImageUrl: channels[index].banner,
              startAtPosition: Duration.zero,
              videoType: channels[index].streamType,
              channelList: channels,
              isLive: true,
              isVOD: false,
              isHomeCategory: true,isBannerSlider: false,
              source: 'isHomeCategory',isSearch: false,
            ),
          ),
        ),
      );

      // Handle any result returned from VideoScreen if needed
      if (result != null) {
        // Process the result
      }
    }
  }
}

class CategoryGridView extends StatefulWidget {
  final Category category;
  final List<Channel> filteredChannels;

  CategoryGridView({required this.category, required this.filteredChannels});

  @override
  _CategoryGridViewState createState() => _CategoryGridViewState();
}

class _CategoryGridViewState extends State<CategoryGridView> {
  final SocketService _socketService = SocketService();
  final int _maxRetries = 3;
  final int _retryDelay = 5; // seconds
  bool _shouldContinueLoading = true;
  bool _isLoading = false; // State to manage loading indicator

  Future<void> _updateChannelUrlIfNeeded(
      List<Channel> channels, int index) async {
    if (channels[index].streamType == 'YoutubeLive') {
      for (int i = 0; i < _maxRetries; i++) {
        if (!_shouldContinueLoading) break;
        try {
          String updatedUrl =
              await _socketService.getUpdatedUrl(channels[index].url);
          channels[index].url = updatedUrl;
          channels[index].streamType = 'M3u8';
          break;
        } catch (e) {
          if (i == _maxRetries - 1) {
            await Future.delayed(Duration(seconds: 10)); // Retry after delay
            continue;
          }
          // if (i == _maxRetries - 1) rethrow;
          await Future.delayed(Duration(seconds: _retryDelay));
        }
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (_isLoading) {
      setState(() {
        _isLoading = false; // Hide the loading indicator
        _shouldContinueLoading = false; // Stop ongoing loading
      });
      return false; // Prevent back navigation when loading
    }
    return true; // Allow navigation if not loading
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop, // Handle back button press
      child: Scaffold(
        backgroundColor: cardColor,
        body: Stack(
          children: [
            GridView.builder(
              padding: EdgeInsets.all(20),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
              ),
              itemCount: widget.filteredChannels.length,
              itemBuilder: (context, index) {
                return FocusableItemWidget(
                  imageUrl: widget
                      .filteredChannels[index].banner, // Extract banner URL
                  name: widget.filteredChannels[index].name, // Extract name
                  onTap: () async {
                    setState(() {
                      _isLoading = true; // Show loading indicator
                    });
                    _shouldContinueLoading = true;

                    await _updateChannelUrlIfNeeded(
                        widget.filteredChannels, index); // Handle URL update
                    if (_shouldContinueLoading) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VideoScreen(
                            videoUrl: widget.filteredChannels[index]
                                .url, // Pass the video URL
                            bannerImageUrl: '', // Banner image URL (optional)
                            startAtPosition:
                                Duration.zero, // Start video at the beginning
                            videoType:
                                widget.filteredChannels[index].streamType,
                            channelList: widget.filteredChannels,
                            isLive: true, isVOD: false,isBannerSlider: false,
                            source: 'isHomeCategory',isSearch: false,
                          ),
                        ),
                      ).then((_) {
                        setState(() {
                          _isLoading =
                              false; // Hide loading indicator after navigation
                        });
                      });
                    }
                  },
                  fetchPaletteColor: (String imageUrl) {
                    return PaletteColorService()
                        .getSecondaryColor(imageUrl); // Fetch the palette color
                  },
                );
              },
            ),
            if (_isLoading)
              Center(
                child: LoadingIndicator() // Circular loading indicator
              ),
          ],
        ),
      ),
    );
  }
}

class ViewAllWidget extends StatefulWidget {
  final VoidCallback onTap;
  final String categoryText;

  ViewAllWidget({required this.onTap, required this.categoryText});

  @override
  _ViewAllWidgetState createState() => _ViewAllWidgetState();
}

class _ViewAllWidgetState extends State<ViewAllWidget> {
  bool isFocused = false;
  Color focusColor = highlightColor;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onFocusChange: (hasFocus) {
        setState(() {
          isFocused = hasFocus;
        });
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (ActivateIntent intent) {
            widget.onTap();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              width: screenwdt * 0.19,
              height: isFocused ? screenhgt * 0.24 : screenhgt * 0.21,
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                border: isFocused
                    ? Border.all(
                        color: focusColor,
                        width: 4.0,
                      )
                    : Border.all(
                        color: Colors.transparent,
                        width: 4.0,
                      ),
                color: Colors.grey[800],
                boxShadow: isFocused
                    ? [
                        BoxShadow(
                          color: focusColor,
                          blurRadius: 25,
                          spreadRadius: 10,
                        )
                      ]
                    : [],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'View All',
                      style: TextStyle(
                        color: isFocused ? focusColor : hintColor,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      widget.categoryText,
                      style: TextStyle(
                        color: isFocused ? focusColor : hintColor,
                        fontWeight: FontWeight.bold,
                        fontSize: nametextsz,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'Channels',
                      style: TextStyle(
                        color: isFocused ? focusColor : hintColor,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10),
            Container(
              width: screenwdt * 0.17,
              // height: screenhgt * 0.15,
              child: Column(
                children: [
                  Text(
                    (widget.categoryText),
                    style: TextStyle(
                      color: isFocused ? focusColor : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                  ),
                  // Text(
                  //   '''See all ${(widget.categoryText).toLowerCase()} channels''',
                  //   style: TextStyle(
                  //     color: isFocused ? focusColor : Colors.grey,
                  //     fontWeight: FontWeight.bold,
                  //   ),
                  //   overflow: TextOverflow.ellipsis,
                  //   maxLines: 3,
                  //   textAlign: TextAlign.center,
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
