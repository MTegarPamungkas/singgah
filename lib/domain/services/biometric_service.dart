abstract interface class BiometricService {
  bool get isSupported;

  Future<bool> isAvailable();

  Future<bool> authenticate({required String reason});
}
