// import 'dart:convert';
// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:http/http.dart' as https;

// import 'package:mobi_tv_entertainment/live_sub_screen/all_channel.dart';
// import 'package:mobi_tv_entertainment/live_sub_screen/entertainment_screen.dart';
// import 'package:mobi_tv_entertainment/live_sub_screen/news_screen.dart';
// import 'package:mobi_tv_entertainment/live_sub_screen/religious_screen.dart';
// import 'package:mobi_tv_entertainment/live_sub_screen/sports_screen.dart';
// import 'package:mobi_tv_entertainment/main.dart';


// // class MyHttpOverrides extends HttpOverrides {
// //   @override 
// //   HttpClient createHttpClient(SecurityContext? context) {
// //     return super.createHttpClient(context)
// //       ..badCertificateCallback =
// //           (X509Certificate cert, String host, int port) => true;
// //   }
// // }

// void main() {
//   // HttpOverrides.global = MyHttpOverrides();
//   runApp(LiveScreen());
// }

// // var highlightColor;
// // var cardColor;
// // var hintColor;
// // var borderColor;

// // var screenhgt;
// // var screenwdt;
// // var screensz;

// // var localImage;

// class LiveScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
// //     screenhgt = MediaQuery.of(context).size.height;
// //     screenwdt = MediaQuery.of(context).size.width;
// //     screensz = MediaQuery.of(context).size;
// //     highlightColor = Colors.blue;
// //     cardColor = Color.fromARGB(255, 8, 1, 34);
// //     hintColor = Colors.white;
// //     borderColor = Color.fromARGB(255, 247, 6, 118);
// //     localImage = Image.asset('assets/logo.png');

//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       // initialRoute: '/',
//       // routes: {
//       //   '/': (context) => AllCannel(),
//       //   '/news': (context) => NewsScreen(),
//       //   '/entertainment': (context) => EntertainmentScreen(),
//       //   '/sports': (context) => SportsScreen(),
//       //   '/religious': (context) => ReligiousScreen(),
//       // },
//       home: MyHomePage(),
//     );
//   }
// }

// class MyHomePage extends StatefulWidget {
//   @override
//   _MyHomePageState createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   int _selectedPage = 0;
//   late PageController _pageController;
//   bool _tvenableAll = false; // Track tvenableAll status

//   @override
//   void initState() {
//     super.initState();
//     _pageController = PageController(initialPage: _selectedPage);
//     _fetchTvenableAllStatus(); // Fetch tvenableAll status
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

//   @override
//   Widget build(BuildContext context) {
//     List<Widget> pages = [
//       AllCannel(),
//       // if (_tvenableAll)
//        NewsScreen(), // Conditionally include SearchScreen
//       EntertainmentScreen(),
//       // if (_tvenableAll)
//        SportsScreen(), // Conditionally include VOD
//       ReligiousScreen(),
//     ];

//     return Scaffold(
//       body: Row(
//         children: <Widget>[
//           NavigationSidebar(
//             selectedPage: _selectedPage,
//             onPageSelected: _onPageSelected,
//             tvenableAll: _tvenableAll, // Pass _tvenableAll
//           ),
//           Expanded(
//             child: PageView(
//               controller: _pageController,
//               onPageChanged: (index) {
//                 setState(() {
//                   _selectedPage = index;
//                 });
//               },
//               children: pages,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class NavigationSidebar extends StatefulWidget {
//   final int selectedPage;
//   final ValueChanged<int> onPageSelected;
//   final bool tvenableAll; // Add this line to accept the parameter

//   const NavigationSidebar({
//     required this.selectedPage,
//     required this.onPageSelected,
//     required this.tvenableAll, // Add this line
//   });

//   @override
//   _NavigationSidebarState createState() => _NavigationSidebarState();
// }

// class _NavigationSidebarState extends State<NavigationSidebar> {
//   late List<FocusNode> _focusNodes;

//   @override
//   void initState() {
//     super.initState();
//     _focusNodes = List.generate(5, (index) => FocusNode());
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       FocusScope.of(context).requestFocus(_focusNodes[0]);
//     });
//   }

//   @override
//   void dispose() {
//     for (var node in _focusNodes) {
//       node.dispose();
//     }
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return 
//     Container(
//       // width: MediaQuery.of(context).size.width * 0.24, // Adjust percentage as needed
//       height: MediaQuery.of(context).size.height *0.2,
//       decoration: BoxDecoration(
//         color: hintColor,
//       ),
//       child: Row(
//         children: <Widget>[
//           Container(
//             width: screenwdt,
//             decoration: BoxDecoration(
//               color: hintColor,
//             ),
//             padding: const EdgeInsets.all(20.0),
//             child: ClipRRect(
//               child: Image.asset('assets/logo.png',
//                 fit: BoxFit.cover,
//                 width: 50,
//               ),
//             ),
//           ),
//           Expanded(
//             child: Padding(
//               padding: const EdgeInsets.only(left:8.0),
//               child: ListView(
//                 scrollDirection: Axis.horizontal,
//                 children: <Widget>[
//                   _buildNavigationItem(
//                     Icons.home,
//                     'HOME',
//                     0,
//                     _focusNodes[0],
//                   ),
//                   if (widget.tvenableAll) // Conditionally show Search option
//                     _buildNavigationItem(
//                       Icons.search,
//                       'SEARCH',
//                       1,
//                       _focusNodes[1],
//                     ),
//                   _buildNavigationItem(
//                     Icons.tv,
//                     'LIVE TV',
//                     2,
//                     _focusNodes[2],
//                   ),
//                   if (widget.tvenableAll) // Conditionally show VOD option
//                     _buildNavigationItem(
//                       Icons.video_camera_front,
//                       'VOD',
//                       3,
//                       _focusNodes[3],
//                     ),
//                   _buildNavigationItem(
//                     Icons.category,
//                     'CATEGORY',
//                     4,
//                     _focusNodes[4],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildNavigationItem(
//       IconData iconData, String title, int index, FocusNode focusNode) {
//     bool isSelected = widget.selectedPage == index;
//     return Focus(
//       focusNode: focusNode,
//       onFocusChange: (hasFocus) {
//         if (hasFocus) {
//           setState(() {}); // Trigger rebuild to update UI when focused
//         }
//       },
//       onKeyEvent: (node, event) {
//         if (HardwareKeyboard.instance
//                 .isLogicalKeyPressed(LogicalKeyboardKey.select) ||
//             HardwareKeyboard.instance
//                 .isLogicalKeyPressed(LogicalKeyboardKey.enter)) {
//           widget.onPageSelected(index);
//           return KeyEventResult.handled;
//         }
//         return KeyEventResult.ignored;
//       },
//       child: GestureDetector(
//         onTap: () {
//           widget.onPageSelected(index);
//           focusNode.requestFocus();
//         },
//         child: Center(
//           child: AnimatedContainer(
//             duration: const Duration(milliseconds: 250),
//             color: hintColor,
//             child: ListTile(
//               leading: Icon(
//                 iconData,
//                 color: focusNode.hasFocus
//                     ? Color.fromARGB(255, 247, 6, 118)
//                     : Color.fromARGB(255, 20, 27, 122),
//                 size: isSelected ? 23 : 20,
//               ),
//               title: Text(
//                 title,
//                 style: TextStyle(
//                   color: focusNode.hasFocus
//                       ? Color.fromARGB(255, 247, 6, 118)
//                       : Color.fromARGB(255, 20, 27, 122),
//                   fontSize: isSelected ? 25 : 20,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }



