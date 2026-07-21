import 'package:flutter/material.dart';

import '../core/theme/pg_colors.dart';

enum PgButtonVariant { primary, secondaryAmber, outline, ghost, danger }

/// Full-width (or inline) pill/rounded button matching the prototype's button
/// styles: solid teal primary, outline surface secondary, ghost text, etc.
class PgButton extends StatelessWidget {
  const PgButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = PgButtonVariant.primary,
    this.expand = true,
    this.dense = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final PgButtonVariant variant;
  final bool expand;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    late final Color bg;
    late final Color fg;
    Border? border;

    switch (variant) {
      case PgButtonVariant.primary:
        bg = c.teal;
        fg = c.onTeal;
        break;
      case PgButtonVariant.secondaryAmber:
        bg = c.amber;
        fg = c.onAmber;
        break;
      case PgButtonVariant.outline:
        bg = c.surface;
        fg = c.text;
        border = Border.all(color: c.line2);
        break;
      case PgButtonVariant.ghost:
        bg = Colors.transparent;
        fg = c.dim;
        break;
      case PgButtonVariant.danger:
        bg = Colors.transparent;
        fg = c.danger;
        border = Border.all(color: c.line2);
        break;
    }

    final child = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[icon!, const SizedBox(width: 9)],
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: dense ? 14 : 16,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: border?.top ?? BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPressed,
        child: Padding(
          padding: dense
              ? const EdgeInsets.symmetric(horizontal: 20, vertical: 12)
              : const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: child,
        ),
      ),
    );
  }
}
