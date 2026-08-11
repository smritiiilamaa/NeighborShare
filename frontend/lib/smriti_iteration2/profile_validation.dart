/// Shared profile validators used by Smriti's profile-update validation tests.
class ProfileValidation {
  const ProfileValidation._();

  static String? requiredField(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    return null;
  }

  static String? email(String? value) {
    final required = requiredField(value, 'Email');
    if (required != null) return required;

    final clean = value!.trim();
    final pattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!pattern.hasMatch(clean)) return 'Enter a valid email address';
    return null;
  }

  static String? postalCode(String? value) {
    final required = requiredField(value, 'Postal code');
    if (required != null) return required;

    final clean = value!.trim().toUpperCase();
    final canadian = RegExp(r'^[A-Z]\d[A-Z][ -]?\d[A-Z]\d$');
    if (!canadian.hasMatch(clean)) return 'Enter a valid Canadian postal code';
    return null;
  }
}
