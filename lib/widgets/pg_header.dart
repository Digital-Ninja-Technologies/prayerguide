import 'package:flutter/material.dart';

import '../core/theme/pg_text.dart';
import 'pg_back_button.dart';

/// Back-button + title row used at the top of nearly every secondary screen.
class PgHeader extends StatelessWidget {
  const PgHeader({
    super.key,
    this.title,
    this.eyebrow,
    this.onBack,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(0, 6, 0, 14),
  });

  final String? title;
  final String? eyebrow;
  final VoidCallback? onBack;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: padding,
        child: Row(
          children: [
            PgBackButton(onTap: onBack),
            const SizedBox(width: 12),
            if (title != null)
              Expanded(
                child: Text(
                  title!,
                  style: PgText.serif(size: 23, weight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              )
            else if (eyebrow != null)
              Expanded(
                child: Text(
                  eyebrow!,
                  style: PgText.sans(
                    size: 13,
                    weight: FontWeight.w700,
                    letterSpacing: .4,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
