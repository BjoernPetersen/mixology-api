import 'package:injectable/injectable.dart';
import 'package:mixology_backend/application/domain/mix_playlist.dart';
import 'package:mixology_backend/application/repos/unit_of_work.dart';
import 'package:mixology_backend/interface/api/util.dart';

@injectable
class ListMixPlaylistsForUser {
  final UnitOfWorkProvider uowProvider;

  ListMixPlaylistsForUser(this.uowProvider);

  Future<List<MixPlaylist>> call(Uuid userId) async {
    return await uowProvider.withUnitOfWork((uow) async {
      return await uow.mixPlaylistRepo.findByUserId(userId);
    });
  }
}
