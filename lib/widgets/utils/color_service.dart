



import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

class PaletteColorService {
//   // Method to get the second most populated color from an image
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



class RandomColorService{
  
}