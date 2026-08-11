import 'package:flutter/material.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  final List<Map<String, String>> listings = [
    {
      "food": "Vegetable Soup",
      "category": "Cooked Meals",
      "quantity": "5 Portions",
      "location": "Scarborough",
      "status": "Available",
    },
    {
      "food": "Fresh Bread",
      "category": "Bakery",
      "quantity": "12 Loaves",
      "location": "North York",
      "status": "Reserved",
    },
    {
      "food": "Apples",
      "category": "Fruits",
      "quantity": "20 Pieces",
      "location": "Etobicoke",
      "status": "Available",
    },
  ];

  void _deleteListing(int index) {
    final foodName = listings[index]["food"];

    setState(() {
      listings.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$foodName deleted successfully."),
        backgroundColor: const Color(0xFF2E7D32),
      ),
    );
  }

  void _editListing(String foodName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Edit feature for $foodName coming soon."),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Listings"),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: listings.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 90,
              color: Colors.grey,
            ),
            SizedBox(height: 20),
            Text(
              "No listings available.",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Create a food listing to help your community.",
              textAlign: TextAlign.center,
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: listings.length,
        itemBuilder: (context, index) {
          final listing = listings[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.fastfood,
                        color: Color(0xFF2E7D32),
                        size: 30,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          listing["food"]!,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == "Edit") {
                            _editListing(listing["food"]!);
                          } else {
                            _deleteListing(index);
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: "Edit",
                            child: Text("Edit"),
                          ),
                          PopupMenuItem(
                            value: "Delete",
                            child: Text("Delete"),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  Row(
                    children: [
                      const Icon(
                        Icons.category,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Text(listing["category"]!),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const Icon(
                        Icons.inventory,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Text(listing["quantity"]!),
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
                      Text(listing["location"]!),
                    ],
                  ),

                  const SizedBox(height: 15),

                  Chip(
                    label: Text(listing["status"]!),
                    backgroundColor:
                    listing["status"] == "Available"
                        ? Colors.green.shade100
                        : Colors.orange.shade100,
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