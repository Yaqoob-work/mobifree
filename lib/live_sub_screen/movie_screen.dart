

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as https;
import 'package:mobi_tv_entertainment/main.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/socket_service.dart';
import '../video_widget/video_screen.dart';

void main() {
  runApp(MovieScreen());
}

class MovieScreen extends StatefulWidget {
  @override
  _MovieScreenState createState() => _MovieScreenState();
}

class _MovieScreenState extends State<MovieScreen> {
  List<dynamic> entertainmentList = [];
  List<int> allowedChannelIds = [];
  bool isLoading = true;
  String errorMessage = '';
  bool _isNavigating = false;
  bool tvenableAll = false;
  final SocketService _socketService = SocketService();
  int _maxRetries = 3;
  int _retryDelay = 5; // seconds

  @override
  void initState() {
    super.initState();
    _socketService.initSocket();
    fetchSettings();
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
        throw Exception(
            'Failed to load settings, status code: ${response.statusCode}');
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
            String channelGenres = channel['genres'].toString();
            String channelStatus = channel['status'].toString();

            return channelGenres.contains('Movies') &&
                   channelStatus == "1" &&
                   (tvenableAll || allowedChannelIds.contains(channelId));
          }).map((channel) {
            channel['isFocused'] = false;
            return channel;
          }).toList();
          isLoading = false;
        });
      } else {
        throw Exception(
            'Failed to load entertainment data, status code: ${response.statusCode}');
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
                  ? Center(
                      child: Text('No Channels Available',
                          style: TextStyle(color: hintColor)))
                  : Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                        ),
                        itemCount: entertainmentList.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () => _navigateToVideoScreen(
                                context, entertainmentList[index]),
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
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.select) {
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

  void _navigateToVideoScreen(
      BuildContext context, dynamic entertainmentItem) async {
    if (_isNavigating) return;
    _isNavigating = true;

    _showLoadingIndicator(context);

    try {
      if (entertainmentItem['stream_type'] == 'YoutubeLive') {
        for (int i = 0; i < _maxRetries; i++) {
          try {
            String updatedUrl = await _socketService.getUpdatedUrl(entertainmentItem['url']);
            entertainmentItem['url'] = updatedUrl;
            entertainmentItem['stream_type'] = 'M3u8';
            break;
          } catch (e) {
            if (i == _maxRetries - 1) rethrow;
            await Future.delayed(Duration(seconds: _retryDelay));
          }
        }
      }

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

  @override
  void dispose() {
    _socketService.dispose();
    super.dispose();
  }
}

