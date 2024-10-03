// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import '../main.dart';

// class TopNavigationBar extends StatefulWidget {
//   final int selectedPage;
//   final ValueChanged<int> onPageSelected;
//   final bool tvenableAll;

//   const TopNavigationBar({
//     required this.selectedPage,
//     required this.onPageSelected,
//     required this.tvenableAll,
//   });

//   @override
//   _TopNavigationBarState createState() => _TopNavigationBarState();
// }

// class _TopNavigationBarState extends State<TopNavigationBar> {
//   late List<FocusNode> _focusNodes;

//   @override
//   void initState() {
//     super.initState();
//     _focusNodes = List.generate(6, (index) => FocusNode());
    
//     // Set initial focus to the first menu item
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _focusNodes[0].requestFocus();
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
//     return Container(
//       padding: EdgeInsets.fromLTRB(
//           screenwdt * 0.01, screenhgt * 0.01, screenwdt * 0.01, screenhgt * 0),
//       color: cardColor,
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: <Widget>[
//           Expanded(
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.start,
//               children: [
//                 Padding(
//                   padding: EdgeInsets.symmetric(
//                       horizontal: screenwdt * 0.1, vertical: 5),
//                   child: _buildNavigationItem('', 0, _focusNodes[0]),
//                 ),
//               ],
//             ),
//           ),
//           Expanded(
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 20),
//                   child: _buildNavigationItem('Vod', 1, _focusNodes[1]),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 20),
//                   child: _buildNavigationItem('Web Series', 2, _focusNodes[2]),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 20),
//                   child: _buildNavigationItem('Live TV', 3, _focusNodes[3]),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 20),
//                   child: _buildNavigationItem('Search', 4, _focusNodes[4]),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 20),
//                   child: _buildNavigationItem('Notification', 5, _focusNodes[5]),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildNavigationItem(String title, int index, FocusNode focusNode) {
//     return Focus(
//       focusNode: focusNode,
//       onFocusChange: (hasFocus) {
//         if (hasFocus) {
//           setState(() {});
//         }
//       },
//       onKeyEvent: (node, event) {
//         if (event is KeyDownEvent) {
//           if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
//             // Move focus to the first item if the last one is focused
//             if (index == _focusNodes.length - 1) {
//               _focusNodes[0].requestFocus();
//             } else {
//               _focusNodes[index + 1].requestFocus();
//             }
//             return KeyEventResult.handled;
//           } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
//             // Move focus to the last item if the first one is focused
//             if (index == 0) {
//               _focusNodes[_focusNodes.length - 1].requestFocus();
//             } else {
//               _focusNodes[index - 1].requestFocus();
//             }
//             return KeyEventResult.handled;
//           } else if (event.logicalKey == LogicalKeyboardKey.select ||
//               event.logicalKey == LogicalKeyboardKey.enter) {
//             widget.onPageSelected(index);
//             return KeyEventResult.handled;
//           }
//         }
//         return KeyEventResult.ignored;
//       },
//       child: GestureDetector(
//         onTap: () {
//           widget.onPageSelected(index);
//           focusNode.requestFocus();
//         },
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             Container(
//               decoration: BoxDecoration(
//                 boxShadow: focusNode.hasFocus
//                     ? [
//                         BoxShadow(
//                           color: Colors.white,
//                           spreadRadius: 1,
//                           blurRadius: 30,
//                         ),
//                       ]
//                     : [],
//               ),
//               child: index == 0
//                   ? Image.asset(
//                       'assets/logo3.png', // Image for the "All" item
//                       height: screenhgt * 0.07, // Adjust the size as needed
//                     )
//                   : index == 4 // Check if this is the "Search" item
//                       ? Icon(
//                           Icons.search, // Replace text with search icon
//                           color: focusNode.hasFocus
//                               ? Color.fromARGB(255, 247, 6, 118)
//                               : hintColor,
//                           size: screenwdt * 0.025, // Adjust icon size
//                         )
//                       : index == 5 // Check if this is the "Notification" item
//                           ? Icon(
//                               Icons.notifications,
//                               color: focusNode.hasFocus
//                                   ? Color.fromARGB(255, 247, 6, 118)
//                                   : hintColor,
//                               size: screenwdt * 0.025, // Adjust icon size
//                             )
//                           : Text(
//                               title,
//                               style: TextStyle(
//                                 color: focusNode.hasFocus
//                                     ? Color.fromARGB(255, 247, 6, 118)
//                                     : hintColor,
//                                 fontSize: screenwdt * 0.015,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }






import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';

// Helper function to generate random light colors
Color generateRandomLightColor() {
  Random random = Random();
  int red = random.nextInt(156) + 100;   // Red values between 100 and 255
  int green = random.nextInt(156) + 100; // Green values between 100 and 255
  int blue = random.nextInt(156) + 100;  // Blue values between 100 and 255

  return Color.fromRGBO(red, green, blue, 1.0); // Full opacity for vibrant colors
}

class TopNavigationBar extends StatefulWidget {
  final int selectedPage;
  final ValueChanged<int> onPageSelected;
  final bool tvenableAll;

  const TopNavigationBar({
    required this.selectedPage,
    required this.onPageSelected,
    required this.tvenableAll,
  });

  @override
  _TopNavigationBarState createState() => _TopNavigationBarState();
}
class _TopNavigationBarState extends State<TopNavigationBar> {
  late List<FocusNode> _focusNodes;
  late List<Color?> _randomColors; // Store random colors for each item

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(4, (index) => FocusNode());
    _randomColors = List.filled(4, null); // Initialize with null

    // Set initial focus to the first menu item
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
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
      padding: EdgeInsets.symmetric(vertical: screenhgt * 0.01, horizontal: screenwdt * 0.04),
      color: cardColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // First button (Logo or Image)
          IntrinsicWidth(
            child: _buildNavigationItem('', 0, _focusNodes[0]),
          ),

          Spacer(),

          // Remaining buttons
          Row(
            children: [
              _buildNavigationItem('Vod', 1, _focusNodes[1]),
              // _buildNavigationItem('Web Series', 2, _focusNodes[2]),
              _buildNavigationItem('Live TV', 2, _focusNodes[2]),
              _buildNavigationItem('Search', 3, _focusNodes[3]),
              // _buildNavigationItem('Notification', 5, _focusNodes[5]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationItem(String title, int index, FocusNode focusNode) {
    return Padding(
      padding: EdgeInsets.only(top: screenwdt * 0.007, left: screenwdt * 0.013, right: screenwdt * 0.013),
      child: IntrinsicWidth(
        child: Focus(
          focusNode: focusNode,
          onFocusChange: (hasFocus) {
            if (hasFocus && _randomColors[index] == null) {
              // Generate the random color only once when focused
              _randomColors[index] = generateRandomLightColor();
            } else if (!hasFocus) {
              // Reset color when focus is lost
              _randomColors[index] = null;
            }
            setState(() {});
          },
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                _focusNodes[(index + 1) % _focusNodes.length].requestFocus();
                return KeyEventResult.handled;
              } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                _focusNodes[(index - 1 + _focusNodes.length) % _focusNodes.length].requestFocus();
                return KeyEventResult.handled;
              } else if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
                widget.onPageSelected(index);
                return KeyEventResult.handled;
              }
            }
            return KeyEventResult.ignored;
          },
          child: GestureDetector(
            onTap: () {
              widget.onPageSelected(index);
              focusNode.requestFocus();
            },
            child: Container(
              decoration: BoxDecoration(
                color: focusNode.hasFocus ? Colors.black : Colors.transparent,
                boxShadow: focusNode.hasFocus
                    ? [
                        BoxShadow(
                          color: _randomColors[index] ?? Colors.transparent, // Use the stored color
                          blurRadius: 15.0,
                          spreadRadius: 5.0,
                        ),
                      ]
                    : [],
                border: focusNode.hasFocus
                    ? Border.all(
                        color: _randomColors[index] ?? Colors.transparent, // Use the stored color
                        width: 2.0,
                      )
                    : Border.all(
                        color: Colors.transparent,
                        width: 2.0,
                      ),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: screenhgt * 0.01, horizontal: 15),
                child: index == 0
                    ? Image.asset(
                        'assets/logo3.png',
                        height: screenhgt * 0.05,
                      )
                    : index == 4
                        ? Icon(
                            Icons.search,
                            color: focusNode.hasFocus
                                ? _randomColors[index] ?? hintColor // Use the stored color
                                : hintColor,
                            size: screenwdt * 0.025,
                          )
                        : index == 5
                            ? Icon(
                                Icons.notifications,
                                color: focusNode.hasFocus
                                    ? _randomColors[index] ?? hintColor // Use the stored color
                                    : hintColor,
                                size: screenwdt * 0.025,
                              )
                            : Text(
                                title,
                                style: TextStyle(
                                  color: focusNode.hasFocus
                                      ? _randomColors[index] ?? hintColor // Use the stored color
                                      : hintColor,
                                  fontSize: menutextsz,
                                  fontWeight: focusNode.hasFocus ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
