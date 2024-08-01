import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mobi_tv_entertainment/main.dart';
import '../video_widget/video_screen.dart';
// import 'video_screen.dart'; // Make sure to replace this with your actual import

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

  void _performSearch(String searchTerm) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() {
        isLoading = true;
        searchResults.clear();
        _itemFocusNodes.clear(); // Clear previous nodes
      });

      try {
        final response = await http.get(
          Uri.parse('https://mobifreetv.com/android/getFeaturedLiveTV'),
          headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
        );

        if (response.statusCode == 200) {
          final List<dynamic> responseData = json.decode(response.body);

          setState(() {
            if (searchTerm.isEmpty) {
              searchResults.clear();
            } else {
              searchResults = responseData
                  .where((channel) =>
                      channel['name'] != null &&
                      channel['name']
                          .toString()
                          .toLowerCase()
                          .contains(searchTerm.toLowerCase()))
                  .toList();
            }
            _itemFocusNodes.addAll(List.generate(
              searchResults.length,
              (index) => FocusNode(),
            ));
            isLoading = false;
          });

          // Schedule focus request after build
          Future.delayed(Duration.zero, () {
            if (_itemFocusNodes.isNotEmpty) {
              FocusScope.of(context).requestFocus(_itemFocusNodes[0]);
            }
          });

        } else {
          throw Exception('Failed to load data');
        }
      } catch (e) {
        print('Error fetching data: $e');
        setState(() {
          isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   backgroundColor: cardColor, 
      //   toolbarHeight: screenhgt * 0.25,
      //   title:te ,
        
      // ),

      
      backgroundColor:cardColor, // Replace with cardColor
      body: Column(
        children: [
          Container(
          // width: screenwdt ,
          // height: screenhgt * 0.2,
          // child: Padding(
            padding: const EdgeInsets.all(15),
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide(color: hintColor, width: 4.0), // Replace with primaryColor
                ),
                labelText: 'Search By Channel Name',
                labelStyle: TextStyle(color: Colors.white), // Replace with hintColor
              ),
              style: TextStyle(color: Colors.white), // Replace with hintColor
              textInputAction: TextInputAction.search,
              textAlignVertical: TextAlignVertical.center,
              onSubmitted: (value) {
                _performSearch(value);
              },
            ),
          // ),
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
                              style: TextStyle(color: Colors.white), // Replace with hintColor
                            ),
                          ],
                        ),
                      ),
                    )
                  : Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
        ],
      ),
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
            width: selectedIndex == index ? screenwdt * 0.35 : screenwdt * 0.27,
            height: selectedIndex == index ? screenhgt * 0.23 : screenhgt * 0.2,
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: hintColor,
              border: Border.all(
                color: hintColor,
                // selectedIndex == index ? hintColor : Colors.transparent, // Replace with primaryColor
                width: 10.0,
              ),
              borderRadius: BorderRadius.circular(5),

            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Image.network(
                searchResults[index]['banner'] ?? '',
                width: selectedIndex == index ? screenwdt * 0.35 : screenwdt * 0.27,
                height: selectedIndex == index ? screenhgt * 0.23 : screenhgt * 0.2,
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Container(
          //   width: selectedIndex == index ? 150 : 100,
          //   child: Text(
          //     searchResults[index]['name'] ?? 'Unknown',
          //     style: TextStyle(
          //       fontSize: 20,
          //       color: selectedIndex == index ? Colors.yellow : Colors.white, // Replace with highlightColor and hintColor
          //     ),
          //     textAlign: TextAlign.center,
          //     overflow: TextOverflow.ellipsis,
          //     maxLines: 1,
          //   ),
          // ),
        ],
      ),
    );
  }

  void _onItemTap(BuildContext context, int index) async {
    if (searchResults[index]['stream_type'] == 'YoutubeLive') {
      final response = await http.get(
        Uri.parse('https://test.gigabitcdn.net/yt-dlp.php?v=' +
            searchResults[index]['url']),
        headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
      );

      if (response.statusCode == 200 &&
          json.decode(response.body)['url'] != '') {
        searchResults[index]['url'] = json.decode(response.body)['url'];
        searchResults[index]['stream_type'] = "M3u8";
      } else {
        throw Exception('Failed to load networks');
      }
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoScreen(
          videoUrl: searchResults[index]['url'] ?? '',
          videoTitle: searchResults[index]['name'] ?? 'Unknown',
          channelList: searchResults,
          onFabFocusChanged: _handleFabFocusChanged,
          genres: '',
        ),
      ),
    );
  }

  void _handleFabFocusChanged(bool hasFocus) {
    // Handle FAB focus change if needed
  }
}
