import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as https;
import 'package:mobi_tv_entertainment/home_sub_screen/home_category.dart';
import 'package:mobi_tv_entertainment/screens/home_screen.dart';
import 'package:mobi_tv_entertainment/screens/splash_screen.dart';
import 'package:mobi_tv_entertainment/screens/vod.dart';
import 'package:mobi_tv_entertainment/screens/search_screen.dart';
import 'package:mobi_tv_entertainment/screens/live_screen.dart';

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

var highlightColor;
var cardColor;
var hintColor;
var borderColor;
var screenhgt;
var screenwdt;
var screensz;
var localImage;

Future<int> fetchtvenableAll() async {
  final response = await https.get(
    Uri.parse('https://api.ekomflix.com/android/getSettings'),
    headers: {
      'x-api-key': 'vLQTuPZUxktl5mVW',
    },
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['tvenableAll'];
  } else {
    throw Exception('Failed to load settings');
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    screenhgt = MediaQuery.of(context).size.height;
    screenwdt = MediaQuery.of(context).size.width;
    screensz = MediaQuery.of(context).size;
    highlightColor = Colors.blue;
    cardColor = Color.fromARGB(255, 8, 1, 34);
    hintColor = Colors.white;
    borderColor = Color.fromARGB(255, 247, 6, 118);
    localImage = Image.asset('assets/logo.png');

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/home': (context) => FutureBuilder<int>(
          future: fetchtvenableAll(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(body: Center(child: CircularProgressIndicator()));
            } else if (snapshot.hasError) {
              return Scaffold(body: Center(child: Text('Error: ${snapshot.error}')));
            } else if (snapshot.hasData) {
              final tvenableAll = snapshot.data ?? 0;
              return MyHomePage(
                enableVOD: tvenableAll == 1,
                enableSearch: true,
              );
            } else {
              return Scaffold(body: Center(child: Text('No Data')));
            }
          },
        ),
      },
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/search':
            return MaterialPageRoute(builder: (_) => SearchScreen());
          case '/live':
            return MaterialPageRoute(builder: (_) => LiveScreen());
          case '/vod':
            return MaterialPageRoute(builder: (_) => VOD());
          case '/category':
            return MaterialPageRoute(builder: (_) => HomeCategory());
          default:
            return null;
        }
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  final bool enableVOD;
  final bool enableSearch;

  MyHomePage({required this.enableVOD, required this.enableSearch});

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
            enableVOD: widget.enableVOD,
            enableSearch: widget.enableSearch,
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
                if (widget.enableSearch) SearchScreen(),
                LiveScreen(),
                if (widget.enableVOD) VOD(),
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
  final bool enableVOD;
  final bool enableSearch;

  const NavigationSidebar({
    required this.selectedPage,
    required this.onPageSelected,
    required this.enableVOD,
    required this.enableSearch,
  });

  @override
  _NavigationSidebarState createState() => _NavigationSidebarState();
}

class _NavigationSidebarState extends State<NavigationSidebar> {
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(
      widget.enableVOD
          ? (widget.enableSearch ? 5 : 4)
          : (widget.enableSearch ? 4 : 3),
      (index) => FocusNode(),
    );
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
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isCompact = constraints.maxWidth < 500;

        return Container(
          width: isCompact ? 80 : MediaQuery.of(context).size.width * 0.24,
          decoration: BoxDecoration(
            color: hintColor,
          ),
          child: Column(
            children: <Widget>[
              Container(
                width:
                    isCompact ? 80 : MediaQuery.of(context).size.width * 0.24,
                padding: const EdgeInsets.all(20.0),
                child: ClipRRect(
                  child: Image.asset(
                    'assets/logo.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: ListView(
                    children: <Widget>[
                      _buildNavigationItem(
                        Icons.home,
                        'HOME',
                        0,
                        _focusNodes[0],
                        isCompact,
                      ),
                      if (widget.enableSearch)
                        _buildNavigationItem(
                          Icons.search,
                          'SEARCH',
                          1,
                          _focusNodes[1],
                          isCompact,
                        ),
                      _buildNavigationItem(
                        Icons.tv,
                        'LIVE TV',
                        widget.enableSearch ? 2 : 1,
                        _focusNodes[widget.enableSearch ? 2 : 1],
                        isCompact,
                      ),
                      if (widget.enableVOD)
                        _buildNavigationItem(
                          Icons.video_camera_front,
                          'VOD',
                          widget.enableSearch ? 3 : 2,
                          _focusNodes[widget.enableSearch ? 3 : 2],
                          isCompact,
                        ),
                      _buildNavigationItem(
                        Icons.category,
                        'CATEGORY',
                        widget.enableVOD
                            ? (widget.enableSearch ? 4 : 3)
                            : (widget.enableSearch ? 3 : 2),
                        _focusNodes[widget.enableVOD
                            ? (widget.enableSearch ? 4 : 3)
                            : (widget.enableSearch ? 3 : 2)],
                        isCompact,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  
  Widget _buildNavigationItem(IconData iconData, String title, int index,
      FocusNode focusNode, bool isCompact) {
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
                size: isSelected ? 30 : 20,
              ),
              title: isCompact
                  ? null
                  : Text(
                      title,
                      style: TextStyle(
                        color: focusNode.hasFocus
                            ? Color.fromARGB(255, 247, 6, 118)
                            : Color.fromARGB(255, 20, 27, 122),
                        fontSize: isSelected ? 18 : 16,
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
