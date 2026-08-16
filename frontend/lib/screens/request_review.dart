import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/api_config.dart';

class RequestReviewScreen extends StatefulWidget {
  final int? accountId;

  const RequestReviewScreen({
    super.key,
    this.accountId,
  });

  @override
  State<RequestReviewScreen> createState() => _RequestReviewScreenState();
}

class _RequestReviewScreenState extends State<RequestReviewScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _requests = [];
  int? _respondingRequestId;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    final accountId = widget.accountId;

    if (accountId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'No donor account was found. Please create a donor profile first.';
        _requests = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http
          .get(
            Uri.parse('$apiBaseUrl/requests/donor/$accountId'),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 20));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is List) {
          setState(() {
            _requests = decoded
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList();
            _isLoading = false;
            _errorMessage = null;
          });
          return;
        }

        setState(() {
          _isLoading = false;
          _errorMessage = 'The server returned an unexpected response.';
          _requests = [];
        });
        return;
      }

      String message = 'Unable to load requests.';

      if (response.body.isNotEmpty) {
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic> && decoded['message'] != null) {
            message = decoded['message'].toString();
          }
        } catch (_) {}
      }

      setState(() {
        _isLoading = false;
        _errorMessage = message;
        _requests = [];
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
            'Could not connect to the server. Please check your connection.';
        _requests = [];
      });

      debugPrint('Fetch donor requests error: $error');
    }
  }

  Future<void> _confirmAndRespond(
    Map<String, dynamic> request,
    String newStatus,
  ) async {

    final currentStatus =
      request['request_status']?.toString().trim().toLowerCase();

    if (newStatus == 'Approved' && currentStatus != 'pending') {
      _showError(
        'This request has already been processed and cannot be approved again.',
      );
      return;
    }
    
    final requestId = request['request_id'];
    final foodName = _readValue(request, 'food_name', fallback: 'this item');
    final recipientName =
        _readValue(request, 'recipient_name', fallback: 'this recipient');
    final isApproving = newStatus == 'Approved';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(isApproving ? 'Approve Request?' : 'Decline Request?'),
          content: Text(
            isApproving
                ? '$recipientName\'s request for "$foodName" will be approved and the listing reserved for them.'
                : '$recipientName\'s request for "$foodName" will be declined and the listing stays available for others.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: isApproving
                    ? const Color(0xFF2E7D32)
                    : Colors.red.shade700,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(isApproving ? 'Approve' : 'Decline'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || requestId == null) {
      return;
    }

    await _respondToRequest(requestId as int, newStatus);
  }

  Future<void> _respondToRequest(int requestId, String newStatus) async {
    setState(() {
      _respondingRequestId = requestId;
    });

    try {
      final response = await http
          .put(
            Uri.parse('$apiBaseUrl/requests/$requestId/status'),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'request_status': newStatus}),
          )
          .timeout(const Duration(seconds: 20));

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == 'Approved'
                  ? 'Request approved.'
                  : 'Request declined.',
            ),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
          ),
        );

        setState(() {
          _respondingRequestId = null;
        });

        await _fetchRequests();
        return;
      }

      String message = 'Unable to update the request.';

      if (response.body.isNotEmpty) {
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic> && decoded['message'] != null) {
            message = decoded['message'].toString();
          }
        } catch (_) {}
      }

      setState(() {
        _respondingRequestId = null;
      });

      _showError(message);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _respondingRequestId = null;
      });

      _showError('Could not connect to the server. Please try again.');
      debugPrint('Respond to request error: $error');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _readValue(
    Map<String, dynamic> request,
    String key, {
    String fallback = 'Not provided',
  }) {
    final value = request[key];

    if (value == null) {
      return fallback;
    }

    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off, size: 82, color: Colors.grey.shade500),
              const SizedBox(height: 18),
              const Text(
                'Unable to load requests',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                _errorMessage ?? 'Something went wrong.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 22),
              OutlinedButton.icon(
                onPressed: _fetchRequests,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 92,
                color: Colors.grey.shade500,
              ),
              const SizedBox(height: 20),
              const Text(
                'No requests yet.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Requests from recipients will show up here.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _fetchRequests,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final requestId = request['request_id'];
    final foodName = _readValue(request, 'food_name');
    final quantity = _readValue(request, 'quantity');
    final pickupLocation = _readValue(request, 'pickup_location');
    final recipientName = _readValue(request, 'recipient_name');
    final phoneNumber = _readValue(request, 'phone_number');
    final message = _readValue(
      request,
      'message',
      fallback: 'No message from recipient.',
    );
    final status = _readValue(request, 'request_status', fallback: 'Pending');
    final statusColor = _statusColor(status);
    final isPending = status.toLowerCase() == 'pending';
    final isResponding =
        _respondingRequestId != null && _respondingRequestId == requestId;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 25,
                  backgroundColor: Color(0xFFE8F5E9),
                  child: Icon(Icons.person, color: Color(0xFF2E7D32)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipientName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'requesting "$foodName"',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _InfoRow(
              icon: Icons.inventory_2_outlined,
              label: 'Quantity',
              value: quantity,
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.location_on_outlined,
              label: 'Pickup',
              value: pickupLocation,
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: phoneNumber,
            ),
            const SizedBox(height: 12),
            Text(message, style: const TextStyle(fontSize: 14, height: 1.4)),
            if (isPending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade300),
                      ),
                      onPressed: isResponding
                          ? null
                          : () => _confirmAndRespond(request, 'Rejected'),
                      icon: const Icon(Icons.close),
                      label: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                      ),
                      onPressed: isResponding
                          ? null
                          : () => _confirmAndRespond(request, 'Approved'),
                      icon: isResponding
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check),
                      label: const Text('Approve'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRequests() {
    return RefreshIndicator(
      onRefresh: _fetchRequests,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(18),
        itemCount: _requests.length,
        itemBuilder: (context, index) => _buildRequestCard(_requests[index]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Requests'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _fetchRequests,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingState()
            : _errorMessage != null
                ? _buildErrorState()
                : _requests.isEmpty
                    ? _buildEmptyState()
                    : _buildRequests(),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF2E7D32)),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }
}
