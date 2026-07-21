import 'package:flutter/material.dart';

import '../core/theme/pg_colors.dart';

/// Rounded, bordered surface card used everywhere in the prototype
/// (`background:var(--surface);border:1px solid var(--line);border-radius:*`).
class PgCard extends StatelessWidget {
  const PgCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 20,
    this.color,
    this.borderColor,
    this.borderWidth = 1,
    this.onTap,
    this.gradient,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final Color? borderColor;
  final double borderWidth;
  final VoidCallback? onTap;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? c.surface) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: borderColor ?? c.line,
          width: borderWidth,
        ),
      ),
      child: child,
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: content,
      ),
    );
  }
}
