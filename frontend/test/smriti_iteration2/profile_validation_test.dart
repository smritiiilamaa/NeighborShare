import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/smriti_iteration2/profile_validation.dart';

void main() {
  group('Smriti Iteration 2 - profile validation', () {
    test('valid email passes', () {
      expect(ProfileValidation.email('smriti@example.com'), isNull);
    });

    test('invalid email is rejected', () {
      expect(
        ProfileValidation.email('smriti.example.com'),
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
