import 'package:mixology_backend/application/repos/unit_of_work.dart';
import 'package:mixology_backend/application/repos/user.dart';
import 'package:mixology_backend/config.dart';
import 'package:mixology_backend/infrastructure/repos/postgres_unit_of_work.dart';
import 'package:mixology_backend/interface/api/util.dart';
import 'package:test/test.dart';

void main() async {
  late final UnitOfWorkProvider uowProvider;

  setUpAll(() {
    uowProvider = PostgresUnitOfWorkProvider(Config.fromEnv());
  });

  tearDownAll(() => uowProvider.dispose());

  group('UserRepository', () {
    test('get non-existent user', () async {
      final user = await uowProvider.withUnitOfWork((uow) {
        return uow.userRepo.findById(Uuid.v4());
      });
      expect(user, isNull);
    });
  });
}
