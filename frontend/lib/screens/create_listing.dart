import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/api_config.dart';
import 'listing_confirmation.dart';

class CreateListingScreen extends StatefulWidget {
  final int? accountId;

  const CreateListingScreen({
    super.key,
    this.accountId,
  });

  @override
  State<CreateListingScreen> createState() =>
      _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _foodNameController =
      TextEditingController();
  final TextEditingController _quantityController =
      TextEditingController();
  final TextEditingController _locationController =
      TextEditingController();
  final TextEditingController _descriptionController =
      TextEditingController();

  final List<String> _categories = const [
    'Cooked Meals',
    'Bakery',
    'Fruits',
    'Vegetables',
    'Other',
  ];

  String _selectedCategory = 'Cooked Meals';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _foodNameController.dispose();
    _quantityController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String? _requiredValidator(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  Future<void> _createListing() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final accountId = widget.accountId;

    if (accountId == null) {
      _showError(
        'No account ID was provided. Create a donor profile first, then open Create Listing from the donor home screen.',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await http
          .post(
            Uri.parse('$apiBaseUrl/listings'),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'account_id': accountId,
              'food_name': _foodNameController.text.trim(),
              'category': _selectedCategory,
              'quantity': _quantityController.text.trim(),
              'pickup_location': _locationController.text.trim(),
              'description': _descriptionController.text.trim(),
            }),
          )
          .timeout(const Duration(seconds: 20));

      Map<String, dynamic>? responseData;

      if (response.body.isNotEmpty) {
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            responseData = decoded;
          }
        } catch (_) {
          responseData = null;
        }
      }

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      if (response.statusCode == 201) {
        final createdListing =
            responseData?['listing'] as Map<String, dynamic>? ??
                {
                  'food_name': _foodNameController.text.trim(),
                  'category': _selectedCategory,
                  'quantity': _quantityController.text.trim(),
                  'pickup_location': _locationController.text.trim(),
                  'description': _descriptionController.text.trim(),
                };

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ListingConfirmationScreen(
              accountId: widget.accountId,
              listing: createdListing,
            ),
          ),
        );
        return;
      }

      _showError(
        responseData?['message']?.toString() ??
            'Unable to create the listing. Server returned ${response.statusCode}.',
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      _showError(
        'Could not connect to the backend. Make sure the Node server is running.',
      );

      debugPrint('Create listing error: $error');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Listing'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Icon(
                    Icons.add_box,
                    size: 80,
                    color: Color(0xFF2E7D32),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Create a Food Listing',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Share extra food with people in your community.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  TextFormField(
                    controller: _foodNameController,
                    decoration: const InputDecoration(
                      labelText: 'Food Name',
                      prefixIcon: Icon(Icons.fastfood),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        _requiredValidator(value, 'Food name'),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.category),
                      border: OutlineInputBorder(),
                    ),
                    items: _categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: _isSubmitting
                        ? null
                        : (value) {
                            if (value == null) return;
                            setState(() {
                              _selectedCategory = value;
                            });
                          },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      prefixIcon: Icon(Icons.inventory),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        _requiredValidator(value, 'Quantity'),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Pickup Location',
                      prefixIcon: Icon(Icons.location_on),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        _requiredValidator(value, 'Pickup location'),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description (Optional)',
                      prefixIcon: Icon(Icons.description),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                      ),
                      onPressed:
                          _isSubmitting ? null : _createListing,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check),
                      label: Text(
                        _isSubmitting
                            ? 'Creating...'
                            : 'Create Listing',
                      ),
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
