import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/pg_colors.dart';
import '../state/repo_providers.dart';
import 'pg_text_field.dart';

enum UsernameFieldStatus { empty, invalidFormat, checking, available, taken, error }

final _formatRegex = RegExp(r'^[a-z0-9_]{3,20}$');

/// A username input with inline format validation and a debounced
/// live-availability check against `is_username_available` — shared between
/// the onboarding create-account form and ChooseUsernameScreen so the
/// checking logic only lives in one place.
class UsernameField extends ConsumerStatefulWidget {
  const UsernameField({
    super.key,
    required this.controller,
    required this.onStatusChanged,
    this.currentUsername,
  });

  final TextEditingController controller;
  final ValueChanged<UsernameFieldStatus> onStatusChanged;

  /// The user's own existing username (ChooseUsernameScreen reused from
  /// Settings) — re-entering it unchanged is always "available" without a
  /// round trip, since it's already theirs.
  final String? currentUsername;

  @override
  ConsumerState<UsernameField> createState() => _UsernameFieldState();
}

class _UsernameFieldState extends ConsumerState<UsernameField> {
  Timer? _debounce;
  UsernameFieldStatus _status = UsernameFieldStatus.empty;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    // Deferred a frame — calling setState (via _setStatus) synchronously
    // here would fire while this widget's own subtree is still mid-build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _onChanged();
    });
  }

  void _setStatus(UsernameFieldStatus status) {
    if (_status == status) return;
    setState(() => _status = status);
    widget.onStatusChanged(status);
  }

  void _onChanged() {
    _debounce?.cancel();
    final value = widget.controller.text.trim();
    if (value.isEmpty) {
      _setStatus(UsernameFieldStatus.empty);
      return;
    }
    if (!_formatRegex.hasMatch(value)) {
      _setStatus(UsernameFieldStatus.invalidFormat);
      return;
    }
    if (widget.currentUsername != null && value == widget.currentUsername) {
      _setStatus(UsernameFieldStatus.available);
      return;
    }
    _setStatus(UsernameFieldStatus.checking);
    _debounce = Timer(const Duration(milliseconds: 400), () => _check(value));
  }

  Future<void> _check(String value) async {
    try {
      final available = await ref
          .read(profileRepositoryProvider)
          .isUsernameAvailable(value);
      if (!mounted || widget.controller.text.trim() != value) return;
      _setStatus(available ? UsernameFieldStatus.available : UsernameFieldStatus.taken);
    } catch (_) {
      if (!mounted || widget.controller.text.trim() != value) return;
      _setStatus(UsernameFieldStatus.error);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  String? get _helperMessage {
    switch (_status) {
      case UsernameFieldStatus.empty:
        return null;
      case UsernameFieldStatus.invalidFormat:
        return '3-20 characters — lowercase letters, numbers, underscore only.';
      case UsernameFieldStatus.checking:
        return 'Checking availability…';
      case UsernameFieldStatus.available:
        return 'Available';
      case UsernameFieldStatus.taken:
        return 'That username is taken.';
      case UsernameFieldStatus.error:
        return "Couldn't check that — try again.";
    }
  }

  Color _helperColor(PgColors c) {
    switch (_status) {
      case UsernameFieldStatus.available:
        return c.teal;
      case UsernameFieldStatus.invalidFormat:
      case UsernameFieldStatus.taken:
      case UsernameFieldStatus.error:
        return c.danger;
      case UsernameFieldStatus.empty:
      case UsernameFieldStatus.checking:
        return c.faint;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final message = _helperMessage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PgTextField(
          controller: widget.controller,
          hint: 'username',
          inputFormatters: [
            TextInputFormatter.withFunction(
                (oldValue, newValue) => newValue.copyWith(text: newValue.text.toLowerCase())),
          ],
        ),
        if (message != null) ...[
          const SizedBox(height: 6),
          Text(message,
              style: TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w600, color: _helperColor(c))),
        ],
      ],
    );
  }
}
