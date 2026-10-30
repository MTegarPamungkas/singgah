import 'package:singgah/domain/entities/natural_draft.dart';
import 'package:singgah/domain/repositories/discovery_repository.dart';

class ParseNaturalReminder {
  const ParseNaturalReminder(this._repository);
  final DiscoveryRepository _repository;

  Future<NaturalDraft> call(String text, {required String localeCode}) =>
      _repository.parseNatural(text, localeCode: localeCode);
}

class SearchPlaces {
  const SearchPlaces(this._repository);
  final DiscoveryRepository _repository;

  Future<List<PlaceSuggestion>> call(
    String query, {
    required String localeCode,
  }) => _repository.searchPlaces(query, localeCode: localeCode);
}

class ReverseGeocode {
  const ReverseGeocode(this._repository);
  final DiscoveryRepository _repository;

  Future<String?> call(
    double latitude,
    double longitude, {
    required String localeCode,
  }) => _repository.reverseGeocode(latitude, longitude, localeCode: localeCode);
}
