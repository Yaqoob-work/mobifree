import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobi_tv_entertainment/home_sub_screen/home_category.dart';
import 'package:mobi_tv_entertainment/screens/home_screen.dart';
import 'package:mobi_tv_entertainment/screens/vod.dart';
import 'package:mobi_tv_entertainment/screens/search_screen.dart';
import 'package:mobi_tv_entertainment/screens/live_screen.dart';
import 'package:mobi_tv_entertainment/screens/splash_screen.dart';
import 'dart:io';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  HttpOverrides.global = MyHttpOverrides();
  runApp(MyApp());
}

var primaryColor;
var highlightColor;
var cardColor;
var hintColor;
var borderColor;

var screenhgt;
var screenwdt;
var screensz;

var localImage;

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    screenhgt = MediaQuery.of(context).size.height;
    screenwdt = MediaQuery.of(context).size.height;
    screensz = MediaQuery.of(context).size;
    primaryColor = Color.fromARGB(255, 248, 8, 8);
    highlightColor = Colors.blue;
    cardColor = Color.fromARGB(255, 8, 1, 34);
    hintColor = Colors.white;
    borderColor = Color.fromARGB(255, 247, 6, 118);
    localImage = Image.asset('assets/logo.png');

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // title: 'Flutter Side Navigation Bar',

      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/myhome': (context) => MyHomePage(),
        '/category': (context) => HomeCategory(),
        '/search': (context) => SearchScreen(),
        '/vod': (context) => VOD(),
        '/live': (context) => LiveScreen(),
      },
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
              children: <Widget>[
                HomeScreen(),
                SearchScreen(),
                LiveScreen(),
                VOD(),
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
    _focusNodes = List.generate(5, (index) => FocusNode());
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
      width: MediaQuery.of(context).size.width *
          0.25, // Adjust percentage as needed
      decoration: BoxDecoration(
        color: hintColor,
      ),
      child: Column(
        children: <Widget>[
          Container(
            width: screenwdt ,
            height: screenhgt * 0.3,
            decoration: BoxDecoration(
              color: hintColor,
            ),
            padding: const EdgeInsets.all(20.0),
            child: ClipRRect(
              child: Image.asset('assets/logo.png',
              //  width: screenwdt * 0.5,
              //  height:screenhgt * 0.3,
              fit: BoxFit.cover,
               ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left:8.0),
              child: ListView(
                children: <Widget>[
                  _buildNavigationItem(
                    Icons.home,
                    'HOME',
                    0,
                    _focusNodes[0],
                  ),
                  _buildNavigationItem(
                    Icons.search,
                    'SEARCH',
                    1,
                    _focusNodes[1],
                  ),
                  _buildNavigationItem(
                    Icons.tv,
                    'LIVE TV',
                    2,
                    _focusNodes[2],
                  ),
                  _buildNavigationItem(
                    Icons.video_camera_front,
                    'VOD',
                    3,
                    _focusNodes[3],
                  ),
                  // _buildNavigationItem(
                  //   Icons.network_wifi_rounded,
                  //   'NETWORK',
                  //   4,
                  //   _focusNodes[4],
                  // ),
                  _buildNavigationItem(
                    Icons.category,
                    'CATEGORY',
                    4,
                    _focusNodes[4],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationItem(
      IconData iconData, String title, int index, FocusNode focusNode) {
    bool isSelected = widget.selectedPage == index;
    return Focus(
      focusNode: focusNode,
      onFocusChange: (hasFocus) {
        if (hasFocus) {
          setState(() {}); // Trigger rebuild to update UI when focused
        }
      },
      onKeyEvent: (node, event) {
        if (HardwareKeyboard.instance
                .isLogicalKeyPressed(LogicalKeyboardKey.select) ||
            HardwareKeyboard.instance
                .isLogicalKeyPressed(LogicalKeyboardKey.enter)) {
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
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            color: hintColor,
            child: ListTile(
              leading: Icon(
                iconData,
                color: focusNode.hasFocus
                    ? Color.fromARGB(255, 247, 6, 118)
                    : Color.fromARGB(255, 20, 27, 122),
                size: isSelected ? 23 : 20,
              ),
              title: Text(
                title,
                style: TextStyle(
                  color: focusNode.hasFocus
                      ? Color.fromARGB(255, 247, 6, 118)
                      : Color.fromARGB(255, 20, 27, 122),
                  fontSize: isSelected ? 25 : 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
