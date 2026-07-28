import 'package:flutter/material.dart';

import '../core/theme/pg_colors.dart';

/// Rounded surface input field matching the prototype's form fields.
class PgTextField extends StatelessWidget {
  const PgTextField({
    super.key,
    this.controller,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
    this.serif = false,
    this.fontWeight = FontWeight.w600,
    this.errorText,
  });

  final TextEditingController? controller;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool serif;
  final FontWeight fontWeight;

  /// Shows this field in its error state: a danger-colored border plus an
  /// inline message below, matching the field-level validation style used
  /// across the app's forms (e.g. "Give this entry a title.").
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color),
        );
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(
        color: c.text,
        fontSize: 15.5,
        fontWeight: fontWeight,
        fontFamily: serif ? 'Spectral' : null,
      ),
      cursorColor: c.teal,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: c.faint, fontWeight: FontWeight.w500),
        filled: true,
        fillColor: c.surface,
        contentPadding: const EdgeInsets.all(15),
        border: border(c.line),
        enabledBorder: border(c.line),
        focusedBorder: border(c.teal),
        errorText: errorText,
        errorMaxLines: 2,
        errorStyle: TextStyle(
            color: c.danger, fontSize: 12.5, fontWeight: FontWeight.w600),
        errorBorder: border(c.danger),
        focusedErrorBorder: border(c.danger),
      ),
    );
  }
}
