import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as https;
import 'package:keep_screen_on/keep_screen_on.dart';
import 'package:mobi_tv_entertainment/main.dart';
import 'package:video_player/video_player.dart';

// Add a global variable for settings
Map<String, dynamic> settings = {};

// Function to fetch settings
Future<void> fetchSettings() async {
  final response = await https.get(
    Uri.parse('https://api.ekomflix.com/android/getSettings'),
    headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
  );

  if (response.statusCode == 200) {
    settings = json.decode(response.body);
  } else {
    throw Exception('Failed to load settings');
  }
}

// Function to fetch categories with settings applied
Future<List<Category>> fetchCategories() async {
  // Fetch settings before fetching categories
  await fetchSettings();

  final response = await https.get(
    Uri.parse('https://api.ekomflix.com/android/getSelectHomeCategory'),
    headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
  );

  if (response.statusCode == 200) {
    List jsonResponse = json.decode(response.body);
    List<Category> categories = jsonResponse
        .map((category) => Category.fromJson(category))
        .toList();

    if (settings['enableAll'] == 0) {
      // Filter categories based on the settings
      for (var category in categories) {
        category.channels.retainWhere(
            (channel) => settings['channels'].contains(int.parse(channel.id)));
      }
    }

    return categories;
  } else {
    throw Exception('Failed to load categories');
  }
}

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

// Your existing Category, Channel, and CategoryWidget classes go here

class Category {
  final String id;
  final String text;
  List<Channel> channels; // Changed to List for mutability

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

// Channel class remains the same


class CategoryWidget extends StatelessWidget {
  bool _isNavigating = false;
  final Category category;

  CategoryWidget({required this.category});
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
                          if (_isNavigating)
                            return; // Check if navigation is already in progress
                          _isNavigating = true; // Set the flag to true
                          _showLoadingIndicator(context);

                          try {
                            if (filteredChannels[index].streamType ==
                                'YoutubeLive') {
                              final response = await https.get(
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
                            Navigator.of(context, rootNavigator: true).pop();

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
                            ).then((_) {
                              // Reset the flag after the navigation is completed
                              _isNavigating = false;
                            });
                          } catch (e) {
                            // Reset navigation flag
                            _isNavigating = false;

                            // Hide the loading indicator in case of an error
                            Navigator.of(context, rootNavigator: true).pop();
                            // Show error message
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Link Error')),
                            );
                          }
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
            Stack(
              children: [
                Container(
                  // padding: EdgeInsets.all(10),
                  margin: EdgeInsets.all(10),
                  child: AnimatedContainer(
                    // padding: EdgeInsets.all(10),
                    width: isFocused ? screenwdt * 0.25 : screenwdt * 0.2,
                    height: isFocused ? screenhgt * 0.22 : screenhgt * 0.18,
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
                        child: CachedNetworkImage(
                          imageUrl: widget.channel.banner,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => localImage,
                          width: isFocused ? screenwdt * 0.25 : screenwdt * 0.2,
                          height: isFocused ? screenhgt * 0.22 : screenhgt * 0.18,
                        ),
                      ),
                    ),
                    // ),
                  ),
                ),
                Positioned(
              left: screenwdt *0.03,
              top: screenhgt * 0.02,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('LIVE',style: TextStyle(color: Colors.red,fontWeight: FontWeight.bold,fontSize: 18),),
                  // SizedBox(width: 2,),
                  // Icon(Icons.live_tv_rounded ,color: Colors.red,)
                ],
              ))
              ],
            ),

            Container(
                width:  screenwdt * 0.2,
            

              child: Text(
                widget.channel.name,
                style: TextStyle(
                  color: isFocused ?highlightColor : hintColor,
                  // fontSize: 20,
                  fontWeight: FontWeight.bold,
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
}

// class Category {
//   final String id;
//   final String text;
//   final List<Channel> channels;

//   Category({
//     required this.id,
//     required this.text,
//     required this.channels,
//   });

//   factory Category.fromJson(Map<String, dynamic> json) {
//     var list = json['channels'] as List;
//     List<Channel> channelsList = list.map((i) => Channel.fromJson(i)).toList();

//     return Category(
//       id: json['id'],
//       text: json['text'],
//       channels: channelsList,
//     );
//   }
// }

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
      Type: json['Type'] ?? '', // Add this line to handle stream_type
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
  bool _isFabFocused = false; // Updated variable name
  Timer? _inactivityTimer;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    KeepScreenOn.turnOn();

    currentIndex = widget.initialIndex;
    _initializeVideoPlayer(widget.channels[currentIndex].url);

    RawKeyboard.instance.addListener(_handleKeyEvent);
    _fabFocusNode.addListener(_onFabFocusChange);
  }

  @override
  void dispose() {
    _controller.dispose();
    _fabFocusNode.dispose();
    KeepScreenOn.turnOff();
    RawKeyboard.instance.removeListener(_handleKeyEvent);
    _inactivityTimer?.cancel();
    super.dispose();
  }

  void _onFabFocusChange() {
    setState(() {
      _isFabFocused = _fabFocusNode.hasFocus;
    });
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.select) {
      if (_isFabFocused) {
        setState(() {
          showChannels = !showChannels;
        });
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _isError
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('Something Went Wrong', style: TextStyle(fontSize: 20)),
                  ElevatedButton(
                      onPressed: () {
                        Navigator.of(context, rootNavigator: true).pop();
                      },
                      child: Text(
                        'Go Back',
                        style: TextStyle(fontSize: 25, color: borderColor),
                      ))
                ],
              )
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
                                      if (_isNavigating)
                                        return; // Check if navigation is already in progress
                                      _isNavigating =
                                          true; // Set the flag to true
                                      _showLoadingIndicator(context);

                                      try {
                                        if (channel.streamType ==
                                                'YoutubeLive' ||
                                            channel.Type == 'Youtube') {
                                          final response = await https.get(
                                            Uri.parse(
                                                'https://test.gigabitcdn.net/yt-dlp.php?v=' +
                                                    channel.url),
                                            headers: {
                                              'x-api-key': 'vLQTuPZUxktl5mVW'
                                            },
                                          );

                                          if (response.statusCode == 200 &&
                                              json.decode(
                                                      response.body)['url'] !=
                                                  '') {
                                            channel.url = json
                                                .decode(response.body)['url'];
                                            channel.streamType = "M3u8";
                                          } else {
                                            throw Exception(
                                                'Failed to load networks');
                                          }
                                        }
                                         Navigator.of(context,
                                                rootNavigator: true)
                                            .pop();

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
                                      } catch (e) {
                                        // Reset navigation flag
                                        _isNavigating = false;

                                        // Hide the loading indicator in case of an error
                                        Navigator.of(context,
                                                rootNavigator: true)
                                            .pop();
                                        // Show error message
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(content: Text('Link Error')),
                                        );
                                      }
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
                        child: Focus(
                          focusNode: _fabFocusNode,
                          child: IconButton(
                            color: _isFabFocused ? borderColor : Colors.white,
                            // focusColor: _isFabFocused?hintColor:Colors.blue,
                            onPressed: () {
                              setState(() {
                                showChannels = !showChannels;
                              });
                            },
                            icon: Container(
                                padding: EdgeInsets.all(3),
                                color: _isFabFocused
                                    ? const Color.fromARGB(195, 0, 0, 0)
                                    : Colors.transparent,
                                child: Icon(
                                  showChannels ? Icons.close : Icons.grid_view,
                                  size: _isFabFocused ? 30 : 20,
                                )),
                          ),
                        ),
                      ),
                    ],
                  )
                : const CircularProgressIndicator(),
      ),
    );
  }
}
