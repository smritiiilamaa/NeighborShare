import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/profile_validation.dart';

void main() {
  group('profile validation', () {
    test('valid email passes', () {
      expect(ProfileValidation.email('user@example.com'), isNull);
    });

    test('invalid email is rejected', () {
      expect(
        ProfileValidation.email('user.example.com'),
        'Enter a valid email address',
      );
    });

    test('required field cannot be blank', () {
      expect(
        ProfileValidation.requiredField('   ', 'Full name'),
        'Full name is required',
      );
    });

    test('valid Canadian postal code passes', () {
      expect(ProfileValidation.postalCode('M1B 2K3'), isNull);
    });

    test('invalid Canadian postal code is rejected', () {
      expect(
        ProfileValidation.postalCode('12345'),
        'Enter a valid Canadian postal code',
      );
    });
  });
}
