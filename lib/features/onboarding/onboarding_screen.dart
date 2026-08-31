import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthResponse;

import '../../core/errors/friendly_error.dart';
import '../../core/theme/pg_colors.dart';
import '../../core/theme/pg_text.dart';
import '../../state/repo_providers.dart';
import '../../widgets/google_logo.dart';
import '../../widgets/pg_back_button.dart';
import '../../widgets/pg_button.dart';
import '../../widgets/pg_form_error.dart';
import '../../widgets/pg_text_field.dart';
import '../../widgets/username_field.dart';

final bool _showAppleSignIn = !kIsWeb && Platform.isIOS;

enum _Step { slide0, slide1, slide2, auth, email, reset, create }

class _SlideData {
  const _SlideData(this.icon, this.title, this.body);
  final IconData icon;
  final String title;
  final String body;
}

const _slides = [
  _SlideData(
    Icons.wb_sunny_outlined,
    'Build a prayer life that lasts',
    'A gentle daily rhythm of Scripture, guided prayer, and stillness — one quiet moment at a time.',
  ),
  _SlideData(
    Icons.menu_book_outlined,
    'Scripture at the center',
    'Every session begins in the Word. Read, reflect, and let the text shape how you pray.',
  ),
  _SlideData(
    Icons.replay_outlined,
    'Return, without pressure',
    'Streaks encourage — they never shame. Miss a day, use a freeze, and simply begin again.',
  ),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  _Step _step = _Step.slide0;
  bool _loading = false;
  String? _error;
  String? _info;

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  UsernameFieldStatus _usernameStatus = UsernameFieldStatus.empty;

  int get _slideIndex => _step.index;

  void _next() {
    setState(() {
      if (_step == _Step.slide2) {
        _step = _Step.auth;
      } else {
        _step = _Step.values[_step.index + 1];
      }
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });
    try {
      await action();
    } catch (e) {
      setState(() => _error = friendlyErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _usernameCtrl.dispose();
    super.dispose();
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
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, 1.2),
              radius: 1.2,
              colors: [c.tealSoft, Colors.transparent],
            ),
          ),
          child: SafeArea(child: _buildStep(c)),
        ),
      ),
    );
  }

  Widget _buildStep(PgColors c) {
    switch (_step) {
      case _Step.slide0:
      case _Step.slide1:
      case _Step.slide2:
        return _buildSlide(c);
      case _Step.auth:
        return _buildAuth(c);
      case _Step.email:
        return _buildEmailSignIn(c);
      case _Step.reset:
        return _buildReset(c);
      case _Step.create:
        return _buildCreate(c);
    }
  }

  Widget _buildSlide(PgColors c) {
    final data = _slides[_slideIndex];
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 20, 32, 30),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => setState(() => _step = _Step.auth),
              child: Text('Skip',
                  style: PgText.sans(
                      size: 13.5, weight: FontWeight.w600, color: c.faint)),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.2),
                      colors: [c.amberSoft, c.tealSoft],
                    ),
                  ),
                  child: Icon(data.icon, size: 60, color: c.teal),
                ),
                const SizedBox(height: 26),
                Text(
                  data.title,
                  textAlign: TextAlign.center,
                  style: PgText.serif(
                      size: 28, weight: FontWeight.w600, height: 1.25),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: 270,
                  child: Text(
                    data.body,
                    textAlign: TextAlign.center,
                    style: PgText.sans(size: 15.5, height: 1.6, color: c.dim),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < 3; i++)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _slideIndex ? c.teal : c.line2,
                    ),
                  ),
              ],
            ),
          ),
          PgButton(
            label: _slideIndex >= 2 ? 'Get started' : 'Continue',
            onPressed: _next,
          ),
        ],
      ),
    );
  }

  Widget _buildAuth(PgColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 36, 30, 30),
      child: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/icon/flame_logo.png',
                    width: 72, height: 72),
                const SizedBox(height: 18),
                Text('Prayer Guide',
                    style: PgText.serif(size: 29, weight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(
                  'A quiet place to return to, each day.',
                  style: PgText.sans(size: 15, color: c.dim),
                ),
              ],
            ),
          ),
          PgFormError(_error, topSpacing: 0, bottomSpacing: 10),
          if (_showAppleSignIn) ...[
            PgButton(
              label: _loading ? 'Continuing…' : 'Continue with Apple',
              variant: PgButtonVariant.outline,
              icon: const Icon(Icons.apple, size: 20),
              onPressed: _loading
                  ? null
                  : () => _run(() async {
                        try {
                          await ref
                              .read(authRepositoryProvider)
                              .signInWithApple();
                        } on SignInWithAppleAuthorizationException catch (e) {
                          if (e.code == AuthorizationErrorCode.canceled) {
                            return;
                          }
                          rethrow;
                        }
                      }),
            ),
            const SizedBox(height: 10),
          ],
          PgButton(
            label: _loading ? 'Continuing…' : 'Continue with Google',
            variant: PgButtonVariant.outline,
            icon: const GoogleLogo(),
            onPressed: _loading
                ? null
                : () => _run(() async {
                      await ref.read(authRepositoryProvider).signInWithGoogle();
                    }),
          ),
          const SizedBox(height: 10),
          PgButton(
            label: 'Continue with email',
            icon: const Icon(Icons.mail_outline_rounded,
                size: 17, color: Colors.white),
            onPressed: () => setState(() => _step = _Step.email),
          ),
          const SizedBox(height: 6),
          Text(
            'By continuing you agree to our Terms & Privacy.\nYour journal is private and encrypted.',
            textAlign: TextAlign.center,
            style: PgText.sans(size: 11.5, height: 1.5, color: c.faint),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailSignIn(PgColors c) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(30, 26, 30, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PgBackButton(onTap: () => setState(() => _step = _Step.auth)),
          const SizedBox(height: 26),
          Text('Welcome back',
              style: PgText.serif(size: 27, weight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Sign in to continue your prayer life.',
              style: PgText.sans(size: 14.5, color: c.dim)),
          const SizedBox(height: 26),
          Text('EMAIL', style: PgText.eyebrow(color: c.dim)),
          const SizedBox(height: 8),
          PgTextField(
              controller: _emailCtrl,
              hint: 'you@email.com',
              keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('PASSWORD', style: PgText.eyebrow(color: c.dim)),
              TextButton(
                onPressed: () => setState(() => _step = _Step.reset),
                child: Text('Forgot?',
                    style: TextStyle(
                        color: c.teal,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5)),
              ),
            ],
          ),
          PgTextField(
              controller: _passwordCtrl, hint: '••••••••', obscureText: true),
          PgFormError(_error, topSpacing: 12),
          if (_info != null) ...[
            const SizedBox(height: 12),
            Text(_info!, style: TextStyle(color: c.teal, fontSize: 13)),
          ],
          const SizedBox(height: 28),
          PgButton(
            label: _loading ? 'Signing in…' : 'Sign in',
            onPressed: _loading
                ? null
                : () => _run(() async {
                      await ref.read(authRepositoryProvider).signInWithEmail(
                            email: _emailCtrl.text.trim(),
                            password: _passwordCtrl.text,
                          );
                    }),
          ),
          const SizedBox(height: 14),
          Center(
            child: Wrap(
              children: [
                Text('New here? ', style: PgText.sans(size: 13, color: c.dim)),
                GestureDetector(
                  onTap: () => setState(() => _step = _Step.create),
                  child: Text('Create an account',
                      style: TextStyle(
                          color: c.teal,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReset(PgColors c) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(30, 26, 30, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PgBackButton(onTap: () => setState(() => _step = _Step.email)),
          const SizedBox(height: 26),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
                color: c.tealSoft, borderRadius: BorderRadius.circular(18)),
            child: Icon(Icons.mail_outline_rounded, size: 28, color: c.teal),
          ),
          const SizedBox(height: 20),
          Text('Reset password',
              style: PgText.serif(size: 27, weight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            "Enter your email and we'll send you a secure link to set a new password.",
            style: PgText.sans(size: 14.5, height: 1.6, color: c.dim),
          ),
          const SizedBox(height: 26),
          Text('EMAIL', style: PgText.eyebrow(color: c.dim)),
          const SizedBox(height: 8),
          PgTextField(
              controller: _emailCtrl,
              hint: 'you@email.com',
              keyboardType: TextInputType.emailAddress),
          PgFormError(_error, topSpacing: 12),
          const SizedBox(height: 28),
          PgButton(
            label: _loading ? 'Sending…' : 'Send reset link',
            onPressed: _loading
                ? null
                : () => _run(() async {
                      await ref
                          .read(authRepositoryProvider)
                          .sendPasswordReset(_emailCtrl.text.trim());
                      if (mounted) {
                        setState(() {
                          _step = _Step.email;
                          _info = 'Check your email for a reset link.';
                        });
                      }
                    }),
          ),
        ],
      ),
    );
  }

  Widget _buildCreate(PgColors c) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(30, 26, 30, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PgBackButton(onTap: () => setState(() => _step = _Step.email)),
          const SizedBox(height: 22),
          Text('Create your account',
              style: PgText.serif(size: 27, weight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Begin a prayer life you can return to.',
              style: PgText.sans(size: 14.5, color: c.dim)),
          const SizedBox(height: 22),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('FIRST NAME', style: PgText.eyebrow(color: c.dim)),
                    const SizedBox(height: 8),
                    PgTextField(controller: _firstNameCtrl, hint: 'First'),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('LAST NAME', style: PgText.eyebrow(color: c.dim)),
                    const SizedBox(height: 8),
                    PgTextField(controller: _lastNameCtrl, hint: 'Last'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text('USERNAME', style: PgText.eyebrow(color: c.dim)),
          const SizedBox(height: 8),
          UsernameField(
            controller: _usernameCtrl,
            onStatusChanged: (s) => setState(() => _usernameStatus = s),
          ),
          const SizedBox(height: 14),
          Text('EMAIL', style: PgText.eyebrow(color: c.dim)),
          const SizedBox(height: 8),
          PgTextField(
              controller: _emailCtrl,
              hint: 'you@email.com',
              keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 14),
          Text('PASSWORD', style: PgText.eyebrow(color: c.dim)),
          const SizedBox(height: 8),
          PgTextField(
              controller: _passwordCtrl,
              hint: 'At least 8 characters',
              obscureText: true),
          PgFormError(_error, topSpacing: 12),
          if (_info != null) ...[
            const SizedBox(height: 12),
            Text(_info!, style: TextStyle(color: c.teal, fontSize: 13)),
          ],
          const SizedBox(height: 28),
          PgButton(
            label: _loading ? 'Creating…' : 'Create account',
            onPressed: _loading || _usernameStatus != UsernameFieldStatus.available
                ? null
                : () => _run(() async {
                      final AuthResponse response;
                      try {
                        response = await ref
                            .read(authRepositoryProvider)
                            .signUpWithEmail(
                              email: _emailCtrl.text.trim(),
                              password: _passwordCtrl.text,
                              name:
                                  '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}'
                                      .trim(),
                              username: _usernameCtrl.text.trim(),
                            );
                      } catch (e) {
                        // The username is inserted in the same DB transaction
                        // as the account itself (see handle_new_user()) — if
                        // someone else grabbed it between the live check and
                        // this submit, the whole signUp() call fails (no
                        // orphan account is left) with a Postgres-trigger
                        // error wrapped in an AuthException, not the clean
                        // PostgrestException friendlyErrorMessage() expects.
                        final msg = e.toString().toLowerCase();
                        if (msg.contains('username') || msg.contains('duplicate')) {
                          if (mounted) {
                            setState(() =>
                                _error = 'That username was just taken — try another.');
                          }
                          return;
                        }
                        rethrow;
                      }
                      if (!mounted) return;
                      if (response.session == null) {
                        setState(() => _info =
                            "Account created. Check your email to confirm before signing in.");
                        return;
                      }
                      context.go('/home');
                    }),
          ),
          const SizedBox(height: 12),
          Text(
            'By creating an account you agree to our Terms & Privacy.\nYour journal stays private and encrypted.',
            textAlign: TextAlign.center,
            style: PgText.sans(size: 11.5, height: 1.5, color: c.faint),
          ),
        ],
      ),
    );
  }
}
