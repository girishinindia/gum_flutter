// Category tile data — one entry per icon in the "Browse Categories"
// grid on the home screen. Each item carries its own colour family so
// the grid can render the premium 3-tone tile (white card · pastel
// glow corner · coloured bottom accent line).

import 'package:flutter/material.dart';

class CategoryItem {
  final String label;
  final IconData icon;
  final List<Color> iconGradient;  // 2-stop colour pair for the icon chip
  final Color glowTint;            // radial glow + shadow + bottom line
  final String subtitle;           // e.g. "60+ courses" or "HOT · 12k+"

  const CategoryItem({
    required this.label,
    required this.icon,
    required this.iconGradient,
    required this.glowTint,
    required this.subtitle,
  });
}
