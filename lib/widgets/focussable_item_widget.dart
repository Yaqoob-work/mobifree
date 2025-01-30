




// Updated FocusableItemWidget
import 'package:flutter/material.dart';
import 'package:mobi_tv_entertainment/main.dart';
import 'package:mobi_tv_entertainment/menu_screens/home_sub_screen/sub_vod.dart';
import 'package:mobi_tv_entertainment/provider/color_provider.dart';
import 'package:provider/provider.dart';


class FocusableItemWidget extends StatefulWidget {
  final String imageUrl;
  final String name;
  final VoidCallback onTap;
  final Future<Color> Function(String imageUrl) fetchPaletteColor;
  final FocusNode? focusNode;
  final Function(bool)? onFocusChange; // Callback for focus change
  final double? width;
  final double? height;
  final double? focusedHeight;

  const FocusableItemWidget({
    required this.imageUrl,
    required this.name,
    required this.onTap,
    required this.fetchPaletteColor,
    this.focusNode,
    this.onFocusChange,
    this.width,
    this.height,
    this.focusedHeight,
  });

  @override
  _FocusableItemWidgetState createState() => _FocusableItemWidgetState();
}

class _FocusableItemWidgetState extends State<FocusableItemWidget> {
  bool isFocused = false;
  Color paletteColor = Colors.pink;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
    _updatePaletteColor();
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _handleFocusChange() {
    final hasFocus = _focusNode.hasFocus;
    setState(() {
      isFocused = hasFocus;
    });
    widget.onFocusChange?.call(hasFocus);

    if (hasFocus) {
      context.read<ColorProvider>().updateColor(paletteColor, true);
    } else {
      context.read<ColorProvider>().resetColor();
    }
  }

  Future<void> _updatePaletteColor() async {
    try {
      final color = await widget.fetchPaletteColor(widget.imageUrl);
      if (mounted) {
        setState(() {
          paletteColor = color;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          paletteColor = Colors.grey;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double containerWidth = widget.width ?? screenwdt * 0.19;
    final double containerHeight = isFocused
        ? (widget.focusedHeight ?? screenhgt * 0.24)
        : (widget.height ?? screenhgt * 0.21);

    return FocusableActionDetector(
      focusNode: _focusNode,
      onFocusChange: (hasFocus) {
        if (hasFocus) {
          context.read<ColorProvider>().updateColor(paletteColor, true);
        }
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
              duration: const Duration(milliseconds: 400),
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
                        ),
                      ]
                    : [],
              ),
              child: displayImage(widget.imageUrl),
            ),

// AnimatedContainer(
//   width: containerWidth,
//   height: containerHeight,
//   duration: const Duration(milliseconds: 400),
//   decoration: BoxDecoration(
//     border: Border.all(
//       color: isFocused ? paletteColor : Colors.transparent,
//       width: 4.0,
//     ),
//     boxShadow: isFocused
//         ? [
//             BoxShadow(
//               color: paletteColor,
//               blurRadius: 25,
//               spreadRadius: 10,
//             ),
//           ]
//         : [],
//   ),
//   child: displayImage(
//     widget.imageUrl,
//     width: containerWidth,
//     height: containerHeight,
//     // backgroundColor: Colors.grey, // Pass grey as the background color
//   ),
// ),


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

