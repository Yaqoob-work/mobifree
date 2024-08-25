import 'dart:convert';
import 'package:http/http.dart' as https;
import 'package:flutter/material.dart';
import 'package:mobi_tv_entertainment/live_sub_screen/all_channel.dart';
import 'package:mobi_tv_entertainment/live_sub_screen/entertainment_screen.dart';
import 'package:mobi_tv_entertainment/live_sub_screen/movie_screen.dart';
import 'package:mobi_tv_entertainment/live_sub_screen/music_screen.dart';
import 'package:mobi_tv_entertainment/live_sub_screen/news_screen.dart';
import 'package:mobi_tv_entertainment/live_sub_screen/religious_screen.dart';
import 'package:mobi_tv_entertainment/live_sub_screen/sports_screen.dart';

import '../video_widget/top_navigation_bar.dart';

class LiveScreen extends StatefulWidget {
  @override
  _LiveScreenState createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  int _selectedPage = 0;
  late PageController _pageController;
  bool _ekomenableAll = false; // Track ekomenableAll status

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedPage);
    _fetchekomenableAllStatus(); // Fetch ekomenableAll status
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageSelected(int index) {
    setState(() {
      _selectedPage = index;
    });
    _pageController.jumpToPage(index);
  }

  Future<void> _fetchekomenableAllStatus() async {
    try {
      final response = await https.get(
        Uri.parse('https://api.ekomflix.com/android/getSettings'),
        headers: {
          'x-api-key': 'vLQTuPZUxktl5mVW',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _ekomenableAll = data['ekomenableAll'] == 1;
        });
      } else {
        print('Failed to load settings');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> pages = [
      // Your LiveScreen content pages
      AllChannel(),
      NewsScreen(),
      MovieScreen(),
      MusicScreen(),
      SportsScreen(),
      ReligiousScreen(),
      EntertainmentScreen(),
    ];

    return Scaffold(
      body: Column(
        children: [
          TopNavigationBar(
            selectedPage: _selectedPage,
            onPageSelected: _onPageSelected,
            ekomenableAll: _ekomenableAll,
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _selectedPage = index;
                });
              },
              children: pages,
            ),
          ),
        ],
      ),
    );
  }
}
