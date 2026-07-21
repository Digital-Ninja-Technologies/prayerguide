import 'package:flutter/material.dart';

import '../core/theme/pg_colors.dart';

/// Small rounded chip/tag/segment button (category tags, tab segments,
/// duration presets) — the `border-radius:100px` pill pattern.
class PgPill extends StatelessWidget {
  const PgPill({
    super.key,
    required this.label,
    this.onTap,
    this.active = false,
    this.activeColor,
    this.activeFg,
    this.dense = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool active;
  final Color? activeColor;
  final Color? activeFg;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bg = active ? (activeColor ?? c.teal) : c.surface;
    final fg = active ? (activeFg ?? c.onTeal) : c.dim;
    final child = Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 12 : 14,
        vertical: dense ? 7 : 8,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
        border: active ? null : Border.all(color: c.line),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: fg),
      ),
    );
    if (onTap == null) return child;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(100),
      child: InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: onTap,
        child: child,
      ),
    );
  }
}
