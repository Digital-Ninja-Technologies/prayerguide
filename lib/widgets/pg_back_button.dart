import 'package:flutter/material.dart';

import '../core/theme/pg_colors.dart';

/// The circular 38x38 back/close chevron button used on nearly every
/// secondary screen header.
class PgBackButton extends StatelessWidget {
  const PgBackButton({super.key, this.onTap, this.icon = Icons.arrow_back_ios_new_rounded});

  final VoidCallback? onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: c.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap ?? () => Navigator.of(context).maybePop(),
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, size: 17, color: c.text),
        ),
      ),
    );
  }
}
