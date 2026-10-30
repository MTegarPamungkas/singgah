/// Holds an invite token that arrived before the user signed in.
///
/// The router consumes it right after authentication so opening a share link
/// on a signed-out device still lands on the invitation, not the dashboard.
abstract final class InviteIntent {
  static String? token;

  static void remember(String value) {
    final trimmed = value.trim();
    token = trimmed.isEmpty ? null : trimmed;
  }

  static String? take() {
    final value = token;
    token = null;
    return value;
  }
}
