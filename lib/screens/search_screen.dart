import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as https;
import 'package:mobi_tv_entertainment/main.dart';
import '../video_widget/video_screen.dart';

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
  double iconSize = 30.0;
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  final List<FocusNode> _itemFocusNodes = [];
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    _itemFocusNodes.forEach((node) => node.dispose());
    super.dispose();
  }

  void _onFocusChanged() {
    setState(() {
      iconSize = _focusNode.hasFocus ? 20.0 : 15.0;
    });
  }

  Future<List<dynamic>> _fetchFromApi1(String searchTerm) async {
    try {
      final response = await https.get(
        Uri.parse(
            'https://acomtv.com/android/searchContent/${Uri.encodeComponent(searchTerm)}/0'),
        headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        return responseData
            .where((channel) =>
                channel['name'] != null &&
                channel['name']
                    .toString()
                    .toLowerCase()
                    .contains(searchTerm.toLowerCase()))
            .toList();
      } else {
        throw Exception('Failed to load data from API 1');
      }
    } catch (e) {
      print('Error fetching from API 1: $e');
      return [];
    }
  }

  // Future<List<dynamic>> _fetchFromApi2(String searchTerm) async {
  //   try {
  //     final response = await https.get(
  //       Uri.parse('https://acomtv.com/android/getFeaturedLiveTV'),
  //       headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
  //     );

  //     if (response.statusCode == 200) {
  //       final List<dynamic> responseData = json.decode(response.body);
  //       return responseData
  //           .where((channel) =>
  //               channel['name'] != null &&
  //               channel['name']
  //                   .toString()
  //                   .toLowerCase()
  //                   .contains(searchTerm.toLowerCase()))
  //           .toList();
  //     } else {
  //       throw Exception('Failed to load data from API 2');
  //     }
  //   } catch (e) {
  //     print('Error fetching from API 2: $e');
  //     return [];
  //   }
  // }

  void _performSearch(String searchTerm) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    // Check if the search term is empty or contains only whitespace
    if (searchTerm.trim().isEmpty) {
      setState(() {
        isLoading = false;
        searchResults.clear(); // Clear the results if the search term is empty
        _itemFocusNodes.clear(); // Clear previous nodes
      });
      return; // Exit the function early
    }

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      setState(() {
        isLoading = true;
        searchResults.clear();
        _itemFocusNodes.clear(); // Clear previous nodes
      });

      try {
        final api1Results = await _fetchFromApi1(searchTerm);
        // final api2Results = await _fetchFromApi2(searchTerm);

        setState(() {
          searchResults = [
            ...api1Results,
            //  ...api2Results
          ];
          _itemFocusNodes.addAll(List.generate(
            searchResults.length,
            (index) => FocusNode(),
          ));
          isLoading = false;
        });

        // Schedule focus request after build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_itemFocusNodes.isNotEmpty &&
              _itemFocusNodes[0].context != null) {
            FocusScope.of(context).requestFocus(_itemFocusNodes[0]);
          }
        });
      } catch (e) {
        // print('Error fetching data: $e');
        setState(() {
          isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cardColor, // Replace with your cardColor
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide(
                      color: hintColor,
                      width: 4.0), // Replace with primaryColor
                ),
                labelText: 'Search By Name',
                labelStyle:
                    TextStyle(color: Colors.white), // Replace with hintColor
              ),
              style: TextStyle(color: Colors.white), // Replace with hintColor
              textInputAction: TextInputAction.search,
              textAlignVertical: TextAlignVertical.center,
              onSubmitted: (value) {
                _performSearch(value);
              },
            ),
          ),
          isLoading
              ? Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              : searchResults.isEmpty
                  ? Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'No results found',
                              style: TextStyle(
                                  color:
                                      Colors.white), // Replace with hintColor
                            ),
                          ],
                        ),
                      ),
                    )
                  : Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
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

  void _showLoadingIndicator(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible:
          false, // Prevents dismissing the dialog by tapping outside
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  Widget _buildGridViewItem(BuildContext context, int index) {
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
        setState(() {
          selectedIndex = hasFocus ? index : -1;
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            width: selectedIndex == index ? screenwdt * 0.35 : screenwdt * 0.3,
            height: selectedIndex == index ? screenhgt * 0.25 : screenhgt * 0.2,
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
                // color: Colors.white,
                border: Border.all(
                  color: selectedIndex == index ? borderColor : hintColor,
                  width: 5.0,
                ),
                borderRadius: BorderRadius.circular(10)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: CachedNetworkImage(
                imageUrl: searchResults[index]['banner'] ?? localImage,
                placeholder: (context, url) => localImage,
                width: selectedIndex == index
                    ? MediaQuery.of(context).size.width * 0.35
                    : MediaQuery.of(context).size.width * 0.28,
                height: selectedIndex == index
                    ? MediaQuery.of(context).size.height * 0.23
                    : MediaQuery.of(context).size.height * 0.2,
                fit: BoxFit.cover,
              ),
            ),
          ),
           Container(
          width: screenwdt * 0.25,
          child: Text(
            (searchResults[index]['name'] ?? '')
                .toString()
                .toUpperCase(),
            style: TextStyle(
              fontSize: 15,
              color: searchResults[index]['isFocused']
                  ? highlightColor
                  : Colors.white,
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
    if (_isNavigating) return; // Check if navigation is already in progress
    _isNavigating = true; // Set the flag to true
    _showLoadingIndicator(context);

    if (searchResults[index]['stream_type'] == 'YoutubeLive' ||
        searchResults[index]['type'] == 'Youtube') {
      try {
        final response = await https.get(
          Uri.parse('https://test.gigabitcdn.net/yt-dlp.php?v=' +
              searchResults[index]['url']),
          headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
        );

        if (response.statusCode == 200) {
          final jsonResponse = json.decode(response.body);
          if (jsonResponse['url'] != '') {
            searchResults[index]['url'] = jsonResponse['url'];
            searchResults[index]['stream_type'] = "M3u8";
          }
        } else {
          _isNavigating = false;

          Navigator.of(context, rootNavigator: true).pop();

          throw Exception('Failed to load networks');
        }
      } catch (e) {
        _isNavigating = false;

        // Hide the loading indicator in case of an error
        Navigator.of(context, rootNavigator: true).pop();
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Link Error')),
        );
      }
    }
        Navigator.of(context, rootNavigator: true).pop();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoScreen(
          videoUrl: searchResults[index]['url'] ?? '',
          videoTitle: searchResults[index]['name'] ?? '',
          channelList: searchResults,
          onFabFocusChanged: _handleFabFocusChanged,
          genres: '',
          channels: [],
          initialIndex: index,
        ),
      ),
    ).then((_) {
      // Reset the flag after the navigation is completed
      _isNavigating = false;
    });
  }

  void _handleFabFocusChanged(bool hasFocus) {
    // Handle FAB focus change if needed
  }
}
