
// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:open_filex/open_filex.dart';
// import 'package:package_info_plus/package_info_plus.dart';
// import 'package:http/http.dart' as https;
// import 'package:path_provider/path_provider.dart';
// import 'menu/top_navigation_bar.dart';
// import 'menu_screens/home_sub_screen/sub_vod.dart';
// import 'menu_screens/live_screen.dart';
// import 'menu_screens/home_screen.dart';
// import 'menu_screens/notification_screen.dart';
// import 'menu_screens/search_screen.dart';
// import 'widgets/small_widgets/loading_indicator.dart';

// // Global navigator key
// final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
//     highlightColor = Colors.blue;
//     cardColor = const Color.fromARGB(255, 8, 1, 34);
//     hintColor = Colors.white;
//     borderColor = const Color.fromARGB(255, 247, 6, 118);
//     localImage = Image.asset(
//       'assets/logo.png',
//       fit: BoxFit.fill,
//     );

//     return MaterialApp(
//       navigatorKey: navigatorKey,
//       debugShowCheckedModeBanner: false,
//       initialRoute: '/',
//       routes: {
//         '/': (context) => MyHome(),
//         '/notification': (context) => NotificationScreen(),
//         '/category': (context) => HomeScreen(),
//         '/search': (context) => SearchScreen(),
//         '/vod': (context) => VOD(),
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
//   bool _tvenableAll = false;
//   String _currentVersion = "";
//   final ApkUpdater _apkUpdater = ApkUpdater();
//   bool _isLoading = true;  // Loading state variable


//   @override
//   void initState() {
//     super.initState();
//     _pageController = PageController(initialPage: _selectedPage);
//     _getAppVersion();
//     _showHomePageFirst();  // Show Home page first
//   }

//   @override
//   void dispose() {
//     _pageController.dispose();
//     super.dispose();
//   }

//   Future<void> _getAppVersion() async {
//     PackageInfo packageInfo = await PackageInfo.fromPlatform();
//     if (mounted) {
//       setState(() {
//         _currentVersion = packageInfo.version;
//       });
//     }
//   }

//   // Show Home page first and after a delay, check for update
//   Future<void> _showHomePageFirst() async {
//     // Show home page first and delay the update check
//     // await Future.delayed(Duration(seconds: 3));  // 3 second delay before checking for update

//     _fetchTvenableAllStatus();  // Check for update after delay
//   }

// //   Future<void> _fetchTvenableAllStatus() async {
// //   try {
// //     final response = await https.get(
// //       Uri.parse('https://api.ekomflix.com/android/getSettings'),
// //       headers: {
// //         'x-api-key': 'vLQTuPZUxktl5mVW',
// //       },
// //     );

// //     if (response.statusCode == 200) {
// //       final data = jsonDecode(response.body);
// //       String serverVersion = data['version'];
// //       String releaseNotes = data['releaseNotes']; // Extract releaseNotes

// //       print('Current Version: $_currentVersion');
// //       print('Server Version: $serverVersion');

// //       if (_isVersionNewer(serverVersion, _currentVersion)) {
// //         // Delay the navigation to ensure context is available
// //         WidgetsBinding.instance.addPostFrameCallback((_) {
// //           String apkUrl = data['apkUrl'];
// //           Navigator.pushReplacement(
// //             context,
// //             MaterialPageRoute(
// //               builder: (context) => UpdatePage(
// //                 apkUrl: apkUrl,
// //                 serverVersion: serverVersion,
// //                 releaseNotes: releaseNotes, // Pass releaseNotes to UpdatePage
// //               ),
// //             ),
// //           );
// //         });
// //       } else {
// //         if (mounted) {
// //           setState(() {
// //             _tvenableAll = data['tvenableAll'] == 1;
// //           });
// //         }
// //       }
// //     } else {
// //       print('Failed to load settings');
// //     }
// //   } catch (e) {
// //     print('Error: $e');
// //   }
// // }


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
//         String serverVersion = data['version'];
//       String releaseNotes = data['releaseNotes']; // Extract releaseNotes


//         // print('Current Version: $_currentVersion');
//         // print('Server Version: $serverVersion');

