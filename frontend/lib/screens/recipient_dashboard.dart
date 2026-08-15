import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/api_config.dart';
import '../services/recipient_session.dart';
import 'browse_listings.dart';
import 'inbox.dart';
import 'recipient_profile.dart';

class RecipientDashboardScreen extends StatefulWidget {
  // Only set when this screen is reached through the normal
  // Create Profile -> Dashboard hop. Any other entry point falls back to
  // RecipientSession instead of a hardcoded placeholder.
  final int? recipientId;
  // Optional HTTP client for testing. If null, the package http will be used.
  final dynamic httpClient;

  const RecipientDashboardScreen({super.key, this.recipientId, this.httpClient});

  @override
  State<RecipientDashboardScreen> createState() =>
      _RecipientDashboardScreenState();
}

class _RecipientDashboardScreenState extends State<RecipientDashboardScreen> {
  bool _isLoading = true;
  bool _isPollingRequest = false;
  String? _errorMessage;
  String? _pollingErrorMessage;
  List<Map<String, dynamic>> _requests = [];
  Timer? _pollingTimer;

  int get _effectiveRecipientId =>
      widget.recipientId ?? RecipientSession.recipientId ?? 1;

  @override
  void initState() {
    super.initState();
    if (widget.recipientId != null) {
      RecipientSession.login(widget.recipientId!);
    }
    _fetchRequests();
    _startPolling();
  }

