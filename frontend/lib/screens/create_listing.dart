import 'package:flutter/material.dart';

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _foodNameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController =
  TextEditingController();

  String _category = "Cooked Meals";

  final List<String> categories = [
    "Cooked Meals",
    "Bakery",
    "Fruits",
    "Vegetables",
    "Other",
  ];

  @override
  void dispose() {
    _foodNameController.dispose();
    _quantityController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _createListing() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Food listing created successfully!"),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );

      _foodNameController.clear();
      _quantityController.clear();
      _locationController.clear();
      _descriptionController.clear();

      setState(() {
        _category = "Cooked Meals";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Listing"),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const Icon(
                  Icons.add_box,
                  size: 80,
                  color: Color(0xFF2E7D32),
                ),

                const SizedBox(height: 15),

                const Text(
                  "Create a Food Listing",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  "Share extra food with people in your community.",
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 30),

                TextFormField(
                  controller: _foodNameController,
                  decoration: const InputDecoration(
                    labelText: "Food Name",
                    prefixIcon: Icon(Icons.fastfood),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                  value == null || value.isEmpty
                      ? "Enter food name"
                      : null,
                ),

                const SizedBox(height: 20),

                DropdownButtonFormField<String>(
                  value: _category,
                  decoration: const InputDecoration(
                    labelText: "Category",
                    prefixIcon: Icon(Icons.category),
                    border: OutlineInputBorder(),
                  ),
                  items: categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _category = value!;
                    });
                  },
                ),

                const SizedBox(height: 20),

                TextFormField(
                  controller: _quantityController,
                  decoration: const InputDecoration(
                    labelText: "Quantity",
                    prefixIcon: Icon(Icons.inventory),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                  value == null || value.isEmpty
                      ? "Enter quantity"
                      : null,
                ),

                const SizedBox(height: 20),

                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: "Pickup Location",
                    prefixIcon: Icon(Icons.location_on),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                  value == null || value.isEmpty
                      ? "Enter pickup location"
                      : null,
                ),

                const SizedBox(height: 20),

                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "Description (Optional)",
                    prefixIcon: Icon(Icons.description),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 30),

                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text("Create Listing"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _createListing,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}