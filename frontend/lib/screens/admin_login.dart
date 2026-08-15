import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/admin_session.dart';
import 'admin_dashboard.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

Future<void> _handleLogin() async {
  FocusScope.of(context).unfocus();

  setState(() {
    _errorMessage = null;
  });

  if (!_formKey.currentState!.validate()) {
    return;
  }

  setState(() {
    _isSubmitting = true;
  });

  try {
    final response = await http.post(
      Uri.parse(
        'https://neighborshare-c2vl.onrender.com/api/accounts/login',
      ),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': _emailController.text.trim().toLowerCase(),
        'password': _passwordController.text,
      }),
    );

    Map<String, dynamic> responseData = {};

    if (response.body.isNotEmpty) {
      responseData =
        jsonDecode(response.body) as Map<String, dynamic>;
    }

    if (!mounted) return;

    if (response.statusCode == 200) {
      final account = responseData['account'];

      if (account is! Map<String, dynamic> ||
          account['account_id'] == null) {
        setState(() {
          _errorMessage =
              'Administrator account information was not returned by the server.';
        });
        return;
      }

      final adminAccountId =
          int.tryParse(account['account_id'].toString());

      if (adminAccountId == null || adminAccountId <= 0) {
        setState(() {
          _errorMessage =
              'Invalid administrator account information.';
        });
        return;
      }

      AdminSession.login(adminAccountId);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const AdminDashboardScreen(),
        ),
      );
    } else if (response.statusCode == 403) {
      setState(() {
        _errorMessage =
            responseData['message']?.toString() ?? 'Access denied.';
      });

      _showAccessDeniedDialog();
    } else {
      setState(() {
        _errorMessage =
            responseData['message']?.toString() ??
            'Invalid email or password.';
      });
    }
  } catch (error) {
    if (!mounted) return;

    setState(() {
      _errorMessage =
          'Unable to connect to the server. Please try again.';
    });
  } finally {
    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
}

void _showAccessDeniedDialog() {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        icon: const Icon(
          Icons.block,
          color: Colors.redAccent,
          size: 48,
        ),
        title: const Text('Access Denied'),
        content: const Text(
          'Only authorized administrators can access the administration panel.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Login'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.admin_panel_settings,
                      size: 64, color: Color(0xFF2E7D32)),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                    decoration: const InputDecoration(
                      labelText: 'Admin Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    validator: _validatePassword,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.redAccent),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _isSubmitting ? null : _handleLogin,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text('Log In'),
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