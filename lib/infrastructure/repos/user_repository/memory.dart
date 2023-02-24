import 'package:injectable/injectable.dart';
import 'package:mixology_backend/application/domain/user.dart';
import 'package:mixology_backend/application/repos/user.dart';
import 'package:sane_uuid/uuid.dart';

@test
@Injectable(as: UserRepository)
class MemoryUserRepository implements UserRepository {
  final List<User<Uuid>> _users = [];

  @override
  Future<User<Uuid>?> findById(Uuid userId) async {
    for (final user in _users) {
      if (user.id == userId) {
        return user;
      }
    }
    return null;
  }

  @override
  Future<User<Uuid>?> findBySpotifyId(String spotifyId) async {
    for (final user in _users) {
      if (user.spotifyId == spotifyId) {
        return user;
      }
    }
    return null;
  }

  @override
  Future<User<Uuid>> insertUser(User<void> user) async {
    final existing = await findBySpotifyId(user.spotifyId);
    if (existing != null) {
      throw ArgumentError.value(user, 'user', 'user already exists');
    }
    final userId = Uuid.v4();
    final userWithId = user.withId(userId);
    _users.add(userWithId);
    return userWithId;
  }

  @override
  Future<void> updateUser(User<Uuid> user) async {
    _users.removeWhere((element) => element.id == user.id);
    _users.add(user);
  }
}
