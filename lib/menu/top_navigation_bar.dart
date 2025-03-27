

// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:mobi_tv_entertainment/provider/color_provider.dart';
// import 'package:mobi_tv_entertainment/provider/focus_provider.dart';
// import 'package:provider/provider.dart';
// import '../main.dart';
// import '../widgets/utils/random_light_color_widget.dart';

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
//     _focusNodes = List.generate(5, (index) => FocusNode());

//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _focusNodes[0].requestFocus();
//       context.read<FocusProvider>().setTopNavigationFocusNode(_focusNodes[0]);
//     });
//   }

//   @override
//   void dispose() {
//     for (var node in _focusNodes) {
//       node.dispose();
//     }
//     super.dispose();
//   }

//   // Color generator function
//   Color _generateRandomColor() {
//     final random = Random();
//     return Color.fromRGBO(
//       random.nextInt(256),
//       random.nextInt(256),
//       random.nextInt(256),
//       1,
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<ColorProvider>(builder: (context, colorProvider, child) {
//       Color backgroundColor = colorProvider.isItemFocused
//           ? colorProvider.dominantColor.withOpacity(0.5)
//           : cardColor;
//       return Container(
//         color: backgroundColor,
//         child: Container(
//           padding: EdgeInsets.symmetric(
//               vertical: screenhgt * 0.01, horizontal: screenwdt * 0.04),
//           color: cardColor,
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               IntrinsicWidth(
//                 child: _buildNavigationItem('', 0, _focusNodes[0]),
//               ),
//               Spacer(),
//               Row(
//                 children: [
//                   _buildNavigationItem('Vod', 1, _focusNodes[1]),
//                   _buildNavigationItem('Live TV', 2, _focusNodes[2]),
//                   _buildNavigationItem('Search', 3, _focusNodes[3]),
//                   _buildNavigationItem('Youtube', 4, _focusNodes[4]),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       );
//     });
//   }

//   Widget _buildNavigationItem(String title, int index, FocusNode focusNode) {
//     return Padding(
//       padding: EdgeInsets.only(
//           top: screenwdt * 0.007,
//           left: screenwdt * 0.013,
//           right: screenwdt * 0.013),
//       child: IntrinsicWidth(
//         child: Focus(
//           focusNode: focusNode,
//           onFocusChange: (hasFocus) {
//             setState(() {
//               if (hasFocus) {
//                 // Navigation focus updates
//                 if (index == 4) {
//                   context
//                       .read<FocusProvider>()
//                       .setYoutubeSearchNavigationFocusNode(focusNode);
//                 }
//                 if (index == 3) {
//                   context
//                       .read<FocusProvider>()
//                       .setSearchNavigationFocusNode(focusNode);
//                 }
//                 if (index == 2) {
//                   context.read<FocusProvider>().setLiveTvFocusNode(focusNode);
//                 }
//                 if (index == 1) {
//                   context.read<FocusProvider>().setVodMenuFocusNode(focusNode);
//                 }

//                 // Har baar naya color generate karein
//                 final newColor = _generateRandomColor();
//                 context.read<ColorProvider>().updateColor(newColor, true);
//               } else {
//                 context.read<ColorProvider>().resetColor();
//               }
//             });
//           },
//           onKeyEvent: (node, event) {
//             if (event is KeyDownEvent) {
//               if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
//                 if (index == 1) {
//                   Future.delayed(Duration(milliseconds: 100), () {
//                     context.read<FocusProvider>().requestVodBannerFocus();
//                   });
//                 }
//                 if (index == 2) {
//                   Future.delayed(Duration(milliseconds: 100), () {
//                     context.read<FocusProvider>().requestLiveScreenFocus();
//                   });
//                 }
//                 if (index == 3) {
//                   Future.delayed(Duration(milliseconds: 100), () {
//                     context.read<FocusProvider>().requestSearchIconFocus();
//                   });
//                 }
//                 if (index == 4) {
//                   Future.delayed(Duration(milliseconds: 100), () {
//                     context
//                         .read<FocusProvider>()
//                         .requestYoutubeSearchIconFocus();
//                   });
//                 }

//                 Future.delayed(Duration(milliseconds: 100), () {
//                   context.read<FocusProvider>().requestWatchNowFocus();
//                 });

//                 return KeyEventResult.handled;
//               } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
//                 _focusNodes[(index + 1) % _focusNodes.length].requestFocus();
//                 return KeyEventResult.handled;
//               } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
//                 _focusNodes[
//                         (index - 1 + _focusNodes.length) % _focusNodes.length]
//                     .requestFocus();
//                 return KeyEventResult.handled;
//               } else if (event.logicalKey == LogicalKeyboardKey.select ||
//                   event.logicalKey == LogicalKeyboardKey.enter) {
//                 widget.onPageSelected(index);

//                 if (index == 0) {
//                   Future.delayed(Duration(milliseconds: 100), () {
//                     context.read<FocusProvider>().requestWatchNowFocus();
//                   });
//                 }
//                 if (index == 1) {
//                   Future.delayed(Duration(milliseconds: 100), () {
//                     context.read<FocusProvider>().requestVodBannerFocus();
//                   });
//                 }
//                 if (index == 2) {
//                   Future.delayed(Duration(milliseconds: 100), () {
//                     context.read<FocusProvider>().requestLiveScreenFocus();
//                   });
//                 }
//                 if (index == 3) {
//                   Future.delayed(Duration(milliseconds: 100), () {
//                     context.read<FocusProvider>().requestSearchIconFocus();
//                   });
//                 }
//                 if (index == 4) {
//                   Future.delayed(Duration(milliseconds: 100), () {
//                     context
//                         .read<FocusProvider>()
//                         .requestYoutubeSearchIconFocus();
//                   });
//                 }

//                 return KeyEventResult.handled;
//               }
//             }
//             return KeyEventResult.ignored;
//           },
//           child: GestureDetector(
//             onTap: () {
//               widget.onPageSelected(index);
//               focusNode.requestFocus();
//             },
//             child: RandomLightColorWidget(
//               hasFocus: focusNode.hasFocus,
//               childBuilder: (Color randomColor) {
//                 final Color currentColor = _generateRandomColor();

//                 return Container(
//                   margin: EdgeInsets.all(screenwdt * 0.001),
//                   decoration: BoxDecoration(
//                     color: focusNode.hasFocus
//                         ? const Color.fromARGB(255, 5, 3, 3)
//                         : Colors.transparent,
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(
//                       color: focusNode.hasFocus
//                           ? currentColor
//                           : Colors.transparent,
//                       width: 2,
//                     ),
//                     boxShadow: focusNode.hasFocus
//                         ? [
//                             BoxShadow(
//                               color: currentColor,
//                               blurRadius: 15.0,
//                               spreadRadius: 5.0,
//                             ),
//                           ]
//                         : [],
//                   ),
//                   padding: EdgeInsets.symmetric(
//                       vertical: screenhgt * 0.01, horizontal: screenwdt * 0.01),
//                   child: index == 0
//                       ? Image.asset(
//                           'assets/logo3.png',
//                           height: screenhgt * 0.05,
//                         )
//                       : Center(
//                           child: Text(
//                             title,
//                             style: TextStyle(
//                               // color: focusNode.hasFocus ? currentColor : hintColor,
//                               color: widget.selectedPage == index
//                                   ? Colors.red // Selected button text color red
//                                   : (focusNode.hasFocus
//                                       ? currentColor
//                                       : hintColor),
//                               fontSize: menutextsz,
//                               fontWeight: focusNode.hasFocus
//                                   ? FontWeight.bold
//                                   : FontWeight.normal,
//                             ),
//                           ),
//                         ),
//                 );
//               },
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }




import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobi_tv_entertainment/provider/color_provider.dart';
import 'package:mobi_tv_entertainment/provider/focus_provider.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../widgets/utils/random_light_color_widget.dart';

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

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(4, (index) => FocusNode());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
      context.read<FocusProvider>().setTopNavigationFocusNode(_focusNodes[0]);
    });
  }

  @override
  void dispose() {
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  // Color generator function
  Color _generateRandomColor() {
    final random = Random();
    return Color.fromRGBO(
      random.nextInt(256),
      random.nextInt(256),
      random.nextInt(256),
      1,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ColorProvider>(builder: (context, colorProvider, child) {
      Color backgroundColor = colorProvider.isItemFocused
          ? colorProvider.dominantColor.withOpacity(0.5)
          : cardColor;
      return Container(
        color: backgroundColor,
        child: Container(
          padding: EdgeInsets.symmetric(
              vertical: screenhgt * 0.01, horizontal: screenwdt * 0.04),
          color: cardColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IntrinsicWidth(
                child: _buildNavigationItem('', 0, _focusNodes[0]),
              ),
              Spacer(),
              Row(
                children: [
                  _buildNavigationItem('Vod', 1, _focusNodes[1]),
                  _buildNavigationItem('Live TV', 2, _focusNodes[2]),
                  _buildNavigationItem('Search', 3, _focusNodes[3]),
                  // _buildNavigationItem('Youtube', 4, _focusNodes[4]),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildNavigationItem(String title, int index, FocusNode focusNode) {
    return Padding(
      padding: EdgeInsets.only(
          top: screenwdt * 0.007,
          left: screenwdt * 0.013,
          right: screenwdt * 0.013),
      child: IntrinsicWidth(
        child: Focus(
          focusNode: focusNode,
          onFocusChange: (hasFocus) {
            setState(() {
              if (hasFocus) {
                // Navigation focus updates
                if (index == 4) {
                  context
                      .read<FocusProvider>()
                      .setYoutubeSearchNavigationFocusNode(focusNode);
                }
                if (index == 3) {
                  context
                      .read<FocusProvider>()
                      .setSearchNavigationFocusNode(focusNode);
                }
                if (index == 2) {
                  context.read<FocusProvider>().setLiveTvFocusNode(focusNode);
                }
                if (index == 1) {
                  context.read<FocusProvider>().setVodMenuFocusNode(focusNode);
                }

                // Har baar naya color generate karein
                final newColor = _generateRandomColor();
                context.read<ColorProvider>().updateColor(newColor, true);
              } else {
                context.read<ColorProvider>().resetColor();
              }
            });
          },
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                if (index == 1) {
                  Future.delayed(Duration(milliseconds: 100), () {
                    context.read<FocusProvider>().requestVodBannerFocus();
                  });
                }
                if (index == 2) {
                  Future.delayed(Duration(milliseconds: 100), () {
                    context.read<FocusProvider>().requestLiveScreenFocus();
                  });
                }
                if (index == 3) {
                  Future.delayed(Duration(milliseconds: 100), () {
                    context.read<FocusProvider>().requestSearchIconFocus();
                  });
                }
                if (index == 4) {
                  Future.delayed(Duration(milliseconds: 100), () {
                    context
                        .read<FocusProvider>()
                        .requestYoutubeSearchIconFocus();
                  });
                }

                Future.delayed(Duration(milliseconds: 100), () {
                  context.read<FocusProvider>().requestWatchNowFocus();
                });

                return KeyEventResult.handled;
              } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                _focusNodes[(index + 1) % _focusNodes.length].requestFocus();
                return KeyEventResult.handled;
              } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                _focusNodes[
                        (index - 1 + _focusNodes.length) % _focusNodes.length]
                    .requestFocus();
                return KeyEventResult.handled;
              } else if (event.logicalKey == LogicalKeyboardKey.select ||
                  event.logicalKey == LogicalKeyboardKey.enter) {
                widget.onPageSelected(index);

                if (index == 0) {
                  Future.delayed(Duration(milliseconds: 100), () {
                    context.read<FocusProvider>().requestWatchNowFocus();
                  });
                }
                if (index == 1) {
                  Future.delayed(Duration(milliseconds: 100), () {
                    context.read<FocusProvider>().requestVodBannerFocus();
                  });
                }
                if (index == 2) {
                  Future.delayed(Duration(milliseconds: 100), () {
                    context.read<FocusProvider>().requestLiveScreenFocus();
                  });
                }
                if (index == 3) {
                  Future.delayed(Duration(milliseconds: 100), () {
                    context.read<FocusProvider>().requestSearchIconFocus();
                  });
                }
                if (index == 4) {
                  Future.delayed(Duration(milliseconds: 100), () {
                    context
                        .read<FocusProvider>()
                        .requestYoutubeSearchIconFocus();
                  });
                }

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
            child: RandomLightColorWidget(
              hasFocus: focusNode.hasFocus,
              childBuilder: (Color randomColor) {
                return Container(
                  margin: EdgeInsets.all(screenwdt * 0.001),
                  decoration: BoxDecoration(
                    color: focusNode.hasFocus
                        ? const Color.fromARGB(255, 5, 3, 3)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: focusNode.hasFocus
                          ? randomColor
                          : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: focusNode.hasFocus
                        ? [
                            BoxShadow(
                              color: randomColor,
                              blurRadius: 15.0,
                              spreadRadius: 5.0,
                            ),
                          ]
                        : [],
                  ),
                  padding: EdgeInsets.symmetric(
                      vertical: screenhgt * 0.01, horizontal: screenwdt * 0.01),
                  child: index == 0
                      ? Image.asset(
                          'assets/logo3.png',
                          height: screenhgt * 0.05,
                        )
                      : Center(
                          child: Text(
                            title,
                            style: TextStyle(
                              // color: focusNode.hasFocus ? currentColor : hintColor,
                              color: widget.selectedPage == index
                                  ? Colors.red // Selected button text color red
                                  : (focusNode.hasFocus
                                      ? randomColor
                                      : hintColor),
                              fontSize: menutextsz,
                              fontWeight: focusNode.hasFocus
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}