//         if (_isVersionNewer(serverVersion, _currentVersion)) {
//           String apkUrl = data['apkUrl'];

//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (context) => UpdatePage(
//                 apkUrl: apkUrl,
//                 serverVersion: serverVersion,
//                 releaseNotes: releaseNotes, // Pass releaseNotes to UpdatePage
//               ),)
//           );
//         } else {
//           if (mounted) {
//             setState(() {
//               _tvenableAll = data['tvenableAll'] == 1;
//               _isLoading = false;
//             });
//           }
//         }
//       } else {
//         print('Failed to load settings');
//               _isLoading = false;

//       }
//     } catch (e) {
//       print('Error: $e');
//               _isLoading = false;

//     }
//   }


//   bool _isVersionNewer(String serverVersion, String currentVersion) {
//     List<String> serverParts = serverVersion.split('.');
//     List<String> currentParts = currentVersion.split('.');

//     int length = serverParts.length > currentParts.length
//         ? serverParts.length
//         : currentParts.length;

//     for (int i = 0; i < length; i++) {
//       int serverPart = i < serverParts.length ? int.parse(serverParts[i]) : 0;
//       int currentPart = i < currentParts.length ? int.parse(currentParts[i]) : 0;

//       if (serverPart > currentPart) {
//         return true;
//       } else if (serverPart < currentPart) {
//         return false;
//       }
//     }
//     return false;
//   }

//   void _onPageSelected(int index) {
//     if (mounted) {
//       setState(() {
//         _selectedPage = index;
//       });
//     }
//     _pageController.jumpToPage(index);
//   }




//   @override
//   Widget build(BuildContext context) {
//         if (_isLoading) {
//       return Scaffold(
//         backgroundColor: Colors.black,
//         body: Center(
//           child:LoadingIndicator(),
//         ),
//       );  // Show loading indicator while fetching data
//     }
//     List<Widget> pages = [
//       HomeScreen(),
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
//                   if (mounted) {
//                     setState(() {
//                       _selectedPage = index;
//                     });
//                   }
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

// class ApkUpdater {
//   final Dio _dio = Dio();

//   Future<void> downloadAndInstallApk(
//     String apkUrl,
//     String fileName,
//     Function(double) progressCallback,
//   ) async {
//     Directory directory = await _getDownloadPath();
//     String savePath = '${directory.path}/$fileName';
//     print("APK save path: $savePath");

//     try {
//       await _dio.download(
//         apkUrl,
//         savePath,
//         onReceiveProgress: (received, total) {
//           double progress = 0.0;
//           if (received != null && total != null && total > 0) {
//             progress = received / total;
//           }
//           progressCallback(progress);
//           // print('Download progress: ${(progress * 10).toStringAsFixed(0)}%');
//         },
//       );

//       if (await File(savePath).exists()) {
//         await _installApk(savePath);
//       } else {
//         print("APK file does not exist at $savePath");
//       }
//     } catch (e) {
//       print("Error during APK download/install: $e");
//       progressCallback(-1.0);
//     }
//   }

//   Future<void> _installApk(String filePath) async {
//     if (Platform.isAndroid) {
//       await OpenFilex.open(filePath);
//     }
//   }

//   Future<Directory> _getDownloadPath() async {
//     return await getApplicationDocumentsDirectory();
//   }
// }




// class UpdatePage extends StatefulWidget {
//   final String apkUrl;
//   final String serverVersion;
//   final String releaseNotes;

//   UpdatePage({
//     required this.apkUrl,
//     required this.serverVersion,
//     required this.releaseNotes,
//   });

//   @override
//   _UpdatePageState createState() => _UpdatePageState();
// }

// class _UpdatePageState extends State<UpdatePage> {
//   final ApkUpdater apkUpdater = ApkUpdater();

//   late FocusNode updateButtonFocusNode;
//   late FocusNode cancelButtonFocusNode;

//   FocusNode? currentFocusNode;

//   double _downloadProgress = 0.0;
//   bool _isDownloading = false;

//   Color backgroundColor = cardColor;

//   @override
//   void initState() {
//     super.initState();

//     updateButtonFocusNode = FocusNode();
//     cancelButtonFocusNode = FocusNode();

