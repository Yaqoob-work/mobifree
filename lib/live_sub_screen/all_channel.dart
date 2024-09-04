import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as https;
// import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:mobi_tv_entertainment/main.dart';
import '../video_widget/vlc_player_screen.dart'; // Added VLC player package

void main() {
  runApp(AllChannel());
}

class AllChannel extends StatefulWidget {
  @override
  _AllChannelState createState() => _AllChannelState();
}

class _AllChannelState extends State<AllChannel> {
  List<dynamic> entertainmentList = [];
  List<int> allowedChannelIds = [];
  bool isLoading = true;
  String errorMessage = '';
  bool _isNavigating = false;
  bool tvenableAll = false;

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
            String channelStatus = channel['status'].toString();

            return channelStatus.contains('1') &&
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
      backgroundColor: Colors.black,
      body: isLoading
          ? Center(child: SpinKitFadingCircle(
  color: borderColor
,
  size: 50.0,
)

)
          : errorMessage.isNotEmpty
              ? Center(
                  child: Text(
                  errorMessage,
                  style: TextStyle(fontSize: 20),
                ))
              : entertainmentList.isEmpty
                  ? Center(child: Text('No Channels Available'))
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
                width: screenwdt * 0.15,
                height: screenhgt * 0.2,
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                    border: Border.all(
                      color: entertainmentList[index]['isFocused']
                          ? Colors.yellow
                          : Colors.transparent,
                      width: 5.0,
                    ),
                    borderRadius: BorderRadius.circular(10)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: CachedNetworkImage(
                    imageUrl: entertainmentList[index]['banner'] ?? '',
                    placeholder: (context, url) => SizedBox(),
                    width: screenwdt * 0.15,
                    height: screenhgt * 0.2,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
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
                    ? Colors.yellow
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
          throw Exception(
              'Failed to load networks, status code: ${response.statusCode}');
        }
      }

      // if (entertainmentItem['stream_type'] == 'VLC') {
      //   Navigator.push(
      //     context,
      //     MaterialPageRoute(
      //       builder: (context) => VlcPlayerScreen(
      //         videoUrl: entertainmentItem['url'],
      //         videoTitle: entertainmentItem['name'],
      //       ),
      //     ),
      //   ).then((_) {
      //     _isNavigating = false;
      //     Navigator.of(context, rootNavigator: true).pop();
      //   });
      // } else {
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
      // }
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
  color: borderColor
,
  size: 50.0,
)


        );
      },
    );
  }
}

// class VlcPlayerScreen extends StatefulWidget {
  // final String videoUrl;
  // final String videoTitle;

  // const VlcPlayerScreen({
  //   Key? key,
  //   required this.videoUrl,
  //   required this.videoTitle,
  // }) : super(key: key);

//   @override
//   _VlcPlayerScreenState createState() => _VlcPlayerScreenState();
// }

// class _VlcPlayerScreenState extends State<VlcPlayerScreen> {
//   late VlcPlayerController _vlcPlayerController;

//   @override
//   void initState() {
//     super.initState();
//     _vlcPlayerController = VlcPlayerController.network(
//       widget.videoUrl,
//       hwAcc: HwAcc.full,
//       autoPlay: true,
//       options: VlcPlayerOptions(),
//     );
//   }

//   @override
//   void dispose() {
//     _vlcPlayerController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Stack(
//         children: [
//           Center(
//             child: VlcPlayer(
//               controller: _vlcPlayerController,
//               aspectRatio: 16 / 9,
//               placeholder: Center(child: SpinKitFadingCircle(
// color: borderColor,
// size: 50.0,
// )
// ),
//             ),
//           ),
//           Positioned(
//             top: 40,
//             left: 20,
//             child: Text(
//               widget.videoTitle,
//               style: TextStyle(color: Colors.white, fontSize: 20),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
