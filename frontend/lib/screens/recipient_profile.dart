import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/api_config.dart';
import '../features/profile_validation.dart';
import 'recipient_dashboard.dart';

class CreateRecipientProfileScreen extends StatefulWidget {
  const CreateRecipientProfileScreen({super.key});

  @override
  State<CreateRecipientProfileScreen> createState() =>
      _CreateRecipientProfileScreenState();
}

class _CreateRecipientProfileScreenState
    extends State<CreateRecipientProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _streetAddressController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _allergiesController = TextEditingController();

  String _selectedDietaryPreference = 'None';
  bool _isSubmitting = false;

  final List<String> _dietaryOptions = [
    'None',
    'Vegetarian',
    'Vegan',
    'Gluten-Free',
    'Dairy-Free',
    'Nut-Free',
    'Halal',
    'Kosher',
  ];

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _streetAddressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _allergiesController.dispose();
    super.dispose();
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    if (value.trim().length < 2) {
      return '$fieldName is too short';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    return ProfileValidation.email(value);
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length != 10) {
      return 'Enter a valid 10-digit phone number';
    }
    return null;
  }

  String? _validatePostalCode(String? value) {
    return ProfileValidation.postalCode(value);
  }

  Future<void> _handleSubmit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/recipients'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'full_name': _fullNameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone_number': _phoneController.text.trim(),
          'street_address': _streetAddressController.text.trim(),
          'city': _cityController.text.trim(),
          'postal_code': _postalCodeController.text.trim(),
          'dietary_preference': _selectedDietaryPreference,
          'allergies': _allergiesController.text.trim().isEmpty
              ? null
              : _allergiesController.text.trim(),
        }),
      );

      if (!mounted) return;

      setState(() => _isSubmitting = false);

      if (response.statusCode == 201) {
        _showSuccessDialog();
      } else {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        _showErrorSnackBar(
          body['message'] as String? ?? 'Failed to create recipient profile.',
        );
      }
    } catch (error) {
      if (!mounted) return;

      setState(() => _isSubmitting = false);

      _showErrorSnackBar(
        'Could not reach the server. Make sure the backend is running.',
      );
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Color(0xFF2E7D32),
                    size: 56,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Profile Created!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Welcome aboard, ${_fullNameController.text.trim().isEmpty ? 'Neighbour' : _fullNameController.text.trim()}! '
                  'Your recipient profile has been successfully created. '
                  'You can now browse and request food donations near you.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      _resetForm();

                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const RecipientDashboardScreen(),
                        ),
                      );
                    },
                    child: const Text('Go to Dashboard'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _fullNameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _streetAddressController.clear();
    _cityController.clear();
    _postalCodeController.clear();
    _allergiesController.clear();
    setState(() {
      _selectedDietaryPreference = 'None';
    });
  }

  void _showHelpTip() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.lightbulb_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Tip: Set your dietary preferences to find food that matches '
                'your needs. This helps donors know what you can accept.',
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'NeighbourShare',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _showHelpTip,
            icon: const Icon(Icons.help_outline, color: Colors.white),
            label: const Text(
              'Help',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.zero,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildSectionHeader(
                            icon: Icons.person_outline,
                            title: 'Personal Information',
                          ),
                          const SizedBox(height: 16),
                          _buildCard(
                            children: [
                              _buildTextField(
                                controller: _fullNameController,
                                label: 'Full Name',
                                hint: 'e.g. Jordan Smith',
                                icon: Icons.person_outline,
                                keyboardType: TextInputType.name,
                                textCapitalization: TextCapitalization.words,
                                validator: (v) =>
                                    _validateRequired(v, 'Full name'),
                              ),
                              const SizedBox(height: 18),
                              _buildTextField(
                                controller: _emailController,
                                label: 'Email Address',
                                hint: 'e.g. jordan@example.com',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: _validateEmail,
                              ),
                              const SizedBox(height: 18),
                              _buildTextField(
                                controller: _phoneController,
                                label: 'Phone Number',
                                hint: 'e.g. (555) 123-4567',
                                icon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                                validator: _validatePhone,
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          _buildSectionHeader(
                            icon: Icons.location_on_outlined,
                            title: 'Address Information',
                          ),
                          const SizedBox(height: 16),
                          _buildCard(
                            children: [
                              _buildTextField(
                                controller: _streetAddressController,
                                label: 'Street Address',
                                hint: 'e.g. 123 Maple Street',
                                icon: Icons.home_outlined,
                                keyboardType: TextInputType.streetAddress,
                                textCapitalization:
                                    TextCapitalization.words,
                                validator: (v) =>
                                    _validateRequired(v, 'Street address'),
                              ),
                              const SizedBox(height: 18),
                              _buildTextField(
                                controller: _cityController,
                                label: 'City',
                                hint: 'e.g. Toronto',
                                icon: Icons.location_city_outlined,
                                keyboardType: TextInputType.text,
                                textCapitalization:
                                    TextCapitalization.words,
                                validator: (v) =>
                                    _validateRequired(v, 'City'),
                              ),
                              const SizedBox(height: 18),
                              _buildTextField(
                                controller: _postalCodeController,
                                label: 'Postal Code',
                                hint: 'e.g. M5V 2T6',
                                icon: Icons.markunread_mailbox_outlined,
                                keyboardType: TextInputType.text,
                                textCapitalization:
                                    TextCapitalization.characters,
                                validator: _validatePostalCode,
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          _buildSectionHeader(
                            icon: Icons.restaurant_outlined,
                            title: 'Dietary Preferences',
                          ),
                          const SizedBox(height: 16),
                          _buildCard(
                            children: [
                              _buildDropdownField(
                                label: 'Dietary Preference',
                                hint: 'Select your dietary preference',
                                value: _selectedDietaryPreference,
                                items: _dietaryOptions,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedDietaryPreference = value!;
                                  });
                                },
                                icon: Icons.restaurant_outlined,
                              ),
                              const SizedBox(height: 18),
                              _buildTextField(
                                controller: _allergiesController,
                                label: 'Allergies (Optional)',
                                hint: 'e.g. Peanuts, Shellfish, Gluten',
                                icon: Icons.healing_outlined,
                                keyboardType: TextInputType.text,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                validator: (v) => null, // Optional field
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          _buildSubmitButton(),
                          const SizedBox(height: 20),
                          _buildTermsText(),
                        ],
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

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2E7D32),
            Color(0xFF66BB6A),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.handshake,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Become a Recipient',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Access fresh food donations from generous neighbours '
            'in your community. Tell us your preferences so we can '
            'match you with the right donations.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.92),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF2E7D32), size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B1B1B),
          ),
        ),
      ],
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required TextInputType keyboardType,
    required String? Function(String?) validator,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF2E7D32)),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String hint,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
    required IconData icon,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF2E7D32)),
      ),
      validator: (v) => _validateRequired(v, 'Dietary preference'),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 54,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF2E7D32),
          disabledBackgroundColor: const Color(0xFF2E7D32).withOpacity(0.7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 2,
        ),
        onPressed: _isSubmitting ? null : _handleSubmit,
        child: _isSubmitting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Text(
                'Create Recipient Profile',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildTermsText() {
    return Text(
      'By creating a recipient profile, you agree to NeighbourShare\'s '
      'Terms of Service and Privacy Policy, and confirm that the '
      'information provided is accurate to the best of your knowledge.',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey.shade600,
        height: 1.5,
      ),
    );
  }
}