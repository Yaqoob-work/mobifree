
// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:mobi_tv_entertainment/menu_screens/home_screen.dart';
// import 'package:mobi_tv_entertainment/menu_screens/notification_screen.dart';
// import 'package:mobi_tv_entertainment/menu_screens/search_screen.dart';
// import 'package:mobi_tv_entertainment/menu_screens/vod.dart';
// import 'package:mobi_tv_entertainment/menu_screens/live_screen.dart';
// import 'package:http/http.dart' as http;
// import 'package:package_info_plus/package_info_plus.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'menu/top_navigation_bar.dart';

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
//         // '/category': (context) => HomeScreen(watchNowButtonFocusNode: watchNowButtonFocusNode),
//         '/search': (context) => SearchScreen(),
//         '/vod': (context) => VOD(),
//         '/': (context) => MyHome(),
//         '/live': (context) => LiveScreen(),
//       },
//     );
//   }
// }

// class UpdateChecker {
//   static const String LAST_UPDATE_CHECK_KEY = 'last_update_check';
//   static const String FORCE_UPDATE_TIME_KEY = 'force_update_time';
//   static const Duration CHECK_INTERVAL = Duration(seconds: 30); // Changed to 30 seconds for testing

//   late BuildContext context;
//   Timer? _timer;
//   bool _forceUpdate = false;
//   bool _isDialogShowing = false;

//   UpdateChecker(this.context) {
//     _startUpdateCheckTimer();
//   }

//   void _startUpdateCheckTimer() {
//     _checkForUpdate(); // Check immediately on start
//     _timer = Timer.periodic(CHECK_INTERVAL, (timer) {
//       _checkForUpdate();
//     });
//   }

//   Future<void> _checkForUpdate() async {
//     final prefs = await SharedPreferences.getInstance();
//     final lastCheck = prefs.getInt(LAST_UPDATE_CHECK_KEY) ?? 0;
//     final now = DateTime.now().millisecondsSinceEpoch;
    

//     if (now - lastCheck >= CHECK_INTERVAL.inMilliseconds || _forceUpdate) {
//       await prefs.setInt(LAST_UPDATE_CHECK_KEY, now);

//       try {
//         final response = await http.get(
//           Uri.parse('https://api.ekomflix.com/android/getSettings'),
//           headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
//         );

//         if (response.statusCode == 200) {
//           final data = jsonDecode(response.body);
//           String apiVersion = data['playstore_version'];
//           String apkUrl = data['playstore_apkUrl'];
//           String releaseNotes = data['playstore_releaseNotes'];
          
//           // Parse the datetime string to milliseconds since epoch
//           // int forceUpdateTime = DateTime.parse(data['playstore_forceUpdateTime']).millisecondsSinceEpoch;


//           // String apiVersion = data['amazonstore_version'];
//           // String apkUrl = data['amazonstore_apkUrl'];
//           // String releaseNotes = data['amazonstore_releaseNotes'];
          
//           // // Parse the datetime string to milliseconds since epoch
//           // int forceUpdateTime = DateTime.parse(data['amazonstore_forceUpdateTime']).millisecondsSinceEpoch;

//           PackageInfo packageInfo = await PackageInfo.fromPlatform();
//           String appVersion = packageInfo.version;

//           // print('API Version: $apiVersion, App Version: $appVersion'); // Debug print

//           if (_isVersionGreater(apiVersion, appVersion)) {
//             // if (forceUpdateTime > 0 && now >= forceUpdateTime) {
//             //   _forceUpdate = true;
//             //   await prefs.setInt(FORCE_UPDATE_TIME_KEY, forceUpdateTime);
//             // }
//             if (!_isDialogShowing) {
//               _showUpdateDialog(apkUrl, releaseNotes, appVersion, apiVersion);
//             }
//           } else {
//             // print('No update needed'); // Debug print
//           }
//         }
//       } catch (e) {
//         // print('Error checking for updates: $e');
//       }
//     }
//   }

//   bool _isVersionGreater(String v1, String v2) {
//     List<int> v1Parts = v1.split('.').map(int.parse).toList();
//     List<int> v2Parts = v2.split('.').map(int.parse).toList();

//     for (int i = 0; i < v1Parts.length && i < v2Parts.length; i++) {
//       if (v1Parts[i] > v2Parts[i]) return true;
//       if (v1Parts[i] < v2Parts[i]) return false;
//     }

//     return v1Parts.length > v2Parts.length;
//   }

