import 'package:singgah/domain/entities/titik.dart';

abstract interface class PlaceRepository {
  Stream<List<Titik>> watchPlaces();

  Future<List<Titik>> getPlaces();

  Future<Titik?> getPlace(String id);

  Future<void> savePlace(Titik place);

  Future<void> deletePlace(String id);
}
