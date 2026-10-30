import 'package:singgah/domain/entities/app_user.dart';
import 'package:singgah/domain/repositories/auth_repository.dart';

class WatchAuthUser {
  const WatchAuthUser(this._repository);
  final AuthRepository _repository;

  Stream<AppUser?> call() => _repository.watchUser();
}

class GetCurrentUser {
  const GetCurrentUser(this._repository);
  final AuthRepository _repository;

  AppUser? call() => _repository.currentUser;
}

class SignInWithEmail {
  const SignInWithEmail(this._repository);
  final AuthRepository _repository;

  Future<AppUser> call({required String email, required String password}) =>
      _repository.signInWithEmail(email: email, password: password);
}

class SignUpWithEmail {
  const SignUpWithEmail(this._repository);
  final AuthRepository _repository;

  Future<AppUser> call({
    required String email,
    required String password,
    required String displayName,
  }) => _repository.signUpWithEmail(
    email: email,
    password: password,
    displayName: displayName,
  );
}

class SignInWithGoogle {
  const SignInWithGoogle(this._repository);
  final AuthRepository _repository;

  Future<AppUser> call() => _repository.signInWithGoogle();
}

class ContinueAsDemo {
  const ContinueAsDemo(this._repository);
  final AuthRepository _repository;

  Future<AppUser> call() => _repository.continueAsDemo();
}

class SignOut {
  const SignOut(this._repository);
  final AuthRepository _repository;

  Future<void> call() => _repository.signOut();
}

class UpdateProfile {
  const UpdateProfile(this._repository);
  final AuthRepository _repository;

  Future<AppUser> call({required String displayName, String? avatarUrl}) =>
      _repository.updateProfile(displayName: displayName, avatarUrl: avatarUrl);
}

class UploadAvatar {
  const UploadAvatar(this._repository);
  final AuthRepository _repository;

  Future<String?> call(List<int> bytes) => _repository.uploadAvatar(bytes);
}
