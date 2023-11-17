import 'package:injectable/injectable.dart';
import 'package:mixology_backend/application/repos/unit_of_work.dart';
import 'package:sane_uuid/uuid.dart';

@injectable
class DeleteCopyMixPlaylist {
  final UnitOfWorkProvider uowProvider;

  DeleteCopyMixPlaylist(this.uowProvider);

  Future<void> call({
    required Uuid userId,
    required String targetId,
  }) async {
    await uowProvider.withUnitOfWork((uow) async {
      await uow.copyMixPlaylistRepo.delete(
        userId: userId,
        targetPlaylistId: targetId,
      );
    });
  }
}
