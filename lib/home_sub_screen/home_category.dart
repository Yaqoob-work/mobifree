import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
// import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as https;
import 'package:keep_screen_on/keep_screen_on.dart';
import 'package:mobi_tv_entertainment/main.dart';
import 'package:video_player/video_player.dart';
import 'package:connectivity_plus/connectivity_plus.dart';


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
    List<Category> categories =
        jsonResponse.map((category) => Category.fromJson(category)).toList();

    if (settings['ekomenableAll'] == 0) {
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

          return Container(
              color: Colors.black,
              child: const Center(child: CircularProgressIndicator()));
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
  final String banner;
  final String genres;
  String url;
  String streamType;
  String type;
  String status;

  Channel({
    required this.id,
    required this.name,
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
      banner: json['banner'],
      genres: json['genres'],
      url: json['url'] ?? '',
      streamType: json['stream_type'] ?? '',
      type: json['Type'] ?? '',
      status: json['status'] ?? '',
    );
  }
}

class CategoryWidget extends StatelessWidget {
  bool _isNavigating = false;
  final Category category;

  CategoryWidget({required this.category});

  void _showLoadingIndicator(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(child: CircularProgressIndicator());
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
                  height: MediaQuery.of(context).size.height * 0.3,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: filteredChannels.length,
                    itemBuilder: (context, index) {
                      return ChannelWidget(
                        channel: filteredChannels[index],
                        onTap: () async {
                          if (_isNavigating) return;
                          _isNavigating = true;
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
                              _isNavigating = false;
                            });
                          } catch (e) {
                            _isNavigating = false;
                            Navigator.of(context, rootNavigator: true).pop();
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
    bool showBanner = widget.channel.status == '1';

    return IntrinsicHeight(
      child: GestureDetector(
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
              if (showBanner)
                Container(
                  margin: EdgeInsets.all(10),
                  child: AnimatedContainer(
                    width: screenwdt * 0.145,
                    height: screenhgt * 0.18,
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isFocused ? borderColor : hintColor,
                        width: 5.0,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: CachedNetworkImage(
                        imageUrl: widget.channel.banner,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Container(color: Colors.grey),
                        width: screenwdt * 0.145,
                        height: screenhgt * 0.18,
                      ),
                    ),
                  ),
                ),
              Container(
                width: screenwdt * 0.2,
                child: Text(
                  widget.channel.name,
                  style: TextStyle(
                    color: isFocused ? Colors.blue : Colors.grey,
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
      ),
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



class _VideoScreenState extends State<VideoScreen> with WidgetsBindingObserver {
  late VideoPlayerController _controller;
  bool _isError = false;
  bool showControls = true; // Controls visibility flag
  Timer? _controlsTimer;
  final FocusNode _focusNode = FocusNode();
  // late Connectivity _connectivity;
  // late ConnectivityResult _connectivityResult;
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    KeepScreenOn.turnOn();
    WidgetsBinding.instance.addObserver(this);
    _initializeVideoPlayer(widget.channels[widget.initialIndex].url);

    RawKeyboard.instance.addListener(_handleKeyEvent);
    _focusNode.requestFocus();
    _resetControlsTimer();

     // Listen for connectivity changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      // print("Connectivity changed: $result");
      _updateConnectionStatus(result);
    });
  }

    void _updateConnectionStatus(ConnectivityResult result) {
    bool wasConnected = _isConnected;
    _isConnected = result != ConnectivityResult.none;

    if (!wasConnected && _isConnected) {
      if (!_controller.value.isPlaying && !_controller.value.isBuffering && _controller.value.isInitialized) {
        _controller.play();
      }
    } else if (wasConnected && !_isConnected) {
      if (_controller.value.isPlaying) {
        _controller.pause();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    KeepScreenOn.turnOff();
    RawKeyboard.instance.removeListener(_handleKeyEvent);
    _connectivitySubscription.cancel();
    _controlsTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _controller.pause();
    } else if (state == AppLifecycleState.resumed) {
      _controller.play();
    }
  }

  void _resetControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 10), () {
      setState(() {
        showControls = false;
      });
    });
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.select) {
        // Toggle play/pause when the select button is pressed
        setState(() {
          if (_controller.value.isPlaying) {
            _controller.pause();
          } else {
            _controller.play();
          }
        });
        _showControls();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
          event.logicalKey == LogicalKeyboardKey.arrowDown ||
          event.logicalKey == LogicalKeyboardKey.arrowLeft ||
          event.logicalKey == LogicalKeyboardKey.arrowRight) {
        // Show controls when navigating with arrow keys
        _showControls();
      }
    }
  }

  void _showControls() {
    setState(() {
      showControls = true;
    });
    _resetControlsTimer();
  }

  void _initializeVideoPlayer(String videoUrl) {
    _controller = VideoPlayerController.network(videoUrl)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      }).catchError((error) {
        setState(() {
          _isError = true;
        });
      });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _showControls, // Show controls on tap
        child: Center(
          child: _isError
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Something Went Wrong',
                        style: TextStyle(fontSize: 20)),
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
                        if (showControls)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: screenhgt * 0.05,
                            child: Focus(
                              focusNode: _focusNode,
                              child: Container(
                                color: Colors.black.withOpacity(0.5),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: IconButton(
                                        icon: Icon(
                                          _controller.value.isPlaying
                                              ? Icons.pause
                                              : Icons.play_arrow,
                                          color: Colors.white,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            if (_controller.value.isPlaying) {
                                              _controller.pause();
                                            } else {
                                              _controller.play();
                                            }
                                          });
                                          _showControls();
                                        },
                                      ),
                                    ),
                                    Expanded(
                                      flex: 15,
                                      child: Center(
                                        child: VideoProgressIndicator(
                                          _controller,
                                          allowScrubbing: true,
                                          colors: VideoProgressColors(
                                              playedColor: borderColor,
                                              bufferedColor: Colors.green,
                                              backgroundColor: Colors.yellow),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 20,
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Center(
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.circle,
                                              color: Colors.red,
                                              size: 15,
                                            ),
                                            SizedBox(
                                              width: 5,
                                            ),
                                            Text(
                                              'Live',
                                              style: TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 20,
                                                  fontWeight:
                                                      FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    )
                  : const CircularProgressIndicator(),
        ),
      ),
    );
  }
}
