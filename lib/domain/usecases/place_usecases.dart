import 'package:singgah/domain/entities/titik.dart';
import 'package:singgah/domain/repositories/place_repository.dart';

class WatchPlaces {
  const WatchPlaces(this._repository);
  final PlaceRepository _repository;

  Stream<List<Titik>> call() => _repository.watchPlaces();
}

class GetPlaces {
  const GetPlaces(this._repository);
  final PlaceRepository _repository;

  Future<List<Titik>> call() => _repository.getPlaces();
}

class GetPlace {
  const GetPlace(this._repository);
  final PlaceRepository _repository;

  Future<Titik?> call(String id) => _repository.getPlace(id);
}

class SavePlace {
  const SavePlace(this._repository);
  final PlaceRepository _repository;

  Future<void> call(Titik place) => _repository.savePlace(place);
}

class DeletePlace {
  const DeletePlace(this._repository);
  final PlaceRepository _repository;

  Future<void> call(String id) => _repository.deletePlace(id);
}
