// Drawer / "More services" / quick-actions menu item — re-used both
// in the side drawer and (later) in the more-services grid.

import 'package:flutter/material.dart';

class MenuAction {
  final String label;
  final IconData icon;
  final Color iconColor;
  final int? badgeCount; // optional notification count

  const MenuAction({
    required this.label,
    required this.icon,
    required this.iconColor,
    this.badgeCount,
  });
}
