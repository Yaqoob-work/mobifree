import 'package:flutter/material.dart';
import 'package:mobi_tv_entertainment/home_sub_screen/banner_slider_screen.dart';
import 'package:mobi_tv_entertainment/home_sub_screen/home_category.dart';
import 'package:mobi_tv_entertainment/home_sub_screen/live_sub_screen.dart';
import 'package:mobi_tv_entertainment/home_sub_screen/sub_network.dart';
import 'package:mobi_tv_entertainment/main.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  FocusNode _liveFocusNode = FocusNode();
  FocusNode _subNetworkNode = FocusNode();

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
    FocusNode _liveFocusNode = FocusNode();
    FocusNode _subNetworkNode = FocusNode();
    super.dispose();
  }

  Future<void> _fetchData() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });

    // Simulate network request delay
    // await Future.delayed(const Duration(seconds: 2));

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
            Container(
              height: 0,
              child: Text(''),
            ),
            // Banner Slider at the top

            Container(
              height: MediaQuery.of(context).size.height * 0.9,
              child: BannerSliderPage(),
            ),

            // Container(
            //   height: MediaQuery.of(context).size.height * 0.5,
            //   child: SubNetwork(),
            // ),

              Container(
              
                    child: Column(
                      // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Network",
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                fontSize: 20,
                                color: AppColors.hintColor,
                              ),
                            ),
                            Text('')
                          ],
                        ),
                        SizedBox(
              height: 250,
              child: SubNetwork(),
            ),
                      ],
                    ),
                  ),
              
            
            
              Container(
              
                  
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,

                          children: [
                            const Text(
                              "Live",
                              style: TextStyle(
                                fontSize: 20,
                                color: AppColors.hintColor,
                              ),
                            ),
                            Text('')
                          ],
                        ),
                         SizedBox(
              height: 250,
              child: LiveSubScreen(),
            ),
                      ],
                    ),
                  ),
                
              
            
           

            Container(
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
