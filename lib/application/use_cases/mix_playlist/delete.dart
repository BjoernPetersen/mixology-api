import 'package:injectable/injectable.dart';
import 'package:mixology_backend/application/repos/unit_of_work.dart';
import 'package:sane_uuid/uuid.dart';

@injectable
class DeleteMixPlaylist {
  final UnitOfWorkProvider uowProvider;

  DeleteMixPlaylist(this.uowProvider);

  Future<void> call({
    required Uuid userId,
    required String playlistId,
  }) async {
    await uowProvider.withUnitOfWork((uow) async {
      await uow.mixPlaylistRepo.delete(
        userId: userId,
        playlistId: playlistId,
      );
    });
  }
}
