/// Tracks whether an Administrator is currently authenticated for this
/// app session. Set by [AdminLoginScreen] on a successful login and
/// checked by [AdminRouteGuard] before any admin-only screen is shown.
class AdminSession {
  AdminSession._();

  static bool _isAuthenticated = false;

  static bool get isAuthenticated => _isAuthenticated;

  static void login() {
    _isAuthenticated = true;
  }

  static void logout() {
    _isAuthenticated = false;
  }
}
