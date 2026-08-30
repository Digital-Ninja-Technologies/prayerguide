import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/friendly_error.dart';
import '../../core/theme/pg_colors.dart';
import '../../core/theme/pg_text.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../state/locale_provider.dart';
import '../../state/profile_provider.dart';
import '../../state/repo_providers.dart';
import '../../state/theme_provider.dart';
import '../../widgets/pg_toggle.dart';

Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
  final c = context.colors;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Text('Sign out?'),
      content: const Text("You'll need to sign back in to continue."),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text('Sign out', style: TextStyle(color: c.danger)),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    await ref.read(authRepositoryProvider).signOut();
  }
}

/// Each language's own name for itself — endonyms aren't translated (a
/// Yoruba speaker sees "Yorùbá" no matter which language the app is
/// currently in, same as any other app's language picker).
const _languageEndonyms = {
  null: 'English', // null = "follow device", shown as English until picked
  'en': 'English',
  'es': 'Español',
  'fr': 'Français',
  'pt': 'Português',
  'yo': 'Yorùbá',
  'ig': 'Igbo',
};

String _languageEndonym(String? code) => _languageEndonyms[code] ?? 'English';

void _showLanguagePicker(BuildContext context, WidgetRef ref, AppLocalizations l) {
  final c = context.colors;
  final current = ref.read(localeProvider)?.languageCode;
  showModalBottomSheet(
    context: context,
    backgroundColor: c.surface,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 34),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.settingsChooseLanguage,
              style: PgText.serif(size: 19, weight: FontWeight.w600)),
          const SizedBox(height: 14),
          for (final code in const ['en', 'es', 'fr', 'pt', 'yo', 'ig'])
            InkWell(
              onTap: () {
                ref.read(localeProvider.notifier).setLocale(Locale(code));
                Navigator.of(sheetContext).pop();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 13),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(_languageEndonym(code),
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: c.text)),
                    ),
                    if (current == code)
                      Icon(Icons.check_rounded, color: c.teal, size: 20),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(profileProvider);
    final profile = profileAsync.valueOrNull;
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final locale = ref.watch(localeProvider);

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
            child: Text(l.settingsProfile,
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
                      if (profile?.username != null)
                        Text('@${profile!.username}',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: c.teal)),
                      Text(profile?.email ?? '',
                          style: TextStyle(fontSize: 13, color: c.dim)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text(l.settingsNotifications,
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
          Text(l.settingsAppearance,
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
                    label: l.settingsDark,
                    icon: Icons.dark_mode_outlined,
                    active: isDark,
                    onTap: () => ref.read(themeModeProvider.notifier).setDark(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ThemeButton(
                    label: l.settingsLight,
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
            child: _LinkRow(
              icon: Icons.translate_rounded,
              label:
                  '${l.settingsLanguage} · ${_languageEndonym(locale?.languageCode)}',
              onTap: () => _showLanguagePicker(context, ref, l),
              showBorder: false,
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
                  icon: Icons.alternate_email_rounded,
                  label: l.settingsChangeUsername,
                  onTap: () => context.push('/settings/username'),
                  showBorder: true,
                ),
                _LinkRow(
                  icon: Icons.local_fire_department_outlined,
                  label: l.settingsYourStreak,
                  onTap: () => context.push('/streak'),
                  showBorder: true,
                ),
                _LinkRow(
                  icon: Icons.insights_outlined,
                  label: l.settingsGrowthInsights,
                  onTap: () => context.push('/insights'),
                  showBorder: true,
                ),
                _LinkRow(
                  icon: Icons.lock_outline_rounded,
                  label: l.settingsPrivacyEncryption,
                  onTap: () => context.push('/privacy'),
                  showBorder: true,
                ),
                _LinkRow(
                    icon: Icons.help_outline_rounded,
                    label: l.settingsAboutHelp,
                    onTap: () => context.push('/about'),
                    showBorder: false),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _confirmSignOut(context, ref),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: c.line2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(l.settingsSignOut,
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
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
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
