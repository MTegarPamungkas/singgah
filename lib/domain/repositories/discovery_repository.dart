import 'package:singgah/domain/entities/natural_draft.dart';

class PlaceSuggestion {
  const PlaceSuggestion({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.category = '',
  });

  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String category;
}

abstract interface class DiscoveryRepository {
  /// Calls the backend AI function. Throws [DiscoveryException] on failure so
  /// the UI can offer manual entry.
  Future<NaturalDraft> parseNatural(String text, {required String localeCode});

  /// Calls the backend geocoding function, never Nominatim directly.
  Future<List<PlaceSuggestion>> searchPlaces(
    String query, {
    required String localeCode,
  });

  Future<String?> reverseGeocode(
    double latitude,
    double longitude, {
    required String localeCode,
  });
}

class DiscoveryException implements Exception {
  const DiscoveryException(this.message, {this.rateLimited = false});

  final String message;
  final bool rateLimited;

  @override
  String toString() => message;
}
