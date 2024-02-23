import 'package:flutter/material.dart';

class FontSizeSettings {
  static double _fontSize = 20.0; // Taille de police par défaut

  static double get fontSize => _fontSize;

  static void setFontSize(double size) {
    _fontSize = size;
  }

}
class ColorSettings {
  static Color backgroundColor = const Color.fromARGB(255, 28, 120, 205);
  static Color fontColor = Colors.black;

  static void setBackgroundColor(Color newColor) {
    backgroundColor = newColor;
  }

  static void setFontColor(Color newColor) {
    fontColor = newColor;
  }

  
}

class ColorModeSettings {
  final Color backgroundColor;
  final Color textColor;

  ColorModeSettings({required this.backgroundColor, required this.textColor});
}

