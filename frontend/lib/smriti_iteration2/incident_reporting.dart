import 'package:flutter/material.dart';

/// Smriti - Iteration 2 / A2 (S9)
/// Coordinates the incident-report flow without duplicating the teammate-owned
/// backend processing, database-save, or validation tasks.
class IncidentReportData {
  final String title;
  final String description;
  final String severity;

  const IncidentReportData({
    required this.title,
    required this.description,
    required this.severity,
  });
}

class IncidentReporting {
  const IncidentReporting._();

  static Future<bool> submit(
    BuildContext context, {
    required IncidentReportData report,
    required Future<bool> Function(IncidentReportData report) sendReport,
  }) async {
    final success = await sendReport(report);
    if (!context.mounted) return success;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Incident report submitted successfully.'
              : 'Incident report could not be submitted.',
        ),
        backgroundColor:
            success ? const Color(0xFF2E7D32) : Colors.redAccent,
      ),
    );

    return success;
  }
}
