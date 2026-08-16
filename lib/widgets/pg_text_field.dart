import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/pg_colors.dart';

/// Rounded surface input field matching the prototype's form fields.
class PgTextField extends StatefulWidget {
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
    this.inputFormatters,
  });

  final TextEditingController? controller;
  final String? hint;
  final List<TextInputFormatter>? inputFormatters;

  /// When true, this is a password-style field: text starts hidden and an
  /// eye icon lets the user reveal/hide it.
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
  State<PgTextField> createState() => _PgTextFieldState();
}

class _PgTextFieldState extends State<PgTextField> {
  late bool _obscured = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color),
        );
    return TextField(
      controller: widget.controller,
      obscureText: _obscured,
      keyboardType: widget.keyboardType,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      inputFormatters: widget.inputFormatters,
      style: TextStyle(
        color: c.text,
        fontSize: 15.5,
        fontWeight: widget.fontWeight,
        fontFamily: widget.serif ? 'Spectral' : null,
      ),
      cursorColor: c.teal,
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: TextStyle(color: c.faint, fontWeight: FontWeight.w500),
        filled: true,
        fillColor: c.surface,
        contentPadding: const EdgeInsets.all(15),
        border: border(c.line),
        enabledBorder: border(c.line),
        focusedBorder: border(c.teal),
        errorText: widget.errorText,
        errorMaxLines: 2,
        errorStyle: TextStyle(
            color: c.danger, fontSize: 12.5, fontWeight: FontWeight.w600),
        errorBorder: border(c.danger),
        focusedErrorBorder: border(c.danger),
        suffixIcon: widget.obscureText
            ? IconButton(
                onPressed: () => setState(() => _obscured = !_obscured),
                icon: Icon(
                  _obscured
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                  color: c.faint,
                ),
              )
            : null,
      ),
    );
  }
}
