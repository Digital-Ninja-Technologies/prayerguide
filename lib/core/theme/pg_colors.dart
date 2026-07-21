import 'package:flutter/material.dart';

/// Design tokens ported 1:1 from the Claude Design prototype's CSS custom
/// properties (see project/PrayerGuide.dc.html, Component.vars()).
class PgColors extends ThemeExtension<PgColors> {
  const PgColors({
    required this.bg,
    required this.bg2,
    required this.surface,
    required this.surface2,
    required this.line,
    required this.line2,
    required this.teal,
    required this.tealDeep,
    required this.tealSoft,
    required this.amber,
    required this.amberSoft,
    required this.text,
    required this.dim,
    required this.faint,
    required this.danger,
    required this.onTeal,
    required this.onAmber,
  });

  final Color bg;
  final Color bg2;
  final Color surface;
  final Color surface2;
  final Color line;
  final Color line2;
  final Color teal;
  final Color tealDeep;
  final Color tealSoft;
  final Color amber;
  final Color amberSoft;
  final Color text;
  final Color dim;
  final Color faint;
  final Color danger;

  /// Text color used on solid teal buttons/surfaces (`#052019` in the source).
  final Color onTeal;

  /// Text color used on solid amber buttons/surfaces (`#2a1a05` in the source).
  final Color onAmber;

  static const dark = PgColors(
    bg: Color(0xFF0E1513),
    bg2: Color(0xFF0A100E),
    surface: Color(0xFF17211F),
    surface2: Color(0xFF1F2B28),
    line: Color(0x13FFFFFF),
    line2: Color(0x24FFFFFF),
    teal: Color(0xFF5BC2B3),
    tealDeep: Color(0xFF2E9488),
    tealSoft: Color(0x215BC2B3),
    amber: Color(0xFFE8B36B),
    amberSoft: Color(0x24E8B36B),
    text: Color(0xFFECEAE3),
    dim: Color(0xFF9AA8A3),
    faint: Color(0xFF5E6D69),
    danger: Color(0xFFC98B8B),
    onTeal: Color(0xFF052019),
    onAmber: Color(0xFF2A1A05),
  );

  static const light = PgColors(
    bg: Color(0xFFF5F2EB),
    bg2: Color(0xFFECE7DD),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFF7F3EB),
    line: Color(0x1A182E2A),
    line2: Color(0x2E182E2A),
    teal: Color(0xFF2E9488),
    tealDeep: Color(0xFF1F726A),
    tealSoft: Color(0x1C2E9488),
    amber: Color(0xFFB9821F),
    amberSoft: Color(0x21B9821F),
    text: Color(0xFF1A2523),
    dim: Color(0xFF586662),
    faint: Color(0xFF95A09B),
    danger: Color(0xFFB26A6A),
    onTeal: Color(0xFF052019),
    onAmber: Color(0xFF2A1A05),
  );

  @override
  PgColors copyWith({
    Color? bg,
    Color? bg2,
    Color? surface,
    Color? surface2,
    Color? line,
    Color? line2,
    Color? teal,
    Color? tealDeep,
    Color? tealSoft,
    Color? amber,
    Color? amberSoft,
    Color? text,
    Color? dim,
    Color? faint,
    Color? danger,
    Color? onTeal,
    Color? onAmber,
  }) {
    return PgColors(
      bg: bg ?? this.bg,
      bg2: bg2 ?? this.bg2,
      surface: surface ?? this.surface,
      surface2: surface2 ?? this.surface2,
      line: line ?? this.line,
      line2: line2 ?? this.line2,
      teal: teal ?? this.teal,
      tealDeep: tealDeep ?? this.tealDeep,
      tealSoft: tealSoft ?? this.tealSoft,
      amber: amber ?? this.amber,
      amberSoft: amberSoft ?? this.amberSoft,
      text: text ?? this.text,
      dim: dim ?? this.dim,
      faint: faint ?? this.faint,
      danger: danger ?? this.danger,
      onTeal: onTeal ?? this.onTeal,
      onAmber: onAmber ?? this.onAmber,
    );
  }

  @override
  PgColors lerp(ThemeExtension<PgColors>? other, double t) {
    if (other is! PgColors) return this;
    return PgColors(
      bg: Color.lerp(bg, other.bg, t)!,
      bg2: Color.lerp(bg2, other.bg2, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      line: Color.lerp(line, other.line, t)!,
      line2: Color.lerp(line2, other.line2, t)!,
      teal: Color.lerp(teal, other.teal, t)!,
      tealDeep: Color.lerp(tealDeep, other.tealDeep, t)!,
      tealSoft: Color.lerp(tealSoft, other.tealSoft, t)!,
      amber: Color.lerp(amber, other.amber, t)!,
      amberSoft: Color.lerp(amberSoft, other.amberSoft, t)!,
      text: Color.lerp(text, other.text, t)!,
      dim: Color.lerp(dim, other.dim, t)!,
      faint: Color.lerp(faint, other.faint, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      onTeal: Color.lerp(onTeal, other.onTeal, t)!,
      onAmber: Color.lerp(onAmber, other.onAmber, t)!,
    );
  }
}

extension PgColorsContext on BuildContext {
  PgColors get colors => Theme.of(this).extension<PgColors>()!;
}
