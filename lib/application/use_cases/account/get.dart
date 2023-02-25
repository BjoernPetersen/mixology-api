import 'package:injectable/injectable.dart';
import 'package:meta/meta.dart';
import 'package:mixology_backend/application/repos/user.dart';
import 'package:sane_uuid/uuid.dart';

@injectable
class GetAccount {
  final UserRepository userRepository;

  GetAccount(this.userRepository);

  Future<AccountInfo?> call(Uuid userId) async {
    final user = await userRepository.findById(userId);

    if (user == null) {
      return null;
    }

    return AccountInfo(
      id: userId,
      name: user.name,
      spotifyId: user.spotifyId,
    );
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
