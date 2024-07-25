

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobi_tv_entertainment/home_sub_screen/home_category.dart';
import 'package:mobi_tv_entertainment/screens/home_screen.dart';
import 'package:mobi_tv_entertainment/screens/network.dart';
import 'package:mobi_tv_entertainment/screens/search_screen.dart';
import 'package:mobi_tv_entertainment/screens/live_screen.dart';
import 'package:mobi_tv_entertainment/screens/v_o_d.dart';


void main() {
  runApp(MyApp());
}
class AppColors {
  static const Color primaryColor = Color.fromARGB(255, 247, 3, 3);
  static const Color highlightColor = Colors.blue;
  static const Color cardColor = Colors.black;
  static const Color hintColor = Colors.white;
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Side Navigation Bar',
      theme: ThemeData(
        primaryColor: AppColors.primaryColor,
        cardColor:AppColors.cardColor,
        highlightColor: AppColors.highlightColor,
        hintColor: AppColors.hintColor,
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue),
      ),
   initialRoute: '/',
      routes: {
        '/': (context) => MyHomePage(),
        // '/videoPlayer': (context) => VideoPlayerScreen(),
        '/category': (context) => HomeCategory(),
        '/search': (context) => SearchScreen(),
        '/vod': (context) => VOD(),
        '/network': (context) => Network(),
      },
      // home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedPage = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedPage);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: <Widget>[
          NavigationSidebar(
            selectedPage: _selectedPage,
            onPageSelected: _onPageSelected,
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _selectedPage = index;
                });
              },
              children: 
              <Widget>
              [
                 HomeScreen(),
                SearchScreen(),
                LiveScreen(),
                VOD(),
                Network(),
                HomeCategory(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NavigationSidebar extends StatefulWidget {
  final int selectedPage;
  final ValueChanged<int> onPageSelected;

  const NavigationSidebar({
    required this.selectedPage,
    required this.onPageSelected,
  });

  @override
  _NavigationSidebarState createState() => _NavigationSidebarState();
}

class _NavigationSidebarState extends State<NavigationSidebar> {
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(6, (index) => FocusNode());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNodes[0]);
    });
  }

  @override
  void dispose() {
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.19, // Adjust percentage as needed
      // color: const Color.fromARGB(255, 136, 51, 122),
       decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Colors.red,Colors.blue ],
      stops: [0.0, 1.0],
      tileMode: TileMode.clamp,
    ),),
      child: Column(
        children: <Widget>[
          Container(
            // color: Colors.white,
            decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Colors.red,Colors.blue],
      stops: [0.0, 1.0],
      tileMode: TileMode.clamp,
    ),),
            padding: const EdgeInsets.all(20.0),
            child: ClipRRect(
              // borderRadius: BorderRadius.circular(40),
              child: Image.asset('assets/logo.png', width: MediaQuery.of(context).size.width * 0.5),
            ),
          ),
          Expanded(
            child: ListView(
              children: <Widget>[
                _buildNavigationItem(
                  Icons.home,
                  'Home',
                  0,
                  _focusNodes[0],
                ),
                _buildNavigationItem(
                  Icons.search,
                  'Search',
                  1,
                  _focusNodes[1],
                ),
                _buildNavigationItem(
                  Icons.tv,
                  'Live TV',
                  2,
                  _focusNodes[2],
                ),
                
                _buildNavigationItem(
                  Icons.movie,
                  'vod',
                  3,
                  _focusNodes[3],
                ),
                _buildNavigationItem(
                  Icons.network_wifi_rounded,
                  'Network',
                  4,
                  _focusNodes[4],
                ),
                _buildNavigationItem(
                  Icons.category,
                  'Category',
                  5,
                  _focusNodes[5],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationItem(IconData iconData, String title, int index, FocusNode focusNode) {
    bool isSelected = widget.selectedPage == index;
    return Focus(
      focusNode: focusNode,
      onFocusChange: (hasFocus) {
        if (hasFocus) {
          setState(() {}); // Trigger rebuild to update UI when focused
        }
      },
      onKey: (node, event) {
        if (event.isKeyPressed(LogicalKeyboardKey.select) || event.isKeyPressed(LogicalKeyboardKey.enter)) {
          widget.onPageSelected(index);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: () {
          widget.onPageSelected(index);
          focusNode.requestFocus();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          // color: isSelected ? Colors.black : const Color.fromARGB(255, 136, 51, 122),
          child: ListTile(
            leading: Icon(
              iconData,
              color: focusNode.hasFocus   ? Colors.yellow :isSelected?AppColors.highlightColor:AppColors.hintColor,
              size:focusNode.hasFocus || isSelected ? 30:25,
            ),
            title: Text(
              title,
              style: TextStyle(
                color: focusNode.hasFocus   ? Colors.yellow :isSelected?AppColors.highlightColor:AppColors.hintColor ,
                fontSize: focusNode.hasFocus || isSelected ?22:18,
              ),
            ),
          ),
        ),
      ),
    );
  }
}