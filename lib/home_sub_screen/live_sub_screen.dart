import 'dart:convert';
import 'package:container_gradient_border/container_gradient_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mobi_tv_entertainment/main.dart';
import '../video_widget/video_screen.dart';


class LiveSubScreen extends StatefulWidget {
  @override
  _LiveSubScreenState createState() => _LiveSubScreenState();
}

class _LiveSubScreenState extends State<LiveSubScreen> {
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
      backgroundColor: Colors.black,
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text('Error: $errorMessage'))
              : entertainmentList.isEmpty
                  ? Center(child: Text('No entertainment channels found'))
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: entertainmentList.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () => _navigateToVideoScreen(
                              context, entertainmentList[index]),
                          child: Focus(
                            onFocusChange: (isFocused) {
                              setState(() {
                                entertainmentList[index]['isFocused'] = isFocused;
                              });
                            },
                            onKey: (node, event) {
                              if (event is RawKeyDownEvent &&
                                  (event.logicalKey == LogicalKeyboardKey.select ||
                                      event.logicalKey == LogicalKeyboardKey.enter)) {
                                _navigateToVideoScreen(context, entertainmentList[index]);
                                return KeyEventResult.handled;
                              }
                              return KeyEventResult.ignored;
                            },
                            child: _buildListViewItem(index),
                          ),
                        );
                      },
                    ),
    );
  }

  Widget _buildListViewItem(int index) {
    return Container(
      width: 240,
      height: 200,
      margin: const EdgeInsets.all(8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: entertainmentList[index]['isFocused'] ? 200 : 120,
              height: entertainmentList[index]['isFocused'] ? 150 : 120,
              child: ContainerGradientBorder(
                width: entertainmentList[index]['isFocused'] ? 190 : 110,
                height: entertainmentList[index]['isFocused'] ? 140 : 110,
                start: Alignment.topLeft,
                end: Alignment.bottomRight,
                borderWidth: 7,
                colorList: entertainmentList[index]['isFocused']
                    ? [
                          AppColors.primaryColor,
                          AppColors.highlightColor,
                          AppColors.primaryColor,
                          AppColors.highlightColor,
                          AppColors.primaryColor,
                          AppColors.highlightColor,
                          AppColors.primaryColor,
                          AppColors.highlightColor,
                          AppColors.primaryColor,
                          AppColors.highlightColor,
                          AppColors.primaryColor,
                          AppColors.highlightColor,
                          AppColors.primaryColor,
                          AppColors.highlightColor,
                          AppColors.primaryColor,
                          AppColors.highlightColor,
                        ]
                      : [AppColors.primaryColor, AppColors.highlightColor],
                borderRadius: 10,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: Image.network(
                    entertainmentList[index]['banner'],
                    width: entertainmentList[index]['isFocused'] ? 180 : 100,
                    height: entertainmentList[index]['isFocused'] ? 130 : 100,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Container(
              width: entertainmentList[index]['isFocused'] ? 180 : 100,
              child: Text(
                entertainmentList[index]['name'] ?? 'Unknown',
                style: TextStyle(
                  fontSize: 20,
                  color: entertainmentList[index]['isFocused']
                      ? AppColors.highlightColor
                      : Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
          onFabFocusChanged: (bool) {},
          genres: '',
        ),
      ),
    );
  }
}
