import 'package:mixology_backend/application/domain/copy_mix_playlist.dart';
import 'package:sane_uuid/uuid.dart';

abstract class CopyMixPlaylistRepository {
  Future<List<CopyMixPlaylist>> findByUserId(Uuid userId);

  Future<List<CopyMixPlaylist>> listAll();

  Future<void> insert(CopyMixPlaylist playlist);

  Future<void> update({
    required String targetPlaylistId,
    required DateTime lastMix,
  });

  Future<void> delete({
    required Uuid userId,
    required String targetPlaylistId,
  });
}
