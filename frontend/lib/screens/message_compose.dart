import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/api_config.dart';
import 'message_details.dart';

class MessageComposeScreen extends StatefulWidget {
  final String donorName;
  final String? listingName;
  final ValueChanged<String>? onSend;

  // Real IDs for sending a live message. recipientId defaults to 1, matching
  // the temporary default used elsewhere until recipient login exists.
  final int? donorId;
  final int recipientId;

  // Optional HTTP client for testing. If null, the package http is used.
  final dynamic httpClient;

  const MessageComposeScreen({
    super.key,
    required this.donorName,
    this.listingName,
    this.onSend,
    this.donorId,
    this.recipientId = 1,
    this.httpClient,
  });

  @override
  State<MessageComposeScreen> createState() => _MessageComposeScreenState();
}

class _MessageComposeScreenState extends State<MessageComposeScreen> {
  final TextEditingController _messageController = TextEditingController();
  String? _validationMessage;
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();

    if (message.isEmpty) {
      setState(() {
        _validationMessage = 'Enter a message before sending.';
      });
      return;
    }

    setState(() {
      _validationMessage = null;
    });

    widget.onSend?.call(message);

    if (widget.donorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This listing is missing a donor to message.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final client = widget.httpClient ?? http.Client();
      final response = await client
          .post(
            Uri.parse('$apiBaseUrl/messages'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'donor_id': widget.donorId,
              'recipient_id': widget.recipientId,
              'message': message,
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (!mounted) return;

      setState(() => _isSending = false);

      if (response.statusCode == 201) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => MessageDetailsScreen(
              personName: widget.donorName,
              avatar: widget.donorName.characters.isEmpty
                  ? '?'
                  : widget.donorName.characters.first.toUpperCase(),
              donorId: widget.donorId,
              recipientId: widget.recipientId,
            ),
          ),
        );
        return;
      }

      String errorText = 'Unable to send message.';
      if (response.body.isNotEmpty) {
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map && decoded['message'] != null) {
            errorText = decoded['message'].toString();
          }
        } catch (_) {}
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorText),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() => _isSending = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not connect to the server.')),
      );

      debugPrint('Send message error: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        title: const Text('New Message'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Message recipient',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFFE8F5E9),
                        child: Text(
                          widget.donorName.characters.first.toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF2E7D32),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.donorName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (widget.listingName?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: 14),
                    Text(
                      'Regarding: ${widget.listingName}',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _messageController,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Message',
              hintText: 'Write a message to the donor',
              alignLabelWithHint: true,
              prefixIcon: const Icon(Icons.message_outlined),
              errorText: _validationMessage,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSending ? null : _sendMessage,
              icon: _isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_outlined),
              label: Text(_isSending ? 'Sending...' : 'Send Message'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
