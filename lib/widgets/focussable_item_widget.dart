// import 'package:flutter/material.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'dart:async';
// import '../main.dart';

// class FocusableItemWidget extends StatefulWidget {
//   final String imageUrl;
//   final String name;
//   final VoidCallback onTap;
//   final Future<Color> Function(String imageUrl) fetchPaletteColor;

//   const FocusableItemWidget({
//     required this.imageUrl,
//     required this.name,
//     required this.onTap,
//     required this.fetchPaletteColor,
//   });

//   @override
//   _FocusableItemWidgetState createState() => _FocusableItemWidgetState();
// }

// class _FocusableItemWidgetState extends State<FocusableItemWidget> {
//   bool isFocused = false;
//   Color paletteColor = Colors.grey; // Default color

//   @override
//   void initState() {
//     super.initState();
//     _updatePaletteColor();
//   }

//   Future<void> _updatePaletteColor() async {
//     Color color = await widget.fetchPaletteColor(widget.imageUrl);
//     setState(() {
//       paletteColor = color;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return FocusableActionDetector(
//       onFocusChange: (hasFocus) {
//         setState(() {
//           isFocused = hasFocus;
//         });
//       },
//       actions: {
//         ActivateIntent: CallbackAction<ActivateIntent>(
//           onInvoke: (ActivateIntent intent) {
//             widget.onTap();
//             return null;
//           },
//         ),
//       },
//       child: GestureDetector(
//         onTap: widget.onTap,
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             AnimatedContainer(

//                               width: screenwdt * 0.19,
//                 height: isFocused ? screenhgt * 0.24 : screenhgt * 0.21,
//               duration: const Duration(milliseconds: 300),
//               decoration: BoxDecoration(
//                 border: Border.all(
//                   color: isFocused ? paletteColor : Colors.transparent,
//                   width: 4.0,
//                 ),
//                 boxShadow: isFocused
//                     ? [
//                         BoxShadow(
//                           color: paletteColor,
//                           blurRadius: 25,
//                           spreadRadius: 10,
//                         )
//                       ]
//                     : [],
//               ),
//               child: CachedNetworkImage(
//                 imageUrl: widget.imageUrl,
//                 placeholder: (context, url) => Container(color: Colors.grey),
//                 fit: BoxFit.cover,
//               ),
//             ),
            
//             SizedBox(height: 10),
//             Text(
//               widget.name.toUpperCase(),
//               style: TextStyle(
//                 color: isFocused ? paletteColor : Colors.grey,
//                 fontWeight: FontWeight.bold,
//               ),
//               textAlign: TextAlign.center,
//               overflow: TextOverflow.ellipsis,
//               maxLines: 1,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }





import 'package:flutter/material.dart';
import 'dart:async';
import '../main.dart';
import '../menu_screens/home_sub_screen/sub_vod.dart';

class FocusableItemWidget extends StatefulWidget {
  final String imageUrl;
  final String name;
  final VoidCallback onTap;
  final Future<Color> Function(String imageUrl) fetchPaletteColor;
  final double? width;
  final double? height;
  final double? focusedHeight;

  const FocusableItemWidget({
    required this.imageUrl,
    required this.name,
    required this.onTap,
    required this.fetchPaletteColor,
    this.width, // Optional width parameter
    this.height, // Optional height parameter when not focused
    this.focusedHeight, // Optional height when focused
  });

  @override
  _FocusableItemWidgetState createState() => _FocusableItemWidgetState();
}

class _FocusableItemWidgetState extends State<FocusableItemWidget> {
  bool isFocused = false;
  Color paletteColor = Colors.grey; // Default color

  @override
  void initState() {
    super.initState();
    _updatePaletteColor();
  }

    Future<void> _updatePaletteColor() async {
    try {
      Color color = await widget.fetchPaletteColor(widget.imageUrl);
      if (mounted) {
        setState(() {
          paletteColor = color;
        });
      }
    } catch (e) {
      // Handle exceptions like network errors here
      if (mounted) {
        setState(() {
          paletteColor = Colors.grey; // fallback color
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine width and height
    final double containerWidth = widget.width ?? screenwdt * 0.19;
    final double containerHeight = isFocused
        ? (widget.focusedHeight ?? screenhgt * 0.24) // Height when focused
        : (widget.height ?? screenhgt * 0.21); // Default height

    return FocusableActionDetector(
      onFocusChange: (hasFocus) {
        setState(() {
          isFocused = hasFocus;
        });
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (ActivateIntent intent) {
            widget.onTap();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AnimatedContainer(
              width: containerWidth,
              height: containerHeight,
              duration: const Duration(milliseconds: 300), // Smooth transition
              decoration: BoxDecoration(
                border: Border.all(
                  color: isFocused ? paletteColor : Colors.transparent,
                  width: 4.0,
                ),
                boxShadow: isFocused
                    ? [
                        BoxShadow(
                          color: paletteColor,
                          blurRadius: 25,
                          spreadRadius: 10,
                        )
                      ]
                    : [],
              ),
              child: displayImage(widget.imageUrl),
            ),
            SizedBox(height: 10),
            Text(
              widget.name.toUpperCase(),
              style: TextStyle(
                color: isFocused ? paletteColor : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