//   void _showUpdateDialog(String apkUrl, String releaseNotes, String currentVersion, String newVersion) {
//     _isDialogShowing = true;
//     showDialog(
//       barrierColor: Colors.black54,
//       context: context,
//       barrierDismissible: !_forceUpdate,
//       builder: (BuildContext context) {
//         return WillPopScope(
//           onWillPop: () async => !_forceUpdate,
//           child: AlertDialog(
//             backgroundColor: cardColor,
//             title: Center(child: Text('NEW UPDATE AVAILABLE', style: TextStyle(color: hintColor))),
//             // content: Column(
//             //   mainAxisSize: MainAxisSize.min,
//             //   crossAxisAlignment: CrossAxisAlignment.start,
//             //   children: [
//             //     Center(child: Text('Current Version: $currentVersion', style: TextStyle(color: hintColor))),
//             //     Center(child: Text('New Version: $newVersion', style: TextStyle(color: hintColor))),
//             //     SizedBox(height: 10),
//             //     Center(child: Text('Release Notes: $releaseNotes', style: TextStyle(color: hintColor))),
//             //   ],
//             // ),
//             actions: [
//               if (!_forceUpdate)
//                 TextButton(
//                   onPressed: () {
//                     Navigator.of(context).pop();
//                     _isDialogShowing = false;
//                   },
//                   child: Center(child: Text('Later')),
//                 ),
//               TextButton(
//                 onPressed: () {
//                   _launchURL(apkUrl);
//                 },
//                 child: Center(child: Text('Update Now')),
//               ),
//             ],
//           ),
//         );
//       },
//     ).then((_) {
//       if (_forceUpdate) {
//         // If it's a force update, show the dialog again immediately
//         _showUpdateDialog(apkUrl, releaseNotes, currentVersion, newVersion);
//       } else {
//         _isDialogShowing = false;
//       }
//     });
//   }

//   Future<void> _launchURL(String url) async {
//     if (await canLaunch(url)) {
//       await launch(url);
//     } else {
//       throw 'Could not launch $url';
//     }
//   }

//   void dispose() {
//     _timer?.cancel();
//   }
// }

// class MyHome extends StatefulWidget {
//   @override
//   _MyHomeState createState() => _MyHomeState();
// }

// class _MyHomeState extends State<MyHome> {
//   int _selectedPage = 0;
//   late PageController _pageController;
//   bool _tvenableAll = false;
//   late UpdateChecker _updateChecker;
//   FocusNode watchNowButtonFocusNode = FocusNode();
  

//   @override
//   void initState() {
//     super.initState();
//     _pageController = PageController(initialPage: _selectedPage);
//     _fetchTvenableAllStatus();
//     _updateChecker = UpdateChecker(context);
//   }

//   @override
//   void dispose() {
//     _pageController.dispose();
//     _updateChecker.dispose();
//     watchNowButtonFocusNode.dispose(); // Dispose of the FocusNode when not in use
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
//       final response = await http.get(
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

//   @override
//   Widget build(BuildContext context) {
//     List<Widget> pages = [
//       HomeScreen(watchNowButtonFocusNode: watchNowButtonFocusNode),
//       VOD(),
//       // VOD(),
//       LiveScreen(),
//       SearchScreen(),
//       // NotificationScreen(),
//     ];

//     return FocusScope(
//       autofocus: true,
//       child: SafeArea(
//         child: Scaffold(
//           body: Column(
//             children: [
//               TopNavigationBar(
//                 selectedPage: _selectedPage,
//                 onPageSelected: _onPageSelected,
//                 tvenableAll: _tvenableAll,
//                 watchNowButtonFocusNode: watchNowButtonFocusNode,
                
//               ),
//               Expanded(
//                 child: PageView(
//                   controller: _pageController,
//                   onPageChanged: (index) {
//                     setState(() {
//                       _selectedPage = index;
//                     });
//                   },
//                   children: pages,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }




import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobi_tv_entertainment/menu_screens/home_screen.dart';
import 'package:mobi_tv_entertainment/menu_screens/notification_screen.dart';
import 'package:mobi_tv_entertainment/menu_screens/search_screen.dart';
import 'package:mobi_tv_entertainment/menu_screens/vod.dart';
import 'package:mobi_tv_entertainment/menu_screens/live_screen.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'menu/top_navigation_bar.dart';

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
    Headingtextsz = MediaQuery.of(context).size.width / 50;
    highlightColor = Colors.blue;
    cardColor = Color.fromARGB(255, 8, 1, 34);
    hintColor = Colors.white;
    borderColor = Color.fromARGB(255, 247, 6, 118);
    localImage = Image.asset(
      'assets/logo.png',
      fit: BoxFit.fill,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/notification': (context) => NotificationScreen(),
        '/mainscreen': (context) => HomeScreen(),
        '/search': (context) => SearchScreen(),
        '/vod': (context) => VOD(),
        '/': (context) => MyHome(),
        '/live': (context) => LiveScreen(),
      },
    );
  }
}

