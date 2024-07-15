import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../video_widget/video_screen.dart';

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
    super.dispose();
  }

  void _onFocusChanged() {
    setState(() {
      iconSize = _focusNode.hasFocus ? 20.0 : 15.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        toolbarHeight: MediaQuery.of(context).size.width * 0.1,
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          decoration: InputDecoration(
            // prefix: IconButton(
            //   icon: Icon(Icons.search, color: Colors.white, size: iconSize),
            //   onPressed: () {
            //     _performSearch(_searchController.text);
            //   },
            // ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: const BorderSide(
                  color: Color.fromARGB(255, 136, 51, 122), width: 4.0),
            ),
            labelText: 'Search By Channel Name',
          ),
          style: const TextStyle(color: Colors.white),
          textInputAction: TextInputAction.search,
          textAlignVertical:
              TextAlignVertical.center, // Vertical center alignment
          onChanged: (value) {
            _performSearch(value);
          },
          onSubmitted: (value) {
            _performSearch(value);
          },
        ),
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          isLoading
              ? const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              : searchResults.isEmpty
                  ? const Expanded(
                      child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'No results found'
                          
                          ,
                            style: TextStyle(color: Color.fromARGB(255, 59, 54, 54)),
                          ),
                          
                        ],
                      )),
                    )
                  : Expanded(
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                        ),
                        itemCount: searchResults.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              _onItemTap(index);
                            },
                            child: _buildGridViewItem(index),
                          );
                        },
                      ),
                    ),
        ],
      ),
    );
  }

  Widget _buildGridViewItem(int index) {
    double bannerWidth = selectedIndex == index ? 110 : 90;
    double bannerHeight = selectedIndex == index ? 90 : 70;

    return Focus(
      onKey: (FocusNode node, RawKeyEvent event) {
        if (event is RawKeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.select) {
          _onItemTap(index);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      onFocusChange: (hasFocus) {
        setState(() {
          selectedIndex = hasFocus ? index : -1;
        });
      },
      child: Container(
        margin: const EdgeInsets.all(8.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: selectedIndex == index
                        ? const Color.fromARGB(255, 136, 51, 122)
                        : Colors.transparent,
                    width: 5.0,
                  ),
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: Image.network(
                    searchResults[index]['banner'] ?? '',
                    width: bannerWidth,
                    height: bannerHeight,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 8.0),
              Container(
                width: bannerWidth,
                child: Text(
                  searchResults[index]['name'] ?? 'Unknown',
                  style: TextStyle(
                    color:
                        selectedIndex == index ? Color.fromARGB(255, 106, 235, 20): Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _performSearch(String searchTerm) async {
    setState(() {
      isLoading = true;
      searchResults.clear();
    });

    try {
      final response = await http.get(
        Uri.parse('https://mobifreetv.com/android/getFeaturedLiveTV'),
        headers: {
          'x-api-key': 'vLQTuPZUxktl5mVW',
        },
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

            // Initialize isFocused to false for each channel
            searchResults.forEach((channel) {
              if (channel['isFocused'] == null) {
                channel['isFocused'] = false;
              }
            });
          }
          isLoading = false;
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
  }

  void _onItemTap(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoScreen(
          videoUrl: searchResults[index]['url'] ?? '',
          videoTitle: searchResults[index]['name'] ?? 'Unknown',
          channelList: searchResults,
          onFabFocusChanged: _handleFabFocusChanged, genres: '',
        ),
      ),
    );
  }

  void _handleFabFocusChanged(bool hasFocus) {
    // Handle FAB focus change if needed
  }
}





