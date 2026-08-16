import 'package:flutter/material.dart';

import 'browse_listings.dart';

class ClaimConfirmationScreen extends StatelessWidget {
  final Map<String, String> foodItem;
  final String requesterName;
  final String phoneNumber;
  final String pickupTime;

  const ClaimConfirmationScreen({
    super.key,
    required this.foodItem,
    required this.requesterName,
    required this.phoneNumber,
    required this.pickupTime,
  });

  String _readValue(String? value, {String fallback = 'Not provided'}) {
    if (value == null || value.trim().isEmpty) {
      return fallback;
    }

    return value.trim();
  }

  @override
  Widget build(BuildContext context) {
    final foodName = _readValue(foodItem['name'], fallback: 'Food item');
    final quantity = _readValue(foodItem['quantity']);
    final location = _readValue(foodItem['location']);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Confirmed'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF2E7D32),
                    size: 84,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Your request has been sent!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'The donor will review your request and respond soon.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.black54),
                  ),
                  const SizedBox(height: 28),
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 22,
                                backgroundColor: Color(0xFFE8F5E9),
                                child: Icon(
                                  Icons.fastfood,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  foodName,
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 28),
                          _ConfirmationRow(label: 'Quantity', value: quantity),
                          const SizedBox(height: 10),
                          _ConfirmationRow(label: 'Pickup', value: location),
                          const SizedBox(height: 10),
                          _ConfirmationRow(
                            label: 'Requested by',
                            value: _readValue(requesterName),
                          ),
                          const SizedBox(height: 10),
                          _ConfirmationRow(
                            label: 'Phone',
                            value: _readValue(phoneNumber),
                          ),
                          const SizedBox(height: 10),
                          _ConfirmationRow(
                            label: 'Preferred time',
                            value: _readValue(pickupTime),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                      ),
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const BrowseListingsScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.list_alt),
                      label: const Text('Back to Listings'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfirmationRow extends StatelessWidget {
  final String label;
  final String value;

  const _ConfirmationRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }
}
