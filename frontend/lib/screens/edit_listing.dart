import 'package:flutter/material.dart';

class EditListingScreen extends StatefulWidget {
  final Map<String, String> listing;

  const EditListingScreen({
    super.key,
    required this.listing,
  });

  @override
  State<EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends State<EditListingScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _foodNameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _locationController;
  late final TextEditingController _descriptionController;

  late String _category;
  late String _status;

  final List<String> _categories = [
    "Cooked Meals",
    "Bakery",
    "Fruits",
    "Vegetables",
    "Other",
  ];

  final List<String> _statuses = [
    "Available",
    "Reserved",
  ];

  @override
  void initState() {
    super.initState();

    _foodNameController = TextEditingController(
      text: widget.listing["food"] ?? "",
    );

    _quantityController = TextEditingController(
      text: widget.listing["quantity"] ?? "",
    );

    _locationController = TextEditingController(
      text: widget.listing["location"] ?? "",
    );

    _descriptionController = TextEditingController(
      text: widget.listing["description"] ?? "",
    );

    _category = _categories.contains(widget.listing["category"])
        ? widget.listing["category"]!
        : _categories.first;

    _status = _statuses.contains(widget.listing["status"])
        ? widget.listing["status"]!
        : _statuses.first;
  }

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
      return "$fieldName is required";
    }

    return null;
  }

  bool _isListingExpired() {
    final status = widget.listing["status"]?.trim().toLowerCase();

    if (status == "expired") {
      return true;
    }

    final expiryText = widget.listing["expiry_date"]?.trim();

    if (expiryText == null || expiryText.isEmpty) {
      return false;
    }

    final expiryDate = DateTime.tryParse(expiryText);

    if (expiryDate == null) {
      return false;
    }

    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final expiry = DateTime(
      expiryDate.year,
      expiryDate.month,
      expiryDate.day,
    );

    return expiry.isBefore(today);
  }

  void _saveChanges() {
    if (_isListingExpired()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Past or expired listings cannot be edited.',
          ),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final updatedListing = <String, String>{
      "food": _foodNameController.text.trim(),
      "category": _category,
      "quantity": _quantityController.text.trim(),
      "location": _locationController.text.trim(),
      "status": _status,
      "description": _descriptionController.text.trim(),
    };

    Navigator.pop(context, updatedListing);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Listing"),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Icon(
                Icons.edit_note,
                size: 80,
                color: Color(0xFF2E7D32),
              ),

              const SizedBox(height: 15),

              const Text(
                "Edit Food Listing",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "Update the information for your food listing.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                ),
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
                    _requiredValidator(value, "Food name"),
              ),

              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: "Category",
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    _category = value;
                  });
                },
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: "Quantity",
                  prefixIcon: Icon(Icons.inventory_2),
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    _requiredValidator(value, "Quantity"),
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
                    _requiredValidator(value, "Pickup location"),
              ),

              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(
                  labelText: "Listing Status",
                  prefixIcon: Icon(Icons.info_outline),
                  border: OutlineInputBorder(),
                ),
                items: _statuses.map((status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    _status = value;
                  });
                },
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: "Description",
                  hintText: "Add details about the food...",
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _saveChanges,
                  icon: const Icon(Icons.save),
                  label: const Text(
                    "Save Changes",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                height: 50,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Cancel"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}