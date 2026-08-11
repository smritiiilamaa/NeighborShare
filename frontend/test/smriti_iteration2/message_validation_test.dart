import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/smriti_iteration2/message_validation.dart';

void main() {
  group('Smriti Iteration 2 - message validation', () {
    test('blank message is rejected', () {
      expect(MessageValidation.validate('  '), 'Enter a message');
    });

    test('normal message passes', () {
      expect(MessageValidation.validate('Is this still available?'), isNull);
    });

    test('message over limit is rejected', () {
      final longMessage = List.filled(501, 'a').join();
      expect(
        MessageValidation.validate(longMessage),
        'Message cannot exceed 500 characters',
      );
    });
  });
}
