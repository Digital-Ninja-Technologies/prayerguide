import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/friendly_error.dart';
import '../../core/theme/pg_colors.dart';
import '../../core/theme/pg_text.dart';
import '../../state/profile_provider.dart';
import '../../widgets/pg_button.dart';
import '../../widgets/pg_header.dart';
import '../../widgets/username_field.dart';

/// Two roles in one screen:
/// - The forced one-time gate for any account without a username yet
///   (`/choose-username`, `canGoBack: false`) — the router's `redirect`
///   sends every logged-in user here until they pick one, and away again
///   the moment they do, so there's no explicit navigation call on success;
///   it just happens as a side effect of `setUsername` updating the profile.
/// - "Change username" from Settings (`/settings/username`, `canGoBack:
///   true`), pre-filled with the current value.
class ChooseUsernameScreen extends ConsumerStatefulWidget {
  const ChooseUsernameScreen({super.key, this.canGoBack = false});
  final bool canGoBack;

  @override
  ConsumerState<ChooseUsernameScreen> createState() => _ChooseUsernameScreenState();
}

class _ChooseUsernameScreenState extends ConsumerState<ChooseUsernameScreen> {
  late final _controller = TextEditingController(
    text: ref.read(profileProvider).valueOrNull?.username ?? '',
  );
  UsernameFieldStatus _status = UsernameFieldStatus.empty;
  bool _saving = false;
  String? _error;

  Future<void> _submit() async {
    if (_status != UsernameFieldStatus.available || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(profileProvider.notifier)
          .setUsername(_controller.text.trim());
      if (widget.canGoBack && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Username updated')));
        context.pop();
      }
      // Forced gate: no manual navigation — the router redirects to /home
      // on its own once profileProvider reflects the new username.
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().contains('23505') || e.toString().contains('duplicate')
              ? 'That username was just taken — try another.'
              : friendlyErrorMessage(e);
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final currentUsername = ref.read(profileProvider).valueOrNull?.username;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 6, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.canGoBack)
                PgHeader(title: 'Change username', onBack: () => context.pop())
              else
                const SizedBox(height: 24),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!widget.canGoBack) ...[
                          Text('Choose a username',
                              style: PgText.serif(size: 26, weight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Text(
                            "This is how others find and share with you on Prayer Guide.",
                            style: TextStyle(fontSize: 14.5, height: 1.5, color: c.dim),
                          ),
                          const SizedBox(height: 22),
                        ],
                        UsernameField(
                          controller: _controller,
                          currentUsername: currentUsername,
                          onStatusChanged: (s) => setState(() => _status = s),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 10),
                          Text(_error!, style: TextStyle(color: c.danger, fontSize: 12.5)),
                        ],
                        const SizedBox(height: 18),
                        PgButton(
                          label: _saving ? 'Saving…' : 'Continue',
                          onPressed: _status == UsernameFieldStatus.available && !_saving
                              ? _submit
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
