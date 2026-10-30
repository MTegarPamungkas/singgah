import 'package:singgah/data/datasources/cloud_gateway.dart';
import 'package:singgah/domain/entities/natural_draft.dart';
import 'package:singgah/domain/repositories/discovery_repository.dart';

class DiscoveryRepositoryImpl implements DiscoveryRepository {
  DiscoveryRepositoryImpl(this._gateway);

  final CloudGateway _gateway;

  @override
  Future<NaturalDraft> parseNatural(
    String text, {
    required String localeCode,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw const DiscoveryException('Empty sentence');
    }
    if (trimmed.length > 500) {
      throw const DiscoveryException('Sentence is too long');
    }
    try {
      final json = await _gateway.parseNaturalReminder(
        trimmed,
        localeCode: localeCode,
      );
      final draft = NaturalDraft.fromAiJson(
        json,
        rawText: trimmed,
        localeCode: localeCode,
      );
      if (!draft.isUsable) {
        throw const DiscoveryException('AI returned an empty title');
      }
      return draft;
    } on DiscoveryException {
      rethrow;
    } catch (error) {
      throw DiscoveryException(error.toString());
    }
  }

  @override
  Future<List<PlaceSuggestion>> searchPlaces(
    String query, {
    required String localeCode,
  }) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return const [];
    try {
      return await _gateway.searchPlaces(trimmed, localeCode: localeCode);
    } on DiscoveryException {
      rethrow;
    } catch (error) {
      throw DiscoveryException(error.toString());
    }
  }

  @override
  Future<String?> reverseGeocode(
    double latitude,
    double longitude, {
    required String localeCode,
  }) async {
    try {
      return await _gateway.reverseGeocode(
        latitude,
        longitude,
        localeCode: localeCode,
      );
    } catch (_) {
      return null;
    }
  }
}
