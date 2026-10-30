import 'package:app_links/app_links.dart';
import 'package:singgah/domain/services/deep_link_service.dart';

DeepLinkService createDeepLinkService() => DeepLinkServiceIO();

class DeepLinkServiceIO implements DeepLinkService {
  final AppLinks _appLinks = AppLinks();

  @override
  Stream<String> get inviteTokens => _appLinks.uriLinkStream
      .map(_tokenFromUri)
      .where((token) => token != null)
      .cast<String>();

  @override
  Future<String?> initialInviteToken() async {
    try {
      final uri = await _appLinks.getInitialLink();
      if (uri == null) return null;
      return _tokenFromUri(uri);
    } catch (_) {
      return null;
    }
  }

  String? _tokenFromUri(Uri uri) {
    final segments = uri.pathSegments;
    final index = segments.indexOf('invite');
    if (index >= 0 && index + 1 < segments.length) {
      final token = segments[index + 1].trim();
      return token.isEmpty ? null : token;
    }
    if (uri.host == 'invite' && segments.isNotEmpty) {
      final token = segments.first.trim();
      return token.isEmpty ? null : token;
    }
    return null;
  }

  @override
  Future<void> dispose() async {}
}
