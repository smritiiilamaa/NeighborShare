import 'package:flutter/material.dart';

/// Smriti - Iteration 2 / R5 (M6)
/// Request confirmation UI shown after a recipient submits a food request.
class RequestConfirmationDialog extends StatelessWidget {
  final String foodName;
  final String requestStatus;

  const RequestConfirmationDialog({
    super.key,
    required this.foodName,
    this.requestStatus = 'Pending',
  });

  static Future<void> show(
    BuildContext context, {
    required String foodName,
    String requestStatus = 'Pending',
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RequestConfirmationDialog(
        foodName: foodName,
        requestStatus: requestStatus,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(
        Icons.check_circle,
        color: Color(0xFF2E7D32),
        size: 54,
      ),
      title: const Text('Request Submitted'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Your request for $foodName was submitted successfully.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Chip(
            avatar: const Icon(Icons.schedule, size: 18),
            label: Text('Status: $requestStatus'),
          ),
          const SizedBox(height: 6),
          const Text(
            'You can check the request status from your recipient dashboard.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13),
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
          ),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
