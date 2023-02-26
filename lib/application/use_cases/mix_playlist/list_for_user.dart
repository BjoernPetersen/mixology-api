import 'package:injectable/injectable.dart';
import 'package:mixology_backend/application/domain/mix_playlist.dart';
import 'package:mixology_backend/application/repos/mix_playlist.dart';
import 'package:mixology_backend/interface/api/util.dart';

@injectable
class ListMixPlaylistsForUser {
  final MixPlaylistRepository repo;

  ListMixPlaylistsForUser(this.repo);

  Future<List<MixPlaylist>> call(Uuid userId) async {
    return await repo.findByUserId(userId);
  }
}
