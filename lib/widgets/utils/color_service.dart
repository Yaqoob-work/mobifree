// import 'package:flutter/material.dart';
// import 'package:palette_generator/palette_generator.dart';
// import 'package:cached_network_image/cached_network_image.dart';

// class ColorUtils {
//   static Future<Color> getPaletteColor(String imageUrl) async {
//     try {
//       final imageProvider = CachedNetworkImageProvider(imageUrl);
//       final paletteGenerator =
//           await PaletteGenerator.fromImageProvider(imageProvider);
//       return paletteGenerator.dominantColor?.color ??
//           Colors.white.withOpacity(0.8);
//     } catch (e) {
//       print('Error fetching palette: $e');
//       return Colors.black.withOpacity(0.5);
//     }
//   }

//   Color getSecondMostPopulatedColor(PaletteGenerator paletteGenerator) {
//     // Sort PaletteColors by population (descending order)
//     final sortedColors = paletteGenerator.paletteColors.toList()
//       ..sort((a, b) => b.population.compareTo(a.population));

//     // If we have at least two colors, return the second one
//     if (sortedColors.length > 1) {
//       return sortedColors[1].color;
//     }

//     // If we only have one color, return it
//     if (sortedColors.isNotEmpty) {
//       return sortedColors[0].color;
//     }

//     // If no colors are available, return the default color
//     return Colors.black.withOpacity(0.5);
//   }
// }



import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

class PaletteColorService {
  // Method to get the second most populated color from an image
  Future<Color> getSecondaryColor(String imageUrl, {Color fallbackColor = Colors.grey}) async {
    try {
      final PaletteGenerator paletteGenerator =
          await PaletteGenerator.fromImageProvider(
        CachedNetworkImageProvider(imageUrl),
        size: const Size(100, 100),
        maximumColorCount: 50,
      );
      return _getSecondMostPopulatedColor(paletteGenerator) ?? fallbackColor;
    } catch (e) {
      // Return fallback color in case of an error
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