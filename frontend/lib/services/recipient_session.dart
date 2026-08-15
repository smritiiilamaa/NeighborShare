/// Tracks the currently logged-in Recipient's ID for this app session.
///
/// Screens reached through the normal Dashboard -> Browse -> Details chain
/// receive the ID as a constructor parameter. Any other entry point (a
/// screen reopened after backing out, a route not part of that chain, a
/// future deep link) falls back to this session instead of silently
/// reverting to a hardcoded placeholder ID.
class RecipientSession {
  RecipientSession._();

  static int? _recipientId;

  static int? get recipientId => _recipientId;

  static bool get isAuthenticated => _recipientId != null;

  static void login(int recipientId) {
    _recipientId = recipientId;
  }

  static void logout() {
    _recipientId = null;
  }
}
