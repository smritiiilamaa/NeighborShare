import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/api_config.dart';
import '../services/recipient_session.dart';
import 'listing_details.dart';
import 'message_compose.dart';
import 'request_food.dart';

class BrowseListingsScreen extends StatefulWidget {
  // Only set when threaded from a screen that already knows it. Any other
  // entry point falls back to RecipientSession instead of a placeholder.
  final int? recipientId;

  const BrowseListingsScreen({super.key, this.recipientId});

  @override
  State<BrowseListingsScreen> createState() => _BrowseListingsScreenState();
}

class _BrowseListingsScreenState extends State<BrowseListingsScreen> {
  int get _effectiveRecipientId =>
      widget.recipientId ?? RecipientSession.recipientId ?? 1;

  final TextEditingController _searchController = TextEditingController();

  String selectedCategory = "All";
  bool isLoading = true;
  String? errorMessage;

  final List<String> categories = [
    "All",
    "Cooked Meals",
    "Bakery",
    "Fruits",
    "Vegetables",
    "Other",
  ];

  List<Map<String, String>> foodListings = [];

  @override
  void initState() {
    super.initState();
    loadListings();
  }

  Future<void> loadListings() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/listings'),
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception(
          'Unable to load listings (${response.statusCode}): ${response.body}',
        );
      }

      final dynamic decoded = jsonDecode(response.body);

      if (decoded is! List) {
        throw const FormatException(
          'The backend returned an unexpected response format.',
        );
      }

      final listings =
          decoded.whereType<Map>().map<Map<String, String>>((item) {
        final map = Map<String, dynamic>.from(item);

        return {
          'listing_id': map['listing_id']?.toString() ?? '',
          'donor_id': map['donor_id']?.toString() ?? '',
          'donor_name': map['donor_name']?.toString() ?? '',
          'name': map['food_name']?.toString() ?? 'Unnamed food',
          'category': map['category']?.toString() ?? 'Other',
          'quantity': map['quantity']?.toString() ?? '',
          'location': map['pickup_location']?.toString() ?? '',
          'description': map['description']?.toString() ?? '',
          'expiry_date': map['expiry_date']?.toString() ?? '',
          'status': map['status']?.toString() ?? 'Available',
        };
      }).toList();

      if (!mounted) return;

      setState(() {
        foodListings = listings;
        isLoading = false;
      });
    } on FormatException catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = error.message;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = error.toString();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = foodListings.where((food) {
      final name = food["name"] ?? "";
      final category = food["category"] ?? "";

      final matchesSearch =
          name.toLowerCase().contains(_searchController.text.toLowerCase());

      final matchesCategory =
          selectedCategory == "All" || category == selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Browse Listings"),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: "Refresh listings",
            onPressed: isLoading ? null : loadListings,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: Colors.green.shade50,
              padding: const EdgeInsets.all(20),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Browse Food Listings",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Find available food donations near you and request items that meet your needs.",
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: "Search food...",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 45,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: selectedCategory == category,
                      selectedColor: Colors.green.shade200,
                      onSelected: (_) {
                        setState(() {
                          selectedCategory = category;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _buildListingsArea(filtered),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListingsArea(List<Map<String, String>> filtered) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              const Text(
                "Could not load food listings.",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: loadListings,
                icon: const Icon(Icons.refresh),
                label: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    if (filtered.isEmpty) {
      return RefreshIndicator(
        onRefresh: loadListings,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 120),
            Icon(
              Icons.search_off,
              size: 72,
              color: Colors.grey.shade500,
            ),
            const SizedBox(height: 16),
            const Text(
              "No food listings found.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Try changing your search or category, or check again later.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadListings,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final food = filtered[index];
          final status = (food["status"] ?? "").trim();
          final isAvailable = status.toLowerCase() == "available";
          final pickupLocation = (food["location"] ?? "").trim();
          final availabilityText = isAvailable
              ? "Available Today"
              : status.isNotEmpty
                  ? status
                  : "Status unknown";

          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FoodListingDetailsPage(
                    listing: food,
                    recipientId: _effectiveRecipientId,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(18),
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            food["name"] ?? "Unnamed food",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Icon(Icons.favorite_border, color: Colors.red),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.category, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(child: Text(food["category"] ?? "Other")),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.inventory_2, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(child: Text(food["quantity"] ?? "")),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            pickupLocation.isNotEmpty
                                ? pickupLocation
                                : "Not specified",
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(availabilityText),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Chip(
                      label: Text(status.isNotEmpty ? status : "Unknown"),
                      backgroundColor: isAvailable
                          ? Colors.green.shade100
                          : Colors.orange.shade100,
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MessageComposeScreen(
                                    donorName: food["donor_name"] ??
                                        "Community donor",
                                    listingName: food["name"],
                                    donorId:
                                        int.tryParse(food["donor_id"] ?? ""),
                                    recipientId: _effectiveRecipientId,
                                  ),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF2E7D32),
                              side: const BorderSide(
                                color: Color(0xFF2E7D32),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                            ),
                            icon: const Icon(Icons.message_outlined, size: 18),
                            label: const Text("Message"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey.shade300,
                              disabledForegroundColor: Colors.grey.shade600,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: !isAvailable
                                ? null
                                : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => RequestFoodScreen(
                                          foodItem: food,
                                          recipientId: _effectiveRecipientId,
                                        ),
                                      ),
                                    );
                                  },
                            child: Text(
                              isAvailable ? "Request Food" : "Not Available",
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
