import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as https;
import 'package:mobi_tv_entertainment/video_widget/vlc_player_screen.dart';
import '../main.dart';
import '../video_widget/socket_service.dart';
import '../video_widget/video_screen.dart';
import '../widgets/utils/color_service.dart';


Map<String, dynamic> settings = {};

// Function to fetch settings with caching
Future<void> fetchSettings() async {
  // final prefs = await SharedPreferences.getInstance();
  // final cachedSettings = prefs.getString('settings');

  // if (cachedSettings != null) {
  //   settings = json.decode(cachedSettings);
  // } else {
    try {
      final response = await https.get(
        Uri.parse('https://api.ekomflix.com/android/getSettings'),
        headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
      );

      if (response.statusCode == 200) {
        settings = json.decode(response.body);
        // prefs.setString('settings', response.body); // Cache settings
      } else {
        throw Exception('Failed to load settings');
      }
    } catch (e) {
      print('Error fetching settings');
    }
  }
// }

void main() {
  runApp(MaterialApp(home: SearchScreen()));
}

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<dynamic> searchResults = [];
  bool isLoading = false;
  TextEditingController _searchController = TextEditingController();
  int selectedIndex = -1;
  final FocusNode _searchFieldFocusNode = FocusNode();
  final FocusNode _searchIconFocusNode = FocusNode();
  Timer? _debounce;
  final List<FocusNode> _itemFocusNodes = [];
  bool _isNavigating = false;
  bool _showSearchField = false;
  Color paletteColor = Colors.grey; // Default color, updated dynamically
  final PaletteColorService _paletteColorService = PaletteColorService();
  final SocketService _socketService = SocketService();
  final int _maxRetries = 3;
  final int _retryDelay = 5; // seconds
  bool _shouldContinueLoading = true;

  @override
  void initState() {
    super.initState();
    _searchFieldFocusNode.addListener(_onSearchFieldFocusChanged);
    _searchIconFocusNode.addListener(_onSearchIconFocusChanged);
    _socketService.initSocket();
    checkServerStatus();
  }

  @override
  void dispose() {
    _searchFieldFocusNode.removeListener(_onSearchFieldFocusChanged);
    _searchIconFocusNode.removeListener(_onSearchIconFocusChanged);
    _searchFieldFocusNode.dispose();
    _searchIconFocusNode.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    _itemFocusNodes.forEach((node) => node.dispose());
    _socketService.dispose();
    super.dispose();
  }

  // Server status check method
  void checkServerStatus() {
    Timer.periodic(Duration(seconds: 10), (timer) {
      // Check if the socket is connected, otherwise attempt to reconnect
      if (!_socketService.socket.connected) {
        print('YouTube server down, retrying...');
        _socketService.initSocket(); // Re-establish the socket connection
      }
    });
  }

  void _onSearchFieldFocusChanged() {
    setState(() {});
  }

  void _onSearchIconFocusChanged() {
    setState(() {});
  }


  // Fetch search results with caching
  Future<List<dynamic>> _fetchFromApi1(String searchTerm) async {
    // final prefs = await SharedPreferences.getInstance();
    // final cachedSearch = prefs.getString('search_$searchTerm');

    // if (cachedSearch != null) {
    //   // Return cached results
    //   return json.decode(cachedSearch);
    // } else {
      try {
        final response = await https.get(
          Uri.parse(
              'https://acomtv.com/android/searchContent/${Uri.encodeComponent(searchTerm)}/0'),
          headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
        );

        if (response.statusCode == 200) {
          final List<dynamic> responseData = json.decode(response.body);

          if (settings['tvenableAll'] == 0) {
            final enabledChannels =
                settings['channels']?.map((id) => id.toString()).toSet() ?? {};

            final filteredResults = responseData
                .where((channel) =>
                    channel['name'] != null &&
                    channel['name']
                        .toString()
                        .toLowerCase()
                        .contains(searchTerm.toLowerCase()) &&
                    enabledChannels.contains(channel['id'].toString()))
                .toList();

            // prefs.setString('search_$searchTerm', json.encode(filteredResults));
            return filteredResults;
          } else {
            final filteredResults = responseData
                .where((channel) =>
                    channel['name'] != null &&
                    channel['name']
                        .toString()
                        .toLowerCase()
                        .contains(searchTerm.toLowerCase()))
                .toList();

            // prefs.setString('search_$searchTerm', json.encode(filteredResults));
            return filteredResults;
          }
        } else {
          throw Exception('Failed to load data from API 1');
        }
      } catch (e) {
        print('Error fetching from API 1');
        return [];
      }
    // }
  }

  // void _performSearch(String searchTerm) {
  //   if (_debounce?.isActive ?? false) _debounce?.cancel();

  //   if (searchTerm.trim().isEmpty) {
  //     setState(() {
  //       isLoading = false;
  //       searchResults.clear();
  //       _itemFocusNodes.clear();
  //     });
  //     return;
  //   }

  //   _debounce = Timer(const Duration(milliseconds: 300), () async {
  //     setState(() {
  //       isLoading = true;
  //       searchResults.clear();
  //       _itemFocusNodes.clear();
  //     });

  //     try {
  //       final api1Results = await _fetchFromApi1(searchTerm);

  //       setState(() {
  //         searchResults = api1Results;
  //         _itemFocusNodes.addAll(List.generate(
  //           searchResults.length,
  //           (index) => FocusNode(),
  //         ));
  //         isLoading = false;
  //       });

  //       WidgetsBinding.instance.addPostFrameCallback((_) {
  //         if (_itemFocusNodes.isNotEmpty &&
  //             _itemFocusNodes[0].context != null) {
  //           FocusScope.of(context).requestFocus(_itemFocusNodes[0]);
  //         }
  //       });
  //     } catch (e) {
  //       setState(() {
  //         isLoading = false;
  //       });
  //     }
  //   });
  // }

  void _performSearch(String searchTerm) {
  if (_debounce?.isActive ?? false) _debounce?.cancel();

  if (searchTerm.trim().isEmpty) {
    setState(() {
      isLoading = false;
      searchResults.clear();
      _itemFocusNodes.clear();
    });
    return;
  }

  _debounce = Timer(const Duration(milliseconds: 300), () async {
    setState(() {
      isLoading = true;
      searchResults.clear();
      _itemFocusNodes.clear();
    });

    try {
      final api1Results = await _fetchFromApi1(searchTerm);

      setState(() {
        searchResults = api1Results;
        _itemFocusNodes.addAll(List.generate(
          searchResults.length,
          (index) => FocusNode(),
        ));
        isLoading = false;
      });



            // Preload images before updating the UI
      await _preloadImages(searchResults);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_itemFocusNodes.isNotEmpty && _itemFocusNodes[0].context != null) {
          FocusScope.of(context).requestFocus(_itemFocusNodes[0]);
        }
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  });
}

