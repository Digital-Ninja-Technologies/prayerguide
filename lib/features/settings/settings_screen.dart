import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/errors/friendly_error.dart';
import '../../core/theme/pg_colors.dart';
import '../../core/theme/pg_text.dart';
import '../../data/models/subscription_status.dart';
import '../../state/profile_provider.dart';
import '../../state/repo_providers.dart';
import '../../state/subscription_provider.dart';
import '../../state/theme_provider.dart';
import '../../widgets/pg_toggle.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final profileAsync = ref.watch(profileProvider);
    final profile = profileAsync.valueOrNull;
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    final displayName =
        (profile?.name.isNotEmpty ?? false) ? profile!.name : 'Your name';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 6, 22, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('Profile',
                style: PgText.serif(size: 26, weight: FontWeight.w600)),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
                color: c.surface,
                border: Border.all(color: c.line),
                borderRadius: BorderRadius.circular(22)),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                        colors: [c.teal, c.tealDeep],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                  ),
                  alignment: Alignment.center,
                  child: Text(initial,
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: c.onTeal)),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(displayName,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700)),
                      Text(profile?.email ?? '',
                          style: TextStyle(fontSize: 13, color: c.dim)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _PremiumCard(
              onTap: () => context.push('/upgrade'),
              sub: ref.watch(subscriptionProvider).valueOrNull),
          const SizedBox(height: 22),
          Text('NOTIFICATIONS',
              style: PgText.sans(
                  size: 12,
                  weight: FontWeight.w700,
                  color: c.dim,
                  letterSpacing: 1)),
          const SizedBox(height: 12),
          _SettingsGroup(
            onTap: () => context.push('/notifications'),
            children: const [
              _ToggleRow(label: 'Daily prayer reminder', value: true),
              _ToggleRow(label: 'Scripture of the day', value: true),
              _ToggleRow(
                  label: 'Streak protection',
                  sub: "A gentle nudge only if you're about to miss a day",
                  value: false,
                  isLast: true),
            ],
          ),
          const SizedBox(height: 20),
          Text('APPEARANCE',
              style: PgText.sans(
                  size: 12,
                  weight: FontWeight.w700,
                  color: c.dim,
                  letterSpacing: 1)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: c.surface,
                border: Border.all(color: c.line),
                borderRadius: BorderRadius.circular(18)),
            child: Row(
              children: [
                Expanded(
                  child: _ThemeButton(
                    label: 'Dark',
                    icon: Icons.dark_mode_outlined,
                    active: isDark,
                    onTap: () => ref.read(themeModeProvider.notifier).setDark(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ThemeButton(
                    label: 'Light',
                    icon: Icons.light_mode_outlined,
                    active: !isDark,
                    onTap: () =>
                        ref.read(themeModeProvider.notifier).setLight(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
                color: c.surface,
                border: Border.all(color: c.line),
                borderRadius: BorderRadius.circular(18)),
            child: Column(
              children: [
                _LinkRow(
                  icon: Icons.local_fire_department_outlined,
                  label: 'Your streak',
                  onTap: () => context.push('/streak'),
                  showBorder: true,
                ),
                _LinkRow(
                  icon: Icons.lock_outline_rounded,
                  label: 'Privacy & encryption',
                  onTap: () => context.push('/privacy'),
                  showBorder: true,
                ),
                _LinkRow(
                    icon: Icons.help_outline_rounded,
                    label: 'About & help',
                    onTap: () => context.push('/about'),
                    showBorder: false),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => ref.read(authRepositoryProvider).signOut(),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: c.line2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('Sign out',
                  style: TextStyle(
                      color: c.danger,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 18),
          const Center(child: _DeleteAccountLink()),
          const SizedBox(height: 16),
          Center(
              child: Text('Prayer Guide · v1.0.0',
                  style: TextStyle(fontSize: 11.5, color: c.faint))),
        ],
      ),
    );
  }
}

class _PremiumCard extends StatelessWidget {
  const _PremiumCard({required this.onTap, required this.sub});
  final VoidCallback onTap;
  final SubscriptionStatus? sub;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final active = sub?.isActive ?? false;
    final title = active
        ? (sub!.isTrial ? 'Trial active' : 'Premium active')
        : 'Go Premium';
    final subtitle = active && sub!.isTrial && sub!.renewsAt != null
        ? 'Until ${DateFormat('MMM d').format(sub!.renewsAt!)} · Audio Bible, growth insights, unlimited companions'
        : 'Audio Bible, growth insights, unlimited companions';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [c.amberSoft, c.surface],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            border: Border.all(color: c.amber),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [c.amber, const Color(0xFF8A5A1A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                    active
                        ? Icons.check_rounded
                        : Icons.workspace_premium_outlined,
                    color: const Color(0xFF2A1A05)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800)),
                    Text(subtitle,
                        style: TextStyle(fontSize: 12.5, color: c.dim)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: c.amber),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children, this.onTap});
  final List<Widget> children;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
              color: c.surface,
              border: Border.all(color: c.line),
              borderRadius: BorderRadius.circular(18)),
          child: Column(children: children),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow(
      {required this.label,
      this.sub,
      required this.value,
      this.isLast = false});
  final String label;
  final String? sub;
  final bool value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
          border: isLast ? null : Border(bottom: BorderSide(color: c.line))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 14.5, fontWeight: FontWeight.w600)),
                if (sub != null)
                  Text(sub!, style: TextStyle(fontSize: 11.5, color: c.faint)),
              ],
            ),
          ),
          IgnorePointer(child: PgToggle(value: value)),
        ],
      ),
    );
  }
}

