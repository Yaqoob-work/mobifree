// import 'dart:math';
// import 'package:flutter/material.dart';

// class RandomLightColorWidget extends StatelessWidget {
//   final Widget Function(Color) childBuilder;
//   final bool hasFocus;

//   RandomLightColorWidget({required this.childBuilder, required this.hasFocus});

//   // Helper function to generate random light colors
//   Color generateRandomLightColor() {
//     Random random = Random();
//     int red = random.nextInt(256); //+ 100; // Red values between 100 and 255
//     int green = random.nextInt(256);// + 100; // Green values between 100 and 255
//     int blue = random.nextInt(256);// + 100; // Blue values between 100 and 255

//     return Color.fromRGBO(red, green, blue, 1.0); // Full opacity
//   }

//   @override
//   Widget build(BuildContext context) {
//     Color randomColor =
//         hasFocus ? generateRandomLightColor() : Colors.transparent;

//     return Container(
//       decoration: BoxDecoration(
//         color: hasFocus ? Colors.black : Colors.transparent,
//         boxShadow: [
//           if (hasFocus)
//             BoxShadow(
//               color: randomColor,
//               blurRadius: 15.0, // Sharper shadow
//               spreadRadius: 5.0, // Prominent shadow
//             )
//         ],
//         borderRadius: BorderRadius.circular(8.0),
//         border: hasFocus
//             ? Border.all(
//                 color: randomColor, // Border same color as shadow
//                 width: 2.0,
//               )
//             : Border.all(
//                 color: Colors.transparent, // Border same color as shadow
//                 width: 2.0,
//               ),
//       ),
//       child:
//           childBuilder(randomColor), // Pass the same random color to the child
//     );
//   }
// }





// import 'dart:math';
// import 'package:flutter/material.dart';

// class RandomLightColorWidget extends StatelessWidget {
//   final Widget Function(Color) childBuilder;
//   final bool hasFocus;

//   RandomLightColorWidget({required this.childBuilder, required this.hasFocus});

//   // Helper function to generate random light colors
//   Color generateRandomLightColor() {
//     Random random = Random();
//     int red = random.nextInt(256);
//     int green = random.nextInt(256);
//     int blue = random.nextInt(256);

//     return Color.fromRGBO(red, green, blue, 1.0); // Full opacity
//   }

//   // Function to determine if a color is too close to white
//   bool isTooWhite(Color color) {
//     return (color.red + color.green + color.blue) > 700; // Check if RGB total is too high
//   }

//   // Function to get non-white color (if the second color is too white, use the third)
//   Color getValidColor() {
//     List<Color> colors = [
//       generateRandomLightColor(),
//       generateRandomLightColor(),
//       generateRandomLightColor(),
//     ];

//     // If the second color is too white, use the third one
//     if (isTooWhite(colors[1])) {
//       return colors[2]; // Return third color if second is too white
//     }

//     return colors[1]; // Otherwise, return the second color
//   }

//   @override
//   Widget build(BuildContext context) {
//     Color randomColor = hasFocus ? getValidColor() : Colors.transparent;

//     return Container(
//       decoration: BoxDecoration(
//         color: hasFocus ? Colors.black : Colors.transparent,
//         boxShadow: [
//           if (hasFocus)
//             BoxShadow(
//               color: randomColor,
//               blurRadius: 15.0, // Sharper shadow
//               spreadRadius: 5.0, // Prominent shadow
//             )
//         ],
//         borderRadius: BorderRadius.circular(8.0),
//         border: hasFocus
//             ? Border.all(
//                 color: randomColor, // Border same color as shadow
//                 width: 2.0,
//               )
//             : Border.all(
//                 color: Colors.transparent, // Border same color as shadow
//                 width: 2.0,
//               ),
//       ),
//       child: childBuilder(randomColor), // Pass the selected random color to the child
//     );
//   }
// }



import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mobi_tv_entertainment/provider/color_provider.dart';
import 'package:provider/provider.dart';

class RandomLightColorWidget extends StatelessWidget {
  final Widget Function(Color) childBuilder;
  final bool hasFocus;

  RandomLightColorWidget({required this.childBuilder, required this.hasFocus});

  // Helper function to generate random light colors
  Color generateRandomLightColor() {
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
    // Access current dominant color from the provider
    final colorProvider = context.read<ColorProvider>();
    final Color randomColor = hasFocus ? colorProvider.dominantColor : Colors.transparent;

    return Container(
      decoration: BoxDecoration(
        color: hasFocus ? Colors.black : Colors.transparent,
        boxShadow: [
          if (hasFocus)
            BoxShadow(
              color: randomColor,
              blurRadius: 15.0,
              spreadRadius: 5.0,
            ),
        ],
        borderRadius: BorderRadius.circular(8.0),
        border: hasFocus
            ? Border.all(color: randomColor, width: 2.0)
            : Border.all(color: Colors.transparent, width: 2.0),
      ),
      child: childBuilder(randomColor),
    );
  }
}
