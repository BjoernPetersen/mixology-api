import 'package:injectable/injectable.dart';
import 'package:mixology_backend/application/repos/mix_playlist.dart';
import 'package:sane_uuid/uuid.dart';

@injectable
class DeleteMixPlaylist {
  final MixPlaylistRepository repo;

  DeleteMixPlaylist(this.repo);

  Future<void> call({
    required Uuid userId,
    required String playlistId,
  }) async {
    await repo.delete(
      userId: userId,
      playlistId: playlistId,
    );
  }
}
