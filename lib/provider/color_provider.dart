// First create a new file: color_provider.dart
import 'package:flutter/material.dart';

class ColorProvider extends ChangeNotifier {
  Color _dominantColor = Colors.transparent;
  bool _isItemFocused = false;

  Color get dominantColor => _dominantColor;
  bool get isItemFocused => _isItemFocused;

  void updateColor(Color newColor, bool isFocused) {
    _dominantColor = newColor;
    _isItemFocused = isFocused;
    notifyListeners();
  }

  void resetColor() {
    _dominantColor = Colors.transparent;
    _isItemFocused = false;
    notifyListeners();
  }
}