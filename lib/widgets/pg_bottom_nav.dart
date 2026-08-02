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
  PgNavItem(Icons.local_fire_department_rounded, 'Streak', '/streak'),
  PgNavItem(Icons.person_rounded, 'Profile', '/settings'),
];

/// Bottom tab bar: Home / Bible / Journal / Sermons / Streak / Profile.
class PgBottomNav extends StatelessWidget {
  const PgBottomNav({super.key, required this.currentRoute, required this.onTap});

  final String currentRoute;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 9, 14, 0),
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
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
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, size: 23, color: color),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
