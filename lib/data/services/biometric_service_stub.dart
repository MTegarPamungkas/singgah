import 'package:singgah/domain/services/biometric_service.dart';

BiometricService createBiometricService() => BiometricServiceStub();

class BiometricServiceStub implements BiometricService {
  @override
  bool get isSupported => false;

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<bool> authenticate({required String reason}) async => false;
}
