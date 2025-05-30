import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as https;
import 'package:mobi_tv_entertainment/provider/focus_provider.dart';
import 'package:mobi_tv_entertainment/video_widget/video_screen.dart';
import 'package:mobi_tv_entertainment/widgets/items/news_item.dart';
import 'package:mobi_tv_entertainment/widgets/models/news_item_model.dart';
import 'package:mobi_tv_entertainment/widgets/small_widgets/empty_state.dart';
import 'package:mobi_tv_entertainment/widgets/small_widgets/error_message.dart';
import 'package:mobi_tv_entertainment/widgets/small_widgets/loading_indicator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MoviesScreen extends StatefulWidget {
  final Function(bool)? onFocusChange;

  const MoviesScreen(
      {Key? key, this.onFocusChange, required FocusNode focusNode})
      : super(key: key);

  @override
  _MoviesScreenState createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen> {
  List<NewsItemModel> _watchlistItems = [];
  Map<String, FocusNode> itemFocusNodes = {};
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isNavigating = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadCachedDataAndFetchWatchlist();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_watchlistItems.isNotEmpty) {
        final firstItemId = _watchlistItems[0].id;
        if (itemFocusNodes.containsKey(firstItemId)) {
          final focusNode = itemFocusNodes[firstItemId]!;
          // context.read<FocusProvider>().setFirstWatchlistItemFocusNode(focusNode);
          print(
              "✅ WatchlistScreen: First item focus node registered: $firstItemId");
        } else {
          print("⚠️ WatchlistScreen: First item NOT registered!");
        }
      }
    });
  }

  void _scrollToFocusedItem(String itemId) {
    if (itemFocusNodes[itemId] != null && itemFocusNodes[itemId]!.hasFocus) {
      Scrollable.ensureVisible(
        itemFocusNodes[itemId]!.context!,
        alignment: 0.05,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _loadCachedDataAndFetchWatchlist() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Load cached data first
      await _loadCachedWatchlistData();

      // Fetch new data in background
      await _fetchWatchlistInBackground();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load watchlist data';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCachedWatchlistData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedWatchlist = prefs.getString('watchlist_data');

      if (cachedWatchlist != null) {
        final List<dynamic> cachedData = json.decode(cachedWatchlist);
        setState(() {
          _watchlistItems =
              cachedData.map((item) => NewsItemModel.fromJson(item)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading cached watchlist data: $e');
    }
  }

  Future<void> _fetchWatchlistInBackground() async {
    try {
      final newWatchlistItems = await _fetchWatchlistFromApi();

      // Cache the new data
      final prefs = await SharedPreferences.getInstance();
      final watchlistJson =
          json.encode(newWatchlistItems.map((item) => item.toJson()).toList());
      prefs.setString('watchlist_data', watchlistJson);

      // Update UI with new data
      setState(() {
        _watchlistItems = newWatchlistItems;
        _isLoading = false;
      });

      // Initialize focus nodes for new items
      for (var item in _watchlistItems) {
        if (!itemFocusNodes.containsKey(item.id)) {
          itemFocusNodes[item.id] = FocusNode()
            ..addListener(() {
              if (itemFocusNodes[item.id]!.hasFocus) {
                _scrollToFocusedItem(item.id);
              }
            });
        }
      }
    } catch (e) {
      print('Error fetching watchlist data: $e');
      setState(() {
        if (_watchlistItems.isEmpty) {
          _errorMessage = 'Failed to load watchlist data';
          _isLoading = false;
        }
      });
    }
  }

  Future<List<NewsItemModel>> _fetchWatchlistFromApi() async {
    try {
      final response = await https.get(
        Uri.parse('https://mobifreetv.com/android/watchlistMovies'),
        headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 'success') {
          final List<dynamic> items = data['data'];
          return items
              .map((item) => NewsItemModel(
                    id: item['id'].toString(),
                    name: item['title'] ?? '',
                    description: item['description'] ?? '',
                    banner: item['poster'] ?? '',
                    poster: item['poster'] ?? '',
                    category: item['category'] ?? '',
                    url: item['stream_url'] ?? '',
                    streamType: item['stream_type'] ?? '',
                    type: item['type'] ?? '',
                    genres: item['genres'] ?? '',
                    status: item['status'] ?? '',
                    videoId: item['video_id'] ?? '',
                    index: '',
                  ))
              .toList();
        } else {
          throw Exception('API returned error: ${data['message']}');
        }
      } else {
        throw Exception(
            'Failed to load watchlist data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in _fetchWatchlistFromApi: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Text(
              'My Watchlist',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _watchlistItems.isEmpty) {
      return LoadingIndicator();
    } else if (_errorMessage.isNotEmpty && _watchlistItems.isEmpty) {
      return ErrorMessage(message: _errorMessage);
    } else if (_watchlistItems.isEmpty) {
      return EmptyState(message: 'Your watchlist is empty');
    } else {
      return _buildWatchlistItems();
    }
  }

  Widget _buildWatchlistItems() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      controller: _scrollController,
      itemCount: _watchlistItems.length,
      itemBuilder: (context, index) {
        return _buildWatchlistItem(_watchlistItems[index], index);
      },
    );
  }

  Widget _buildWatchlistItem(NewsItemModel item, int index) {
    // Create focus node if it doesn't exist
    itemFocusNodes.putIfAbsent(
        item.id,
        () => FocusNode()
          ..addListener(() {
            if (itemFocusNodes[item.id]!.hasFocus) {
              _scrollToFocusedItem(item.id);
            }
          }));

    return NewsItem(
      key: Key(item.id),
      hideDescription: true,
      item: item,
      focusNode: itemFocusNodes[item.id],
      onTap: () => _navigateToVideoScreen(item),
      onEnterPress: _handleEnterPress,
      onUpPress: () {
        // Handle up navigation if needed
        widget.onFocusChange?.call(false);
      },
      onDownPress: () {
        // Handle down navigation if needed
        context.read<FocusProvider>().requestSubVodFocus();
      },
    );
  }

  void _handleEnterPress(String itemId) {
    final selectedItem =
        _watchlistItems.firstWhere((item) => item.id == itemId);
    _navigateToVideoScreen(selectedItem);
  }

  Future<void> _navigateToVideoScreen(NewsItemModel item) async {
    if (_isNavigating) return;
    _isNavigating = true;

    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoScreen(
            videoUrl: item.url,
            bannerImageUrl: item.banner,
            startAtPosition: Duration.zero,
            videoType: item.streamType,
            channelList: _watchlistItems,
            isLive: false,
            isVOD: true,
            isBannerSlider: false,
            source: 'watchlist',
            isSearch: false,
            videoId: int.tryParse(item.id),
            unUpdatedUrl: item.url,
            name: item.name,
            liveStatus: true,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Something Went Wrong')),
      );
    } finally {
      _isNavigating = false;
    }
  }

  @override
  void dispose() {
    for (var node in itemFocusNodes.values) {
      node.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }
}
