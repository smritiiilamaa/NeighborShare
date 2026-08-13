import 'package:flutter/material.dart';

import 'create_listing.dart';
import 'my_listings.dart';

class ListingConfirmationScreen extends StatelessWidget {
  final int? accountId;
  final Map<String, dynamic> listing;

  const ListingConfirmationScreen({
    super.key,
    required this.accountId,
    required this.listing,
  });

  String _readValue(String key, {String fallback = 'Not provided'}) {
    final value = listing[key];

    if (value == null) {
      return fallback;
    }

    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  @override
  Widget build(BuildContext context) {
    final foodName = _readValue('food_name');
    final category = _readValue('category');
    final quantity = _readValue('quantity');
    final pickupLocation = _readValue('pickup_location');
    final description = _readValue(
      'description',
      fallback: 'No description provided.',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Listing Confirmed'),
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
                    'Your listing is live!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Recipients nearby can now see and request this food.',
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
                          _ConfirmationRow(label: 'Category', value: category),
                          const SizedBox(height: 10),
                          _ConfirmationRow(label: 'Quantity', value: quantity),
                          const SizedBox(height: 10),
                          _ConfirmationRow(
                            label: 'Pickup',
                            value: pickupLocation,
                          ),
                          const SizedBox(height: 10),
                          _ConfirmationRow(
                            label: 'Description',
                            value: description,
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
                            builder: (_) => MyListingsScreen(
                              accountId: accountId,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.list_alt),
                      label: const Text('View My Listings'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => CreateListingScreen(
                              accountId: accountId,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Create Another Listing'),
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
          width: 110,
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
