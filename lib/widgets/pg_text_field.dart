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
  });

  final TextEditingController? controller;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool serif;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.teal),
        ),
      ),
    );
  }
}
