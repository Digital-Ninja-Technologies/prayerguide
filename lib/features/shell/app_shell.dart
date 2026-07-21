import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/pg_bottom_nav.dart';

/// Wraps the 5 primary tabs (Home, Bible, Journal, Streak, Profile) with the
/// persistent bottom nav bar, matching the prototype's app shell.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(bottom: false, child: shell),
      bottomNavigationBar: PgBottomNav(
        currentRoute: pgNavItems[shell.currentIndex].route,
        onTap: (route) {
          final index = pgNavItems.indexWhere((i) => i.route == route);
          shell.goBranch(index, initialLocation: index == shell.currentIndex);
        },
      ),
    );
  }
}
