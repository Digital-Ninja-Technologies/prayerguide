import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/subscription_provider.dart';
import '../theme/pg_colors.dart';
import '../../widgets/pg_button.dart';

/// Gate a premium feature at the point of use: if the user isn't on
/// Premium (or an active trial), shows a popup explaining what the feature
/// is and prompting them to upgrade — with a button that takes them to the
/// app's own Upgrade screen — then returns whether they're clear to
/// proceed. Call before navigating to (or unlocking) a premium-only
/// feature:
///
/// ```dart
/// onPressed: () async {
///   if (await requirePremium(
///     context,
///     ref,
///     feature: 'Focus Mode',
///     description: 'Silence distractions during prayer with a gentle, '
///         'distraction-free session timer.',
///   )) {
///     if (context.mounted) context.push('/focus/setup');
///   }
/// },
/// ```
Future<bool> requirePremium(
  BuildContext context,
  WidgetRef ref, {
  required String feature,
  required String description,
}) async {
  final status = await ref.read(subscriptionProvider.future);
  if (status.isActive) return true;
  if (!context.mounted) return false;
  return await _showPremiumUpsell(context, feature: feature, description: description) ?? false;
}

Future<bool?> _showPremiumUpsell(
  BuildContext context, {
  required String feature,
  required String description,
}) {
  final c = context.colors;
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(feature),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$feature is a Premium feature.',
            style: TextStyle(fontWeight: FontWeight.w700, color: c.text),
          ),
          const SizedBox(height: 8),
          Text(description, style: TextStyle(color: c.dim, height: 1.4)),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('Maybe later', style: TextStyle(color: c.dim)),
        ),
        PgButton(
          label: 'Upgrade to Premium',
          expand: false,
          dense: true,
          variant: PgButtonVariant.secondaryAmber,
          onPressed: () {
            Navigator.of(context).pop(false);
            context.push('/upgrade');
          },
        ),
      ],
    ),
  );
}
