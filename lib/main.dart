import 'dart:convert';
import 'dart:io';
import 'package:mobi_tv_entertainment/menu_screens/home_screen.dart';
import 'package:mobi_tv_entertainment/menu_screens/notification_screen.dart';
import 'package:mobi_tv_entertainment/menu_screens/search_screen.dart';
import 'package:mobi_tv_entertainment/menu_screens/splash_screen.dart';
import 'package:mobi_tv_entertainment/menu_screens/vod.dart';
import 'package:http/http.dart' as https;
import 'package:flutter/material.dart';
import 'menu/top_navigation_bar.dart';
import 'menu_screens/live_screen.dart';

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
var nametextsz;
var menutextsz;
var Headingtextsz;

var localImage;

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    screenhgt = MediaQuery.of(context).size.height;
    screenwdt = MediaQuery.of(context).size.width;
    screensz = MediaQuery.of(context).size;
    nametextsz = MediaQuery.of(context).size.width / 60.0;
    menutextsz = MediaQuery.of(context).size.width / 70;
    Headingtextsz = MediaQuery.of(context).size.width / 50 ;
    highlightColor = Colors.blue;
    cardColor = Color.fromARGB(255, 8, 1, 34);
    hintColor = Colors.white;
    borderColor = Color.fromARGB(255, 247, 6, 118);
    localImage = Image.asset('assets/logo.png' ,fit: BoxFit.fill,);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        // '/': (context) => SplashScreen(),
        '/notification': (context) => NotificationScreen(),
        '/category': (context) => HomeScreen(),
        '/search': (context) => SearchScreen(),
        '/vod': (context) => VOD(),
        '/': (context) => MyHome(),
        '/live': (context) => LiveScreen(),
        
      },
    );
  }
}



class MyHome extends StatefulWidget {
  @override
  _MyHomeState createState() => _MyHomeState();
}

class _MyHomeState extends State<MyHome> {
  int _selectedPage = 0;
  late PageController _pageController;
  bool _tvenableAll = false; // Track tvenableAll status

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedPage);
    _fetchTvenableAllStatus(); // Fetch tvenableAll status
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

  Future<void> _fetchTvenableAllStatus() async {
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
      HomeScreen(),
      VOD(),
      // VOD(),
      LiveScreen(),
      SearchScreen(),
      // NotificationScreen(),
      // ReligiousScreen(),
      // EntertainmentScreen(),
    ];

    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            TopNavigationBar(
              selectedPage: _selectedPage,
              onPageSelected: _onPageSelected,
              tvenableAll: _tvenableAll,
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
            // Positioned(
            //   left: 0,
            //   right: 0,
            //   top: 0,
            //   child:
        
            // ),
          ],
        ),
      ),
    );
  }
}



// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:mobi_tv_entertainment/menu_screens/home_screen.dart';
// import 'package:mobi_tv_entertainment/menu_screens/notification_screen.dart';
// import 'package:mobi_tv_entertainment/menu_screens/search_screen.dart';
// import 'package:mobi_tv_entertainment/menu_screens/vod.dart';
// import 'package:mobi_tv_entertainment/menu_screens/splash_screen.dart';
// import 'package:http/http.dart' as https;
// import 'menu/top_navigation_bar.dart';
// import 'menu_screens/live_screen.dart';
// import 'package:package_info_plus/package_info_plus.dart';
// import 'package:url_launcher/url_launcher.dart';

// class MyHttpOverrides extends HttpOverrides {
//   @override
//   HttpClient createHttpClient(SecurityContext? context) {
//     return super.createHttpClient(context)
//       ..badCertificateCallback =
//           (X509Certificate cert, String host, int port) => true;
//   }
// }

// void main() {
//   HttpOverrides.global = MyHttpOverrides();
//   runApp(MyApp());
// }

// var highlightColor;
// var cardColor;
// var hintColor;
// var borderColor;

// var screenhgt;
// var screenwdt;
// var screensz;
// var nametextsz;
// var menutextsz;
// var Headingtextsz;

