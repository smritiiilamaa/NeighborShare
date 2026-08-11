import 'package:flutter/material.dart';

import '../features/listing_availability.dart';
import '../features/message_validation.dart';
import '../features/request_confirmation.dart';

class RequestFoodScreen extends StatefulWidget {
  final Map<String, String> foodItem;

  const RequestFoodScreen({super.key, required this.foodItem});

  @override
  State<RequestFoodScreen> createState() => _RequestFoodScreenState();
}

class _RequestFoodScreenState extends State<RequestFoodScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  String _pickupTime = "Morning";

  final List<String> pickupTimes = [
    "Morning",
    "Afternoon",
    "Evening",
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    final unavailable = ListingAvailability.unavailableMessage(
      widget.foodItem["status"],
    );

    if (unavailable != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(unavailable), backgroundColor: Colors.redAccent),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    await RequestConfirmationDialog.show(
      context,
      foodName: widget.foodItem["name"] ?? "Food item",
      requestStatus: "Pending",
    );

    if (!mounted) return;

    _nameController.clear();
    _phoneController.clear();
    _messageController.clear();

    setState(() {
      _pickupTime = "Morning";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Request Food"),
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
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.fastfood,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.foodItem["name"] ?? "Food item",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                [
                                  widget.foodItem["quantity"],
                                  widget.foodItem["location"],
                                ].where((v) => v != null && v.isNotEmpty).join(" • "),
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  "Request a Food Donation",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  "Complete the form below to request this food donation.",
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 30),

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "Full Name",
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                  value == null || value.isEmpty
                      ? "Enter your full name"
                      : null,
                ),

                const SizedBox(height: 20),

                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: "Phone Number",
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                  value == null || value.isEmpty
                      ? "Enter your phone number"
                      : null,
                ),

                const SizedBox(height: 20),

                DropdownButtonFormField<String>(
                  value: _pickupTime,
                  decoration: const InputDecoration(
                    labelText: "Preferred Pickup Time",
                    prefixIcon: Icon(Icons.schedule),
                    border: OutlineInputBorder(),
                  ),
                  items: pickupTimes.map((time) {
                    return DropdownMenuItem(
                      value: time,
                      child: Text(time),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _pickupTime = value!;
                    });
                  },
                ),

                const SizedBox(height: 20),

                TextFormField(
                  controller: _messageController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: "Message to Donor",
                    prefixIcon: Icon(Icons.message),
                    border: OutlineInputBorder(),
                  ),
                  maxLength: MessageValidation.maxLength,
                  validator: MessageValidation.validate,
                ),

                const SizedBox(height: 30),

                SizedBox(
                  height: 55,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.send),
                    label: const Text("Submit Request"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _submitRequest,
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