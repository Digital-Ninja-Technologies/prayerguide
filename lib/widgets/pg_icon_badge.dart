import 'package:flutter/material.dart';

/// Rounded-square colored icon badge (used for guide categories, list rows,
/// challenge/plan icons, etc).
class PgIconBadge extends StatelessWidget {
  const PgIconBadge({
    super.key,
    required this.icon,
    required this.color,
    required this.background,
    this.size = 46,
    this.iconSize = 22,
    this.radius = 14,
    this.circular = false,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final double size;
  final double iconSize;
  final double radius;
  final bool circular;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        shape: circular ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circular ? null : BorderRadius.circular(radius),
      ),
      child: Icon(icon, size: iconSize, color: color),
    );
  }
}
