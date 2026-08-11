import 'package:flutter/material.dart';

import '../services/admin_session.dart';
import 'admin_login.dart';

/// Wraps any admin-only screen. Renders [child] only when [AdminSession]
/// reports an authenticated admin; otherwise redirects to
/// [AdminLoginScreen] so unauthenticated users can never reach
/// admin-only resources by navigating directly to them.
class AdminRouteGuard extends StatelessWidget {
  final Widget child;

  const AdminRouteGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!AdminSession.isAuthenticated) {
      return const AdminLoginScreen();
    }

    return child;
  }
}
