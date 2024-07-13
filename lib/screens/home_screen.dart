import 'package:flutter/material.dart';
import 'package:mobi_tv_entertainment/home_sub_screen/banner_slider_screen.dart';
import 'package:mobi_tv_entertainment/home_sub_screen/entertainment_screen.dart';
import 'package:mobi_tv_entertainment/home_sub_screen/entertainment_sub_screen.dart';
import 'package:mobi_tv_entertainment/home_sub_screen/home_category.dart';
import 'package:mobi_tv_entertainment/home_sub_screen/live_sub_screen.dart';
import 'package:mobi_tv_entertainment/home_sub_screen/movies_screen.dart';
// import 'package:mobi_tv_entertainment/live/screens/home_sub_screen/news_sub_screen.dart';
import 'package:mobi_tv_entertainment/home_sub_screen/popular_network_list_screen.dart';
import 'package:mobi_tv_entertainment/home_sub_screen/religious_screen.dart';
import 'package:mobi_tv_entertainment/home_sub_screen/religious_sub_screen.dart';
import 'package:mobi_tv_entertainment/home_sub_screen/web_series_screen.dart';
import 'package:mobi_tv_entertainment/screens/live_screen.dart';
// import 'package:mobi_tv_entertainment/live/screens/news_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  FocusNode _newsFocusNode = FocusNode();
  FocusNode _liveFocusNode = FocusNode();
  FocusNode _entertainmentFocusNode = FocusNode();
  FocusNode _religiousFocusNode = FocusNode();
  FocusNode _moviesFocusNode = FocusNode();
  FocusNode _webseriesFocusNode = FocusNode();
  FocusNode _bannersliderFocusNode = FocusNode();
  FocusNode _homecategoryFocusNode = FocusNode();
  FocusNode _popularNetworkFocusNode = FocusNode();

  @override
  void dispose() {
    _newsFocusNode.dispose();
    _entertainmentFocusNode.dispose();
    _religiousFocusNode.dispose();
    _moviesFocusNode.dispose();
    _webseriesFocusNode.dispose();
    _bannersliderFocusNode.dispose();
    _homecategoryFocusNode.dispose();
    _popularNetworkFocusNode.dispose();
    _liveFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Slider at the top
            Focus(
              focusNode: _bannersliderFocusNode,
              onFocusChange: (bool hasFocus) {
                setState(() {
                  // Handle focus change if needed
                });
              },
              child: Container(
                // decoration: BoxDecoration(
                //   border: Border.all(
                //     color: _bannersliderFocusNode.hasFocus
                //         ? const Color.fromARGB(255, 136, 51, 122)
                //         : Colors.transparent,
                //     width: 5,
                //   ),
                // ),
                height: MediaQuery.of(context).size.height * 0.8,
                child: BannerSliderPage(),
              ),
            ),

            Focus(
              focusNode: _popularNetworkFocusNode,
              onFocusChange: (bool hasFocus) {
                setState(() {
                  // Handle focus change if needed
                });
              },
              child: Container(
                height: MediaQuery.of(context).size.height * 0.50,
                child: PopularNetworkListScreen(),
              ),
            ),
            const Divider(
              color: const Color.fromARGB(255, 136, 51, 122),
              height: 20,
              thickness: 2,
            ),
            Focus(
              focusNode: _homecategoryFocusNode,
              onFocusChange: (bool hasFocus) {
                setState(() {
                  // Handle focus change if needed
                });
              },
              child: Container(
                height: 990,
                child: HomeCategory(),
              ),
            ),
            const Divider(
              color: const Color.fromARGB(255, 136, 51, 122),
              height: 20,
              thickness: 2,
            ),
            // Web Series Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Center(
                child: Focus(
                  focusNode: _webseriesFocusNode,
                  onFocusChange: (bool hasFocus) {
                    setState(() {
                      // Handle focus change if needed
                    });
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Web Series",
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WebSeriesScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'View All',
                          style: TextStyle(
                            fontSize: 20,
                            color: _webseriesFocusNode.hasFocus
                                ? const Color.fromARGB(255, 136, 51, 122)
                                : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 180,
              child: WebSeriesScreen(),
            ),
            const Divider(
              color: const Color.fromARGB(255, 136, 51, 122),
              height: 20,
              thickness: 2,
            ),

            // Movies Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Center(
                child: Focus(
                  focusNode: _moviesFocusNode,
                  onFocusChange: (bool hasFocus) {
                    setState(() {
                      // Handle focus change if needed
                    });
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      
                      const Text(
                        "Movies",
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MoviesScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'View All',
                          style: TextStyle(
                            fontSize: 20,
                            color: _moviesFocusNode.hasFocus
                                ? const Color.fromARGB(255, 136, 51, 122)
                                : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 180,
              child: MoviesScreen(),
            ),
            const Divider(
              color: const Color.fromARGB(255, 136, 51, 122),
              height: 20,
              thickness: 2,
            ),

            // News Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Center(
                child: Focus(
                  focusNode: _liveFocusNode,
                  onFocusChange: (bool hasFocus) {
                    setState(() {
                      // Handle focus change if needed
                    });
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Live",
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LiveScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'View All',
                          style: TextStyle(
                            fontSize: 20,
                            color: _liveFocusNode.hasFocus
                                ? const Color.fromARGB(255, 136, 51, 122)
                                : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 180,
              child: LiveSubScreen(),
            ),
            const Divider(
              color: const Color.fromARGB(255, 136, 51, 122),
              height: 20,
              thickness: 2,
            ),
            // Entertainment Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Center(
                child: Focus(
                  focusNode: _entertainmentFocusNode,
                  onFocusChange: (bool hasFocus) {
                    setState(() {
                      // Handle focus change if needed
                    });
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Entertainment',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EntertainmentScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'View All',
                          style: TextStyle(
                            fontSize: 20,
                            color: _entertainmentFocusNode.hasFocus
                                ? const Color.fromARGB(255, 136, 51, 122)
                                : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 180,
              child: EntertainmentSubScreen(),
            ),
            const Divider(
              color: const Color.fromARGB(255, 136, 51, 122),
              height: 20,
              thickness: 2,
            ),
            // Religious Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Center(
                child: Focus(
                  focusNode: _religiousFocusNode,
                  onFocusChange: (bool hasFocus) {
                    setState(() {
                      // Handle focus change if needed
                    });
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Religious',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReligiousScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'View All',
                          style: TextStyle(
                            fontSize: 20,
                            color: _religiousFocusNode.hasFocus
                                ? const Color.fromARGB(255, 136, 51, 122)
                                : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 180,
              child: ReligiousSubScreen(),
            ),
          ],
        ),
      ),
    );
  }
}
