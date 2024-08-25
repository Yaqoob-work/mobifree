import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as https;
import 'package:mobi_tv_entertainment/main.dart';
import '../video_widget/video_screen.dart';

void main() {
  runApp(MovieScreen());
}

class MovieScreen extends StatefulWidget {
  @override
  MovieScreenState createState() => MovieScreenState();
}

class MovieScreenState extends State<MovieScreen> {
  List<dynamic> entertainmentList = [];
  List<int> allowedChannelIds = [];
  bool isLoading = true;
  String errorMessage = '';
  bool _isNavigating = false;
  bool ekomenableAll = false;

  @override
  void initState() {
    super.initState();
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
          ekomenableAll = settingsData['ekomenableAll'] == 1;
        });

        // print('Allowed Channel IDs: $allowedChannelIds');
        // print('Enable All: $ekomenableAll');

        fetchEntertainment();
      } else {
        throw Exception('Something Went Wrong');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Something Went Wrong';
        isLoading = false;
      });
      // print('Error in fetchSettings: $e');
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

            // Check if the status is "1" and apply the existing filters
            return channel['status'] == "1" &&
                channelStatus.contains('Movies') &&
                (ekomenableAll || allowedChannelIds.contains(channelId));
          }).map((channel) {
            channel['isFocused'] = false;
            return channel;
          }).toList();

          // print(
          //     'Channel IDs from API: ${responseData.map((channel) => channel['id']).toList()}');
          // print(
          //     'Filtered Entertainment List Length: ${entertainmentList.length}');

          isLoading = false;
        });
      } else {
        throw Exception('Something Went Wrong');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Something Went Wrong';
        isLoading = false;
      });
      // print('Error in fetchEntertainment: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cardColor,
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(
                  child: Text(
                  errorMessage,
                  style: TextStyle(fontSize: 20),
                ))
              : entertainmentList.isEmpty
                  ? Center(child: Text('Something Went Wrong'))
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
    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.select) {
          _navigateToVideoScreen(context, entertainmentList[index]);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      onFocusChange: (hasFocus) {
        setState(() {
          entertainmentList[index]['isFocused'] = hasFocus;
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
                width:
                    // entertainmentList[index]['isFocused']? screenwdt * 0.2:
                    screenwdt * 0.15,
                height:
                    // entertainmentList[index]['isFocused']? screenhgt * 0.25:
                    screenhgt * 0.2,
                duration: const Duration(milliseconds: 3),
                decoration: BoxDecoration(
                    border: Border.all(
                      color: entertainmentList[index]['isFocused']
                          ? borderColor
                          : hintColor,
                      width: 5.0,
                    ),
                    borderRadius: BorderRadius.circular(10)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: CachedNetworkImage(
                    imageUrl: entertainmentList[index]['banner'] ?? localImage,
                    placeholder: (context, url) => localImage,
                    width:
                        // entertainmentList[index]['isFocused']? screenwdt * 0.2:
                        screenwdt * 0.15,
                    height:
                        // entertainmentList[index]['isFocused']? screenhgt * 0.23:
                        screenhgt * 0.2,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Positioned(
              //     left: screenwdt * 0.03,
              //     top: screenhgt * 0.02,
              //     child: Row(
              //       mainAxisAlignment: MainAxisAlignment.center,
              //       crossAxisAlignment: CrossAxisAlignment.center,
              //       children: [
              //         Text(
              //           'LIVE',
              //           style: TextStyle(
              //               color: Colors.red,
              //               fontWeight: FontWeight.bold,
              //               fontSize: 18),
              //         ),
              //       ],
              //     ))
            ],
          ),
          Container(
            width: screenwdt * 0.15,
            child: Text(
              (entertainmentList[index]['name'] ?? 'Unknown')
                  .toString()
                  .toUpperCase(),
              style: TextStyle(
                fontSize: 15,
                color: entertainmentList[index]['isFocused']
                    ? highlightColor
                    : Colors.white,
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
        final response = await https.get(
          Uri.parse('https://test.gigabitcdn.net/yt-dlp.php?v=' +
              entertainmentItem['url']!),
          headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
        );

        if (response.statusCode == 200) {
          entertainmentItem['url'] = json.decode(response.body)['url']!;
          entertainmentItem['stream_type'] = "M3u8";
        } else {
          throw Exception('Something Went Wrong');
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
        SnackBar(content: Text('Something Went Wrong')),
      );
      // print('Error in _navigateToVideoScreen: $e');
    }
  }

  void _showLoadingIndicator(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }
}
