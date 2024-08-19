import 'package:flutter/material.dart';
import 'package:mobi_tv_entertainment/live_sub_screen/all_channel.dart';
import 'package:mobi_tv_entertainment/live_sub_screen/entertainment_screen.dart';
import 'package:mobi_tv_entertainment/live_sub_screen/music_screen.dart';
import 'package:mobi_tv_entertainment/live_sub_screen/news_screen.dart';
import 'package:mobi_tv_entertainment/live_sub_screen/religious_screen.dart';
import 'package:mobi_tv_entertainment/live_sub_screen/sports_screen.dart';
import 'package:mobi_tv_entertainment/main.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  @override
  _CustomAppBarState createState() => _CustomAppBarState();

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}

class _CustomAppBarState extends State<CustomAppBar> {
  final List<FocusNode> _focusNodes = List<FocusNode>.generate(6, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    // Optionally request focus for the first button
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white54,
      // automaticallyImplyLeading: false,
      actions: [
        Expanded(
          child: FocusTraversalGroup(
            policy: OrderedTraversalPolicy(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFocusedButton(context, 'All', AllChannel(), 0),
                _buildFocusedButton(context, 'News', NewsScreen(), 1),
                _buildFocusedButton(context, 'Entertainment', EntertainmentScreen(), 2),
                _buildFocusedButton(context, 'Music', MusicScreen(), 3),
                _buildFocusedButton(context, 'Sports', SportsScreen(), 4),
                _buildFocusedButton(context, 'Religious', ReligiousScreen(), 5),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFocusedButton(BuildContext context, String label, Widget page, int index) {
    return Focus(
      focusNode: _focusNodes[index],
      onFocusChange: (hasFocus) {
        // Optional: Handle focus change if needed
      },
      child: Builder(
        builder: (context) {
          final bool hasFocus = Focus.of(context).hasFocus;
          return ElevatedButton(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty .resolveWith<Color?>(
                (Set<WidgetState > states) {
                  if (hasFocus) {
                    return borderColor; // Change to yellow when focused
                  }
                  return cardColor; // Default color when not focused
                },
              ),
            //   foregroundColor: WidgetStateProperty.resolveWith<Color?>(
            //   (Set<WidgetState> states) {
            //     if (states.contains(WidgetState .focused)) {
            //       return cardColor; // Change text color when focused
            //     }
            //     return hintColor; // Default text color when not focused
            //   },
            // ),
            ),
            child: Text(
              label,
              style: TextStyle(
              fontSize: hasFocus ? 20.0 : 16.0, // Change font size based on focus
              color: hintColor
            ),
              ),
            onPressed: () async {
            // Navigate to the page and wait for the result
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => page),
            );

            // If result is true, refresh the page
            if (result == true) {
              setState(() {
                // Refresh logic here
              });
            }
          },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }
}

void main() {
  runApp(MaterialApp(
    home: Scaffold(
      appBar: CustomAppBar(),
      body: Center(
        child: Text('Home Page'),
      ),
    ),
  ));
}

