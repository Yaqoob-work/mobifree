import 'package:flutter/material.dart';
import 'package:mobi_tv_entertainment/home_sub_screen/banner_slider_screen.dart';
import 'package:mobi_tv_entertainment/home_sub_screen/home_category.dart';
import 'package:mobi_tv_entertainment/home_sub_screen/live_sub_screen.dart';
import 'package:mobi_tv_entertainment/home_sub_screen/sub_vod.dart';
import 'package:mobi_tv_entertainment/main.dart';

void main() {
  runApp(HomeScreen());
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _fetchData();
  }

  @override
  void dispose() {
    // Dispose of the ScrollController
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });

    // Simulate network request delay
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
    });
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cardColor,
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 0,
              child: Text(''),
            ),
            Container(
              height: MediaQuery.of(context).size.height * 0.7,
              child: BannerSlider(),
            ),
            Container(
              child: Column(
                children: [
                  Container(
                    color: cardColor,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: Text(
                              "CONTENTS",
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: hintColor,
                              ),
                            ),
                          ),
                        ),
                        Text('')
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 200,
                    child: SubVod(),
                  ),
                ],
              ),
            ),
            Container(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    color: cardColor,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Text(
                            "LIVE",
                            style: TextStyle(
                              fontSize: 20,
                              color: hintColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text('')
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 200,
                    child: LiveSubScreen(),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 1500,
              child: HomeCategory(),
            ),
            Container(
              height: 0,
              child: Text(''),
            ),
            if (_isLoading) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


