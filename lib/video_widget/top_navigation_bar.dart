import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobi_tv_entertainment/main.dart';

class TopNavigationBar extends StatefulWidget {
  final int selectedPage;
  final ValueChanged<int> onPageSelected;
  final bool ekomenableAll;

  const TopNavigationBar({
    required this.selectedPage,
    required this.onPageSelected,
    required this.ekomenableAll,
  });

  @override
  _TopNavigationBarState createState() => _TopNavigationBarState();
}

class _TopNavigationBarState extends State<TopNavigationBar> {
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(7, (index) => FocusNode());
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
      color: Colors.blueGrey[800],
      padding: const EdgeInsets.symmetric(vertical: 15),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          Flexible(
              flex: 1, child: _buildNavigationItem('All', 0, _focusNodes[0])),
          Flexible(
              flex: 1, child: _buildNavigationItem('News', 1, _focusNodes[1])),
          Flexible(
              flex: 1,
              child: _buildNavigationItem('Movies', 2, _focusNodes[2])),
          Flexible(
              flex: 1, child: _buildNavigationItem('Music', 3, _focusNodes[3])),
          Flexible(
              flex: 1,
              child: _buildNavigationItem('Sports', 4, _focusNodes[4])),
          Flexible(
              flex: 1,
              child: _buildNavigationItem('Religious', 5, _focusNodes[5])),
          Flexible(
              flex: 1,
              child: _buildNavigationItem('Entertainment', 6, _focusNodes[6])),
        ],
      ),
      //  )
    );
  }

  Widget _buildNavigationItem(String title, int index, FocusNode focusNode) {
    bool isSelected = widget.selectedPage == index;
    return Focus(
      focusNode: focusNode,
      onFocusChange: (hasFocus) {
        if (hasFocus) {
          setState(() {});
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // FittedBox(
            // child:
            Text(
              title,
              style: TextStyle(
                color: focusNode.hasFocus
                    ? Color.fromARGB(255, 247, 6, 118)
                    : Colors.white,
                fontSize: screenwdt * 0.015,
                fontWeight: FontWeight.bold,
              ),
            ),
            // ),
          ],
        ),
      ),
    );
  }
}
