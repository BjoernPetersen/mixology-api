import 'package:injectable/injectable.dart';
import 'package:mixology_backend/application/repos/user.dart';
import 'package:sane_uuid/uuid.dart';

@injectable
class DeleteAccount {
  final UserRepository userRepository;

  DeleteAccount(this.userRepository);

  Future<void> call(Uuid userId) async {
    await userRepository.deleteUser(userId);
  }
}