  Future<void> _fetchRequests({bool notifyStatusChanges = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = widget.httpClient ?? http.Client();
      final response = await client.get(
        Uri.parse(
          '$apiBaseUrl/recipients/$_effectiveRecipientId/requests',
        ),
        headers: const {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 20));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is List) {
          final fetchedRequests = decoded
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
          final statusNotifications = notifyStatusChanges
              ? _statusChangeNotifications(fetchedRequests)
              : <String>[];

          setState(() {
            _requests = fetchedRequests;
            _isLoading = false;
            _pollingErrorMessage = null;
          });
          for (final notification in statusNotifications) {
            _showStatusNotification(notification);
          }
          return;
        }

        setState(() {
          _isLoading = false;
          _errorMessage = 'The server returned an unexpected response.';
        });
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load your requests.';
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not connect to the server.';
      });

      debugPrint('Fetch recipient requests error: $error');
    }
  }

  void _startPolling() {
    const pollingInterval = Duration(seconds: 30);
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(pollingInterval, (_) {
      _pollForRequestUpdates();
    });
  }

  Future<void> _pollForRequestUpdates() async {
    if (!mounted || _isPollingRequest) {
      return;
    }

    _isPollingRequest = true;

    try {
      final client = widget.httpClient ?? http.Client();
      final response = await client.get(
        Uri.parse(
          '$apiBaseUrl/recipients/$_effectiveRecipientId/requests',
        ),
        headers: const {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 20));

      if (!mounted) return;

      if (response.statusCode != 200) {
        if (_pollingErrorMessage == null) {
          setState(() {
            _pollingErrorMessage =
                'Unable to refresh request status. Retaining current data.';
          });
        }
        return;
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! List) {
        if (_pollingErrorMessage == null) {
          setState(() {
            _pollingErrorMessage =
                'Invalid data received while refreshing request status.';
          });
        }
        return;
      }

      final fetchedRequests = decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

      final statusNotifications = _statusChangeNotifications(fetchedRequests);

      if (!_requestsAreEqual(_requests, fetchedRequests)) {
        setState(() {
          _requests = fetchedRequests;
          _pollingErrorMessage = null;
        });
      }

      for (final notification in statusNotifications) {
        _showStatusNotification(notification);
      }
    } catch (error) {
      if (!mounted) return;

      if (_pollingErrorMessage == null) {
        setState(() {
          _pollingErrorMessage =
              'Unable to refresh request status. Retaining current data.';
        });
      }

      debugPrint('Polling recipient requests error: $error');
    } finally {
      _isPollingRequest = false;
    }
  }

  List<String> _statusChangeNotifications(
    List<Map<String, dynamic>> fetchedRequests,
  ) {
    final previousStatuses = <dynamic, String>{
      for (final request in _requests)
        request['request_id']: request['request_status']?.toString() ?? '',
    };

    return fetchedRequests
        .where((request) => previousStatuses.containsKey(request['request_id']))
        .map((request) {
          final previousStatus = previousStatuses[request['request_id']];
          final currentStatus = request['request_status']?.toString() ?? '';

          if (previousStatus == currentStatus) return null;
          if (currentStatus == 'Approved') {
            return 'Your food request was approved.';
          }
          if (currentStatus == 'Rejected') {
            return 'Your food request was rejected.';
          }
          return null;
        })
        .whereType<String>()
        .toList();
  }

  void _showStatusNotification(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF2E7D32),
      ),
    );
  }

  bool _requestsAreEqual(
    List<Map<String, dynamic>> current,
    List<Map<String, dynamic>> next,
  ) {
    if (current.length != next.length) {
      return false;
    }

    for (var i = 0; i < current.length; i++) {
      final currentRequest = current[i];
      final nextRequest = next[i];

      if (currentRequest['request_id'] != nextRequest['request_id'] ||
          currentRequest['request_status'] != nextRequest['request_status']) {
        return false;
      }
    }

    return true;
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.hourglass_top;
      case 'approved':
        return Icons.check_circle_outline;
      case 'rejected':
      case 'cancelled':
        return Icons.cancel_outlined;
      case 'completed':
        return Icons.task_alt;
      default:
        return Icons.help_outline;
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 400;
    final bool isLargeScreen = screenWidth >= 700;

    final activeRequests = _requests.where((request) {
      final status =
          (request['request_status'] ?? 'Pending').toString().toLowerCase();
      return status == 'pending' || status == 'approved';
    }).toList();

    final pastRequests = _requests.where((request) {
      final status =
          (request['request_status'] ?? 'Pending').toString().toLowerCase();
      return status != 'pending' && status != 'approved';
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Recipient Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Inbox',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      InboxScreen(recipientId: _effectiveRecipientId),
                ),
              );
            },
            icon: const Icon(Icons.mail_outline),
          ),
          IconButton(
            tooltip: 'Refresh requests',
            onPressed: _isLoading ? null : () => _fetchRequests(notifyStatusChanges: true),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_pollingErrorMessage != null)
              Container(
                width: double.infinity,
                color: Colors.yellow[700],
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                child: Text(
                  _pollingErrorMessage!,
                  style: const TextStyle(color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _fetchRequests(notifyStatusChanges: true),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
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
                                    Expanded(
                                      child: _buildActionCard(
                                        context: context,
                                        icon: Icons.search,
                                        title: 'Browse Food',
                                        description:
                                            'Search available food donations near you.',
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  BrowseListingsScreen(recipientId: _effectiveRecipientId),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildActionCard(
                                        context: context,
                                        icon: Icons.person_outline,
                                        title: 'My Profile',
                                        description:
                                            'View or update your recipient information.',
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  CreateRecipientProfileScreen(
                                                    recipientId: _effectiveRecipientId,
                                                  )
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    _buildActionCard(
                                      context: context,
                                      icon: Icons.search,
                                      title: 'Browse Food',
                                      description:
                                          'Search available food donations near you.',
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                BrowseListingsScreen(recipientId: _effectiveRecipientId),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 14),
                                    _buildActionCard(
                                      context: context,
                                      icon: Icons.person_outline,
                                      title: 'My Profile',
                                      description:
                                          'View or update your recipient information.',
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                CreateRecipientProfileScreen(
                                                  recipientId: _effectiveRecipientId,
                                                )
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                          const SizedBox(height: 28),
                          Text(
                            'My Requests',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 20 : 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildRequestsSection(
                            requests: activeRequests,
                            emptyMessage: 'No active requests right now.',
                          ),
                          const SizedBox(height: 28),
                          Text(
                            'Request History',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 20 : 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildRequestsSection(
                            requests: pastRequests,
                            emptyMessage:
                                'Completed food requests will appear here.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
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
                builder: (_) => BrowseListingsScreen(recipientId: _effectiveRecipientId),
              ),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CreateRecipientProfileScreen(
                  recipientId: _effectiveRecipientId,
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildRequestsSection({
    required List<Map<String, dynamic>> requests,
    required String emptyMessage,
  }) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Icon(Icons.cloud_off, size: 40, color: Colors.grey.shade500),
            const SizedBox(height: 10),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _fetchRequests,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (requests.isEmpty) {
      return _buildEmptyCard(emptyMessage);
    }

    return Column(
      children: [
        for (final request in requests) ...[
          _buildRequestCard(request),
          const SizedBox(height: 12),
        ],
      ],
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
                  'Welcome, Recipient!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Browse nearby donations and manage your food requests.',
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
    required BuildContext context,
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

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final foodName = (request['food_name'] ?? 'Food item').toString();
    final status = (request['request_status'] ?? 'Pending').toString();
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

  Widget _buildEmptyCard(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.history,
            size: 48,
            color: Colors.grey,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
