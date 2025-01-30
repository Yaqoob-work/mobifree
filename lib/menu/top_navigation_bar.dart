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
  Map<int, Color> _nodeColors = {};

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(4, (index) => FocusNode());

    // // Set initial focus to the first menu item
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   _focusNodes[0].requestFocus();
    // });

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

  // Add color generator function
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
      // Get background color based on provider state
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
              // First button (Logo or Image)
              IntrinsicWidth(
                child: _buildNavigationItem('', 0, _focusNodes[0]),
              ),

              Spacer(),

              // Remaining buttons
              Row(
                children: [
                  _buildNavigationItem('Vod', 1, _focusNodes[1]),
                  _buildNavigationItem('Live TV', 2, _focusNodes[2]),
                  _buildNavigationItem('Search', 3, _focusNodes[3]),
                  // _buildNavigationItem('Notification', 4, _focusNodes[4]),
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
                // Add this condition here ⬇️
                if (index == 2) {
                  // Live TV button का index
                  context.read<FocusProvider>().setLiveTvFocusNode(focusNode);
                }
                // Generate color only if not already stored
                if (!_nodeColors.containsKey(index)) {
                  _nodeColors[index] = _generateRandomColor();
                }
                // Use stored color
                context
                    .read<ColorProvider>()
                    .updateColor(_nodeColors[index]!, true);
              } else {
                context.read<ColorProvider>().resetColor();
              }
            }); // Trigger UI update on focus change
          },
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (index == 1) { // VOD button
        Future.delayed(Duration(milliseconds: 100), () {
          context.read<FocusProvider>().requestVodBannerFocus();
        });
      }
      if (index == 2) { // Live TV button
        Future.delayed(Duration(milliseconds: 100), () {
          context.read<FocusProvider>().requestLiveScreenFocus();
        });
      }

            if (index == 3) { // Assuming 3 is the search button index
        Future.delayed(Duration(milliseconds: 100), () {
          context.read<FocusProvider>().requestSearchIconFocus();
        });
      }
      // General HomeScreen focus handling (Watch Now button)
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
                if (index == 1) {
                  // Check if Vod button is selected
                  Future.delayed(Duration(milliseconds: 100), () {
                    context.read<FocusProvider>().requestVodBannerFocus();
                  });
                }
                if (index == 2) {
                  // Check if Vod button is selected
                  Future.delayed(Duration(milliseconds: 100), () {
                    context.read<FocusProvider>().requestLiveScreenFocus();
                  });
                }

                      if (index == 3) {
        // Enter pressed on the Search button
        Future.delayed(Duration(milliseconds: 100), () {
          context.read<FocusProvider>().requestSearchIconFocus();
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
                // अगर पहले से color stored है तो वही use करें, नहीं तो नया store करें
                if (focusNode.hasFocus && !_nodeColors.containsKey(index)) {
                  _nodeColors[index] = randomColor;
                }
                // हमेशा stored color का use करें
                final Color currentColor = _nodeColors[index] ?? randomColor;

                return Container(
                  margin: EdgeInsets.all(screenwdt * 0.001),
                  decoration: BoxDecoration(
                    color: focusNode.hasFocus
                        ? const Color.fromARGB(255, 5, 3, 3)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: focusNode.hasFocus
                          ? currentColor
                          : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: focusNode.hasFocus
                        ? [
                            BoxShadow(
                              color: currentColor,
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
                              color:
                                  focusNode.hasFocus ? currentColor : hintColor,
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
