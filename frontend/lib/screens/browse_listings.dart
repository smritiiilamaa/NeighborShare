import 'package:flutter/material.dart';
import 'request_food.dart';
import '../features/listing_availability.dart';

class BrowseListingsScreen extends StatefulWidget {
  const BrowseListingsScreen({super.key});

  @override
  State<BrowseListingsScreen> createState() => _BrowseListingsScreenState();
}

class _BrowseListingsScreenState extends State<BrowseListingsScreen> {
  final TextEditingController _searchController = TextEditingController();

  String selectedCategory = "All";

  final List<String> categories = [
    "All",
    "Cooked Meals",
    "Bakery",
    "Fruits",
    "Vegetables",
  ];

  final List<Map<String, String>> foodListings = [
    {
      "name": "Vegetable Soup",
      "category": "Cooked Meals",
      "quantity": "5 Portions",
      "location": "Scarborough",
      "status": "Available",
    },
    {
      "name": "Fresh Bread",
      "category": "Bakery",
      "quantity": "12 Loaves",
      "location": "North York",
      "status": "Available",
    },
    {
      "name": "Apples",
      "category": "Fruits",
      "quantity": "20 Pieces",
      "location": "Etobicoke",
      "status": "Available",
    },
    {
      "name": "Carrots",
      "category": "Vegetables",
      "quantity": "8 Bags",
      "location": "Downtown Toronto",
      "status": "Reserved",
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = foodListings.where((food) {
      final matchesSearch = food["name"]!
          .toLowerCase()
          .contains(_searchController.text.toLowerCase());

      final matchesCategory =
          selectedCategory == "All" || food["category"] == selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Browse Listings"),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
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
              child: filtered.isEmpty
                  ? const Center(
                child: Text(
                  "No food listings found.",
                  style: TextStyle(fontSize: 18),
                ),
              )
                  : ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final food = filtered[index];

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
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
                                  food["name"]!,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.favorite_border,
                                color: Colors.red,
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          Row(
                            children: [
                              const Icon(
                                Icons.category,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 8),
                              Text(food["category"]!),
                            ],
                          ),

                          const SizedBox(height: 8),

                          Row(
                            children: [
                              const Icon(
                                Icons.inventory_2,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Text(food["quantity"]!),
                            ],
                          ),

                          const SizedBox(height: 8),

                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Text(food["location"]!),
                            ],
                          ),

                          const SizedBox(height: 8),

                          const Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: Colors.blue,
                              ),
                              SizedBox(width: 8),
                              Text("Available Today"),
                            ],
                          ),

                          const SizedBox(height: 12),

                          Chip(
                            label: Text(food["status"]!),
                            backgroundColor:
                            food["status"] == "Available"
                                ? Colors.green.shade100
                                : Colors.orange.shade100,
                          ),

                          const SizedBox(height: 15),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                const Color(0xFF2E7D32),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    Colors.grey.shade300,
                                disabledForegroundColor:
                                    Colors.grey.shade600,
                                padding:
                                const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              onPressed: !ListingAvailability.isAvailable(food["status"])
                                  ? null
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => RequestFoodScreen(
                                            foodItem: food,
                                          ),
                                        ),
                                      );
                                    },
                              child: Text(
                                ListingAvailability.isAvailable(food["status"])
                                    ? "Request Food"
                                    : "Not Available",
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}