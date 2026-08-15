import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/api_config.dart';
import '../services/recipient_session.dart';
import 'message_compose.dart';
import 'request_food.dart';

class FoodListingDetailsPage extends StatelessWidget {
  final Map<String, String> listing;
  // Only set when threaded from a screen that already knows it. Any other
  // entry point falls back to RecipientSession instead of a placeholder.
  final int? recipientId;

  const FoodListingDetailsPage({
    super.key,
    required this.listing,
    this.recipientId,
  });

  int get _effectiveRecipientId =>
      recipientId ?? RecipientSession.recipientId ?? 1;

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'reserved':
        return Colors.orange;
      case 'collected':
        return Colors.blue;
      case 'expired':
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _statusBackground(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Colors.green.shade100;
      case 'reserved':
        return Colors.orange.shade100;
      case 'collected':
        return Colors.blue.shade100;
      case 'expired':
      case 'cancelled':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  String _formatExpiryDate(String? value) {
    final expiryDate = DateTime.tryParse(value ?? '');
    if (expiryDate == null) return 'Not specified';

    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];

    return '${monthNames[expiryDate.month - 1]} ${expiryDate.day}, ${expiryDate.year}';
  }

  @override
  Widget build(BuildContext context) {
    final foodName = listing['name'] ?? 'Unnamed food';
    final category = listing['category'] ?? 'Other';
    final quantity = listing['quantity'] ?? 'Not specified';
    final location = listing['location'] ?? 'Not specified';
    final description = listing['description'] ?? 'No additional description provided.';
    final expiryDate = _formatExpiryDate(listing['expiry_date']);
    final status = listing['status'] ?? 'Available';
    final donorName = listing['donor_name'] ?? listing['donorId'] ?? 'Community donor';
    final donorId = int.tryParse(listing['donor_id'] ?? '');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Listing Details'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.fastfood_outlined,
                    size: 60,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Food Listing',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    foodName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'Listing Information',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            _informationCard(
              icon: Icons.category_outlined,
              title: 'Category',
              value: category,
            ),

            _informationCard(
              icon: Icons.inventory_2_outlined,
              title: 'Quantity',
              value: quantity,
            ),

            _informationCard(
              icon: Icons.location_on_outlined,
              title: 'Pickup Location',
              value: location,
            ),

            _informationCard(
              icon: Icons.event_outlined,
              title: 'Expiry Date',
              value: expiryDate,
            ),

            _informationCard(
              icon: Icons.person_outline,
              title: 'Donor',
              value: donorName,
            ),

            _informationCard(
              icon: Icons.info_outline,
              title: 'Status',
              value: status,
              valueColor: _statusColor(status),
              backgroundColor: _statusBackground(status),
            ),

            _informationCard(
              icon: Icons.description_outlined,
              title: 'Description',
              value: description,
            ),

            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MessageComposeScreen(
                        donorName: donorName,
                        listingName: foodName,
                        donorId: donorId,
                        recipientId: _effectiveRecipientId,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.message_outlined),
                label: const Text(
                  'Message Donor',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2E7D32),
                  side: const BorderSide(color: Color(0xFF2E7D32)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RequestFoodScreen(
                        foodItem: listing,
                        recipientId: _effectiveRecipientId,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.request_page),
                label: const Text(
                  'Request Food',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _informationCard({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
    Color? backgroundColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.green.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: valueColor ?? Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ListingDetailsPage extends StatefulWidget {
  final Map<String, String> listing;
  final int listingId;

  const ListingDetailsPage({
    super.key,
    required this.listing,
    required this.listingId,
  });

  @override
  State<ListingDetailsPage> createState() => _ListingDetailsPageState();
}

class _ListingDetailsPageState extends State<ListingDetailsPage> {
  bool _isSubmitting = false;

  Color _statusColor(String status) {
    switch (status) {
      case "Pending":
        return Colors.orange;
      case "Under Review":
        return Colors.blue;
      case "Resolved":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _statusBackground(String status) {
    switch (status) {
      case "Pending":
        return Colors.orange.shade100;
      case "Under Review":
        return Colors.blue.shade100;
      case "Resolved":
        return Colors.green.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  Future<void> _updateModerationStatus(String status) async {
    setState(() => _isSubmitting = true);

    try {
      final response = await http
          .put(
            Uri.parse(
              '$apiBaseUrl/listings/${widget.listingId}/moderation-status',
            ),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'moderation_status': status}),
          )
          .timeout(const Duration(seconds: 20));

      if (!mounted) return;

      setState(() => _isSubmitting = false);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Listing marked as $status.'),
            backgroundColor: Colors.blue,
          ),
        );
        Navigator.pop(context, true);
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update the listing.')),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() => _isSubmitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not connect to the server.')),
      );

      debugPrint('Update moderation status error: $error');
    }
  }

  Future<void> _removeListing() async {
    setState(() => _isSubmitting = true);

    try {
      final response = await http
          .delete(Uri.parse('$apiBaseUrl/listings/${widget.listingId}'))
          .timeout(const Duration(seconds: 20));

      if (!mounted) return;

      setState(() => _isSubmitting = false);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Listing removed.'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context, true);
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to remove the listing.')),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() => _isSubmitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not connect to the server.')),
      );

      debugPrint('Remove listing error: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.listing["food_name"] ?? "Unknown Listing";
    final reportedBy = widget.listing["flagged_by"] ?? "Unknown";
    final reason = widget.listing["flag_reason"] ?? "No reason provided";
    final status = widget.listing["moderation_status"] ?? "Unknown";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Listing Details"),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.flag_outlined,
                    size: 60,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Flagged Listing",
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              "Report Information",
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            _informationCard(
              icon: Icons.person_outline,
              title: "Reported By",
              value: reportedBy,
            ),

            _informationCard(
              icon: Icons.warning_amber_outlined,
              title: "Reported Reason",
              value: reason,
            ),

            _informationCard(
              icon: Icons.info_outline,
              title: "Current Status",
              value: status,
              valueColor: _statusColor(status),
              backgroundColor: _statusBackground(status),
            ),

            const SizedBox(height: 25),

            const Text(
              "Moderation Actions",
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting
                    ? null
                    : () => _updateModerationStatus('Under Review'),
                icon: const Icon(Icons.rate_review_outlined),
                label: const Text(
                  "Mark as Under Review",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: _isSubmitting
                    ? null
                    : () => _confirmRemoval(context, title),
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                ),
                label: const Text(
                  "Remove Listing",
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                    color: Colors.red,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Colors.blue.shade100,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Review the reported reason carefully before taking moderation action.",
                      style: TextStyle(
                        color: Colors.blue.shade900,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _informationCard({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
    Color? backgroundColor,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: const Color(0xFF2E7D32),
            size: 27,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmRemoval(
      BuildContext context,
      String title,
      ) {
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
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _removeListing();
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
}
