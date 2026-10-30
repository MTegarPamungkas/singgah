import 'package:equatable/equatable.dart';

class Titik extends Equatable {
  const Titik({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.address = '',
    this.radiusMeters = 150,
    this.iconKey = 'pin',
    this.colorHex = '#C94F0E',
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String ownerId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  /// Android geofences below 100 m are unreliable. Values are clamped by the
  /// editor and again by the planner.
  final int radiusMeters;
  final String iconKey;
  final String colorHex;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  bool get hasValidCoordinates =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;

  Titik copyWith({
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    int? radiusMeters,
    String? iconKey,
    String? colorHex,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Titik(
      id: id,
      ownerId: ownerId,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusMeters: (radiusMeters ?? this.radiusMeters).clamp(100, 2000),
      iconKey: iconKey ?? this.iconKey,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    ownerId,
    name,
    address,
    latitude,
    longitude,
    radiusMeters,
    iconKey,
    colorHex,
    createdAt,
    updatedAt,
    deletedAt,
  ];
}