class _ThemeButton extends StatelessWidget {
  const _ThemeButton(
      {required this.label,
      required this.icon,
      required this.active,
      required this.onTap});
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: active ? c.teal : c.surface2,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: active ? null : Border.all(color: c.line)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: active ? c.onTeal : c.dim),
              const SizedBox(width: 7),
              Text(label,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: active ? c.onTeal : c.dim)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow(
      {required this.icon,
      required this.label,
      required this.onTap,
      required this.showBorder});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
            border:
                showBorder ? Border(bottom: BorderSide(color: c.line)) : null),
        child: Row(
          children: [
            Icon(icon, size: 19, color: c.teal),
            const SizedBox(width: 12),
            Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 14.5, fontWeight: FontWeight.w600))),
            Icon(Icons.chevron_right_rounded, size: 17, color: c.faint),
          ],
        ),
      ),
    );
  }
}

/// Deliberately understated — a small plain-text link, not a bordered
/// button like Sign out — since this is a rarely-needed, one-way action
/// that shouldn't visually compete with everyday settings. Apple App Store
/// Review Guideline 5.1.1(v) requires apps with account creation to offer
/// in-app deletion, not just an "email us" path.
class _DeleteAccountLink extends ConsumerStatefulWidget {
  const _DeleteAccountLink();

  @override
  ConsumerState<_DeleteAccountLink> createState() => _DeleteAccountLinkState();
}

class _DeleteAccountLinkState extends ConsumerState<_DeleteAccountLink> {
  bool _deleting = false;

  Future<void> _confirmAndDelete() async {
    final c = context.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete your account?'),
        content: const Text(
            "This permanently deletes your account and everything in it — journal, prayer requests, streak, companion pairing. This can't be undone."),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete my account', style: TextStyle(color: c.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await ref.read(authRepositoryProvider).deleteAccount();
      // No further navigation needed — deleteAccount() signs out, and the
      // router's own redirect takes it from there once currentUser is null.
    } catch (e) {
      if (mounted) {
        setState(() => _deleting = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return TextButton(
      onPressed: _deleting ? null : _confirmAndDelete,
      style: TextButton.styleFrom(
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap),
      child: Text(
        _deleting ? 'Deleting…' : 'Delete account',
        style: TextStyle(
            fontSize: 12, color: c.faint, fontWeight: FontWeight.w500),
      ),
    );
  }
}
