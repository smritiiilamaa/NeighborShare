import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/api_config.dart';

class MessageDetailsScreen extends StatefulWidget {
  final String personName;
  final String avatar;
  final List<Map<String, dynamic>>? initialMessages;

  // When both are provided, the screen fetches and sends real messages
  // for this donor/recipient conversation instead of using sample data.
  final int? donorId;
  final int? recipientId;

  // Which side of the conversation is viewing/sending -- determines which
  // messages render as "mine" and what sender_role a reply is tagged with.
  final String viewerRole;

  const MessageDetailsScreen({
    super.key,
    required this.personName,
    required this.avatar,
    this.initialMessages,
    this.donorId,
    this.recipientId,
    this.viewerRole = 'Recipient',
  });

  @override
  State<MessageDetailsScreen> createState() =>
      _MessageDetailsScreenState();
}

class _MessageDetailsScreenState
    extends State<MessageDetailsScreen> {
  final TextEditingController _messageController =
  TextEditingController();

  final ScrollController _scrollController =
  ScrollController();

  final List<Map<String, dynamic>> _messages = [];

  bool get _isLiveConversation =>
      widget.donorId != null && widget.recipientId != null;

  bool _isLoading = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    if (_isLiveConversation) {
      _fetchConversation();
    } else if (widget.initialMessages != null) {
      _messages.addAll(widget.initialMessages!);
    } else {
      _loadSampleMessages();
    }
  }

  Future<void> _fetchConversation() async {
    setState(() => _isLoading = true);

    try {
      final response = await http
          .get(
            Uri.parse(
              '$apiBaseUrl/messages/conversation'
              '?donorId=${widget.donorId}&recipientId=${widget.recipientId}',
            ),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 20));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is List) {
          setState(() {
            _messages
              ..clear()
              ..addAll(decoded.whereType<Map>().map(
                    (item) => {
                      'message': item['message'],
                      'isMe': item['sender_role'] == widget.viewerRole,
                      'time': item['sent_at']?.toString() ?? '',
                    },
                  ));
            _isLoading = false;
          });
          _scrollToBottom();
          return;
        }
      }

      setState(() => _isLoading = false);
    } catch (error) {
      if (!mounted) return;

      setState(() => _isLoading = false);
      debugPrint('Fetch conversation error: $error');
    }
  }

  void _loadSampleMessages() {
    if (widget.personName == "Sarah Lee") {
      _messages.addAll([
        {
          "message":
          "Hi! Is the vegetable soup still available?",
          "isMe": false,
          "time": "10:30 AM",
        },
        {
          "message": "Yes, it is still available!",
          "isMe": true,
          "time": "10:32 AM",
        },
        {
          "message":
          "Great! I would like to request it.",
          "isMe": false,
          "time": "10:33 AM",
        },
      ]);
    } else if (widget.personName == "John Doe") {
      _messages.addAll([
        {
          "message":
          "Thank you for accepting my food request!",
          "isMe": false,
          "time": "9:15 AM",
        },
        {
          "message":
          "You're welcome! I'm happy to help.",
          "isMe": true,
          "time": "9:20 AM",
        },
      ]);
    } else if (widget.personName == "Michael Smith") {
      _messages.addAll([
        {
          "message":
          "I will pick up the bread tomorrow.",
          "isMe": false,
          "time": "Yesterday",
        },
        {
          "message":
          "Sounds good. I'll have it ready for you.",
          "isMe": true,
          "time": "Yesterday",
        },
      ]);
    } else if (widget.personName == "Jessica Brown") {
      _messages.addAll([
        {
          "message":
          "Thank you for helping our community.",
          "isMe": false,
          "time": "Yesterday",
        },
        {
          "message": "You're very welcome!",
          "isMe": true,
          "time": "Yesterday",
        },
      ]);
    } else {
      _messages.add({
        "message":
        "Hello! Welcome to NeighbourShare.",
        "isMe": false,
        "time": "Now",
      });
    }
  }

  void _sendMessage() {
    final message =
    _messageController.text.trim();

    if (message.isEmpty || _isSending) {
      return;
    }

    if (_isLiveConversation) {
      _sendLiveMessage(message);
      return;
    }

    setState(() {
      _messages.add({
        "message": message,
        "isMe": true,
        "time": _currentTime(),
      });

      _messageController.clear();
    });

    _scrollToBottom();
  }

  Future<void> _sendLiveMessage(String message) async {
    setState(() => _isSending = true);

    try {
      final response = await http
          .post(
            Uri.parse('$apiBaseUrl/messages'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'donor_id': widget.donorId,
              'recipient_id': widget.recipientId,
              'message': message,
              'sender_role': widget.viewerRole,
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (!mounted) return;

      setState(() => _isSending = false);

      if (response.statusCode == 201) {
        _messageController.clear();
        await _fetchConversation();
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

  String _currentTime() {
    final now = DateTime.now();

    final hour = now.hour == 0
        ? 12
        : now.hour > 12
        ? now.hour - 12
        : now.hour;

    final minute =
    now.minute.toString().padLeft(2, "0");

    final period =
    now.hour >= 12 ? "PM" : "AM";

    return "$hour:$minute $period";
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration:
          const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF4F7F5),

      appBar: AppBar(
        backgroundColor:
        const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white,
              child: Text(
                widget.avatar,
                style: const TextStyle(
                  color: Color(0xFF2E7D32),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.personName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
                overflow:
                TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? _buildEmptyChat()
                : ListView.builder(
              controller:
              _scrollController,
              padding:
              const EdgeInsets.fromLTRB(
                16,
                20,
                16,
                20,
              ),
              itemCount:
              _messages.length,
              itemBuilder:
                  (context, index) {
                return _buildMessageBubble(
                  _messages[index],
                );
              },
            ),
          ),

          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
      Map<String, dynamic> message,
      ) {
    final bool isMe =
    message["isMe"] as bool;

    final String text =
    message["message"] as String;

    final String time =
    message["time"] as String;

    return Align(
      alignment: isMe
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        constraints:
        const BoxConstraints(
          maxWidth: 300,
        ),
        margin:
        const EdgeInsets.only(bottom: 12),
        padding:
        const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isMe
              ? const Color(0xFF2E7D32)
              : Colors.white,
          borderRadius:
          BorderRadius.only(
            topLeft:
            const Radius.circular(18),
            topRight:
            const Radius.circular(18),
            bottomLeft:
            Radius.circular(
              isMe ? 18 : 4,
            ),
            bottomRight:
            Radius.circular(
              isMe ? 4 : 18,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: 0.05,
              ),
              blurRadius: 4,
              offset:
              const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isMe
                    ? Colors.white
                    : Colors.black87,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              time,
              style: TextStyle(
                color: isMe
                    ? Colors.white70
                    : Colors.grey.shade500,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding:
      const EdgeInsets.fromLTRB(
        12,
        10,
        12,
        12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.08,
            ),
            blurRadius: 8,
            offset:
            const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment:
          CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller:
                _messageController,
                minLines: 1,
                maxLines: 4,
                textCapitalization:
                TextCapitalization.sentences,
                decoration:
                InputDecoration(
                  hintText:
                  "Type a message...",
                  filled: true,
                  fillColor:
                  const Color(0xFFF4F7F5),
                  contentPadding:
                  const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border:
                  OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(24),
                    borderSide:
                    BorderSide.none,
                  ),
                ),
                onSubmitted: (_) {
                  _sendMessage();
                },
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration:
              const BoxDecoration(
                color: Color(0xFF2E7D32),
                shape: BoxShape.circle,
              ),
              child: IconButton(
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
                    : const Icon(Icons.send),
                color: Colors.white,
                tooltip: "Send message",
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 20),
            const Text(
              "Start a Conversation",
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Send a message to "
                  "${widget.personName}.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}