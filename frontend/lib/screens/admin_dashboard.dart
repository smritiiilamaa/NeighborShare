import 'package:flutter/material.dart';

import '../services/admin_session.dart';
import 'reports.dart';
import 'flagged_listings.dart';
import 'user_information.dart';
import 'feedback_page.dart';
import 'order_history.dart';
import 'incident_report.dart';
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
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        elevation: 0,
        title: const Text(
          "Admin Dashboard",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),

      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.green.shade700,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.admin_panel_settings,
                      size: 35,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "Administrator",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "NeighbourShare",
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            _drawerItem(
              context,
              Icons.dashboard,
              "Dashboard",
              null,
            ),

            _drawerItem(
              context,
              Icons.bar_chart,
              "Reports",
              const ReportsPage(),
            ),

            _drawerItem(
              context,
              Icons.flag,
              "Flagged Listings",
              const FlaggedListingsPage(),
            ),

            _drawerItem(
              context,
              Icons.people,
              "User Information",
              const UserInformationPage(),
            ),

            _drawerItem(
              context,
              Icons.feedback,
              "Feedback",
              const FeedbackPage(),
            ),

            _drawerItem(
              context,
              Icons.history,
              "Order History",
              const OrderHistoryPage(),
            ),

            _drawerItem(
              context,
              Icons.description,
              "Incident Reports",
              const IncidentReportPage(),
            ),

            const Divider(),

            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Logout"),
              onTap: () {
                AdminSession.logout();

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminLoginScreen(),
                  ),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              "Welcome, Admin 👋",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "Manage users, food listings and platform activities.",
            ),

            const SizedBox(height: 25),

            Row(
              children: [
                Expanded(
                  child: _statCard(
                    "Users",
                    "152",
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _statCard(
                    "Listings",
                    "89",
                    Icons.fastfood,
                    Colors.orange,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            Row(
              children: [
                Expanded(
                  child: _statCard(
                    "Reports",
                    "12",
                    Icons.report,
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _statCard(
                    "Feedback",
                    "36",
                    Icons.feedback,
                    Colors.green,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            const Text(
              "Quick Actions",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 1.1,
              children: [

                _actionCard(
                  context,
                  Icons.bar_chart,
                  "Generate Reports",
                  Colors.blue,
                  const ReportsPage(),
                ),

                _actionCard(
                  context,
                  Icons.flag,
                  "Flagged Listings",
                  Colors.red,
                  const FlaggedListingsPage(),
                ),

                _actionCard(
                  context,
                  Icons.people,
                  "User Information",
                  Colors.deepPurple,
                  const UserInformationPage(),
                ),

                _actionCard(
                  context,
                  Icons.feedback,
                  "Feedback",
                  Colors.teal,
                  const FeedbackPage(),
                ),

                _actionCard(
                  context,
                  Icons.history,
                  "Order History",
                  Colors.orange,
                  const OrderHistoryPage(),
                ),

                _actionCard(
                  context,
                  Icons.description,
                  "Incident Reports",
                  Colors.green,
                  const IncidentReportPage(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(
      BuildContext context,
      IconData icon,
      String title,
      Widget? page,
      ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);

        if (page != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => page,
            ),
          );
        }
      },
    );
  }

  Widget _statCard(
      String title,
      String value,
      IconData icon,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            blurRadius: 6,
            color: Colors.black12,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 35),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(title),
        ],
      ),
    );
  }

  Widget _actionCard(
      BuildContext context,
      IconData icon,
      String title,
      Color color,
      Widget page,
      ) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => page,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(
                icon,
                color: color,
                size: 30,
              ),
            ),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
