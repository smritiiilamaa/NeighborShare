import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/api_config.dart';

class MyListingsScreen extends StatefulWidget {
  final int? accountId;

  const MyListingsScreen({
    super.key,
    this.accountId,
  });

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _listings = [];

  @override
  void initState() {
    super.initState();
    _fetchListings();
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
            headers: const {
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 20));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is List) {
          setState(() {
            _listings = decoded
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList();
            _isLoading = false;
            _errorMessage = null;
          });
          return;
        }

        if (decoded is Map<String, dynamic> && decoded['listings'] is List) {
          final rawListings = decoded['listings'] as List;

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

      String message = 'Unable to load your listings.';

      if (response.body.isNotEmpty) {
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic> &&
              decoded['message'] != null) {
            message = decoded['message'].toString();
          }
        } catch (_) {}
      }

      setState(() {
        _isLoading = false;
        _errorMessage = message;
        _listings = [];
      });
    } on FormatException {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'The server returned invalid data.';
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

      debugPrint('Fetch donor listings error: $error');
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

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_off,
                size: 82,
                color: Colors.grey.shade500,
              ),
              const SizedBox(height: 18),
              const Text(
                'Unable to load listings',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _errorMessage ?? 'Something went wrong.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 22),
              OutlinedButton.icon(
                onPressed: _fetchListings,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 92,
                color: Colors.grey.shade500,
              ),
              const SizedBox(height: 20),
              const Text(
                'No listings available.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Create a food listing to help your community.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _fetchListings,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListingCard(Map<String, dynamic> listing) {
    final foodName = _readValue(listing, 'food_name');
    final category = _readValue(listing, 'category');
    final quantity = _readValue(listing, 'quantity');
    final pickupLocation = _readValue(listing, 'pickup_location');
    final description = _readValue(
      listing,
      'description',
      fallback: 'No description provided.',
    );
    final status = _readValue(
      listing,
      'status',
      fallback: 'Available',
    );

    final statusColor = _statusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 25,
                  backgroundColor: Color(0xFFE8F5E9),
                  child: Icon(
                    Icons.fastfood,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        foodName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        category,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _InfoRow(
              icon: Icons.inventory_2_outlined,
              label: 'Quantity',
              value: quantity,
            ),
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.location_on_outlined,
              label: 'Pickup',
              value: pickupLocation,
            ),
            const SizedBox(height: 14),
            Text(
              description,
              style: const TextStyle(
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListings() {
    return RefreshIndicator(
      onRefresh: _fetchListings,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(18),
        itemCount: _listings.length,
        itemBuilder: (context, index) {
          return _buildListingCard(_listings[index]);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Listings'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _fetchListings,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingState()
            : _errorMessage != null
                ? _buildErrorState()
                : _listings.isEmpty
                    ? _buildEmptyState()
                    : _buildListings(),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 21,
          color: const Color(0xFF2E7D32),
        ),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }
}
