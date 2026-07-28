import 'package:flutter/material.dart';

import '../core/theme/pg_colors.dart';

/// Standard form-level error message — a submission/validation failure not
/// tied to one specific field (e.g. "Could not save: $e", "Wrong
/// passphrase"). For an error tied to a single field, use
/// [PgTextField.errorText] instead so it renders inline under that field.
///
/// Renders nothing when [message] is null, so it can sit unconditionally in
/// a form's widget tree: `PgFormError(_error)`.
class PgFormError extends StatelessWidget {
  const PgFormError(this.message,
      {super.key, this.topSpacing = 10, this.bottomSpacing = 0});

  final String? message;

  /// Space above/below the message, only applied when [message] is
  /// non-null (so it doesn't leave a gap when there's nothing to show).
  final double topSpacing;
  final double bottomSpacing;

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    final c = context.colors;
    return Padding(
      padding: EdgeInsets.only(top: topSpacing, bottom: bottomSpacing),
      child: Text(message!, style: TextStyle(color: c.danger, fontSize: 13)),
    );
  }
}
