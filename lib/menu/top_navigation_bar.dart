import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobi_tv_entertainment/provider/color_provider.dart';
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
    _focusNodes = List.generate(5, (index) => FocusNode());

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
                  _buildNavigationItem('Notification', 4, _focusNodes[4]),
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
            setState(() {}); // Trigger UI update on focus change
          },
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
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
                    color:
                        focusNode.hasFocus ? Colors.black : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          focusNode.hasFocus ? randomColor : Colors.transparent,
                      width: 2,
                    ),
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
                              color: focusNode.hasFocus
                                  ? randomColor // Use the random color for the text when focused
                                  : hintColor,
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
