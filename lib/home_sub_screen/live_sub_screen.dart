import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as https;
import 'package:mobi_tv_entertainment/main.dart';
import '../video_widget/video_screen.dart';

// var liveHeight;
class LiveSubScreen extends StatefulWidget {
  @override
  _LiveSubScreenState createState() => _LiveSubScreenState();
}

class _LiveSubScreenState extends State<LiveSubScreen> {
  List<dynamic> entertainmentList = [];
  bool isLoading = true;
  String errorMessage = '';
   bool   _isNavigating = false;


  @override
  void initState() {
    super.initState();
    fetchEntertainment();
  }

  Future<void> fetchEntertainment() async {
    try {
      final response = await https.get(
        Uri.parse('https://acomtv.com/android/getFeaturedLiveTV'),
        headers: {
          'x-api-key': 'vLQTuPZUxktl5mVW',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);

        setState(() {
          entertainmentList = responseData
              .where((channel) =>
                  channel['status'] != null && channel['status'].contains('1'))
              .map((channel) {
            channel['isFocused'] = false; // Add isFocused field
            return channel;
          }).toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cardColor,
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text('Error: $errorMessage'))
              : entertainmentList.isEmpty
                  ? Center(child: Text('No entertainment channels found'))
                  : LayoutBuilder(builder: (context, constraints) {
                      //  liveHeight = constraints.maxHeight;
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: entertainmentList.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () => _navigateToVideoScreen(
                                context, entertainmentList[index]),
                            child: Focus(
                              onFocusChange: (isFocused) {
                                setState(() {
                                  entertainmentList[index]['isFocused'] =
                                      isFocused;
                                });
                              },
                              onKeyEvent: (node, event) {
                                if (event is KeyDownEvent &&
                                    (event.logicalKey ==
                                            LogicalKeyboardKey.select ||
                                        event.logicalKey ==
                                            LogicalKeyboardKey.enter)) {
                                  _navigateToVideoScreen(
                                      context, entertainmentList[index]);
                                  return KeyEventResult.handled;
                                }
                                return KeyEventResult.ignored;
                              },
                              child: _buildListViewItem(index),
                            ),
                          );
                        },
                      );
                    }),
    );
  }

  Widget _buildListViewItem(int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(10),
          child: AnimatedContainer(
            // curve: Curves.ease,
            width: entertainmentList[index]['isFocused']
                ? screenwdt * 0.35
                : screenwdt * 0.3,
            height: entertainmentList[index]['isFocused']
                ? screenhgt * 0.25
                : screenhgt * 0.2,
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
                color: hintColor,
                border: Border.all(
                  color: entertainmentList[index]['isFocused']
                      ? borderColor
                      : hintColor,
                  width: 5.0,
                ),
                borderRadius: BorderRadius.circular(10)),

            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Image.network(
                entertainmentList[index]['banner'],
                width: entertainmentList[index]['isFocused']
                    ? screenwdt * 0.3
                    : screenwdt * 0.27,
                height: entertainmentList[index]['isFocused']
                    ? screenhgt * 0.23
                    : screenhgt * 0.2,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        // Container(
        //   width: entertainmentList[index]['isFocused']
        //       ? screenwdt * 0.3
        //       : screenwdt * 0.25,
        //   child: Text(
        //     (entertainmentList[index]['name'] ?? 'Unknown')
        //         .toString()
        //         .toUpperCase(),
        //     style: TextStyle(
        //       fontSize: 20,
        //       color: entertainmentList[index]['isFocused']
        //           ? highlightColor
        //           : Colors.white,
        //     ),
        //     textAlign: TextAlign.center,
        //     maxLines: 1,
        //     overflow: TextOverflow.ellipsis,
        //   ),
        // ),
      ],
    );
  }

  void _navigateToVideoScreen(
      BuildContext context, dynamic entertainmentItem) async {

if (_isNavigating) return;  // Check if navigation is already in progress
    _isNavigating = true;  // Set the flag to true

    if (entertainmentItem['stream_type'] == 'YoutubeLive') {
      final response = await https.get(
        Uri.parse('https://test.gigabitcdn.net/yt-dlp.php?v=' +
            entertainmentItem['url']!),
        headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
      );

      if (response.statusCode == 200) {
        entertainmentItem['url'] = json.decode(response.body)['url'];
        entertainmentItem['stream_type'] = "M3u8";
      } else {
        throw Exception('Failed to load networks');
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
      // Reset the flag after the navigation is completed
      _isNavigating = false;
    });
  }
}
