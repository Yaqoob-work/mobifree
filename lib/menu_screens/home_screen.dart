import 'dart:async';
import 'dart:convert';
import 'package:mobi_tv_entertainment/main.dart';
import 'package:mobi_tv_entertainment/menu_screens/home_sub_screen/sub_vod.dart';
import 'package:mobi_tv_entertainment/menu_screens/vod.dart';
import 'package:mobi_tv_entertainment/menu_two_items/Music_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as https;
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_sub_screen/banner_slider_screen.dart';
import 'home_sub_screen/home_category.dart';

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
  bool _tvenableAll = false; // Add a variable to track tvenableAll status
  bool _isSplashVisible = true;
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _fetchData();
    _checkIfSplashNeeded();
    _resetSplashFlag();
  }

  // Har baar app start hone par splash ko dikhana hai to flag reset karein
  Future<void> _resetSplashFlag() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('splashShown', false); // Reset splash flag
  }

  // Yeh function check karega agar splash pehle dikha chuka hai ya nahi
  Future<void> _checkIfSplashNeeded() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool splashShown = prefs.getBool('splashShown') ?? false;

    if (splashShown) {
      setState(() {
        _isSplashVisible = false; // Splash ko hide kar dega
      });
    } else {
      // Splash ko 2 seconds ke liye dikhao, aur fir next steps lo
      Timer(Duration(seconds: 5), () {
        setState(() {
          _isSplashVisible = false;
          prefs.setBool('splashShown', true); // Splash ko mark karo as shown
        });
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });

    // Simulate network request delay
    await Future.delayed(const Duration(seconds: 1));

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
          _tvenableAll = data['tvenableAll'] == 1;
        });
      } else {
        // Handle errors or non-200 responses
        print('Failed to load settings');
      }
    } catch (e) {
      // Handle network errors or JSON parsing errors
      print('Error: $e');
    }

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
      body: Container(
        width: screenwdt,
        height: screenhgt,
        child: Stack(
          children: [
            SingleChildScrollView(
              controller: _scrollController,
              child: Padding(
                padding:  EdgeInsets.symmetric(horizontal:  screenwdt *0.03),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Container(
                    //   height: screenhgt*0.01,
                    //   child: Text('.'),
                    // ),
                    // if (_tvenableAll) // Conditionally display SubVod
                    Container(
                      color: cardColor,
                      height: screenhgt *0.65,
                      child: BannerSlider(),
                    ),
                    // if (_tvenableAll) // Conditionally display SubVod
                    Container(
                      color: cardColor,
                      child: SizedBox(
                        height: screenhgt * 0.5,
                        child: MusicScreen(),
                      ),
                    ),
                    //             // if (_tvenableAll) // Conditionally display SubVod
                    Container(
                      color: cardColor,
                      child: SizedBox(
                        height: screenhgt * 0.5,
                        child: SubVod(),
                      ),
                    ),
                    //               Container(
                    //   color: cardColor,
                    //   child: SizedBox(
                    //     height: screenhgt,
                    //     child: Tabbar(),
                    //   ),
                    // ),
                    Container(
                      color: cardColor,
                      child: SizedBox(
                        height: screenhgt * 4,
                        child: HomeCategory(),
                      ),
                    ),
                
                    // Container(
                    //   height: 0,
                    //   child: Text(''),
                    // ),
                    if (_isLoading)
                      // ...[
                      // const Padding(
                      // padding: EdgeInsets.symmetric(vertical: 20),
                      // child:
                      Center(
                        child: SpinKitFadingCircle(
                          color: borderColor,
                          size: 50.0,
                        ),
                      ),
                    // ),
                    // ],
                  ],
                ),
              ),
            ),
            // if (_isSplashVisible)
            //   Positioned.fill(
            //     child: Container(
            //       color: Colors.white, // Optional: Splash screen background color
            //       child: Image.asset(
            //         'assets/logo.png', // Splash image
            //         fit: BoxFit.fill ,
            //       ),
            //     ),
            //   ),
          ],
        ),
      ),
    );
  }
}