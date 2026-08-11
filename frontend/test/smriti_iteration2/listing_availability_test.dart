import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/smriti_iteration2/listing_availability.dart';

void main() {
  group('Smriti Iteration 2 - listing availability', () {
    test('available listing can be requested', () {
      expect(ListingAvailability.isAvailable('Available'), isTrue);
    });

    test('reserved listing cannot be requested', () {
      expect(ListingAvailability.isAvailable('Reserved'), isFalse);
      expect(
        ListingAvailability.unavailableMessage('Reserved'),
        contains('no longer available'),
      );
    });
  });
}
