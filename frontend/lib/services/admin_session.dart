/// Tracks the currently authenticated Administrator for this app session.
class AdminSession {
  AdminSession._();

  static bool _isAuthenticated = false;
  static int? _accountId;

  static bool get isAuthenticated => _isAuthenticated;

  static int? get accountId => _accountId;

  static void login(int accountId) {
    _isAuthenticated = true;
    _accountId = accountId;
  }

  static void logout() {
    _isAuthenticated = false;
    _accountId = null;
  }
}