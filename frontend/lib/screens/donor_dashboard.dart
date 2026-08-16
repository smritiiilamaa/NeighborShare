import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/api_config.dart';
import 'browse_listings.dart';
import 'create_listing.dart';
import 'donor_profile.dart';
import 'inbox.dart';
import 'my_listings.dart';
import 'request_review.dart';

// Tracks which pending request IDs this donor has already been notified
// about. Kept at module level (not on State) so it survives navigating away
// from and back to the dashboard, which destroys and recreates the State.
final Set<int> _seenDonorRequestIds = {};
bool _donorRequestsBaselineSet = false;

class DonorDashboardScreen extends StatefulWidget {
  final int? accountId;
  // Optional HTTP client for testing.
  final dynamic httpClient;

  const DonorDashboardScreen({super.key, this.accountId, this.httpClient});

  @override
  State<DonorDashboardScreen> createState() => _DonorDashboardScreenState();
}

class _DonorDashboardScreenState extends State<DonorDashboardScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _listings = [];

  // Messages are tied to donor_id (donor_profiles), not accountId
  // (user_accounts), so the inbox needs this derived from a listing.
  int? get _donorId {
    if (_listings.isEmpty) return null;
    return int.tryParse(_listings.first['donor_id']?.toString() ?? '');
  }

  @override
  void initState() {
    super.initState();
    _fetchListings();
    _checkForNewRequests();
  }

  Future<void> _refreshDashboard() async {
    await _fetchListings();
    await _checkForNewRequests();
  }

  Future<void> _checkForNewRequests() async {
    final accountId = widget.accountId;

    if (accountId == null) return;

    try {
      final client = widget.httpClient ?? http.Client();
      final response = await client
          .get(
            Uri.parse('$apiBaseUrl/requests/donor/$accountId'),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 20));

      if (!mounted || response.statusCode != 200) return;

      final decoded = jsonDecode(response.body);

      if (decoded is! List) return;

      final requests = decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

      final pending = requests
          .where((r) => (r['request_status'] ?? '').toString() == 'Pending')
          .toList();

      final newOnes = _donorRequestsBaselineSet
          ? pending
              .where(
                (r) =>
                    r['request_id'] is int &&
                    !_seenDonorRequestIds.contains(r['request_id']),
              )
              .toList()
          : <Map<String, dynamic>>[];

      for (final r in pending) {
        final id = r['request_id'];
        if (id is int) _seenDonorRequestIds.add(id);
      }
      _donorRequestsBaselineSet = true;

      if (newOnes.isNotEmpty && mounted) {
        _showRequestNotification(newOnes.first, newOnes.length - 1);
      }
    } catch (error) {
      debugPrint('Check for new requests error: $error');
    }
  }

  void _showRequestNotification(Map<String, dynamic> request, int extraCount) {
    final requestId = request['request_id'];

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 8),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        content: _buildRequestNotificationCard(
          requestId: requestId is int ? requestId : null,
          recipientName:
              _readValue(request, 'recipient_name', fallback: 'Someone'),
          foodName: _readValue(request, 'food_name', fallback: 'your item'),
          quantity: _readValue(request, 'quantity', fallback: ''),
          message: _readValue(request, 'message', fallback: ''),
          extraCount: extraCount,
        ),
      ),
    );
  }

  Widget _buildRequestNotificationCard({
    required int? requestId,
    required String recipientName,
    required String foodName,
    required String quantity,
    required String message,
    required int extraCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.notifications_active,
                color: Color(0xFF2E7D32),
                size: 18,
              ),
              const SizedBox(width: 6),
              const Text(
                'NEW FOOD REQUEST',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Color(0xFF2E7D32),
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              const Text(
                'Just now',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFFE8F5E9),
                child: Icon(Icons.person, color: Color(0xFF2E7D32), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black87, fontSize: 14),
                    children: [
                      TextSpan(
                        text: recipientName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: ' requested your '),
                      TextSpan(
                        text: foodName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (quantity.isNotEmpty && quantity != 'Not provided') ...[
            const SizedBox(height: 8),
            Text(
              'Quantity: $quantity',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ],
          if (message.isNotEmpty && message != 'Not provided') ...[
            const SizedBox(height: 6),
            Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
            ),
          ],
          if (extraCount > 0) ...[
            const SizedBox(height: 6),
            Text(
              '+$extraCount more new request${extraCount > 1 ? 's' : ''}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF2E7D32),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade300),
                  ),
                  onPressed: requestId == null
                      ? null
                      : () => _respondToNotificationRequest(
                            requestId,
                            'Rejected',
                          ),
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                  ),
                  onPressed: requestId == null
                      ? null
                      : () => _respondToNotificationRequest(
                            requestId,
                            'Approved',
                          ),
                  child: const Text('Approve'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _respondToNotificationRequest(
    int requestId,
    String newStatus,
  ) async {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    try {
      final response = await http
          .put(
            Uri.parse('$apiBaseUrl/requests/$requestId/status'),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'request_status': newStatus}),
          )
          .timeout(const Duration(seconds: 20));

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == 'Approved'
                  ? 'Request approved.'
                  : 'Request declined.',
            ),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
          ),
        );

        await _fetchListings();
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Unable to update the request.'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not connect to the server.'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );

      debugPrint('Respond to request error: $error');
    }
  }

  Future<void> _fetchListings() async {
    final accountId = widget.accountId;

    if (accountId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'No donor account was found. Please create a donor profile first.';
        _listings = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http
          .get(
            Uri.parse('$apiBaseUrl/donors/$accountId/listings'),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 20));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        final rawListings = decoded is List
            ? decoded
            : (decoded is Map<String, dynamic> && decoded['listings'] is List)
                ? decoded['listings'] as List
                : null;

        if (rawListings != null) {
          setState(() {
            _listings = rawListings
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList();
            _isLoading = false;
            _errorMessage = null;
          });
          return;
        }

        setState(() {
          _isLoading = false;
          _errorMessage = 'The server returned an unexpected response.';
          _listings = [];
        });
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load your listings.';
        _listings = [];
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
            'Could not connect to the server. Please check your connection.';
        _listings = [];
      });

      debugPrint('Fetch donor dashboard listings error: $error');
    }
  }

  String _readValue(
    Map<String, dynamic> listing,
    String key, {
    String fallback = 'Not provided',
  }) {
    final value = listing[key];

    if (value == null) {
      return fallback;
    }

    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'reserved':
        return Colors.orange;
      case 'collected':
      case 'completed':
        return Colors.blue;
      case 'expired':
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Icons.check_circle_outline;
      case 'reserved':
        return Icons.hourglass_top;
      case 'collected':
      case 'completed':
        return Icons.task_alt;
      case 'expired':
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 400;
    final bool isLargeScreen = screenWidth >= 700;

    final completedListings = _listings
        .where((listing) =>
            _readValue(listing, 'status', fallback: '').toLowerCase() ==
                'collected' ||
            _readValue(listing, 'status', fallback: '').toLowerCase() ==
                'completed')
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Donor Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: _donorId == null
                ? 'Inbox (create a listing first)'
                : 'Inbox',
            onPressed: _donorId == null
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => InboxScreen(donorId: _donorId),
                      ),
                    );
                  },
            icon: const Icon(Icons.mail_outline),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _refreshDashboard,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildWelcomeSection(isSmallScreen),
                  const SizedBox(height: 24),

                  Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 20 : 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),

                  isLargeScreen
                      ? Row(
                          children: [
                            Expanded(child: _buildCreateListingCard()),
                            const SizedBox(width: 16),
                            Expanded(child: _buildRequestsCard()),
                            const SizedBox(width: 16),
                            Expanded(child: _buildBrowseListingsCard()),
                            const SizedBox(width: 16),
                            Expanded(child: _buildMyProfileCard()),
                          ],
                        )
                      : Column(
                          children: [
                            _buildCreateListingCard(),
                            const SizedBox(height: 14),
                            _buildRequestsCard(),
                            const SizedBox(height: 14),
                            _buildBrowseListingsCard(),
                            const SizedBox(height: 14),
                            _buildMyProfileCard(),
                          ],
                        ),

                  const SizedBox(height: 28),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'My Listings',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 20 : 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!_isLoading &&
                          _errorMessage == null &&
                          _listings.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MyListingsScreen(
                                  accountId: widget.accountId,
                                ),
                              ),
                            );
                          },
                          child: const Text('View All'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  _buildMyListingsSection(),

                  const SizedBox(height: 28),

                  Text(
                    'Donation History',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 20 : 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),

                  completedListings.isEmpty
                      ? _buildEmptyHistoryCard()
                      : Column(
                          children: completedListings
                              .map(
                                (listing) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildListingCard(listing),
                                ),
                              )
                              .toList(),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            label: 'Browse',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
        onDestinationSelected: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const BrowseListingsScreen(),
              ),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CreateDonorProfileScreen(),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildMyListingsSection() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Icon(Icons.cloud_off, size: 48, color: Colors.grey.shade500),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _fetchListings,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_listings.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Column(
          children: [
            Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'No listings yet',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 6),
            Text(
              'Create a food listing to help your community.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final preview = _listings.take(3).toList();

    return Column(
      children: preview
          .map(
            (listing) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildListingCard(listing),
            ),
          )
          .toList(),
    );
  }

  Widget _buildListingCard(Map<String, dynamic> listing) {
    final foodName = _readValue(listing, 'food_name');
    final quantity = _readValue(listing, 'quantity');
    final status = _readValue(listing, 'status', fallback: 'Available');
    final statusColor = _statusColor(status);

    return Card(
      elevation: 1,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.15),
          child: Icon(_statusIcon(status), color: statusColor),
        ),
        title: Text(
          foodName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text('Quantity: $quantity'),
        ),
        trailing: Chip(
          label: Text(status),
          backgroundColor: statusColor.withOpacity(0.15),
          labelStyle: TextStyle(
            color: statusColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 20 : 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2E7D32),
            Color(0xFF66BB6A),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.volunteer_activism,
              color: Colors.white,
              size: isSmallScreen ? 34 : 44,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, Donor!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Share surplus food with your community and track your donations.',
                  style: TextStyle(
                    color: Colors.white,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF2E7D32),
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 17),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreateListingCard() {
    return _buildActionCard(
      icon: Icons.add_circle_outline,
      title: 'Create Listing',
      description: 'Post surplus food for neighbours to request.',
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CreateListingScreen(accountId: widget.accountId),
          ),
        );
        _fetchListings();
      },
    );
  }

  Widget _buildRequestsCard() {
    return _buildActionCard(
      icon: Icons.inbox_outlined,
      title: 'Requests',
      description: 'Review and respond to food requests from recipients.',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RequestReviewScreen(accountId: widget.accountId),
          ),
        );
      },
    );
  }

  Widget _buildBrowseListingsCard() {
    return _buildActionCard(
      icon: Icons.search,
      title: 'Browse Listings',
      description: 'See what other donors are sharing nearby.',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const BrowseListingsScreen(),
          ),
        );
      },
    );
  }

  Widget _buildMyProfileCard() {
    return _buildActionCard(
      icon: Icons.person_outline,
      title: 'My Profile',
      description: 'View or update your donor information.',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CreateDonorProfileScreen(),
          ),
        );
      },
    );
  }

  Widget _buildEmptyHistoryCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.history,
            size: 48,
            color: Colors.grey,
          ),
          SizedBox(height: 12),
          Text(
            'No completed donations yet',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Completed food donations will appear here.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
