import 'package:flutter/material.dart';

import '../../core/theme/pg_text.dart';

/// The image saved/shared for a devotional — a fixed, self-contained visual
/// (not the on-screen DevotionalScreen, which has navigation chrome that
/// makes no sense outside the app). Colors are hardcoded to the dark
/// palette rather than read from `context.colors` deliberately: this image
/// travels outside the app, so it needs to look the same regardless of the
/// sharer's or viewer's device theme. Mirrors scripture_share_card.dart's
/// exact structure/branding.
class DevotionalShareCard extends StatelessWidget {
  const DevotionalShareCard({
    super.key,
    required this.title,
    required this.question,
    required this.reference,
    required this.dateLabel,
  });

  final String title;
  final String question;
  final String reference;
  final String dateLabel;

  static const width = 360.0;
  static const height = 450.0;

  static const _bg = Color(0xFF0E1513);
  static const _bg2 = Color(0xFF17211F);
  static const _line = Color(0x1EFFFFFF);
  static const _teal = Color(0xFF5BC2B3);
  static const _amber = Color(0xFFE8B36B);
  static const _text = Color(0xFFECEAE3);
  static const _dim = Color(0xFF9AA8A3);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(color: _bg),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Row(
              children: [
                Image.asset('assets/icon/flame_logo.png',
                    width: 20, height: 20),
                const SizedBox(width: 8),
                Text('Prayer Guide',
                    style: PgText.serif(
                        size: 13, weight: FontWeight.w600, color: _text)),
                const Spacer(),
                Text(dateLabel.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: _dim)),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('DEVOTIONAL',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                          color: _teal)),
                  const SizedBox(height: 10),
                  Text(title,
                      textAlign: TextAlign.center,
                      style: PgText.serif(
                          size: 22, weight: FontWeight.w600, color: _text)),
                  const SizedBox(height: 16),
                  Text(
                    '"$question"',
                    textAlign: TextAlign.center,
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                    style: PgText.serif(
                        size: 17,
                        weight: FontWeight.w500,
                        style: FontStyle.italic,
                        height: 1.45,
                        color: _text),
                  ),
                  const SizedBox(height: 14),
                  Text(reference,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700, color: _amber)),
                ],
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
            decoration: const BoxDecoration(
              color: _bg2,
              border: Border(top: BorderSide(color: _line)),
            ),
            child: Column(
              children: [
                Text('Build a prayer life that lasts',
                    textAlign: TextAlign.center,
                    style: PgText.serif(size: 14, weight: FontWeight.w600, color: _text)),
                const SizedBox(height: 4),
                const Text('Download Prayer Guide free to enjoy this every day',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: _dim)),
                const SizedBox(height: 12),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _StorePill(icon: Icons.apple, label: 'App Store'),
                    SizedBox(width: 10),
                    _StorePill(icon: Icons.android_rounded, label: 'Google Play'),
                  ],
                ),
                const SizedBox(height: 10),
                const Text('prayerguide.thedigitalninjatech.com',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: _dim)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StorePill extends StatelessWidget {
  const _StorePill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: DevotionalShareCard._teal.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DevotionalShareCard._teal.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: DevotionalShareCard._teal),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: DevotionalShareCard._teal)),
        ],
      ),
    );
  }
}
