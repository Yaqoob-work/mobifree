


import 'package:flutter/material.dart';
import 'package:mobi_tv_entertainment/home_sub_screen/banner_slider_screen.dart';
import 'package:mobi_tv_entertainment/home_sub_screen/home_category.dart';
import 'package:mobi_tv_entertainment/home_sub_screen/live_sub_screen.dart';
import 'package:mobi_tv_entertainment/home_sub_screen/sub_network.dart';
import 'package:mobi_tv_entertainment/main.dart';
import 'package:mobi_tv_entertainment/screens/live_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  int _page = 1;
  List<dynamic> _dataList = []; // Replace dynamic with your data type

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
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _fetchData();
  }

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
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });

    // Fetch data from your API and update _dataList
    // final newData = await fetchDataFromAPI(page: _page);
    // setState(() {
    //   _dataList.addAll(newData);
    //   _isLoading = false;
    //   _page++;
    // });

    setState(() {
      _isLoading = false;
    });
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        controller: _scrollController,
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
                height: MediaQuery.of(context).size.height * 0.5,
                child: SubNetwork(),
              ),
            ),
            
            Focus(
              focusNode: _homecategoryFocusNode,
              onFocusChange: (bool hasFocus) {
                setState(() {
                  // Handle focus change if needed
                });
              },
              child: Container(
                height: 1200,
                child: HomeCategory(),
              ),
            ),
           
            const Divider(
              color: AppColors.primaryColor,
              height: 20,
              thickness: 2,
            ),

            // News Section
            
            // const Divider(
            //   color: AppColors.primaryColor,
            //   height: 20,
            //   thickness: 2,
            // ),
            // // Entertainment Section
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            //   child: Center(
            //     child: Focus(
            //       focusNode: _entertainmentFocusNode,
            //       onFocusChange: (bool hasFocus) {
            //         setState(() {
            //           // Handle focus change if needed
            //         });
            //       },
            //       child: Row(
            //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //         children: [
            //           const Text(
            //             'Entertainment',
            //             style: TextStyle(
            //               fontSize: 20,
            //               color: AppColors.hintColor,
            //             ),
            //           ),
            //           InkWell(
            //             onTap: () {
            //               Navigator.push(
            //                 context,
            //                 MaterialPageRoute(
            //                   builder: (context) => EntertainmentScreen(),
            //                 ),
            //               );
            //             },
            //             child: Text(
            //               'View All',
            //               style: TextStyle(
            //                 fontSize: 20,
            //                 color: _entertainmentFocusNode.hasFocus
            //                     ? AppColors.highlightColor
            //                     : AppColors.hintColor,
            //               ),
            //             ),
            //           ),
            //         ],
            //       ),
            //     ),
            //   ),
            // ),
            // SizedBox(
            //   height: 180,
            //   child: EntertainmentSubScreen(),
            // ),
            // const Divider(
            //   color:AppColors.primaryColor,
            //   height: 20,
            //   thickness: 2,
            // ),
            // // Religious Section
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            //   child: Center(
            //     child: Focus(
            //       focusNode: _religiousFocusNode,
            //       onFocusChange: (bool hasFocus) {
            //         setState(() {
            //           // Handle focus change if needed
            //         });
            //       },
            //       child: Row(
            //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //         children: [
            //           const Text(
            //             'Religious',
            //             style: TextStyle(
            //               fontSize: 20,
            //               color: AppColors.hintColor,
            //             ),
            //           ),
            //           InkWell(
            //             onTap: () {
            //               Navigator.push(
            //                 context,
            //                 MaterialPageRoute(
            //                   builder: (context) => ReligiousScreen(),
            //                 ),
            //               );
            //             },
            //             child: Text(
            //               'View All',
            //               style: TextStyle(
            //                 fontSize: 20,
            //                 color: _religiousFocusNode.hasFocus
            //                     ? AppColors.highlightColor
            //                     : AppColors.hintColor,
            //               ),
            //             ),
            //           ),
            //         ],
            //       ),
            //     ),
            //   ),
            // ),
            // SizedBox(
            //   height: 180,
            //   child: ReligiousSubScreen(),
            // ),
            // Loader for pagination
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

