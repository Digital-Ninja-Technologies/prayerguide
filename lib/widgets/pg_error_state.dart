import 'package:flutter/material.dart';

import '../core/errors/friendly_error.dart';
import '../core/theme/pg_colors.dart';
import '../core/theme/pg_text.dart';
import 'pg_button.dart';

/// A calm, on-brand stand-in for a screen/section that failed to load —
/// used wherever an `AsyncValue.error` or similar was previously rendered
/// as a raw `Text('Could not load X.\n$e')` exception dump. Give it the
/// actual error object (not a pre-formatted string) so it can translate it
/// via [friendlyErrorMessage] rather than showing something dev-facing.
class PgErrorState extends StatelessWidget {
  const PgErrorState({
    super.key,
    required this.error,
    this.onRetry,
    this.compact = false,
  });

  final Object error;

  /// Shown as a "Try again" button when set.
  final VoidCallback? onRetry;

  /// A smaller, inline variant for use inside a card/section rather than
  /// filling a whole screen.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final message = friendlyErrorMessage(error);
    return Padding(
      padding:
          EdgeInsets.symmetric(vertical: compact ? 24 : 56, horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 52 : 70,
            height: compact ? 52 : 70,
            decoration: BoxDecoration(
                color: c.surface2,
                borderRadius: BorderRadius.circular(compact ? 16 : 22)),
            child: Icon(Icons.cloud_off_rounded,
                size: compact ? 24 : 32, color: c.dim),
          ),
          SizedBox(height: compact ? 12 : 16),
          Text('Something went wrong',
              style: PgText.serif(
                  size: compact ? 16 : 19, weight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: compact ? 13 : 13.5, color: c.dim, height: 1.5),
          ),
          if (onRetry != null) ...[
            SizedBox(height: compact ? 14 : 18),
            PgButton(
                label: 'Try again',
                expand: false,
                dense: compact,
                onPressed: onRetry),
          ],
        ],
      ),
    );
  }
}
