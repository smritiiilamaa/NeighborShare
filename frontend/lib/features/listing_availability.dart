/// Prevents a recipient from requesting/claiming a listing that has already
/// been accepted/reserved or is otherwise unavailable.
class ListingAvailability {
  const ListingAvailability._();

  static bool isAvailable(String? status) {
    return (status ?? '').trim().toLowerCase() == 'available';
  }

  static String? unavailableMessage(String? status) {
    if (isAvailable(status)) return null;

    final value = (status ?? '').trim();
    if (value.isEmpty) return 'This listing is not available.';

    return 'This listing is no longer available (status: $value).';
  }
}
