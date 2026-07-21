import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'pg_colors.dart';

class AppTheme {
  static ThemeData _build(PgColors c, Brightness brightness) {
    final base = ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: c.bg,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: c.teal,
        onPrimary: c.onTeal,
        secondary: c.amber,
        onSecondary: c.onAmber,
        error: c.danger,
        onError: Colors.white,
        surface: c.surface,
        onSurface: c.text,
      ),
      fontFamily: GoogleFonts.manrope().fontFamily,
      textTheme: GoogleFonts.manropeTextTheme().apply(
        bodyColor: c.text,
        displayColor: c.text,
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      dividerColor: c.line,
      extensions: [c],
    );
    return base;
  }

  static ThemeData get dark => _build(PgColors.dark, Brightness.dark);
  static ThemeData get light => _build(PgColors.light, Brightness.light);
}
