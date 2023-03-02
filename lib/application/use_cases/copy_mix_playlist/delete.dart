import 'package:injectable/injectable.dart';
import 'package:mixology_backend/application/repos/copy_mix_playlist.dart';
import 'package:sane_uuid/uuid.dart';

@injectable
class DeleteCopyMixPlaylist {
  final CopyMixPlaylistRepository repo;

  DeleteCopyMixPlaylist(this.repo);

  Future<void> call({
    required Uuid userId,
    required String? sourceId,
  }) async {
    await repo.delete(
      userId: userId,
      sourcePlaylistId: sourceId,
    );
  }
}
