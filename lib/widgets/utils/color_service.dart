



// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';
// import 'package:palette_generator/palette_generator.dart';

// class PaletteColorService {
// //   // Method to get the second most populated color from an image
//   Future<Color> getSecondaryColor(String imageUrl, {Color fallbackColor = Colors.pink}) async {
//     try {
//       final PaletteGenerator paletteGenerator =
//           await PaletteGenerator.fromImageProvider(
//         CachedNetworkImageProvider(imageUrl),
//         size: const Size(100, 100),
//         maximumColorCount: 100,
//       );
//       return _getSecondMostPopulatedColor(paletteGenerator) ?? fallbackColor;
//     } catch (e) {
//       // Return fallback color in case of an error
//       return fallbackColor;
//     }
//   }

//   // Method to get the second most populated color
//   Color? _getSecondMostPopulatedColor(PaletteGenerator paletteGenerator) {
//     final sortedColors = paletteGenerator.paletteColors.toList()
//       ..sort((a, b) => b.population.compareTo(a.population));

//     if (sortedColors.length > 1) {
//       return sortedColors[1].color;
//     } else if (sortedColors.isNotEmpty) {
//       return sortedColors[0].color;
//     } else {
//       return null; // No colors available
//     }
//   }
// }



// class RandomColorService{
  
// }





import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

class PaletteColorService {
  // Method to get the second most populated color from an image
  Future<Color> getSecondaryColor(String imageUrl, {Color fallbackColor = Colors.pink}) async {
    try {
      final PaletteGenerator paletteGenerator = await PaletteGenerator.fromImageProvider(
        CachedNetworkImageProvider(imageUrl),
        size: const Size(100, 100),
        maximumColorCount: 100,
      ).timeout(const Duration(seconds: 5)); // <-- Add timeout here

      return _getSecondMostPopulatedColor(paletteGenerator) ?? fallbackColor;
    } catch (e) {
      // Return fallback color in case of an error (timeout, network, etc)
      return fallbackColor;
    }
  }

  // Method to get the second most populated color
  Color? _getSecondMostPopulatedColor(PaletteGenerator paletteGenerator) {
    final sortedColors = paletteGenerator.paletteColors.toList()
      ..sort((a, b) => b.population.compareTo(a.population));

    if (sortedColors.length > 1) {
      return sortedColors[1].color;
    } else if (sortedColors.isNotEmpty) {
      return sortedColors[0].color;
    } else {
      return null; // No colors available
    }
  }
}

class RandomColorService {
  /// Returns a random light color.
  Color getRandomLightColor() {
    // Simple pastel color generator
    return Color.fromARGB(
      255,
      (200 + (55 * _randomDouble())).toInt(),
      (200 + (55 * _randomDouble())).toInt(),
      (200 + (55 * _randomDouble())).toInt(),
    );
  }

  double _randomDouble() => (0.0 + (1.0 - 0.0) * (DateTime.now().microsecond % 1000) / 1000);
}
