import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as https;
import 'package:keep_screen_on/keep_screen_on.dart';
import 'package:mobi_tv_entertainment/main.dart';
import 'package:video_player/video_player.dart';
// import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../services/socket_service.dart';
// import '../video_widget/vlc_player_screen.dart';

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
    throw Exception('Something Went Wrong');
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

    if (settings['tvenableAll'] == 0) {
      // Filter categories based on the settings
      for (var category in categories) {
        category.channels.retainWhere(
            (channel) => settings['channels'].contains(int.parse(channel.id)));
      }
    }

    return categories;
  } else {
    throw Exception('Something Went Wrong');
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
  void dispose() {
    super.dispose();
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
              child: Center(
                  child: SpinKitFadingCircle(
                color: borderColor,
                size: 50.0,
              )));
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

class CategoryWidget extends StatefulWidget {
  final Category category;

  CategoryWidget({required this.category});

  @override
  State<CategoryWidget> createState() => _CategoryWidgetState();
}

class _CategoryWidgetState extends State<CategoryWidget> {
  bool _isNavigating = false;
  final SocketService _socketService = SocketService();
  int _maxRetries = 3;
  int _retryDelay = 5; // seconds

  @override
  void initState() {
    super.initState();
    _socketService.initSocket();
    fetchSettings();
  }

  @override
  void dispose() {
    _socketService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Channel> filteredChannels = widget.category.channels
        .where((channel) => channel.url.isNotEmpty)
        .toList();

    return filteredChannels.isNotEmpty
        ? Container(
            color: cardColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Text(
                    widget.category.text.toUpperCase(),
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
                          // Set a timeout to reset _isNavigating after 10 seconds
                          Timer(Duration(seconds: 10), () {
                            _isNavigating = false;
                          });

                          bool shouldPop = true;
                          bool shouldPlayVideo = true;

                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (BuildContext context) {
                              return WillPopScope(
                                onWillPop: () async {
                                  shouldPlayVideo = false;
                                  shouldPop = false;
                                  return true;
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

                          try {
                            if (filteredChannels[index].streamType ==
                                'YoutubeLive') {
                              for (int i = 0; i < _maxRetries; i++) {
                                try {
                                  String updatedUrl =
                                      await _socketService.getUpdatedUrl(
                                          filteredChannels[index].url);
                                  filteredChannels[index].url = updatedUrl;
                                  filteredChannels[index].streamType = 'M3u8';
                                  break;
                                } catch (e) {
                                  if (i == _maxRetries - 1) rethrow;
                                  await Future.delayed(
                                      Duration(seconds: _retryDelay));
                                }
                              }
                            }
                            if (shouldPop) {
                              Navigator.of(context)
                                  .pop(); // Dismiss the loading indicator
                            }
                            if (shouldPlayVideo) {
                              // if (filteredChannels[index].streamType == 'VLC') {
                              //   Navigator.push(
                              //     context,
                              //     MaterialPageRoute(
                              //       builder: (context) => VlcPlayerScreen(
                              //         channels: filteredChannels,
                              //         initialIndex: index,
                              //         onFabFocusChanged: (bool) {},
                              //         genres: '',
                              //         videoUrl: '',
                              //         videoTitle: '',
                              //         channelList: [],
                              //       ),
                              //     ),
                              //   ).then((_) {
                              //     _isNavigating = false;
                              //     Navigator.of(context, rootNavigator: true)
                              //         .pop();
                              //   });
                              // } else {

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => WillPopScope(
                                    onWillPop: () async {
                                      // Stop the video when navigating back
                                      final videoScreenState =
                                          context.findAncestorStateOfType<
                                              _VideoScreenState>();
                                      if (videoScreenState != null) {
                                        videoScreenState._controller.pause();
                                        videoScreenState._controller.dispose();
                                      }
                                      return true;
                                    },
                                    child: VideoScreen(
                                      channels: filteredChannels,
                                      initialIndex: index,
                                    ),
                                  ),
                                ),
                              ).then((_) {
                                _isNavigating = false;
                              });
                            }
                            // }
                          } catch (e) {
                            if (shouldPop) {
                              Navigator.of(context)
                                  .pop(); // Dismiss the loading indicator
                            }
                            _isNavigating = false;
                            Navigator.of(context, rootNavigator: true).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Something Went Wrong')),
                            );
                          } finally {
                            _isNavigating = false;
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
                    color: isFocused ? borderColor : Colors.grey,
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
  // final String videoUrl;
  // final String videoTitle;

  VideoScreen({
    required this.channels,
    required this.initialIndex,
    // required this.videoUrl,
    // required this.videoTitle,
  });

  @override
  _VideoScreenState createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> with WidgetsBindingObserver {
  late VideoPlayerController _controller;
  bool _isError = false;
  bool showControls = true;
  Timer? _controlsTimer;
  final FocusNode _focusNode = FocusNode();
  bool _isConnected = true;
  Timer? _connectivityCheckTimer;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    KeepScreenOn.turnOn();
    WidgetsBinding.instance.addObserver(this);
    // _initializeVideoPlayer(widget.videoUrl);
    _initializeVideoPlayer(widget.channels[widget.initialIndex].url);
    RawKeyboard.instance.addListener(_handleKeyEvent);
    _focusNode.requestFocus();
    _resetControlsTimer();
    _startConnectivityCheck();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    KeepScreenOn.turnOff();
    RawKeyboard.instance.removeListener(_handleKeyEvent);
    _connectivityCheckTimer?.cancel();
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

    @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isVideoInitialized && !_controller.value.isPlaying) {
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
        setState(() {
          _isVideoInitialized = true;
        });
        _controller.play();
      }).catchError((error) {
        setState(() {
          _isError = true;
        });
      });
  }

  void _startConnectivityCheck() {
    _connectivityCheckTimer =
        Timer.periodic(Duration(seconds: 5), (timer) async {
      try {
        final result = await InternetAddress.lookup('google.com');
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          _updateConnectionStatus(true);
        } else {
          _updateConnectionStatus(false);
        }
      } on SocketException catch (_) {
        _updateConnectionStatus(false);
      }
    });
  }

  void _updateConnectionStatus(bool isConnected) {
    if (isConnected != _isConnected) {
      setState(() {
        _isConnected = isConnected;
      });
      if (!isConnected) {
        _controller.pause();
      } else if (_controller.value.isBuffering ||
          !_controller.value.isPlaying) {
        _controller.play();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _controller.pause();
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: _showControls,
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
                          child: Text('Go Back',
                              style:
                                  TextStyle(fontSize: 25, color: Colors.red)),
                        )
                      ],
                    )
                  : _controller.value.isInitialized
                      ? Stack(
                          children: [
                            AspectRatio(
                              aspectRatio: 16 / 9,
                              child: FittedBox(
                                fit: BoxFit.cover,
                                child: SizedBox(
                                  width: screenwdt,
                                  height: screenhgt,
                                  child: VideoPlayer(_controller),
                                ),
                              ),
                            ),
                            // Positioned.fill(
                            //   child: AspectRatio(
                            //     aspectRatio: 16 / 9,
                            //     child: VideoPlayer(_controller),
                            //   ),
                            // ),
                            if (showControls)
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
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
                                                if (_controller
                                                    .value.isPlaying) {
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
                                                  backgroundColor:
                                                      Colors.yellow),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 20),
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
                                                SizedBox(width: 5),
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
                                        SizedBox(width: 20),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        )
                      : SpinKitFadingCircle(
                          color: borderColor,
                          size: 50.0,
                        )),
        ),
      ),
    );
  }
}
