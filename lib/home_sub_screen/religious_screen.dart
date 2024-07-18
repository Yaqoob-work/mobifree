import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

import '../video_widget/video_screen.dart';

class ReligiousScreen extends StatefulWidget {
  @override
  _ReligiousScreenState createState() => _ReligiousScreenState();
}

class _ReligiousScreenState extends State<ReligiousScreen> {
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
                  channel['genres'].contains('Religious'))
              .map((channel) {
                channel['isFocused'] = false; // Add isFocused field
                return channel;
              })
              .toList();
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
      backgroundColor: Colors.black,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text('Error: $errorMessage'))
              : entertainmentList.isEmpty
                  ? const Center(child: Text('No entertainment channels found'))
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: entertainmentList.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () => _navigateToVideoScreen(context, entertainmentList[index]),
                          child: _buildGridViewItem(index),
                        );
                      },
                    ),
    );
  }

  Widget _buildGridViewItem(int index) {
    return Focus(
      onKey: (FocusNode node, RawKeyEvent event) {
        if (event is RawKeyDownEvent && event.logicalKey == LogicalKeyboardKey.select) {
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
        margin: const EdgeInsets.all(8.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: entertainmentList[index]['isFocused'] ?const Color.fromARGB(255, 136, 51, 122) : Colors.transparent,
                    width: 3.0,
                  ),
                  borderRadius: BorderRadius.circular(15.0),
                ),
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
              const SizedBox(height: 8.0),
              Text(
                entertainmentList[index]['name'] ?? 'Unknown',
                style:  TextStyle(
                  color:entertainmentList[index]['isFocused'] ?Color.fromARGB(255, 106, 235, 20): Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
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
          channelList: entertainmentList, onFabFocusChanged: (bool ) {  }, genres: '',url: '',
          playUrl: '',playVideo: (String id) {  },
        ),
      ),
    );
  }
}



