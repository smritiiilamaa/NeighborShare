import 'package:flutter/material.dart';

class RequestStatusDisplay extends StatelessWidget {
  final String foodName;
  final String status;
  final String? donorName;

  const RequestStatusDisplay({
    super.key,
    required this.foodName,
    required this.status,
    this.donorName,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = status.trim().toLowerCase();
    final config = _statusConfig(normalized);

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: config.backgroundColor,
          child: Icon(config.icon, color: config.foregroundColor),
        ),
        title: Text(foodName, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          donorName == null || donorName!.trim().isEmpty
              ? config.message
              : '${config.message}\nDonor: $donorName',
        ),
        isThreeLine: donorName != null && donorName!.trim().isNotEmpty,
        trailing: Chip(label: Text(_titleCase(status))),
      ),
    );
  }

  _StatusConfig _statusConfig(String status) {
    switch (status) {
      case 'approved':
        return const _StatusConfig(
          Icons.check_circle,
          Color(0xFFE8F5E9),
          Color(0xFF2E7D32),
          'Your request was approved.',
        );
      case 'rejected':
      case 'declined':
        return const _StatusConfig(
          Icons.cancel,
          Color(0xFFFFEBEE),
          Colors.redAccent,
          'Your request was declined.',
        );
      case 'completed':
        return const _StatusConfig(
          Icons.task_alt,
          Color(0xFFE3F2FD),
          Colors.blue,
          'This request has been completed.',
        );
      case 'cancelled':
        return const _StatusConfig(
          Icons.remove_circle_outline,
          Color(0xFFF5F5F5),
          Colors.grey,
          'This request was cancelled.',
        );
      default:
        return const _StatusConfig(
          Icons.schedule,
          Color(0xFFFFF3E0),
          Colors.orange,
          'Waiting for the donor to respond.',
        );
    }
  }

  static String _titleCase(String value) {
    final clean = value.trim();
    if (clean.isEmpty) return 'Pending';
    return '${clean[0].toUpperCase()}${clean.substring(1).toLowerCase()}';
  }
}

class _StatusConfig {
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final String message;

  const _StatusConfig(
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.message,
  );
}
