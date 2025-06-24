import 'package:flutter/material.dart' show BoxDecoration, Color, BorderRadius, Border;

class ProductUIHelpers {
  // Formatage des dates
  static String formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return 'Il y a ${difference.inMinutes}min';
      }
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays}j';
    } else if (difference.inDays < 30) {
      return 'Il y a ${(difference.inDays / 7).round()} semaines';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
  
  // Styles de containers réutilisables
  static BoxDecoration infoContainerDecoration(Color color) {
    return BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    );
  }
}