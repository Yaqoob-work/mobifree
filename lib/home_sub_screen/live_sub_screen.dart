import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
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
  bool _isNavigating = false;
  bool tvenableAll = false;
  List<int> allowedChannelIds = [];

  @override
  void initState() {
    super.initState();
    // fetchEntertainment();
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

        print('Allowed Channel IDs: $allowedChannelIds');
        print('Enable All: $tvenableAll');

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
      print('Error in fetchSettings: $e');
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
            // Ensure 'id' is parsed as an int and check 'status' properly
            int channelId = int.tryParse(channel['id'].toString()) ?? 0;
            String channelStatus = channel['status'].toString();

            return channelStatus.contains('1') &&
                (tvenableAll || allowedChannelIds.contains(channelId));
          }).map((channel) {
            channel['isFocused'] = false;
            return channel;
          }).toList();

          print(
              'Channel IDs from API: ${responseData.map((channel) => channel['id']).toList()}');
          print(
              'Filtered Entertainment List Length: ${entertainmentList.length}');

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
      print('Error in fetchEntertainment: $e');
    }
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
      backgroundColor: cardColor,
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('Something Went Wrong',
                        style: TextStyle(fontSize: 20)),
                    // ElevatedButton(onPressed: (){Navigator.of(context, rootNavigator: true).pop();}, child: Text('Go Back',style: TextStyle(fontSize: 25,color: borderColor),))
                  ],
                )
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
          child: Stack(
            children: [
              AnimatedContainer(
                // curve: Curves.ease,
                width: 
                entertainmentList[index]['isFocused']? screenwdt * 0.35:
                     screenwdt * 0.3,
                height: 
                // entertainmentList[index]['isFocused']? screenhgt * 0.25:
                    screenhgt * 0.2,
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
                  child: CachedNetworkImage(
                    imageUrl: entertainmentList[index]['banner'],
                    placeholder: (context, url) => localImage,
                    width: 
                    // entertainmentList[index]['isFocused']? screenwdt * 0.3:
                        screenwdt * 0.27,
                    height: 
                    // entertainmentList[index]['isFocused']? screenhgt * 0.23:
                       screenhgt * 0.2,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                left: screenwdt * 0.03,
                top: screenhgt * 0.02,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'LIVE',
                        style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 18),
                      ),
                      // SizedBox(width: 2,),
                      // Icon(Icons.live_tv_rounded ,color: Colors.red,)
                    ]),
              )
            ],
          ),
        ),
        Container(
          width:
          //  entertainmentList[index]['isFocused'] ? screenwdt * 0.3:
           screenwdt * 0.25,
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
    );
  }

  void _navigateToVideoScreen(
      BuildContext context, dynamic entertainmentItem) async {
    if (_isNavigating) return; // Check if navigation is already in progress
    _isNavigating = true; // Set the flag to true

    // Show loading indicator
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
        // Hide the loading indicator
        Navigator.of(context, rootNavigator: true).pop();
      });
    } catch (e) {
      // Hide the loading indicator in case of an error
      Navigator.of(context, rootNavigator: true).pop();
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Something Went Wrong')),
      );
    }
  }
}