// var localImage;

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     screenhgt = MediaQuery.of(context).size.height;
//     screenwdt = MediaQuery.of(context).size.width;
//     screensz = MediaQuery.of(context).size;
//     nametextsz = MediaQuery.of(context).size.width / 60.0;
//     menutextsz = MediaQuery.of(context).size.width / 70;
//     Headingtextsz = MediaQuery.of(context).size.width / 50;
//     highlightColor = Colors.blue;
//     cardColor = Color.fromARGB(255, 8, 1, 34);
//     hintColor = Colors.white;
//     borderColor = Color.fromARGB(255, 247, 6, 118);
//     localImage = Image.asset(
//       'assets/logo.png',
//       fit: BoxFit.fill,
//     );

//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       initialRoute: '/',
//       routes: {
//         '/notification': (context) => NotificationScreen(),
//         '/category': (context) => HomeScreen(),
//         '/search': (context) => SearchScreen(),
//         '/vod': (context) => VOD(),
//         '/': (context) => MyHome(),
//         '/live': (context) => LiveScreen(),
//       },
//     );
//   }
// }

// class MyHome extends StatefulWidget {
//   @override
//   _MyHomeState createState() => _MyHomeState();
// }

// class _MyHomeState extends State<MyHome> {
//   int _selectedPage = 0;
//   late PageController _pageController;
//   bool _tvenableAll = false; // Track tvenableAll status

//   @override
//   void initState() {
//     super.initState();
//     _pageController = PageController(initialPage: _selectedPage);
//     _fetchTvenableAllStatus();
//     _checkForUpdate(); // Check for updates during initialization
//   }

//   @override
//   void dispose() {
//     _pageController.dispose();
//     super.dispose();
//   }

//   void _onPageSelected(int index) {
//     setState(() {
//       _selectedPage = index;
//     });
//     _pageController.jumpToPage(index);
//   }

//   Future<void> _fetchTvenableAllStatus() async {
//     try {
//       final response = await https.get(
//         Uri.parse('https://api.ekomflix.com/android/getSettings'),
//         headers: {
//           'x-api-key': 'vLQTuPZUxktl5mVW',
//         },
//       );

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         setState(() {
//           _tvenableAll = data['tvenableAll'] == 1;
//         });
//       } else {
//         print('Failed to load settings');
//       }
//     } catch (e) {
//       print('Error: $e');
//     }
//   }

//   // Function to check for app updates
//   Future<void> _checkForUpdate() async {
//     try {
//       final response = await https.get(
//         Uri.parse('https://api.ekomflix.com/android/getSettings'),
//         headers: {
//           'x-api-key': 'vLQTuPZUxktl5mVW',
//         },
//       );

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         String latestVersion = data['version'];
//         // String apkUrl = data['apkUrl'];
//         String apkUrl = 
//         'https://play.google.com/store/apps/details?id=com.ekamflixtv.cti';
//         String releaseNotes = data['releaseNotes'];

//         // Get the current app version
//         PackageInfo packageInfo = await PackageInfo.fromPlatform();
//         String currentVersion = packageInfo.version;

//         // If the latest version is different, show the update dialog
//         if (latestVersion != currentVersion) {
//           _showUpdateDialog(
//             apkUrl, 
//             releaseNotes);
//         }
//       } else {
//         print('Failed to check for update');
//       }
//     } catch (e) {
//       print('Error: $e');
//     }
//   }

//   void _showUpdateDialog(String apkUrl, String releaseNotes) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text('New Update Available'),
//           content: Text('Release Notes:\n$releaseNotes'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(),
//               child: Text('Later'),
//             ),
//             TextButton(
//               onPressed: () {
//                 _launchURL(apkUrl);
//               },
//               child: Text('Update Now'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Future<void> _launchURL(String url) async {
//     if (await canLaunch(url)) {
//       await launch(url);
//     } else {
//       throw 'Could not launch $url';
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     List<Widget> pages = [
//       HomeScreen(),
//       VOD(),
//       VOD(),
//       LiveScreen(),
//       SearchScreen(),
//       NotificationScreen(),
//     ];

//     return SafeArea(
//       child: Scaffold(
//         body: Column(
//           children: [
//             TopNavigationBar(
//               selectedPage: _selectedPage,
//               onPageSelected: _onPageSelected,
//               tvenableAll: _tvenableAll,
//             ),
//             Expanded(
//               child: PageView(
//                 controller: _pageController,
//                 onPageChanged: (index) {
//                   setState(() {
//                     _selectedPage = index;
//                   });
//                 },
//                 children: pages,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
