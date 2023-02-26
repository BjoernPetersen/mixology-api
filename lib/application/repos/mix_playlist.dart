import 'package:mixology_backend/application/domain/mix_playlist.dart';
import 'package:sane_uuid/uuid.dart';

abstract class MixPlaylistRepository {
  Future<List<MixPlaylist>> findByUserId(Uuid userId);

  Future<List<MixPlaylist>> listAll();

  Future<void> insert(MixPlaylist playlist);

  Future<void> update({
    required String id,
    required String name,
    required DateTime lastMix,
  });

  Future<void> delete({
    required Uuid userId,
    required String playlistId,
  });
}
