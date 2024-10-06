import 'dart:math';
import 'package:flutter/material.dart';

class RandomLightColorWidget extends StatelessWidget {
  final Widget Function(Color) childBuilder;
  final bool hasFocus;

  RandomLightColorWidget({required this.childBuilder, required this.hasFocus});

  // Helper function to generate random light colors
  Color generateRandomLightColor() {
    Random random = Random();
    int red = random.nextInt(256); //+ 100; // Red values between 100 and 255
    int green = random.nextInt(256);// + 100; // Green values between 100 and 255
    int blue = random.nextInt(256);// + 100; // Blue values between 100 and 255

    return Color.fromRGBO(red, green, blue, 1.0); // Full opacity
  }

  @override
  Widget build(BuildContext context) {
    Color randomColor =
        hasFocus ? generateRandomLightColor() : Colors.transparent;

    return Container(
      decoration: BoxDecoration(
        color: hasFocus ? Colors.black : Colors.transparent,
        boxShadow: [
          if (hasFocus)
            BoxShadow(
              color: randomColor,
              blurRadius: 15.0, // Sharper shadow
              spreadRadius: 5.0, // Prominent shadow
            )
        ],
        borderRadius: BorderRadius.circular(8.0),
        border: hasFocus
            ? Border.all(
                color: randomColor, // Border same color as shadow
                width: 2.0,
              )
            : Border.all(
                color: Colors.transparent, // Border same color as shadow
                width: 2.0,
              ),
      ),
      child:
          childBuilder(randomColor), // Pass the same random color to the child
    );
  }
}