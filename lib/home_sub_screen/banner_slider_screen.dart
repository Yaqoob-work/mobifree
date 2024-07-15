import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';

class BannerSliderPage extends StatefulWidget {
  @override
  _BannerSliderPageState createState() => _BannerSliderPageState();
}

class _BannerSliderPageState extends State<BannerSliderPage> {
  List<String> _imageUrls = [];
  List<String> _videoUrls = [];
  List<String> _titles = [];
  int _currentIndex = 0;
  PageController _pageController = PageController();
  VideoPlayerController? _controller;
  FocusNode _bigBannerFocusNode = FocusNode();
  List<FocusNode> _smallBannerFocusNodes = [];
  FocusNode _fabFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _fetchSliderData();
  }

  void _fetchSliderData() async {
    String apiUrl = 'https://mobifreetv.com/android/getCustomImageSlider';

    try {
      var response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'x-api-key': 'vLQTuPZUxktl5mVW', // Replace with your actual API key
        },
      );

      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);
        List<String> imageUrls = [];
        List<String> videoUrls = [];
        List<String> titles = [];

        for (var item in jsonData) {
          imageUrls.add(item['banner']);
          videoUrls.add(item['url']);
          titles.add(item['title']); // Assuming 'title' is the key for the title field
        }

        setState(() {
          _imageUrls = imageUrls;
          _videoUrls = videoUrls;
          _titles = titles;
          _smallBannerFocusNodes = List.generate(_imageUrls.length, (_) => FocusNode());
        });

        _startAutoSliding();
      } else {
        print('Failed to load slider data: ${response.statusCode}');
        // Print response body for more details if needed
        print(response.body);
      }
    } catch (e) {
      print('Error loading slider data: $e');
    }
  }

  void _startAutoSliding() {
    Timer.periodic(Duration(seconds: 5), (timer) {
      if (_currentIndex < _imageUrls.length - 1) {
        _currentIndex++;
      } else {
        _currentIndex = 0;
      }
      _pageController.animateToPage(
        _currentIndex,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _controller?.dispose();
    _bigBannerFocusNode.dispose();
    _smallBannerFocusNodes.forEach((node) => node.dispose());
    _fabFocusNode.dispose();
    super.dispose();
  }

  void _scrollToIndex(int index) {
    _pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );

    // Center the selected banner in the small banner list
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = screenWidth * 0.3;
    final scrollOffset = index * itemWidth;
    final maxScrollExtent = _pageController.position.maxScrollExtent;

    if (scrollOffset > maxScrollExtent) {
      _pageController.jumpTo(maxScrollExtent);
    } else {
      _pageController.jumpTo(scrollOffset);
    }
  }

  Widget _buildSmallBannerList() {
    return Positioned(
      bottom: MediaQuery.of(context).size.height * 0.19,
      left: MediaQuery.of(context).size.width * 0.054,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.08,
        width: MediaQuery.of(context).size.width * 0.29,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _imageUrls.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.0),
              child: Focus(
                focusNode: _smallBannerFocusNodes[index],
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentIndex = index;
                    });
                    _scrollToIndex(index);
                    FocusScope.of(context).requestFocus(_bigBannerFocusNode);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _currentIndex == index ? const Color.fromARGB(255, 136, 51, 122) : Colors.transparent,
                        width: 3.0,
                      ),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: _imageUrls[index],
                      fit: BoxFit.cover,
                      width: 80,
                      height: 20,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _playVideo(String videoUrl) {
    _controller?.dispose();
    _controller = VideoPlayerController.network(videoUrl)
      ..initialize().then((_) {
        setState(() {});
        _controller?.play();
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _imageUrls.isEmpty
          ? Center(child: CircularProgressIndicator())
          : Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Positioned.fill(
                  child: Focus(
                    focusNode: _bigBannerFocusNode,
                    onKey: (FocusNode node, RawKeyEvent event) {
                      if (event is RawKeyDownEvent &&
                          (event.logicalKey == LogicalKeyboardKey.select ||
                              event.logicalKey == LogicalKeyboardKey.enter)) {
                        _playVideo(_videoUrls[_currentIndex]);
                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    },
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _imageUrls.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        return Stack(
                          fit: StackFit.expand,
                          children: <Widget>[
                            Container(
                              
                              child: CachedNetworkImage(
                                imageUrl: _imageUrls[index],
                                fit: BoxFit.cover,
                              ),
                            ),
                            if (_videoUrls.isNotEmpty &&
                                _controller != null &&
                                _controller!.value.isInitialized)
                              AspectRatio(
                                aspectRatio: 16 / 9,
                                child: VideoPlayer(_controller!),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                _buildSmallBannerList(),
                Positioned(
                  left: 16.0,
                  bottom: 0,
                  top: 0,
                  child: Container(
                    height: MediaQuery.of(context).size.height,
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _titles.isNotEmpty ? _titles[_currentIndex] : 'Banner Title',
                          style: TextStyle(
                            fontSize: 35.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: MediaQuery.of(context).size.width * 0.01,
                  bottom: MediaQuery.of(context).size.height * 0.18,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back_ios),
                    onPressed: () {
                      if (_currentIndex > 0) {
                        _pageController.previousPage(
                          duration: Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                  ),
                ),
                Positioned(
                  left: MediaQuery.of(context).size.width * 0.34,
                  bottom: MediaQuery.of(context).size.height * 0.18,
                  child: IconButton(
                    icon: Icon(Icons.arrow_forward_ios),
                    onPressed: () {
                      if (_currentIndex < _imageUrls.length - 1) {
                        _pageController.nextPage(
                          duration: Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                  ),
                ),
                Positioned(
                  left: 50.0,
                  // right: 50.0,
                  bottom: MediaQuery.of(context).size.height * 0.01,
                  child: IntrinsicWidth(
                    child: Focus(
                      focusNode: _fabFocusNode,
                      onFocusChange: (hasFocus) {
                        setState(() {});
                      },
                      child: FloatingActionButton.extended(
                        backgroundColor: _fabFocusNode.hasFocus ? Color.fromARGB(188, 136, 51, 122) : Colors.white,
                        onPressed: () {
                          _playVideo(_videoUrls[_currentIndex]);
                        },
                        label: Text(
                          _titles.isNotEmpty ? _titles[_currentIndex] : 'Banner Title',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: BannerSliderPage(),
  ));
}