class UpdateChecker {
  static const String LAST_UPDATE_CHECK_KEY = 'last_update_check';
  static const String FORCE_UPDATE_TIME_KEY = 'force_update_time';
  static const Duration CHECK_INTERVAL = Duration(hours: 8); // Changed to 30 seconds for testing

  late BuildContext context;
  Timer? _timer;
  bool _forceUpdate = false;
  bool _isDialogShowing = false;

  UpdateChecker(this.context) {
    _startUpdateCheckTimer();
  }

  void _startUpdateCheckTimer() {
    _checkForUpdate(); // Check immediately on start
    _timer = Timer.periodic(CHECK_INTERVAL, (timer) {
      _checkForUpdate();
    });
  }

  Future<void> _checkForUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheck = prefs.getInt(LAST_UPDATE_CHECK_KEY) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    

    if (now - lastCheck >= CHECK_INTERVAL.inMilliseconds || _forceUpdate) {
      await prefs.setInt(LAST_UPDATE_CHECK_KEY, now);

      try {
        final response = await http.get(
          Uri.parse('https://api.ekomflix.com/android/getSettings'),
          headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          // String apiVersion = data['playstore_version'];
          // String apkUrl = data['playstore_apkUrl'];
          // String releaseNotes = data['playstore_releaseNotes'];
          
          // // Parse the datetime string to milliseconds since epoch
          // int forceUpdateTime = DateTime.parse(data['playstore_forceUpdateTime']).millisecondsSinceEpoch;


          String apiVersion = data['amazonstore_version'];
          String apkUrl = data['amazonstore_apkUrl'];
          String releaseNotes = data['amazonstore_releaseNotes'];
          
          // Parse the datetime string to milliseconds since epoch
          int forceUpdateTime = DateTime.parse(data['amazonstore_forceUpdateTime']).millisecondsSinceEpoch;

          PackageInfo packageInfo = await PackageInfo.fromPlatform();
          String appVersion = packageInfo.version;

          if (_isVersionGreater(apiVersion, appVersion)) {
            if (forceUpdateTime > 0 && now >= forceUpdateTime) {
              _forceUpdate = true;
              await prefs.setInt(FORCE_UPDATE_TIME_KEY, forceUpdateTime);
            }
            if (!_isDialogShowing) {
              _showUpdateDialog(apkUrl, releaseNotes, appVersion, apiVersion);
            }
          }
        }
      } catch (e) {
        // Handle error
      }
    }
  }

  bool _isVersionGreater(String v1, String v2) {
    List<int> v1Parts = v1.split('.').map(int.parse).toList();
    List<int> v2Parts = v2.split('.').map(int.parse).toList();

    for (int i = 0; i < v1Parts.length && i < v2Parts.length; i++) {
      if (v1Parts[i] > v2Parts[i]) return true;
      if (v1Parts[i] < v2Parts[i]) return false;
    }

    return v1Parts.length > v2Parts.length;
  }

  void _showUpdateDialog(String apkUrl, String releaseNotes, String currentVersion, String newVersion) {
    _isDialogShowing = true;
    showDialog(
      barrierColor: Colors.black54,
      context: context,
      barrierDismissible: !_forceUpdate,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => !_forceUpdate,
          child: AlertDialog(
            backgroundColor: cardColor,
            title: Center(child: Text('NEW UPDATE AVAILABLE', style: TextStyle(color: hintColor))),
            actions: [
              if (!_forceUpdate)
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _isDialogShowing = false;
                  },
                  child: Center(child: Text('Later')),
                ),
              TextButton(
                onPressed: () {
                  _launchURL(apkUrl);
                },
                child: Center(child: Text('Update Now')),
              ),
            ],
          ),
        );
      },
    ).then((_) {
      if (_forceUpdate) {
        _showUpdateDialog(apkUrl, releaseNotes, currentVersion, newVersion);
      } else {
        _isDialogShowing = false;
      }
    });
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  void dispose() {
    _timer?.cancel();
  }
}

class MyHome extends StatefulWidget {
  @override
  _MyHomeState createState() => _MyHomeState();
}

class _MyHomeState extends State<MyHome> {
  int _selectedPage = 0;
  late PageController _pageController;
  bool _tvenableAll = false;
  late UpdateChecker _updateChecker;


  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedPage);
    _fetchTvenableAllStatus();
    _updateChecker = UpdateChecker(context);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _updateChecker.dispose();
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
      final response = await http.get(
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
      print('Error: ');
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> pages = [
      HomeScreen(),
      VOD(),
      LiveScreen(),
      SearchScreen(),
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
          ],
        ),
      ),
    );
  }
}