//     updateButtonFocusNode.addListener(_onFocusChange);
//     cancelButtonFocusNode.addListener(_onFocusChange);

//     currentFocusNode = updateButtonFocusNode;

//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (mounted) {
//         FocusScope.of(context).requestFocus(updateButtonFocusNode);
//       }
//     });
//   }

//   @override
//   void dispose() {
//     updateButtonFocusNode.removeListener(_onFocusChange);
//     cancelButtonFocusNode.removeListener(_onFocusChange);
//     updateButtonFocusNode.dispose();
//     cancelButtonFocusNode.dispose();
//     super.dispose();
//   }

//   void _onFocusChange() {
//     if (mounted) {
//       setState(() {
//         if (updateButtonFocusNode.hasFocus) {
//           // backgroundColor = Colors.blueGrey;
//         } else if (cancelButtonFocusNode.hasFocus) {
//           // backgroundColor = Colors.grey;
//         } else {
//           // backgroundColor = cardColor;
//         }
//       });
//     }
//   }

//   bool _handleKeyEvent(FocusNode node, RawKeyEvent event) {
//     if (event is RawKeyDownEvent) {
//       if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
//           event.logicalKey == LogicalKeyboardKey.arrowUp ||
//           event.logicalKey == LogicalKeyboardKey.arrowLeft ||
//           event.logicalKey == LogicalKeyboardKey.arrowRight) {
//         _moveFocus(event.logicalKey);
//         return true;
//       } else if (event.logicalKey == LogicalKeyboardKey.select ||
//           event.logicalKey == LogicalKeyboardKey.enter) {
//         _activateButton(node);
//         return true;
//       }
//     }
//     return false;
//   }

//   void _moveFocus(LogicalKeyboardKey key) {
//     if (mounted) {
//       setState(() {
//         if (currentFocusNode == updateButtonFocusNode) {
//           if (key == LogicalKeyboardKey.arrowRight ||
//               key == LogicalKeyboardKey.arrowDown) {
//             // currentFocusNode = cancelButtonFocusNode;
//             currentFocusNode = updateButtonFocusNode;

//           }
//         } else if (currentFocusNode == cancelButtonFocusNode) {
//           if (key == LogicalKeyboardKey.arrowLeft ||
//               key == LogicalKeyboardKey.arrowUp) {
//             currentFocusNode = updateButtonFocusNode;
//           }
//         }
//         FocusScope.of(context).requestFocus(currentFocusNode);
//       });
//     }
//   }

//   void _activateButton(FocusNode node) {
//     if (node == updateButtonFocusNode) {
//       _startUpdate();
//     } else if (node == cancelButtonFocusNode) {
//       _cancelUpdate();
//     }
//   }

//   void _startUpdate() async {
//     String fileName = 'update.apk';
//     setState(() {
//       _isDownloading = true;
//       _downloadProgress = 0.0;
//     });
//     await apkUpdater.downloadAndInstallApk(widget.apkUrl, fileName, (progress) {
//       if (mounted) {
//         setState(() {
//           _downloadProgress = progress;
//         });
//       }
//     });
//     if (mounted) {
//       setState(() {
//         _isDownloading = false;
//       });
//     }
//   }

//   void _cancelUpdate() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => MyHome()),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: cardColor ,
//       body: RawKeyboardListener(
//         focusNode: FocusNode(),
//         onKey: (event) {
//           _handleKeyEvent(currentFocusNode!, event);
//         },
//         child: Center(
//           child: SingleChildScrollView(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               crossAxisAlignment: CrossAxisAlignment.center ,
//               children: [
//                 const Text(
//                   'New Update Available',
//                   style: TextStyle(
//                     fontSize: 36,
//                     color: Colors.white,
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 Text(
//                   'Version ${widget.serverVersion}',
//                   style: const TextStyle(
//                     fontSize: 24,
//                     color: Colors.white70,
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 20.0),
//                   child: Text(
//                     widget.releaseNotes,
//                     style: const TextStyle(
//                       fontSize: 20,
//                       color: Colors.white,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                 ),
//                 const SizedBox(height: 50),
//                 if (_isDownloading)
//                   Column(
//                     children: [
//                       Row(
//                         children: [
//                           Expanded(flex:1,child:  Text('')),
//                           Expanded(flex:10,child:LinearProgressIndicator(
//                             value: _downloadProgress,
//                             backgroundColor: Colors.grey,
//                             valueColor:
//                                 const AlwaysStoppedAnimation<Color>(Colors.blue),
//                           ), ),
//                           Expanded(flex:1,child: Text('')),
                          
