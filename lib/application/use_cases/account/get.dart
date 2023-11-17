import 'package:injectable/injectable.dart';
import 'package:meta/meta.dart';
import 'package:mixology_backend/application/repos/unit_of_work.dart';
import 'package:sane_uuid/uuid.dart';

@injectable
class GetAccount {
  final UnitOfWorkProvider uowProvider;

  GetAccount(this.uowProvider);

  Future<AccountInfo?> call(Uuid userId) async {
    return await uowProvider.withUnitOfWork((uow) async {
      final user = await uow.userRepo.findById(userId);

      if (user == null) {
        return null;
      }

      return AccountInfo(
        id: userId,
        name: user.name,
        spotifyId: user.spotifyId,
      );
    });
  }
}

@immutable
class AccountInfo {
  final Uuid id;
  final String name;
  final String spotifyId;

  AccountInfo({
    required this.id,
    required this.name,
    required this.spotifyId,
  });
}
