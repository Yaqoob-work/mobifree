import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mobi_tv_entertainment/main.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(HomeCategory());
}

// double categoryheight = 0;

class HomeCategory extends StatefulWidget {
  @override
  _HomeCategoryState createState() => _HomeCategoryState();
}

class _HomeCategoryState extends State<HomeCategory> {
  late Future<List<Category>> _categories;

  @override
  void initState() {
    super.initState();
    _categories = fetchCategories();
  }

  Future<List<Category>> fetchCategories() async {
    final response = await http.get(
      Uri.parse('https://acomtv.com/android/getSelectHomeCategory'),
      headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
    );

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse
          .map((category) => Category.fromJson(category))
          .toList();
    } else {
      throw Exception('Failed to load categories');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            return Center(child: Text("${snapshot.error}"));
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

class CategoryWidget extends StatelessWidget {
  final Category category;

  CategoryWidget({required this.category});

  @override
  Widget build(BuildContext context) {
    List<Channel> filteredChannels =
        category.channels.where((channel) => channel.url.isNotEmpty).toList();

    return filteredChannels.isNotEmpty
        ? Container(
            color: cardColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Text(
                    category.text.toUpperCase(),
                    style: TextStyle(
                      color: hintColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(
                  height: screenhgt * 0.3,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: filteredChannels.length,
                    itemBuilder: (context, index) {
                      return ChannelWidget(
                        channel: filteredChannels[index],
                        onTap: () async {
                          if (filteredChannels[index].streamType ==
                              'YoutubeLive') {
                            final response = await http.get(
                              Uri.parse(
                                  'https://test.gigabitcdn.net/yt-dlp.php?v=' +
                                      filteredChannels[index].url),
                              headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
                            );

                            if (response.statusCode == 200 &&
                                json.decode(response.body)['url'] != '') {
                              filteredChannels[index].url =
                                  json.decode(response.body)['url'];
                              filteredChannels[index].streamType = "M3u8";
                            } else {
                              throw Exception('Failed to load networks');
                            }
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VideoScreen(
                                channels: filteredChannels,
                                initialIndex: index,
                                videoUrl: null,
                                videoTitle: null,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          )
        : const SizedBox.shrink();
  }
}

class ChannelWidget extends StatefulWidget {
  final Channel channel;
  final VoidCallback onTap;

  ChannelWidget({required this.channel, required this.onTap});

  @override
  _ChannelWidgetState createState() => _ChannelWidgetState();
}

class _ChannelWidgetState extends State<ChannelWidget> {
  bool isFocused = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Focus(
        onFocusChange: (hasFocus) {
          setState(() {
            isFocused = hasFocus;
          });
        },
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.select) {
            widget.onTap();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              // padding: EdgeInsets.all(10),
              margin: EdgeInsets.all(10),
              child: AnimatedContainer(
                // padding: EdgeInsets.all(10),
                width: isFocused ? screenwdt * 0.35 : screenwdt * 0.27,
                height: isFocused ? screenhgt * 0.23 : screenhgt * 0.2,
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isFocused ? borderColor : hintColor,
                    width: 5.0,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                // child: Opacity(
                //   opacity: isFocused ? 1 : 0.7,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Material(
                    elevation: 0,
                    child: Image.network(
                      widget.channel.banner,
                      fit: BoxFit.cover,
                      width: isFocused ? screenwdt * 0.35 : screenwdt * 0.27,
                      height: isFocused ? screenhgt * 0.23 : screenhgt * 0.2,
                    ),
                  ),
                ),
                // ),
              ),
            ),

            // Container(
            //     width: isFocused
            // ? screenwdt * 0.3
            // : screenwdt * 0.27,

            //   child: Text(
            //     widget.channel.name,
            //     style: TextStyle(
            //       color: isFocused ?highlightColor : hintColor,
            //       fontSize: 20,
            //       fontWeight: FontWeight.bold,
            //     ),
            //     textAlign: TextAlign.center,
            //     overflow: TextOverflow.ellipsis,
            //     maxLines: 1,
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}

class Category {
  final String id;
  final String text;
  final List<Channel> channels;

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
  final String banner;
  final String genres;
  String url;
  String streamType; // Add this line 
  String Type; // Add this line 
  Channel({
    required this.id,
    required this.name,
    required this.banner,
    required this.genres,
    required this.url,
    required this.streamType, // Add this line
    required this.Type, // Add this line
  });

  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(
      id: json['id'],
      name: json['name'],
      banner: json['banner'],
      genres: json['genres'],
      url: json['url'] ?? '', // Default empty string if 'url' is null
      streamType:
          json['stream_type'] ?? '', // Add this line to handle stream_type
      Type:    json['Type'] ?? '', // Add this line to handle stream_type
    );
  }
}

class VideoScreen extends StatefulWidget {
  final List<Channel> channels;
  final int initialIndex;

  VideoScreen({
    required this.channels,
    required this.initialIndex,
    required videoUrl,
    required videoTitle,
  });

  @override
  _VideoScreenState createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  late VideoPlayerController _controller;
  bool _isError = false;
  String _errorMessage = '';
  bool showChannels = false;
  int currentIndex = 0;
  FocusNode _fabFocusNode = FocusNode();
  bool _isFabFocusNode = false;
  Timer? _inactivityTimer;
  bool  _isNavigating = true; 

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _initializeVideoPlayer(widget.channels[currentIndex].url);

    RawKeyboard.instance.addListener(_handleKeyEvent);
    _fabFocusNode.addListener(_onfabFocusNode);

    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   FocusScope.of(context).requestFocus(_fabFocusNode);
    // });
  }

  @override
  void dispose() {
    _controller.dispose();
    _fabFocusNode.dispose();
    RawKeyboard.instance.removeListener(_handleKeyEvent);
    _inactivityTimer?.cancel();
    super.dispose();
  }

  void _onfabFocusNode() {
    setState(() {
      _isFabFocusNode = _fabFocusNode.hasFocus;
      _isFabFocusNode = true;
    });
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.select) {
      setState(() {
        showChannels = !showChannels;
      });
    }
    _resetInactivityTimer();
  }

  void _initializeVideoPlayer(String videoUrl) {
    _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      }).catchError((error) {
        setState(() {
          _isError = true;
          _errorMessage = error.toString();
        });
      });
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(seconds: 10), () {
      setState(() {
        showChannels = false;
      });
    });
  }

  void _changeChannel(int index) {
    setState(() {
      currentIndex = index;
      _initializeVideoPlayer(widget.channels[currentIndex].url);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _isError
            ? Text('Error loading video: $_errorMessage')
            : _controller.value.isInitialized
                ? Stack(
                    children: [
                      Positioned.fill(
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: VideoPlayer(_controller),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Visibility(
                          visible: showChannels,
                          child: Container(
                            height: 210,
                            color: Colors.black.withOpacity(0.5),
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: widget.channels.length,
                              itemBuilder: (context, index) {
                                final channel = widget.channels[index];
                                return GestureDetector(
                                  onTap: () => _changeChannel(index),
                                  child: ChannelWidget(
                                    channel: channel,
                                    onTap: () async {
                                    
if (_isNavigating) return;  // Check if navigation is already in progress
    _isNavigating = true;  // Set the flag to true

                                      if (channel.streamType == 'YoutubeLive' || channel.Type == 'Youtube') {
                                        final response = await http.get(
                                          Uri.parse(
                                              'https://test.gigabitcdn.net/yt-dlp.php?v=' +
                                                  channel.url),
                                          headers: {
                                            'x-api-key': 'vLQTuPZUxktl5mVW'
                                          },
                                        );

                                        if (response.statusCode == 200 &&
                                            json.decode(response.body)['url'] !=
                                                '') {
                                          channel.url =
                                              json.decode(response.body)['url'];
                                          channel.streamType = "M3u8";
                                        } else {
                                          throw Exception(
                                              'Failed to load networks');
                                        }
                                      }

                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => VideoScreen(
                                            channels: widget.channels,
                                            initialIndex: index,
                                            videoUrl: null,
                                            videoTitle: null,
                                          ),
                                        ),
                                      ).then((_) {
      // Reset the flag after the navigation is completed
      _isNavigating = false;
    });
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 16,
                        bottom: showChannels ? 220 : 16,

                        child: IconButton(
                          color: hintColor,
                          // backgroundColor: _isFabFocusNode
                          //         ? borderColor
                          //         : Colors.transparent,
                          focusColor: Colors.black54,
                          onPressed: () {
                            setState((hasFocus) {
                              showChannels = !showChannels;
                              _isFabFocusNode = hasFocus;
                            } as VoidCallback);
                          },
                          icon: Icon(
                              showChannels ? Icons.close : Icons.grid_view),
                        ),
                        // ),
                        // ),
                        // ),
                      ),
                    ],
                  )
                : const CircularProgressIndicator(),
      ),
    );
  }
}