//                         ],
//                       ),
//                       const SizedBox(height: 10),
//                       Text(
//                         'Downloading... ${(_downloadProgress * 100).toStringAsFixed(0)}%',
//                         style: const TextStyle(
//                           fontSize: 20,
//                           color: Colors.white,
//                         ),
//                       ),
//                     ],
//                   )
//                 else
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Focus(
//                         focusNode: updateButtonFocusNode,
//                         child: GestureDetector(
//                           onTap: _startUpdate,
//                           child: Container(
//                             width: 200,
//                             height: 60,
//                             decoration: BoxDecoration(
//                               color: updateButtonFocusNode.hasFocus
//                                   ? Colors.black
//                                   : Colors.grey,
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             alignment: Alignment.center,
//                             child:  Text(
//                               'Update Now',
//                               style: TextStyle(
//                                 fontSize: 24,
//                                color:  updateButtonFocusNode.hasFocus
//                                   ? Colors.green
//                                   : Colors.black,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                       // const SizedBox(width: 30),
//                       // Focus(
//                       //   focusNode: cancelButtonFocusNode,
//                       //   child: GestureDetector(
//                       //     onTap: _cancelUpdate,
//                       //     child: Container(
//                       //       width: 200,
//                       //       height: 60,
//                       //       decoration: BoxDecoration(
//                       //         color: cancelButtonFocusNode.hasFocus
//                       //             ? Colors.black
//                       //             : Colors.grey,
//                       //         borderRadius: BorderRadius.circular(8),
//                       //       ),
//                       //       alignment: Alignment.center,
//                       //       child:  Text(
//                       //         'Cancel',
//                       //         style: TextStyle(
//                       //           fontSize: 24,
//                       //           color: cancelButtonFocusNode.hasFocus
//                       //             ? Colors.red
//                       //             : Colors.black,
//                       //         ),
//                       //       ),
//                       //     ),
//                       //   ),
//                       // ),
//                     ],
//                   ),
//               ],
//             ),
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
import 'package:mobi_tv_entertainment/menu_screens/live_screen.dart';
import 'package:http/http.dart' as https;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'menu/top_navigation_bar.dart';
import 'menu_screens/home_sub_screen/sub_vod.dart';

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

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // bool _showSplashImage = true; // Controls splash image visibility

  @override
  void initState() {
    super.initState();

    // // Show the splash image for 2 seconds
    // Timer(Duration(seconds: 3), () {
    //   setState(() {
    //     _showSplashImage = false; // Hide splash image after 2 seconds
    //   });
    // });
  }

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
      home: Stack(
        children: [
          MyHome(), // Main app content
          // if (_showSplashImage)
          //   Container(
          //     color: cardColor, // Background color for the splash screen
          //     child: Center(
          //       child: Image.asset(
          //         'assets/logo.png',
          //         fit: BoxFit.fill,
          //         width: screenwdt,
          //         height: screenhgt,
          //       ), // Path to splash ima
          //     ),
          //   ),
        ],
      ),
      routes: {
        '/notification': (context) => NotificationScreen(),
        '/mainscreen': (context) => HomeScreen(),
        '/search': (context) => SearchScreen(),
        '/vod': (context) => VOD(),
        '/live': (context) => LiveScreen(),
      },
    );
  }
}

