import 'package:flutter/material.dart';

import 'admin_dashboard.dart';
import 'admin_route_guard.dart';
import 'browse_listings.dart';
import 'create_listing.dart';
import 'donor_profile.dart';
import 'my_listings.dart';
import 'recipient_profile.dart';

class DonorHomeScreen extends StatefulWidget {
  final int? accountId;

  const DonorHomeScreen({
    super.key,
    this.accountId,
  });

  @override
  State<DonorHomeScreen> createState() => _DonorHomeScreenState();
}

class _DonorHomeScreenState extends State<DonorHomeScreen> {
  int _selectedIndex = 0;

  void _openDonorProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateDonorProfileScreen(),
      ),
    );
  }

  void _openRecipientProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateRecipientProfileScreen(),
      ),
    );
  }

  void _openBrowseListings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const BrowseListingsScreen(),
      ),
    );
  }

  void _openCreateListing() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateListingScreen(
          accountId: widget.accountId,
        ),
      ),
    );
  }

  void _openMyListings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MyListingsScreen(
          accountId: widget.accountId,
        ),
      ),
    );
  }

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        break;
      case 1:
        _openDonorProfile();
        break;
      case 2:
        _openBrowseListings();
        break;
      case 3:
        _openMyListings();
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
                  constraints: const BoxConstraints(maxWidth: 600),
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
                      SizedBox(height: isSmallScreen ? 25 : 35),
                      SizedBox(
                        height: buttonHeight,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.search),
                          label: const Text('Browse Listings'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _openBrowseListings,
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
                          onPressed: _openDonorProfile,
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
                          onPressed: _openRecipientProfile,
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
                          onPressed: _openCreateListing,
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
                          onPressed: _openMyListings,
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
