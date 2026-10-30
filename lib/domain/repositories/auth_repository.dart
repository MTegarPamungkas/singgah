import 'package:singgah/domain/entities/app_user.dart';

abstract interface class AuthRepository {
  bool get isDemo;

  bool get isConfigured;

  AppUser? get currentUser;

  Stream<AppUser?> watchUser();

  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  });

  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  });

  Future<AppUser> signInWithGoogle();

  Future<AppUser> continueAsDemo();

  Future<void> signOut();

  Future<AppUser> updateProfile({
    required String displayName,
    String? avatarUrl,
  });

  Future<String?> uploadAvatar(List<int> bytes);
}
