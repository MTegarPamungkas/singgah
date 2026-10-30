import 'package:equatable/equatable.dart';

import 'package:singgah/domain/services/location_service.dart';

class GeofenceSummary extends Equatable {
  const GeofenceSummary({
    this.supported = false,
    this.enabled = true,
    this.permission = LocationPermissionState.denied,
    this.registered = 0,
    this.skipped = 0,
    this.updatedAt,
    this.refreshing = false,
  });

  final bool supported;
  final bool enabled;
  final LocationPermissionState permission;
  final int registered;
  final int skipped;
  final DateTime? updatedAt;
  final bool refreshing;

  bool get isActive =>
      supported &&
      enabled &&
      (permission == LocationPermissionState.grantedForeground ||
          permission == LocationPermissionState.grantedBackground);

  bool get hasBackground =>
      permission == LocationPermissionState.grantedBackground;

  @override
  List<Object?> get props => [
    supported,
    enabled,
    permission,
    registered,
    skipped,
    updatedAt,
    refreshing,
  ];
}