class UpdateChecker {
  static const String LAST_UPDATE_CHECK_KEY = 'last_update_check';
  static const String FORCE_UPDATE_TIME_KEY = 'force_update_time';
  static const Duration CHECK_INTERVAL = Duration(hours: 8);

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
        final response = await https.get(
          Uri.parse('https://api.ekomflix.com/android/getSettings'),
          headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          String apiVersion = data['amazonstore_version'];
          String apkUrl = data['amazonstore_apkUrl'];
          String releaseNotes = data['amazonstore_releaseNotes'];

          int forceUpdateTime =
              DateTime.parse(data['amazonstore_forceUpdateTime'])
                  .millisecondsSinceEpoch;

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

  void _showUpdateDialog(String apkUrl, String releaseNotes,
      String currentVersion, String newVersion) {
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
            title: Center(
                child: Text('NEW UPDATE AVAILABLE',
                    style: TextStyle(color: hintColor))),
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







// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:mobi_tv_entertainment/menu_screens/home_screen.dart';
// import 'package:mobi_tv_entertainment/menu_screens/notification_screen.dart';
// import 'package:mobi_tv_entertainment/menu_screens/search_screen.dart';
// import 'package:mobi_tv_entertainment/menu_screens/live_screen.dart';
// import 'package:http/http.dart' as https;
// import 'package:package_info_plus/package_info_plus.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'menu/top_navigation_bar.dart';
// import 'menu_screens/home_sub_screen/sub_vod.dart';

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

// class MyApp extends StatefulWidget {
//   @override
//   _MyAppState createState() => _MyAppState();
// }

// class _MyAppState extends State<MyApp> {
//   // bool _showSplashImage = true; // Controls splash image visibility

//   @override
//   void initState() {
//     super.initState();

//     // // Show the splash image for 2 seconds
//     // Timer(Duration(seconds: 3), () {
//     //   setState(() {
//     //     _showSplashImage = false; // Hide splash image after 2 seconds
//     //   });
//     // });
//   }

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
//       home: Stack(
//         children: [
//           MyHome(), // Main app content
//           // if (_showSplashImage)
//           //   Container(
//           //     color: cardColor, // Background color for the splash screen
//           //     child: Center(
//           //       child: Image.asset(
//           //         'assets/logo.png',
//           //         fit: BoxFit.fill,
//           //         width: screenwdt,
//           //         height: screenhgt,
//           //       ), // Path to splash ima
//           //     ),
//           //   ),
//         ],
//       ),
//       routes: {
//         '/notification': (context) => NotificationScreen(),
//         '/mainscreen': (context) => HomeScreen(),
//         '/search': (context) => SearchScreen(),
//         '/vod': (context) => VOD(),
//         '/live': (context) => LiveScreen(),
//       },
//     );
//   }
// }

// class UpdateChecker {
//   static const String LAST_UPDATE_CHECK_KEY = 'last_update_check';
//   static const String FORCE_UPDATE_TIME_KEY = 'force_update_time';
//   static const Duration CHECK_INTERVAL = Duration(hours: 8);

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
//         final response = await https.get(
//           Uri.parse('https://api.ekomflix.com/android/getSettings'),
//           headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
//         );

//         if (response.statusCode == 200) {
//           final data = jsonDecode(response.body);

//           String apiVersion = data['playstore_version'];
//           String apkUrl = data['playstore_apkUrl'];
//           String releaseNotes = data['playstore_releaseNotes'];

//           int forceUpdateTime =
//               DateTime.parse(data['playstore_forceUpdateTime'])
//                   .millisecondsSinceEpoch;

//           PackageInfo packageInfo = await PackageInfo.fromPlatform();
//           String appVersion = packageInfo.version;

//           if (_isVersionGreater(apiVersion, appVersion)) {
//             if (forceUpdateTime > 0 && now >= forceUpdateTime) {
//               _forceUpdate = true;
//               await prefs.setInt(FORCE_UPDATE_TIME_KEY, forceUpdateTime);
//             }
//             if (!_isDialogShowing) {
//               _showUpdateDialog(apkUrl, releaseNotes, appVersion, apiVersion);
//             }
//           }
//         }
//       } catch (e) {
//         // Handle error
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

//   void _showUpdateDialog(String apkUrl, String releaseNotes,
//       String currentVersion, String newVersion) {
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
//             title: Center(
//                 child: Text('NEW UPDATE AVAILABLE',
//                     style: TextStyle(color: hintColor))),
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
//       print('Error: ');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     List<Widget> pages = [
//       HomeScreen(),
//       VOD(),
//       LiveScreen(),
//       SearchScreen(),
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




