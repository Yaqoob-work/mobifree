import 'dart:async';
import 'dart:convert';
import 'package:container_gradient_border/container_gradient_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mobi_tv_entertainment/main.dart';

import '../video_widget/video_screen.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Entertainment App',
      theme: ThemeData.dark(),
      home: EntertainmentScreen(),
    );
  }
}

class EntertainmentScreen extends StatefulWidget {
  @override
  _EntertainmentScreenState createState() => _EntertainmentScreenState();
}

class _EntertainmentScreenState extends State<EntertainmentScreen> {
  List<dynamic> entertainmentList = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchEntertainment();
  }

  Future<void> fetchEntertainment() async {
    try {
      final response = await http.get(
        Uri.parse('https://mobifreetv.com/android/getFeaturedLiveTV'),
        headers: {
          'x-api-key': 'vLQTuPZUxktl5mVW',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);

        setState(() {
          entertainmentList = responseData
              .where((channel) =>
                  channel['genres'] != null &&
                  channel['genres'].contains('Entertainment'))
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
      backgroundColor: AppColors.cardColor,
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text('Error: $errorMessage'))
              : entertainmentList.isEmpty
                  ? Center(child: Text('No entertainment channels found'))
                  : GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: entertainmentList.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () =>
                              _navigateToVideoScreen(context, entertainmentList[index]),
                          child: _buildGridViewItem(index),
                        );
                      },
                    ),
    );
  }

  Widget _buildGridViewItem(int index) {
    return Focus(
      onKeyEvent: (FocusNode node, KeyEvent  event) {
        if (event is KeyDownEvent  &&
            (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter)) {
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
      child: Container(
        margin: EdgeInsets.all(8.0),
        // child: ClipRRect(
        //   borderRadius: BorderRadius.circular(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                // decoration: BoxDecoration(
                //   border: Border.all(
                //     color: entertainmentList[index]['isFocused']
                //         ? AppColors.primaryColor
                //         : Colors.transparent,
                //     width: 5.0,
                //   ),
                //   borderRadius: BorderRadius.circular(17.0),
                // ),
                 child: ContainerGradientBorder(
                  width:entertainmentList[index]['isFocused'] ? 110 : 70,
                  height:entertainmentList[index]['isFocused'] ? 90 : 70,
                  start: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  borderWidth: 7,
                  colorList: const [
                    AppColors.primaryColor,
                    AppColors.highlightColor
                  ],
                  borderRadius: 10,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: Image.network(
                    entertainmentList[index]['banner'],
                    width: entertainmentList[index]['isFocused'] ? 110 : 90,
                    height: entertainmentList[index]['isFocused'] ? 90 : 70,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              ),
              SizedBox(height: 8.0),
              Container(
                    width: entertainmentList[index]['isFocused'] ? 110 : 90,

                      child: Center(
                        child: Text(
                          entertainmentList[index]['name'] ?? 'Unknown',
                          style: TextStyle(
                            fontSize: 20,
                            color:entertainmentList[index]['isFocused'] ?AppColors.highlightColor: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  
            ],
          ),
        ),
      
    );
  }

  void _navigateToVideoScreen(BuildContext context, dynamic entertainmentItem) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoScreen(
          videoUrl: entertainmentItem['url'],
          videoTitle: entertainmentItem['name'],
          channelList: entertainmentList,
          onFabFocusChanged: _handleFabFocusChanged, genres: '', url: '',
          playUrl: '',playVideo: (String id) {  }, id: '',channels: [], initialIndex: 1,
        ),
      ),
    );
  }

  void _handleFabFocusChanged(bool hasFocus) {
    setState(() {
      // Update FAB focus state
      // This method can be called from VideoScreen to update FAB focus state
    });
  }
}



