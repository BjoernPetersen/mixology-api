import 'package:injectable/injectable.dart';
import 'package:mixology_backend/application/domain/copy_mix_playlist.dart';
import 'package:mixology_backend/application/repos/copy_mix_playlist.dart';
import 'package:mixology_backend/interface/api/util.dart';

@injectable
class ListCopyMixPlaylistsForUser {
  final CopyMixPlaylistRepository repo;

  ListCopyMixPlaylistsForUser(this.repo);

  Future<List<CopyMixPlaylist>> call(Uuid userId) async {
    return await repo.findByUserId(userId);
  }
}
