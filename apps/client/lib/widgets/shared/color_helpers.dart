// lib/widgets/shared/color_helpers.dart
import 'package:flutter/material.dart';

class ColorHelpers {
  /// Obtient une shade sombre pour une couleur donnée
  static Color getDarkShade(Color color) {
    if (color == Colors.red) return Colors.red.shade700;
    if (color == Colors.blue) return Colors.blue.shade700;
    if (color == Colors.green) return Colors.green.shade700;
    if (color == Colors.orange) return Colors.orange.shade700;
    if (color == Colors.purple) return Colors.purple.shade700;
    if (color == Colors.teal) return Colors.teal.shade700;
    return color; // Fallback pour les couleurs personnalisées
  }

  /// Obtient une shade medium pour une couleur donnée
  static Color getMediumShade(Color color) {
    if (color == Colors.red) return Colors.red.shade600;
    if (color == Colors.blue) return Colors.blue.shade600;
    if (color == Colors.green) return Colors.green.shade600;
    if (color == Colors.orange) return Colors.orange.shade600;
    if (color == Colors.purple) return Colors.purple.shade600;
    if (color == Colors.grey) return Colors.grey.shade600;
    return color;
  }

  /// Obtient une shade claire pour une couleur donnée
  static Color getLightShade(Color color) {
    if (color == Colors.red) return Colors.red.shade50;
    if (color == Colors.blue) return Colors.blue.shade50;
    if (color == Colors.green) return Colors.green.shade50;
    if (color == Colors.orange) return Colors.orange.shade50;
    if (color == Colors.purple) return Colors.purple.shade50;
    if (color == Colors.grey) return Colors.grey.shade50;
    return color;
  }
}