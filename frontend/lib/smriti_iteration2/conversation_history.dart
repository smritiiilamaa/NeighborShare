import 'package:flutter/material.dart';

/// Smriti - Iteration 2 / D6 (S2)
class ConversationMessage {
  final String senderName;
  final String text;
  final DateTime sentAt;
  final bool sentByCurrentUser;

  const ConversationMessage({
    required this.senderName,
    required this.text,
    required this.sentAt,
    required this.sentByCurrentUser,
  });
}

class ConversationHistory extends StatelessWidget {
  final List<ConversationMessage> messages;

  const ConversationHistory({
    super.key,
    required this.messages,
  });

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble_outline, size: 52, color: Colors.grey),
              SizedBox(height: 12),
              Text('No messages yet.'),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final message = messages[index];
        final alignment = message.sentByCurrentUser
            ? Alignment.centerRight
            : Alignment.centerLeft;
        final background = message.sentByCurrentUser
            ? const Color(0xFFE8F5E9)
            : Colors.grey.shade100;

        return Align(
          alignment: alignment,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.senderName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(message.text),
                    const SizedBox(height: 5),
                    Text(
                      _formatTime(message.sentAt),
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
