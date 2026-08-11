import 'package:flutter/material.dart';

import '../services/admin_session.dart';
import 'admin_login.dart';

/// Placeholder landing screen behind [AdminRouteGuard], standing in until
/// the full dashboard layout (moderation panel, reports, analytics) is
/// built out. Exists so role-based access control has a real screen to
/// protect and can be demonstrated end-to-end.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: () {
              AdminSession.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified_user, size: 64, color: Color(0xFF2E7D32)),
              SizedBox(height: 16),
              Text(
                'Access granted — you are logged in as Administrator.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
