import 'package:singgah/domain/entities/titipan.dart';
import 'package:singgah/domain/entities/titipan_feed.dart';
import 'package:singgah/domain/repositories/titipan_repository.dart';

class WatchTitipanFeed {
  const WatchTitipanFeed(this._repository);
  final TitipanRepository _repository;

  Stream<TitipanFeed> call() => _repository.watchFeed();
}

class GetTitipanFeed {
  const GetTitipanFeed(this._repository);
  final TitipanRepository _repository;

  Future<TitipanFeed> call() => _repository.getFeed();
}

class GetTitipan {
  const GetTitipan(this._repository);
  final TitipanRepository _repository;

  Future<Titipan?> call(String id) => _repository.getTitipan(id);
}

class SaveTitipan {
  const SaveTitipan(this._repository);
  final TitipanRepository _repository;

  Future<void> call(Titipan titipan) => _repository.saveTitipan(titipan);
}

class DeleteTitipan {
  const DeleteTitipan(this._repository);
  final TitipanRepository _repository;

  Future<void> call(String id) => _repository.deleteTitipan(id);
}

class AcceptTitipanInvite {
  const AcceptTitipanInvite(this._repository);
  final TitipanRepository _repository;

  Future<Titipan> call(String token) => _repository.acceptInvite(token);
}

class EnsureTitipanInviteLink {
  const EnsureTitipanInviteLink(this._repository);
  final TitipanRepository _repository;

  Future<String> call(Titipan titipan) => _repository.ensureInviteLink(titipan);
}

class MarkTitipanRead {
  const MarkTitipanRead(this._repository);
  final TitipanRepository _repository;

  Future<void> call(String id) => _repository.markRead(id);
}

class RefreshTitipan {
  const RefreshTitipan(this._repository);
  final TitipanRepository _repository;

  Future<void> call() => _repository.refresh();
}
