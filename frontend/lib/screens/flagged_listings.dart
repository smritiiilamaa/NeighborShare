import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/api_config.dart';
import '../services/admin_session.dart';
import 'listing_details.dart';

class FlaggedListingsPage extends StatefulWidget {
  const FlaggedListingsPage({super.key});

  @override
  State<FlaggedListingsPage> createState() => _FlaggedListingsPageState();
}

class _FlaggedListingsPageState extends State<FlaggedListingsPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _flaggedListings = [];

  @override
  void initState() {
    super.initState();
    _fetchFlaggedListings();
  }

  Future<void> _fetchFlaggedListings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http
          .get(
            Uri.parse('$apiBaseUrl/listings/flagged'),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 20));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is List) {
          setState(() {
            _flaggedListings = decoded
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList();
            _isLoading = false;
          });
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
        _errorMessage = 'Unable to load flagged listings.';
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not connect to the server.';
      });

      debugPrint('Fetch flagged listings error: $error');
    }
  }

  Future<void> _removeListing(int listingId, String title) async {
    final adminAccountId = AdminSession.accountId;

    if (!AdminSession.isAuthenticated ||
        adminAccountId == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Administrator permission is required to remove listings.',
          ),
        ),
      );

      return;
    }

    try {
      final response = await http
          .delete(
            Uri.parse('$apiBaseUrl/listings/$listingId'),
            headers: {
              'Accept': 'application/json',
              'x-admin-account-id': adminAccountId.toString(),
            },
          )
          .timeout(const Duration(seconds: 20));

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"$title" was removed.'),
            backgroundColor: Colors.red.shade700,
          ),
        );
        await _fetchFlaggedListings();
        return;
      }

      String message = 'Unable to remove the listing.';

      if (response.body.isNotEmpty) {
        try {
          final decoded = jsonDecode(response.body);

          if (decoded is Map<String, dynamic> &&
              decoded['message'] != null) {
            message = decoded['message'].toString();
          }
        } catch (_) {}
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade700,
        ),
      );

    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not connect to the server.')),
      );

      debugPrint('Remove listing error: $error');
    }
  }

  void _showRemoveDialog(int listingId, String title) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Remove Listing"),
          content: Text(
            "Are you sure you want to remove \"$title\"?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _removeListing(listingId, title);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text("Remove"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Flagged Listings"),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _fetchFlaggedListings,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off, size: 48, color: Colors.grey.shade500),
              const SizedBox(height: 12),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _fetchFlaggedListings,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_flaggedListings.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchFlaggedListings,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 120),
            Icon(Icons.flag_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'No flagged listings.',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchFlaggedListings,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _flaggedListings.length,
        itemBuilder: (context, index) {
          final listing = _flaggedListings[index];
          final listingId = listing['listing_id'] as int;
          final title = (listing['food_name'] ?? 'Unnamed listing').toString();
          final reportedBy = (listing['flagged_by'] ?? 'Anonymous').toString();
          final reason = (listing['flag_reason'] ?? 'No reason provided').toString();
          final status = (listing['moderation_status'] ?? 'Pending').toString();

          return Card(
            elevation: 4,
            margin: const EdgeInsets.only(bottom: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 19,
                        color: Color(0xFF2E7D32),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text("Reported By: $reportedBy")),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.warning_amber_outlined,
                        size: 19,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text("Reason: $reason")),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 19,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Text("Status: $status"),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          final changed = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ListingDetailsPage(
                                listing: listing.map(
                                  (key, value) => MapEntry(key, value.toString()),
                                ),
                                listingId: listingId,
                              ),
                            ),
                          );
                          if (changed == true) {
                            _fetchFlaggedListings();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.visibility),
                        label: const Text("Review"),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () => _showRemoveDialog(listingId, title),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.delete),
                        label: const Text("Remove"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
