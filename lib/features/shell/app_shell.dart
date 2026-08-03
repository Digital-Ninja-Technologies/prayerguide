import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/pg_bottom_nav.dart';

/// Wraps the primary tabs (Home, Bible, Journal, Sermons, Profile)
/// with the persistent bottom nav bar.
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
