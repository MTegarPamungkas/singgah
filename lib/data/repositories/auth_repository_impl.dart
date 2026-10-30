import 'dart:async';
import 'dart:convert';

import 'package:appwrite/appwrite.dart' as aw;
import 'package:appwrite/enums.dart' as awenums;
import 'package:appwrite/models.dart' as awmodels;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:singgah/core/config/app_config.dart';
import 'package:singgah/data/datasources/cloud_gateway.dart';
import 'package:singgah/data/datasources/local_store.dart';
import 'package:singgah/data/seed/demo_seeder.dart';
import 'package:singgah/domain/entities/app_user.dart';
import 'package:singgah/domain/repositories/auth_repository.dart';
import 'package:uuid/uuid.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required LocalStore store,
    required DemoSeeder seeder,
    aw.Client? client,
    CloudGateway? gateway,
    Uuid? uuid,
  }) : _store = store,
       _seeder = seeder,
       _client = client,
       _gateway = gateway,
       _uuid = uuid ?? const Uuid() {
    _restoreSession();
  }

  final LocalStore _store;
  final DemoSeeder _seeder;
  final aw.Client? _client;
  final CloudGateway? _gateway;
  final Uuid _uuid;
  final StreamController<AppUser?> _sessionController =
      StreamController<AppUser?>.broadcast();

  static const String _sessionMetaKey = 'appwrite_session';

  AppUser? _cachedUser;
  AppUser? _demoUser;
  Future<void> _scopeChain = Future<void>.value();

  aw.Account? get _account => _client == null ? null : aw.Account(_client);
  aw.Storage? get _storage => _client == null ? null : aw.Storage(_client);

  @override
  AppUser? get currentUser => isDemo ? _demoUser : _cachedUser;

  @override
  bool get isDemo => _client == null;

  @override
  bool get isConfigured => _client != null;

  @override
  Stream<AppUser?> watchUser() async* {
    if (isDemo) {
      if (_demoUser == null) {
        final saved = _store.getMeta('demo_user');
        if (saved is Map) {
          _demoUser = AppUser(
            id: saved['id'] as String? ?? AppConfig.demoUserId,
            email: saved['email'] as String? ?? AppConfig.demoEmail,
            displayName: saved['display_name'] as String? ?? AppConfig.demoName,
            avatarUrl: saved['avatar_url'] as String?,
            isDemo: true,
            createdAt: DateTime.tryParse(saved['created_at'] as String? ?? ''),
          );
        }
      }
      final demoUser = _demoUser;
      if (demoUser != null) await _ensureScope(demoUser.id);
      yield demoUser;
      yield* _sessionController.stream;
      return;
    }

    try {
      final user = await _getAccountWithSessionRetry();
      final mapped = _mapUser(user);
      _cachedUser = mapped;
      await _ensureScope(mapped.id, discardDemoData: true);
      yield mapped;
    } on aw.AppwriteException catch (error) {
      if (error.code != 401) rethrow;
      _cachedUser = null;
      await _store.removeMeta(_sessionMetaKey);
      yield null;
    }
    yield* _sessionController.stream;
  }

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _createSession(email: email.trim(), password: password);
    return _finishSignIn();
  }

  @override
  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final account = _requireAccount();
    await account.create(
      userId: _uuid.v4(),
      email: email.trim(),
      password: password,
      name: displayName.trim(),
    );
    await _createSession(email: email.trim(), password: password);
    return _finishSignIn();
  }

  /// Creates a session and makes sure the client can use it.
  ///
  /// On the web the SDK relies on browser cookies. On Android/iOS the SDK's
  /// cookie jar rejects Appwrite's `SameSite=None` session cookie when the
  /// endpoint is plain HTTP (the cookie lacks `Secure`), so the app keeps the
  /// session token and sends it through `X-Appwrite-Session` instead.
  Future<void> _createSession({
    required String email,
    required String password,
  }) async {
    final account = _requireAccount();
    if (kIsWeb) {
      await account.createEmailPasswordSession(
        email: email,
        password: password,
      );
      return;
    }

    final response = await http.post(
      Uri.parse('${AppConfig.appwriteEndpoint}/account/sessions/email'),
      headers: {
        'X-Appwrite-Project': AppConfig.appwriteProjectId,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _errorFrom(response);
    }
    final session = _sessionFromResponse(response);
    if (session == null) {
      throw aw.AppwriteException(
        'The sign-in response did not include a session.',
        500,
      );
    }
    _applySession(session);
    await _store.setMeta(_sessionMetaKey, session);
  }

  aw.AppwriteException _errorFrom(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map) {
        return aw.AppwriteException(
          body['message']?.toString() ?? 'Request failed',
          response.statusCode,
          body['type']?.toString(),
          response.body,
        );
      }
    } catch (_) {
      // Fall back to the status code below.
    }
    return aw.AppwriteException(
      'Request failed with status ${response.statusCode}',
      response.statusCode,
      null,
      response.body,
    );
  }

  String? _sessionFromResponse(http.Response response) {
    final setCookie =
        response.headers['set-cookie'] ?? response.headers['Set-Cookie'];
    if (setCookie == null) return null;
    final match = RegExp(r'a_session_[A-Za-z0-9]+(?:_legacy)?=([^;,\s]+)')
        .firstMatch(setCookie);
    if (match == null) return null;
    return Uri.decodeComponent(match.group(1)!);
  }

  void _applySession(String session) {
    _client?.setSession(session);
  }

  void _restoreSession() {
    if (kIsWeb || _client == null) return;
    final saved = _store.getMeta(_sessionMetaKey);
    if (saved is String && saved.isNotEmpty) {
      _applySession(saved);
    }
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    final account = _requireAccount();
    await account.createOAuth2Session(
      provider: awenums.OAuthProvider.google,
      success: AppConfig.oauthRedirectUrl,
      failure: '${AppConfig.appScheme}://login-failure',
    );
    try {
      return await _finishSignIn();
    } on aw.AppwriteException catch (error) {
      if (error.code == 401) {
        throw StateError(
          'Google sign-in opened in a browser. The app will continue automatically.',
        );
      }
      rethrow;
    }
  }

  Future<AppUser> _finishSignIn() async {
    final user = await _getAccountWithSessionRetry();
    final mapped = _mapUser(user);
    _cachedUser = mapped;
    await _ensureScope(mapped.id, discardDemoData: true);
    _sessionController.add(mapped);
    return mapped;
  }

  /// The Android client persists the session cookie asynchronously after the
  /// sign-in response, so the very next call can race the cookie jar write and
  /// come back 401. Retry briefly before surfacing a login failure.
  Future<awmodels.User> _getAccountWithSessionRetry() async {
    final account = _requireAccount();
    for (var attempt = 0; ; attempt++) {
      try {
        return await account.get();
      } on aw.AppwriteException catch (error) {
        if (error.code != 401 || attempt >= 5) rethrow;
        await Future<void>.delayed(Duration(milliseconds: 60 * (attempt + 1)));
      }
    }
  }

  @override
  Future<AppUser> continueAsDemo() async {
    if (!isDemo) {
      throw UnsupportedError(
        'Demo mode is unavailable while Appwrite is configured.',
      );
    }
    await _ensureScope(AppConfig.demoUserId);
    await _seeder.seedIfNeeded();
    final user = AppUser(
      id: AppConfig.demoUserId,
      email: AppConfig.demoEmail,
      displayName: AppConfig.demoName,
      isDemo: true,
      createdAt: DateTime.now(),
    );
    _demoUser = user;
    await _store.setMeta('demo_user', {
      'id': user.id,
      'email': user.email,
      'display_name': user.displayName,
      'created_at': user.createdAt?.toIso8601String(),
    });
    _sessionController.add(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    if (isDemo) {
      _demoUser = null;
      _sessionController.add(null);
      await _store.clearUserData();
      return;
    }
    // Remove the push target while the session is still valid.
    final token = _store.getMeta('push_token');
    if (token is String && token.isNotEmpty) {
      try {
        await _gateway?.unregisterDeviceToken(token);
      } catch (_) {
        // Sign-out must still succeed if the network is unavailable.
      }
    }
    try {
      await _account?.deleteSessions();
    } catch (_) {
      // An expired session is already effectively signed out.
    }
    _client?.setSession('');
    await _store.removeMeta(_sessionMetaKey);
    _cachedUser = null;
    _sessionController.add(null);
    await _store.clearUserData();
  }

  @override
  Future<AppUser> updateProfile({
    required String displayName,
    String? avatarUrl,
  }) async {
    final name = displayName.trim();
    if (name.isEmpty) throw StateError('Display name is required.');
    if (isDemo) {
      final current = _demoUser;
      if (current == null) throw StateError('No active session.');
      final updated = current.copyWith(
        displayName: name,
        avatarUrl: avatarUrl ?? current.avatarUrl,
      );
      _demoUser = updated;
      await _store.setMeta('demo_user', {
        'id': updated.id,
        'email': updated.email,
        'display_name': updated.displayName,
        'avatar_url': updated.avatarUrl,
        'created_at': updated.createdAt?.toIso8601String(),
      });
      _sessionController.add(updated);
      return updated;
    }

    final account = _requireAccount();
    await account.updateName(name: name);
    if (avatarUrl != null) {
      final current = await account.get();
      final prefs = Map<String, dynamic>.from(current.prefs.data);
      prefs['avatar_url'] = avatarUrl;
      await account.updatePrefs(prefs: prefs);
    }
    final user = await account.get();
    final mapped = _mapUser(user);
    _cachedUser = mapped;
    _sessionController.add(mapped);
    return mapped;
  }

  @override
  Future<String?> uploadAvatar(List<int> bytes) async {
    if (isDemo) return null;
    final storage = _storage;
    final user = _cachedUser;
    if (storage == null || user == null) return null;
    final file = await storage.createFile(
      bucketId: AppConfig.appwriteAvatarBucket,
      fileId: aw.ID.unique(),
      file: aw.InputFile.fromBytes(
        bytes: bytes,
        filename: 'avatar.jpg',
        contentType: 'image/jpeg',
      ),
      permissions: [
        aw.Permission.read(aw.Role.any()),
        aw.Permission.update(aw.Role.user(user.id)),
        aw.Permission.delete(aw.Role.user(user.id)),
      ],
    );
    final base = AppConfig.appwriteEndpoint.endsWith('/')
        ? AppConfig.appwriteEndpoint.substring(
            0,
            AppConfig.appwriteEndpoint.length - 1,
          )
        : AppConfig.appwriteEndpoint;
    return '$base/storage/buckets/${AppConfig.appwriteAvatarBucket}/files/'
        '${file.$id}/view?project=${AppConfig.appwriteProjectId}'
        '&v=${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _ensureScope(String userId, {bool discardDemoData = false}) {
    _scopeChain = _scopeChain
        .catchError((Object _) {})
        .then(
          (_) =>
              _store.ensureUserScope(userId, discardDemoData: discardDemoData),
        );
    return _scopeChain;
  }

  aw.Account _requireAccount() {
    final account = _account;
    if (account == null) {
      throw UnsupportedError(
        'Cloud is not configured. Use demo mode or set APPWRITE_ENDPOINT and APPWRITE_PROJECT_ID.',
      );
    }
    return account;
  }

  AppUser _mapUser(awmodels.User user) {
    final prefs = user.prefs.data;
    final displayName = user.name.trim().isNotEmpty
        ? user.name
        : (user.email.split('@').first.isEmpty
              ? 'Singgah user'
              : user.email.split('@').first);
    return AppUser(
      id: user.$id,
      email: user.email,
      displayName: displayName,
      avatarUrl: prefs['avatar_url']?.toString(),
      isDemo: false,
      createdAt: DateTime.tryParse(user.$createdAt),
    );
  }
}
