import 'package:flutter/material.dart';

import '../core/theme/pg_colors.dart';

class PgSectionLabel extends StatelessWidget {
  const PgSectionLabel(this.text, {super.key, this.color, this.padding});

  final String text;
  final Color? color;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: padding ?? const EdgeInsets.only(bottom: 12),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
          color: color ?? c.dim,
        ),
      ),
    );
  }
}