Future<void> _preloadImages(List<dynamic> results) async {
  for (var result in results) {
    final imageUrl = result['banner'] ?? localImage;

    if (imageUrl.isNotEmpty) {
      await precacheImage(CachedNetworkImageProvider(imageUrl), context);
    }
  }
}



  Future<void> _updatePaletteColor(String imageUrl) async {
    try {
      Color color = await _paletteColorService.getSecondaryColor(imageUrl);
      setState(() {
        paletteColor = color;
      });
    } catch (e) {
      print('Error updating palette color: ');
      // Set a default color in case of an error
      setState(() {
        paletteColor = Colors.grey;
      });
    }
  }

  void _toggleSearchField() {
    setState(() {
      _showSearchField = !_showSearchField;
      if (_showSearchField) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _searchFieldFocusNode.requestFocus();
        });
      } else {
        _searchIconFocusNode.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cardColor,
      body: Column(
        children: [
          // SizedBox(height: screenhgt * 0.01),
          _buildSearchBar(),
          Expanded(
            child: isLoading
                ? Center(
                    child: SpinKitFadingCircle(
                      color: borderColor,
                      size: 50.0,
                    ),
                  )
                : searchResults.isEmpty
                    ? Center(
                        child: Text(
                          'No results found',
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    : Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: screenwdt * 0.03),
                        child: GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                            // childAspectRatio: 0.7,
                            // crossAxisSpacing: 10,
                            // mainAxisSpacing: 10,
                          ),
                          itemCount: searchResults.length,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () {
                                _onItemTap(context, index);
                              },
                              child: _buildGridViewItem(context, index),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      width: screenwdt * 0.93,
      padding: EdgeInsets.only(top: screenhgt * 0.02),
      height: screenhgt * 0.1,
      child: Row(
        children: [
          if (!_showSearchField) Expanded(child: Text('')),
          if (_showSearchField)
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFieldFocusNode,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(color: Colors.grey, width: 4.0),
                  ),
                  labelText: 'Search By Name',
                  labelStyle: TextStyle(color: Colors.white),
                ),
                style: TextStyle(color: Colors.white),
                textInputAction: TextInputAction.search,
                textAlignVertical: TextAlignVertical.center,
                onChanged: (value) {
                  _performSearch(value);
                },
                onSubmitted: (value) {
                  _performSearch(value);
                  _toggleSearchField();
                },
                autofocus: true,
              ),
            ),
          Focus(
            focusNode: _searchIconFocusNode,
            onKey: (node, event) {
              if (event is RawKeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.select) {
                _toggleSearchField();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: IconButton(
              icon: Icon(
                Icons.search,
                color:
                    _searchIconFocusNode.hasFocus ? borderColor : Colors.white,
                size: _searchIconFocusNode.hasFocus ? 35 : 30,
              ),
              onPressed: _toggleSearchField,
              focusColor: Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridViewItem(BuildContext context, int index) {
    final result = searchResults[index];
    final status = result['status'] ?? '';

    return Focus(
      focusNode: _itemFocusNodes[index],
      onKeyEvent: (FocusNode node, KeyEvent event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.select) {
          _onItemTap(context, index);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      onFocusChange: (hasFocus) {
        _updatePaletteColor(result['banner'] ?? '');

        setState(() {
          selectedIndex = hasFocus ? index : -1;
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            width: screenwdt * 0.19,
            height: screenhgt * 0.2,
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              border: selectedIndex == index
                  ? Border.all(
                      color: paletteColor,
                      width: 3.0,
                    )
                  : Border.all(
                      color: Colors.transparent,
                      width: 3.0,
                    ),
              // borderRadius: BorderRadius.circular(10),
              boxShadow: selectedIndex == index
                  ? [
                      BoxShadow(
                        color: paletteColor,
                        blurRadius: 25,
                        spreadRadius: 10,
                      )
                    ]
                  : [],
            ),
            child: status == '1'
                ? ClipRRect(
                    // borderRadius: BorderRadius.circular(5),
                    child: CachedNetworkImage(
                      imageUrl: result['banner'] ?? localImage,
                      placeholder: (context, url) => localImage,
                      width: screenwdt * 0.19,
                      height: screenhgt * 0.2,
                      fit: BoxFit.cover,
                    ),
                  )
                : null,
          ),
          Container(
            width: MediaQuery.of(context).size.width * 0.15,
            child: Text(
              (result['name'] ?? '').toString().toUpperCase(),
              style: TextStyle(
                fontSize: 15,
                color: selectedIndex == index ? paletteColor : Colors.white,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _onItemTap(BuildContext context, int index) async {
    if (_isNavigating) return;
    _isNavigating = true;
    _showLoadingIndicator(context);

    try {
      await _updateChannelUrlIfNeeded(searchResults, index);
      if (_shouldContinueLoading) {
        await _navigateToVideoScreen(context, searchResults, index);
      }
    } catch (e) {
      print("Error playing video: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Something Went Wrong')),
      );
    } finally {
      // Always reset these states regardless of success or failure
      _isNavigating = false;
      _shouldContinueLoading = true;
      _dismissLoadingIndicator();
    }
  }

  Future<void> _updateChannelUrlIfNeeded(
      List<dynamic> channels, int index) async {
    if (channels[index]['stream_type'] == 'YoutubeLive' ||
        channels[index]['stream_type'] == 'Youtube') {
      for (int i = 0; i < _maxRetries; i++) {
        if (!_shouldContinueLoading) break;
        try {
          String updatedUrl =
              await _socketService.getUpdatedUrl(channels[index]['url']);
          channels[index]['url'] = updatedUrl;
          channels[index]['stream_type'] = 'M3u8';
          break;
        } catch (e) {
          if (i == _maxRetries - 1) rethrow;
          await Future.delayed(Duration(seconds: _retryDelay));
        }
      }
    }
  }

  Future<void> _navigateToVideoScreen(
      BuildContext context, List<dynamic> channels, int index) async {
    if (_shouldContinueLoading) {
      if (channels[index]['stream_type'] == 'VLC' ||
          channels[index]['stream_type'] == 'VLC') {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PopScope(
              canPop: false,
              onPopInvoked: (didPop) {
                if (didPop) return;
                Navigator.of(context).pop();
              },
              child: VlcPlayerScreen(
                videoUrl: channels[index]['url'] ?? '',
                // videoTitle: channels[index]['name'] ?? '',
                channelList: channels,
                genres: channels[index]['genres'] ?? '',
                // channels: channels,
                // initialIndex: index,
                bannerImageUrl: '',
                startAtPosition: Duration.zero, 
                // onFabFocusChanged: (bool) {  }, 
                isLive: false,
              ),
            ),
          ),
        );
      } else {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PopScope(
              canPop: false,
              onPopInvoked: (didPop) {
                if (didPop) return;
                Navigator.of(context).pop();
              },
              child: VideoScreen(
                videoUrl: channels[index]['url'] ?? '',
                // videoTitle: channels[index]['name'] ?? '',
                // channelList: channels,
                // genres: channels[index]['genres'] ?? '',
                // channels: channels,
                // initialIndex: index,
                bannerImageUrl: '',
                startAtPosition: Duration.zero,
              ),
            ),
          ),
        );
      }
    }
  }

  void _showLoadingIndicator(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async {
            _shouldContinueLoading = false;
            _dismissLoadingIndicator(); // Adjust the method if needed
            return Future.value(
                false); // Prevent dialog from closing automatically
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
      // Reset the state before popping the navigator
      _isNavigating = false;
      // _shouldContinueLoading = true;

      Navigator.of(context).pop();
    }
  }
}
