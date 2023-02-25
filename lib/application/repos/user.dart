import 'package:mixology_backend/application/domain/user.dart';
import 'package:sane_uuid/uuid.dart';

abstract class UserRepository {
  Future<User<Uuid>?> findById(Uuid userId);
  Future<User<Uuid>?> findBySpotifyId(String spotifyId);
  Future<User<Uuid>> insertUser(User<void> user);
  Future<void> updateUser(User<Uuid> user);
  Future<void> deleteUser(Uuid userId);
}
