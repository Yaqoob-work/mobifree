import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mobi_tv_entertainment/main.dart';
import '../video_widget/video_screen.dart';

class LiveScreen extends StatefulWidget {
  @override
  _LiveScreenState createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
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
                  : GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        // childAspectRatio: 0.75,
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
          // Padding(
            // padding: const EdgeInsets.all(10.0),
            // child: 
            Material(
              elevation: 0,
              // child: Container(
                // decoration: BoxDecoration(boxShadow: entertainmentList[index]['isFocused']?[]:[]),
                child: AnimatedContainer(
                  curve: Curves.easeInOut,
                  width: entertainmentList[index]['isFocused']
                      ? screenwdt * 0.35
                      : screenwdt * 0.3,
                  height: entertainmentList[index]['isFocused']
                      ? screenhgt * 0.23
                      : screenhgt * 0.2,
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: entertainmentList[index]['isFocused']
                          ? hintColor
                          : Colors.white,
                      width: 10.0,
                      
                    ),
                    // boxShadow:entertainmentList[index]['isFocused']? []:[],
                    
                  ),
                  
                  // child: Opacity(
                    // opacity: entertainmentList[index]['isFocused'] ? 1 : 0.7,
                    // child: Card(
                    //   elevation:entertainmentList[index]['isFocused']? 0:0,
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
              // ),
            ),
              // ),
            // ),
          // ),
          

          // const SizedBox(height: 8.0),
          // Container(
          //   width: entertainmentList[index]['isFocused'] ? 180 : 120,
          //   child: Text(
          //     // entertainmentList[index]['name'] ?? 'Unknown',
          //     (entertainmentList[index]['name'] ?? 'UNKNOWN').toUpperCase(),

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
          onFabFocusChanged: (bool) {},
          genres: '',
        ),
      ),
    );
  }
}
