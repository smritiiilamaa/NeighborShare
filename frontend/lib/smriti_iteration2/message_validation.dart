/// Smriti - Iteration 2 / R8 (S7)
class MessageValidation {
  const MessageValidation._();

  static const int maxLength = 500;

  static String? validate(String? value) {
    final message = (value ?? '').trim();

    if (message.isEmpty) {
      return 'Enter a message';
    }

    if (message.length < 2) {
      return 'Message is too short';
    }

    if (message.length > maxLength) {
      return 'Message cannot exceed $maxLength characters';
    }

    return null;
  }
}
