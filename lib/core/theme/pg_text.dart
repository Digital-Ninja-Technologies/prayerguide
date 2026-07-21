import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography helpers matching the prototype: Spectral (serif) for scripture
/// and headings, Manrope (sans) for UI chrome.
class PgText {
  static TextStyle serif({
    double size = 16,
    FontWeight weight = FontWeight.w500,
    Color? color,
    double? height,
    FontStyle style = FontStyle.normal,
    double? letterSpacing,
  }) {
    return GoogleFonts.spectral(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      fontStyle: style,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle sans({
    double size = 14,
    FontWeight weight = FontWeight.w500,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.manrope(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// Uppercase eyebrow / section label style used throughout the app.
  static TextStyle eyebrow({Color? color, double size = 12}) {
    return sans(
      size: size,
      weight: FontWeight.w700,
      color: color,
      letterSpacing: 1,
    );
  }
}
