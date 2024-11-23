import 'package:mobi_tv_entertainment/main.dart';
import 'package:mobi_tv_entertainment/menu_screens/home_sub_screen/sub_vod.dart';
import 'package:flutter/material.dart';
import 'package:mobi_tv_entertainment/widgets/small_widgets/loading_indicator.dart';
import 'home_sub_screen/banner_slider_screen.dart';
import 'home_sub_screen/home_category.dart';
import 'home_sub_screen/music_screen.dart';

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
  // double _bannerHeight = screenhgt; // Initial height
  // double _bannerWidth = screenwdt; // Initial height

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    // _fetchData();
    // _checkIfSplashNeeded();
    // _resetSplashFlag();
    // _initializeScreen();
  }

  //   Future<void> _initializeScreen() async {
  //   // Add slight delay to ensure proper widget tree building
  //   await Future.delayed(Duration(milliseconds: 100));
  //   if (mounted) {
  //     setState(() {
  //       _isLoading = false;
  //     });
  //   }
  // }

  // void _onBannerHeightChange(double newHeight) {
  //   setState(() {
  //     _bannerHeight =
  //         newHeight > 0 ? newHeight : screenhgt * 0.5; // Ensure non-zero height
  //   });
  // }

  // void _onBannerWidthChange(double newWidth) {
  //   setState(() {
  //     _bannerWidth =
  //         newWidth > 0 ? newWidth : screenwdt; // Ensure non-zero width
  //   });
  // }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }


  void _scrollListener() {
    // if (_scrollController.position.pixels ==
    //     _scrollController.position.maxScrollExtent) {
    //   // _fetchData();
    // }
    if (!_isLoading && _scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
  // _fetchData();
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
                padding: EdgeInsets.symmetric(horizontal: screenwdt * 0.03),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Container(
                    //   height: screenhgt*0.000001,
                    //   child: EmptyPage(),
                    // ),
                    // if (_tvenableAll) // Conditionally display SubVod
                    Container(
                      color: cardColor,
                      height: screenhgt*0.5,
                      width: screenwdt,
                      child: BannerSlider(
                        // initialHeight: screenhgt * 0.5,
                        // onHeightChange: _onBannerHeightChange,
                        // initialWidth: screenwdt,
                        // onWidthChange: _onBannerWidthChange,
                      ),
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

                    Container(
                      color: cardColor,
                      child: SizedBox(
                        height: screenhgt * 4,
                        child: HomeCategory(),
                      ),
                    ),
                    if (_isLoading)
                      // ...[
                      // const Padding(
                      // padding: EdgeInsets.symmetric(vertical: 20),
                      // child:
                      Center(
                        child: LoadingIndicator()
                      ),
                    // ),
                    // ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
