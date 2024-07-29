import 'dart:async';
import 'dart:convert';
import 'package:container_gradient_border/container_gradient_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mobi_tv_entertainment/main.dart';

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
  Timer? _debounce;

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
        backgroundColor: cardColor,
        toolbarHeight: MediaQuery.of(context).size.height * 0.25,
        title: Container(
            width: MediaQuery.of(context).size.width - 20,
            height: MediaQuery.of(context).size.height * 0.2,
            
            
            child: Padding(
              padding: const EdgeInsets.all( 10),
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide:  BorderSide(
                        color: primaryColor, width: 4.0),
                  ),
                  labelText: 'Search By Channel Name',
                  labelStyle: TextStyle(color: hintColor),
                ),
                style:  TextStyle(color: hintColor),
                textInputAction: TextInputAction.search,
                textAlignVertical:
                    TextAlignVertical.center, // Vertical center alignment
                onSubmitted: (value) {
                  _performSearch(value);
                },
              ),
            ),
          // ),
        ),
      ),
      backgroundColor: cardColor,
      body: Column(
        children: [
          isLoading
              ?  Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              : searchResults.isEmpty
                  ?  Expanded(
                      child: Center(
                          child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'No results found',
                            style: TextStyle(color: hintColor),
                          ),
                        ],
                      )),
                    )
                  : Expanded(
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          // childAspectRatio: 0.9,
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
    return Focus(
      onKeyEvent: (FocusNode node, KeyEvent event) {
        if (event is KeyDownEvent &&
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
        // margin: const EdgeInsets.all(8.0),
        width: 250,
        height: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: selectedIndex == index ? 200 : 130,
                height: selectedIndex == index ? 170 : 130,
                child: ContainerGradientBorder(
                  width: selectedIndex == index ? 180 : 120,
                  height: selectedIndex == index ? 150 : 120,
                  start: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  borderWidth: 7,
                   colorList: selectedIndex == index ? [
                     primaryColor,
                        highlightColor,
                        primaryColor,
                        highlightColor,
                        primaryColor,
                        highlightColor,
                        primaryColor,
                        highlightColor,
                        primaryColor,
                        highlightColor,
                        primaryColor,
                        highlightColor,
                        primaryColor,
                        highlightColor,
                        primaryColor,
                        highlightColor,
                        
                        primaryColor,
                        highlightColor,
                        primaryColor,
                        highlightColor,
                        primaryColor,
                        highlightColor,
                        primaryColor,
                        highlightColor,
                        primaryColor,
                        highlightColor,
                        primaryColor,
                        highlightColor,
                        primaryColor,
                        highlightColor,
                        primaryColor,
                        highlightColor,
    
                  ]
                  :
                  [
                    primaryColor,
                    highlightColor
                  ],
                  borderRadius: 14,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: Image.network(
                      searchResults[index]['banner'] ?? '',
                      width: selectedIndex == index ? 160 : 100,
                      height: selectedIndex == index ? 130 : 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
                 Container(
                  width: selectedIndex == index ? 150 : 100,
                  child: Text(
                    searchResults[index]['name'] ?? 'Unknown',
                    style: TextStyle(
                      fontSize: 20,
                      color: selectedIndex == index
                          ? highlightColor
                          : hintColor,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              
            ],
          ),
        
      ),
    );
  }

  void _performSearch(String searchTerm) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () async {
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
    });
  }

  void _onItemTap(int index) {
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
