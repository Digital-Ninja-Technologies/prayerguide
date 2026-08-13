import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme/pg_colors.dart';

class PgNavItem {
  const PgNavItem(this.icon, this.label, this.route);
  final IconData icon;
  final String label;
  final String route;
}

const pgNavItems = [
  PgNavItem(Icons.home_rounded, 'Home', '/home'),
  PgNavItem(Icons.menu_book_rounded, 'Bible', '/bible'),
  PgNavItem(Icons.edit_note_rounded, 'Journal', '/journal'),
  PgNavItem(Icons.mic_rounded, 'Sermons', '/sermons'),
  PgNavItem(Icons.smart_display_rounded, 'Channel', '/channel'),
  PgNavItem(Icons.person_rounded, 'Profile', '/settings'),
];

/// Bottom tab bar: Home / Bible / Journal / Sermons / Channel / Profile.
///
/// A floating, frosted-glass pill — blurred translucent background, rounded
/// stadium shape, icon-only with an animated highlight pill behind the
/// active tab — in the style of Instagram/iOS's "liquid glass" tab bars,
/// rather than the old opaque, full-width, labelled bar.
class PgBottomNav extends StatelessWidget {
  const PgBottomNav({super.key, required this.currentRoute, required this.onTap});

  final String currentRoute;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
      child: SafeArea(
        top: false,
        minimum: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: c.surface.withValues(alpha: 0.66),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: c.line2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final item in pgNavItems)
                    _NavButton(
                      item: item,
                      active: item.route == currentRoute,
                      onTap: () => onTap(item.route),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.item, required this.active, required this.onTap});

  final PgNavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = active ? c.teal : c.faint;
    return Tooltip(
      message: item.label,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(horizontal: active ? 16 : 11, vertical: 10),
          decoration: BoxDecoration(
            color: active ? c.teal.withValues(alpha: 0.16) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(item.icon, size: 22, color: color),
        ),
      ),
    );
  }
}
