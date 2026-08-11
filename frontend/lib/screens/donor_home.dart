import 'package:flutter/material.dart';
import 'donor_profile.dart';
import 'recipient_profile.dart';
import 'browse_listings.dart';
import 'create_listing.dart';
import 'my_listings.dart';
import 'admin_route_guard.dart';
import 'admin_dashboard.dart';

class DonorHomeScreen extends StatefulWidget {
  const DonorHomeScreen({super.key});

  @override
  State<DonorHomeScreen> createState() => _DonorHomeScreenState();
}

class _DonorHomeScreenState extends State<DonorHomeScreen> {
  int _selectedIndex = 0;

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CreateDonorProfileScreen(),
          ),
        );
        break;

      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const BrowseListingsScreen(),
          ),
        );
        break;

      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const MyListingsScreen(),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    final bool isSmallScreen = screenWidth < 360;
    final bool isLargeScreen = screenWidth >= 600;

    final double horizontalPadding = isSmallScreen
        ? 12
        : isLargeScreen
            ? 32
            : 20;

    final double titleFontSize = isSmallScreen
        ? 22
        : isLargeScreen
            ? 32
            : 28;

    final double descriptionFontSize = isSmallScreen
        ? 14
        : isLargeScreen
            ? 18
            : 16;

    final double iconSize = isSmallScreen
        ? 65
        : isLargeScreen
            ? 110
            : 90;

    final double buttonHeight = isSmallScreen
        ? 48
        : isLargeScreen
            ? 60
            : 55;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'NeighbourShare',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isSmallScreen ? 18 : 20,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 20,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 600,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 10),

                      Icon(
                        Icons.volunteer_activism,
                        color: const Color(0xFF2E7D32),
                        size: iconSize,
                      ),

                      const SizedBox(height: 20),

                      Text(
                        'Welcome to NeighbourShare!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        'Help reduce food waste by donating surplus food or '
                        'browse available food donations in your community.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: descriptionFontSize,
                          color: Colors.black87,
                        ),
                      ),

                      SizedBox(
                        height: isSmallScreen ? 25 : 35,
                      ),

                      SizedBox(
                        height: buttonHeight,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.search),
                          label: const Text('Browse Listings'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const BrowseListingsScreen(),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 15),

                      SizedBox(
                        height: buttonHeight,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.person),
                          label: const Text('Create Donor Profile'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF388E3C),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const CreateDonorProfileScreen(),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 15),

                      SizedBox(
                        height: buttonHeight,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.people),
                          label: const Text('Create Recipient Profile'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const CreateRecipientProfileScreen(),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 15),

                      SizedBox(
                        height: buttonHeight,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add_box),
                          label: const Text('Create Listing'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF43A047),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const CreateListingScreen(),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 15),

                      SizedBox(
                        height: buttonHeight,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.list_alt),
                          label: const Text('My Listings'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF66BB6A),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const MyListingsScreen(),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 15),

                      SizedBox(
                        height: buttonHeight,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.admin_panel_settings),
                          label: const Text('Admin'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2E7D32),
                            side: const BorderSide(
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                          onPressed: () {
                            // Guarded — routes to the Admin Dashboard
                            // only if AdminSession reports an
                            // authenticated admin, otherwise falls
                            // back to AdminLoginScreen.
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AdminRouteGuard(
                                  child: AdminDashboardScreen(),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF2E7D32),
        unselectedItemColor: Colors.grey,
        selectedFontSize: isSmallScreen ? 10 : 12,
        unselectedFontSize: isSmallScreen ? 9 : 11,
        onTap: _onNavTap,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Browse',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'My Listings',
          ),
        ],
      ),
    );
  }
}