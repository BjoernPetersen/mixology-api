import 'package:mixology_backend/application/repos/copy_mix_playlist.dart';
import 'package:mixology_backend/application/repos/mix_playlist.dart';
import 'package:mixology_backend/application/repos/user.dart';

abstract interface class UnitOfWork {
  CopyMixPlaylistRepository get copyMixPlaylistRepo;

  MixPlaylistRepository get mixPlaylistRepo;

  UserRepository get userRepo;
}

abstract interface class UnitOfWorkProvider {
  Future<T> withUnitOfWork<T>(Future<T> Function(UnitOfWork uow) action);
  Future<void> dispose();
}
