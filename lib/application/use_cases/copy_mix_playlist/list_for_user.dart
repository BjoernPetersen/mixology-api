import 'package:injectable/injectable.dart';
import 'package:mixology_backend/application/domain/copy_mix_playlist.dart';
import 'package:mixology_backend/application/repos/unit_of_work.dart';
import 'package:mixology_backend/interface/api/util.dart';

@injectable
class ListCopyMixPlaylistsForUser {
  final UnitOfWorkProvider uowProvider;

  ListCopyMixPlaylistsForUser(this.uowProvider);

  Future<List<CopyMixPlaylist>> call(Uuid userId) async {
    return await uowProvider.withUnitOfWork((uow) async {
      return await uow.copyMixPlaylistRepo.findByUserId(userId);
    });
  }
}
