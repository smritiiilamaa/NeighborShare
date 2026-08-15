import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/api_config.dart';
import 'message_details.dart';

class InboxScreen extends StatefulWidget {
  // Exactly one of these should be set: donorId shows the donor's inbox
  // (conversations grouped by recipient), recipientId shows the
  // recipient's inbox (conversations grouped by donor).
  final int? donorId;
  final int? recipientId;
  final http.Client? httpClient;

  const InboxScreen({
    super.key,
    this.donorId,
    this.recipientId,
    this.httpClient,
  }) : assert(
          donorId != null || recipientId != null,
          'InboxScreen requires either a donorId or a recipientId.',
        );

  bool get _isDonorView => donorId != null;

  @override
  State<InboxScreen> createState() =>
      _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;
  String? _errorMessage;

  String _searchText = "";

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      final client = widget.httpClient ?? http.Client();
      final uri = widget._isDonorView
          ? Uri.parse('$apiBaseUrl/messages/donor/${widget.donorId}')
          : Uri.parse('$apiBaseUrl/messages/${widget.recipientId}');
      final response = await client.get(
        uri,
        headers: const {'Accept': 'application/json'},
      );

      if (!mounted) return;

      if (response.statusCode != 200) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Unable to load messages.';
        });
        return;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'The server returned an unexpected response.';
        });
        return;
      }

      final messages = decoded
          .whereType<Map>()
          .map((message) => Map<String, dynamic>.from(message))
          .toList();

      setState(() {
        _conversations
          ..clear()
          ..addAll(_buildConversations(messages));
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not connect to the server.';
      });
      debugPrint('Load messages error: $error');
    }
  }

  List<Map<String, dynamic>> _buildConversations(
    List<Map<String, dynamic>> messages,
  ) {
    // Donor view groups by who the recipient was; recipient view groups by
    // who the donor was -- either way, that's "the other person" in each
    // conversation.
    final otherPartyField =
        widget._isDonorView ? 'recipient_id' : 'donor_id';
    final otherPartyLabel = widget._isDonorView ? 'Recipient' : 'Donor';
    final myRole = widget._isDonorView ? 'Donor' : 'Recipient';

    final groupedMessages =
        <int, List<Map<String, dynamic>>>{};

    for (final message in messages) {
      final otherPartyId =
          int.tryParse(message[otherPartyField].toString());

      if (otherPartyId == null) continue;

      groupedMessages
          .putIfAbsent(otherPartyId, () => [])
          .add(message);
    }

    return groupedMessages.entries.map((entry) {
      final conversationMessages = entry.value;

      final unreadMessages = conversationMessages
          .where((message) =>
              message['is_read'] != true && message['sender_role'] != myRole)
          .toList();

      final latestMessage = conversationMessages.last;

      return {
        "name": "$otherPartyLabel #${entry.key}",
        "message":
            latestMessage['message']?.toString() ?? '',
        "time":
            _formatMessageTime(latestMessage['sent_at']),
        "unread": unreadMessages.isNotEmpty,
        "count": unreadMessages.length,
        "avatar": entry.key.toString(),
        otherPartyField: entry.key,
        "message_ids": conversationMessages
            .map((message) => message['message_id'])
            .where((id) => id != null)
            .toList(),
        "messages":
            conversationMessages.map(_toDetailMessage).toList(),
      };
    }).toList();
  }

  Map<String, dynamic> _toDetailMessage(Map<String, dynamic> message) {
    final myRole = widget._isDonorView ? 'Donor' : 'Recipient';
    final isMe = message['sender_role'] == myRole;

    return {
      "message": message['message']?.toString() ?? '',
      "isMe": isMe,
      "time": _formatMessageTime(message['sent_at']),
    };
  }

  String _formatMessageTime(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    if (parsed == null) return '';
    return '${parsed.month}/${parsed.day} ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
  }

  List<Map<String, dynamic>>
  get _filteredConversations {
    if (_searchText.trim().isEmpty) {
      return _conversations;
    }

    final search =
    _searchText.toLowerCase().trim();

    return _conversations.where((conversation) {
      final name = conversation["name"]
          .toString()
          .toLowerCase();

      final message = conversation["message"]
          .toString()
          .toLowerCase();

      return name.contains(search) ||
          message.contains(search);
    }).toList();
  }

  int get _unreadConversationCount {
    return _conversations
        .where(
          (conversation) =>
      conversation["unread"] == true,
    )
        .length;
  }

  // ==========================================
  // OPEN ACTUAL CONVERSATION
  // ==========================================

  Future<void> _openConversation(
      Map<String, dynamic> conversation,
      ) async {
    final messageIds = (conversation['message_ids'] as List<dynamic>?) ?? [];
    final unread = conversation['unread'] == true;

    if (unread && messageIds.isNotEmpty) {
      try {
        final client = widget.httpClient ?? http.Client();
        final readUri = widget._isDonorView
            ? Uri.parse('$apiBaseUrl/messages/donor/${widget.donorId}/read')
            : Uri.parse('$apiBaseUrl/messages/${widget.recipientId}/read');
        final response = await client.patch(
          readUri,
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'message_ids': messageIds}),
        );

        if (!mounted) return;
        if (response.statusCode != 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to mark messages as read.')),
          );
          return;
        }

        setState(() {
          conversation['unread'] = false;
          conversation['count'] = 0;
        });
      } catch (error) {
        debugPrint('Mark messages read error: $error');
        return;
      }
    }

    final String name =
    conversation["name"] as String;

    final String avatar =
    conversation["avatar"] as String;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MessageDetailsScreen(
          personName: name,
          avatar: avatar,
          initialMessages:
              (conversation['messages'] as List<dynamic>?)
                  ?.whereType<Map>()
                  .map((message) => Map<String, dynamic>.from(message))
                  .toList(),
          donorId: widget._isDonorView
              ? widget.donorId
              : conversation['donor_id'] as int?,
          recipientId: widget._isDonorView
              ? conversation['recipient_id'] as int?
              : widget.recipientId,
          viewerRole: widget._isDonorView ? 'Donor' : 'Recipient',
        ),
      ),
    );
  }

  // ==========================================
  // MARK ALL AS READ
  // ==========================================

  void _markAllAsRead() {
    setState(() {
      for (final conversation
      in _conversations) {
        conversation["unread"] = false;
        conversation["count"] = 0;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
        Text("All messages marked as read."),
        backgroundColor:
        Color(0xFF2E7D32),
      ),
    );
  }

  // ==========================================
  // DELETE CONVERSATION
  // ==========================================

  void _deleteConversation(int index) {
    final conversation =
    _filteredConversations[index];

    final originalIndex =
    _conversations.indexOf(conversation);

    final name = conversation["name"];

    setState(() {
      _conversations.removeAt(originalIndex);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Conversation with $name deleted.",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final conversations =
        _filteredConversations;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Inbox",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor:
        const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          if (_unreadConversationCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                "Mark all read",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // ==========================================
          // SEARCH
          // ==========================================

          Padding(
            padding:
            const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              8,
            ),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchText = value;
                });
              },
              decoration: InputDecoration(
                hintText:
                "Search messages or people",
                prefixIcon:
                const Icon(Icons.search),
                suffixIcon:
                _searchText.isNotEmpty
                    ? IconButton(
                  onPressed: () {
                    setState(() {
                      _searchText = "";
                    });
                  },
                  icon: const Icon(
                    Icons.clear,
                  ),
                )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(14),
                  borderSide:
                  BorderSide(
                    color:
                    Colors.grey.shade300,
                  ),
                ),
                enabledBorder:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(14),
                  borderSide:
                  BorderSide(
                    color:
                    Colors.grey.shade300,
                  ),
                ),
              ),
            ),
          ),

          // ==========================================
          // UNREAD SUMMARY
          // ==========================================

          if (_unreadConversationCount > 0 &&
              _searchText.isEmpty)
            Container(
              width: double.infinity,
              margin:
              const EdgeInsets.fromLTRB(
                16,
                8,
                16,
                8,
              ),
              padding:
              const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color:
                const Color(0xFFE8F5E9),
                borderRadius:
                BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons
                        .mark_email_unread_outlined,
                    color:
                    Color(0xFF2E7D32),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "$_unreadConversationCount unread "
                        "conversation"
                        "${_unreadConversationCount == 1 ? '' : 's'}",
                    style: const TextStyle(
                      color:
                      Color(0xFF2E7D32),
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          // ==========================================
          // CONVERSATIONS
          // ==========================================

          Expanded(
            child: _errorMessage != null
                ? Center(child: Text(_errorMessage!))
                : conversations.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding:
              const EdgeInsets.all(16),
              itemCount:
              conversations.length,
              itemBuilder:
                  (context, index) {
                return _buildConversationCard(
                  conversations[index],
                  index,
                );
              },
            ),
          ),
        ],
      ),

      // ==========================================
      // NEW MESSAGE BUTTON
      // ==========================================

      floatingActionButton:
      FloatingActionButton(
        backgroundColor:
        const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        tooltip: "New Message",
        onPressed: () {
          _showNewMessageDialog();
        },
        child: const Icon(
          Icons.edit_outlined,
        ),
      ),
    );
  }

  // ==========================================
  // CONVERSATION CARD
  // ==========================================

  Widget _buildConversationCard(
      Map<String, dynamic> conversation,
      int index,
      ) {
    final String name =
    conversation["name"] as String;

    final String message =
    conversation["message"] as String;

    final String time =
    conversation["time"] as String;

    final bool unread =
    conversation["unread"] as bool;

    final int count =
    conversation["count"] as int;

    final String avatar =
    conversation["avatar"] as String;

    return Dismissible(
      key: ValueKey(
        "$name-$index",
      ),
      direction:
      DismissDirection.endToStart,
      background: Container(
        margin:
        const EdgeInsets.only(
          bottom: 12,
        ),
        padding:
        const EdgeInsets.only(
          right: 20,
        ),
        alignment:
        Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius:
          BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      onDismissed: (_) {
        _deleteConversation(index);
      },
      child: Card(
        margin:
        const EdgeInsets.only(
          bottom: 12,
        ),
        elevation:
        unread ? 4 : 1,
        shape:
        RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: () {
            _openConversation(
              conversation,
            );
          },
          borderRadius:
          BorderRadius.circular(16),
          child: Padding(
            padding:
            const EdgeInsets.all(15),
            child: Row(
              children: [
                // ==========================================
                // AVATAR
                // ==========================================

                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor:
                      const Color(
                        0xFFE8F5E9,
                      ),
                      child: Text(
                        avatar,
                        style:
                        const TextStyle(
                          color:
                          Color(
                            0xFF2E7D32,
                          ),
                          fontSize: 20,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                    ),

                    if (unread)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 13,
                          height: 13,
                          decoration:
                          const BoxDecoration(
                            color:
                            Colors.red,
                            shape:
                            BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: 14),

                // ==========================================
                // MESSAGE CONTENT
                // ==========================================

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style:
                              TextStyle(
                                fontSize: 16,
                                fontWeight:
                                unread
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            time,
                            style:
                            TextStyle(
                              fontSize: 12,
                              color: Colors
                                  .grey.shade500,
                              fontWeight:
                              unread
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              message,
                              maxLines: 2,
                              overflow:
                              TextOverflow.ellipsis,
                              style:
                              TextStyle(
                                fontSize: 14,
                                color: Colors
                                    .grey.shade700,
                                fontWeight:
                                unread
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                height: 1.3,
                              ),
                            ),
                          ),

                          if (count > 0)
                            Container(
                              margin:
                              const EdgeInsets.only(
                                left: 8,
                              ),
                              padding:
                              const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration:
                              const BoxDecoration(
                                color:
                                Color(0xFF2E7D32),
                                shape:
                                BoxShape.circle,
                              ),
                              child: Text(
                                count.toString(),
                                style:
                                const TextStyle(
                                  color:
                                  Colors.white,
                                  fontSize: 11,
                                  fontWeight:
                                  FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 5),

                const Icon(
                  Icons.chevron_right,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // EMPTY STATE
  // ==========================================

  Widget _buildEmptyState() {
    final bool isSearching =
        _searchText.trim().isNotEmpty;

    return Center(
      child: Padding(
        padding:
        const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Icon(
              isSearching
                  ? Icons.search_off
                  : Icons.mail_outline,
              size: 85,
              color:
              Colors.grey.shade400,
            ),

            const SizedBox(height: 20),

            Text(
              isSearching
                  ? "No Conversations Found"
                  : "Your Inbox Is Empty",
              style: const TextStyle(
                fontSize: 21,
                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              isSearching
                  ? "Try searching for another person "
                  "or message."
                  : "Your conversations and messages "
                  "will appear here.",
              textAlign:
              TextAlign.center,
              style: TextStyle(
                color:
                Colors.grey.shade600,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // NEW MESSAGE DIALOG
  // ==========================================

  void _showNewMessageDialog() {
    final nameController =
    TextEditingController();

    final messageController =
    TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(18),
          ),
          title:
          const Text("New Message"),
          content: Column(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              TextField(
                controller:
                nameController,
                decoration:
                const InputDecoration(
                  labelText:
                  "Recipient",
                  prefixIcon:
                  Icon(Icons.person),
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller:
                messageController,
                maxLines: 3,
                decoration:
                const InputDecoration(
                  labelText:
                  "Message",
                  alignLabelWithHint: true,
                  prefixIcon:
                  Icon(Icons.message),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child:
              const Text("Cancel"),
            ),

            ElevatedButton(
              onPressed: () {
                final name =
                nameController.text
                    .trim();

                final message =
                messageController.text
                    .trim();

                if (name.isEmpty ||
                    message.isEmpty) {
                  return;
                }

                setState(() {
                  _conversations.insert(
                    0,
                    {
                      "name": name,
                      "message": message,
                      "time": "Just now",
                      "unread": false,
                      "count": 0,
                      "avatar": name
                          .substring(0, 1)
                          .toUpperCase(),
                    },
                  );
                });

                Navigator.pop(context);

                ScaffoldMessenger.of(
                  this.context,
                ).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Message conversation created.",
                    ),
                    backgroundColor:
                    Color(0xFF2E7D32),
                  ),
                );
              },
              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                const Color(0xFF2E7D32),
                foregroundColor:
                Colors.white,
              ),
              child:
              const Text("Send"),
            ),
          ],
        );
      },
    );
  }
}