import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as https;
import 'package:mobi_tv_entertainment/main.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../video_widget/video_screen.dart';
import '../video_widget/vlc_player_screen.dart';

void main() {
  runApp(MusicScreen());
}

class MusicScreen extends StatefulWidget {
  @override
  _MusicScreenState createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  List<dynamic> entertainmentList = [];
  List<int> allowedChannelIds = [];
  bool isLoading = true;
  String errorMessage = '';
  bool _isNavigating = false;
  bool tvenableAll = false;
  late IO.Socket socket;

  @override
  void initState() {
    super.initState();
    connectSocket();
    fetchSettings();
  }

  void connectSocket() {
    socket = IO.io('https://65.2.6.179:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();
    socket.on('connect', (_) {
      print('Connected to socket server');
    });

    socket.on('videoUrl', (data) {
      print('Received video URL: $data');
      if (data['youtubeId'] != null && data['videoUrl'] != null) {
        setState(() {
          for (var item in entertainmentList) {
            if (item['url'] == data['youtubeId']) {
              item['url'] = data['videoUrl'];
              item['stream_type'] = 'M3u8';
              break;
            }
          }
        });
      }
    });

    socket.on('error', (error) {
      print('Socket error: $error');
    });
  }

  @override
  void dispose() {
    socket.disconnect();
    super.dispose();
  }

  Future<void> fetchSettings() async {
    try {
      final response = await https.get(
        Uri.parse('https://api.ekomflix.com/android/getSettings'),
        headers: {
          'x-api-key': 'vLQTuPZUxktl5mVW',
        },
      );

      if (response.statusCode == 200) {
        final settingsData = json.decode(response.body);
        setState(() {
          allowedChannelIds = List<int>.from(settingsData['channels']);
          tvenableAll = settingsData['tvenableAll'] == 1;
        });

        fetchEntertainment();
      } else {
        throw Exception('Failed to load settings, status code: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error in fetchSettings: $e';
        isLoading = false;
      });
    }
  }

  Future<void> fetchEntertainment() async {
    try {
      final response = await https.get(
        Uri.parse('https://api.ekomflix.com/android/getFeaturedLiveTV'),
        headers: {
          'x-api-key': 'vLQTuPZUxktl5mVW',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);

        setState(() {
          entertainmentList = responseData.where((channel) {
            int channelId = int.tryParse(channel['id'].toString()) ?? 0;
            String channelStatus = channel['genres'].toString();
            String status = channel['status'].toString();

            return channelStatus.contains('Music') &&
                (tvenableAll || allowedChannelIds.contains(channelId)) &&
                status == '1';
          }).map((channel) {
            channel['isFocused'] = false;
            return channel;
          }).toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load entertainment data, status code: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error in fetchEntertainment: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cardColor,
      body: isLoading
          ? Center(
              child: SpinKitFadingCircle(
                color: borderColor,
                size: 50.0,
              ),
            )
          : errorMessage.isNotEmpty
              ? Center(
                  child: Text(
                    errorMessage,
                    style: TextStyle(fontSize: 20, color: hintColor),
                  ),
                )
              : entertainmentList.isEmpty
                  ? Center(child: Text('No Channels Available', style: TextStyle(color: hintColor)))
                  : Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                        ),
                        itemCount: entertainmentList.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () => _navigateToVideoScreen(context, entertainmentList[index]),
                            child: _buildGridViewItem(index),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _buildGridViewItem(int index) {
    final item = entertainmentList[index];
    final bool isFocused = item['isFocused'] ?? false;

    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.select) {
          _navigateToVideoScreen(context, item);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      onFocusChange: (hasFocus) {
        setState(() {
          item['isFocused'] = hasFocus;
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            children: [
              AnimatedContainer(
                curve: Curves.ease,
                width: MediaQuery.of(context).size.width * 0.15,
                height: MediaQuery.of(context).size.height * 0.2,
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isFocused ? borderColor : Colors.transparent,
                    width: 5.0,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: CachedNetworkImage(
                    imageUrl: item['banner'] ?? localImage,
                    placeholder: (context, url) => localImage,
                    width: MediaQuery.of(context).size.width * 0.15,
                    height: MediaQuery.of(context).size.height * 0.2,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
          Container(
            width: MediaQuery.of(context).size.width * 0.15,
            child: Text(
              (item['name'] ?? '').toString().toUpperCase(),
              style: TextStyle(
                fontSize: 15,
                color: isFocused ? highlightColor : hintColor,
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

  void _navigateToVideoScreen(BuildContext context, dynamic entertainmentItem) async {
    if (_isNavigating) return;
    _isNavigating = true;

    _showLoadingIndicator(context);

    try {
      if (entertainmentItem['stream_type'] == 'YoutubeLive') {
        socket.emit('youtubeId', entertainmentItem['url']);
        await Future.delayed(Duration(seconds: 5));
        if (entertainmentItem['stream_type'] != 'M3u8') {
          throw Exception('Failed to fetch YouTube URL');
        }
      }

      if (entertainmentItem['stream_type'] == 'VLC') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VlcPlayerScreen(
              videoUrl: entertainmentItem['url'],
              videoTitle: entertainmentItem['name'],
              channelList: entertainmentList,
              onFabFocusChanged: (bool) {},
              genres: '',
              channels: [],
              initialIndex: 1,
            ),
          ),
        ).then((_) {
          _isNavigating = false;
          Navigator.of(context, rootNavigator: true).pop();
        });
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoScreen(
              videoUrl: entertainmentItem['url'],
              videoTitle: entertainmentItem['name'],
              channelList: entertainmentList,
              onFabFocusChanged: (bool) {},
              genres: '',
              channels: [],
              initialIndex: 1,
            ),
          ),
        ).then((_) {
          _isNavigating = false;
          Navigator.of(context, rootNavigator: true).pop();
        });
      }
    } catch (e) {
      _isNavigating = false;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Link Error: $e')),
      );
    }
  }

  void _showLoadingIndicator(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: SpinKitFadingCircle(
            color: borderColor,
            size: 50.0,
          ),
        );
      },
    );
  }
}