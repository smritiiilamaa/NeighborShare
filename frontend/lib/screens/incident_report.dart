import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/api_config.dart';

class IncidentReportPage extends StatefulWidget {
  // Optional HTTP client for testing. If null, the package http is used.
  final dynamic httpClient;

  const IncidentReportPage({super.key, this.httpClient});

  @override
  State<IncidentReportPage> createState() => _IncidentReportPageState();
}

class _IncidentReportPageState extends State<IncidentReportPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String? _titleError;
  String? _descriptionError;
  bool _isSubmitting = false;

  bool _isLoading = true;
  String? _loadError;
  List<Map<String, dynamic>> _incidents = [];

  @override
  void initState() {
    super.initState();
    _fetchIncidents();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _fetchIncidents() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final client = widget.httpClient ?? http.Client();
      final response = await client
          .get(
            Uri.parse('$apiBaseUrl/incidents'),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 20));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is List) {
          setState(() {
            _incidents = decoded
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList();
            _isLoading = false;
          });
          return;
        }
      }

      setState(() {
        _isLoading = false;
        _loadError = 'Unable to load incident reports.';
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _loadError = 'Could not connect to the server.';
      });

      debugPrint('Fetch incident reports error: $error');
    }
  }

  Future<void> _submitReport() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    setState(() {
      _titleError = title.isEmpty ? 'Report title is required.' : null;
      _descriptionError =
          description.isEmpty ? 'Report details are required.' : null;
    });

    if (_titleError != null || _descriptionError != null) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final client = widget.httpClient ?? http.Client();
      final response = await client
          .post(
            Uri.parse('$apiBaseUrl/incidents'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'title': title,
              'description': description,
              'reported_by': 'Administrator',
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (!mounted) return;

      setState(() => _isSubmitting = false);

      if (response.statusCode == 201) {
        _titleController.clear();
        _descriptionController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Incident report submitted.'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );

        await _fetchIncidents();
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to submit the report.')),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() => _isSubmitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not connect to the server.')),
      );

      debugPrint('Submit incident report error: $error');
    }
  }

  Future<void> _updateStatus(int incidentId, String status) async {
    try {
      final client = widget.httpClient ?? http.Client();
      final response = await client
          .put(
            Uri.parse('$apiBaseUrl/incidents/$incidentId/status'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'status': status}),
          )
          .timeout(const Duration(seconds: 20));

      if (!mounted) return;

      if (response.statusCode == 200) {
        await _fetchIncidents();
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update the incident.')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not connect to the server.')),
      );

      debugPrint('Update incident status error: $error');
    }
  }

  String _formatDate(String? value) {
    final date = DateTime.tryParse(value ?? '');
    if (date == null) return 'Unknown date';

    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    return '${monthNames[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Incident Reports"),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _fetchIncidents,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchIncidents,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            _buildReportForm(),
            const SizedBox(height: 24),
            const Text(
              'Recent Incidents',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_loadError != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  children: [
                    Text(_loadError!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _fetchIncidents,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else if (_incidents.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('No incident reports yet.')),
              )
            else
              ..._incidents.map(_buildIncidentCard),
          ],
        ),
      ),
    );
  }

  Widget _buildReportForm() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Submit an Incident Report",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: "Report title",
                hintText: "Describe the incident",
                errorText: _titleError,
                prefixIcon: const Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: "Incident details",
                hintText: "Explain what happened",
                errorText: _descriptionError,
                alignLabelWithHint: true,
                prefixIcon: const Icon(Icons.description_outlined),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitReport,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(_isSubmitting ? 'Submitting...' : 'Submit Report'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncidentCard(Map<String, dynamic> incident) {
    final incidentId = incident['incident_id'] as int;
    final status = (incident['status'] ?? 'Open').toString();

    Color statusColor;
    switch (status) {
      case "Open":
        statusColor = Colors.red;
        break;
      case "Investigating":
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.green;
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'INC-${incidentId.toString().padLeft(3, '0')}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              (incident['title'] ?? '').toString(),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text('Reported By: ${incident['reported_by'] ?? 'Unknown'}'),
            Text('Date: ${_formatDate(incident['created_at']?.toString())}'),
            const SizedBox(height: 12),
            Text(
              (incident['description'] ?? '').toString(),
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  "Status:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(status),
                  backgroundColor: statusColor.withValues(alpha: 0.15),
                  labelStyle: TextStyle(color: statusColor),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: status == 'Investigating'
                      ? null
                      : () => _updateStatus(incidentId, 'Investigating'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  icon: const Icon(Icons.edit),
                  label: const Text("Review"),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: status == 'Resolved'
                      ? null
                      : () => _updateStatus(incidentId, 'Resolved'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  icon: const Icon(Icons.check),
                  label: const Text("Resolve"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
