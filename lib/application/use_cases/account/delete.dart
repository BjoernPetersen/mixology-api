// ignore_for_file: unused_import

import 'package:injectable/injectable.dart';
import 'package:mixology_backend/application/repos/unit_of_work.dart';
import 'package:mixology_backend/application/repos/user.dart';
import 'package:sane_uuid/uuid.dart';

@injectable
class DeleteAccount {
  final UnitOfWorkProvider uowProvider;

  DeleteAccount(this.uowProvider);

  Future<void> call(Uuid userId) async {
    await uowProvider.withUnitOfWork((uow) async {
      await uow.userRepo.deleteUser(userId);
    });
  }
}
