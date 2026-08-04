import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/friendly_error.dart';
import '../../core/theme/pg_colors.dart';
import '../../core/theme/pg_text.dart';
import '../../state/repo_providers.dart';
import '../../widgets/pg_button.dart';
import '../../widgets/pg_form_error.dart';
import '../../widgets/pg_text_field.dart';

/// Reached only via the password-reset email's link, which puts the user in
/// a recovery session (see AuthRepository.sendPasswordReset and
/// app_router.dart's redirect for AuthChangeEvent.passwordRecovery) — this
/// screen is the second half of the "forgot password" flow the email starts.
class ResetPasswordConfirmScreen extends ConsumerStatefulWidget {
  const ResetPasswordConfirmScreen({super.key});

  @override
  ConsumerState<ResetPasswordConfirmScreen> createState() =>
      _ResetPasswordConfirmScreenState();
}

class _ResetPasswordConfirmScreenState
    extends ConsumerState<ResetPasswordConfirmScreen> {
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final password = _password.text;
    if (password.length < 8) {
      setState(() => _error = 'Use at least 8 characters.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).updatePassword(password);
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) setState(() => _error = friendlyErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -1),
            radius: 1.3,
            colors: [c.amberSoft, Colors.transparent],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(30, 36, 30, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                      color: c.tealSoft,
                      borderRadius: BorderRadius.circular(18)),
                  child:
                      Icon(Icons.lock_reset_rounded, size: 28, color: c.teal),
                ),
                const SizedBox(height: 20),
                Text('Set a new password',
                    style: PgText.serif(size: 27, weight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(
                  "You're almost there — choose a new password for your account.",
                  style: PgText.sans(size: 14.5, height: 1.6, color: c.dim),
                ),
                const SizedBox(height: 26),
                Text('NEW PASSWORD', style: PgText.eyebrow(color: c.dim)),
                const SizedBox(height: 8),
                PgTextField(
                  controller: _password,
                  hint: 'At least 8 characters',
                  obscureText: true,
                ),
                PgFormError(_error, topSpacing: 12),
                const Spacer(),
                PgButton(
                  label: _loading ? 'Saving…' : 'Save new password',
                  onPressed: _loading ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
