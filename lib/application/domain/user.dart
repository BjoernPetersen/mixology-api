import 'package:sane_uuid/uuid.dart';

class User<ID extends Uuid?> {
  final ID id;
  final String spotifyId;
  final String name;
  final String spotifyRefreshToken;

  User({
    required this.id,
    required this.spotifyId,
    required this.name,
    required this.spotifyRefreshToken,
  });

  static User<void> register({
    required String spotifyId,
    required String name,
    required String spotifyRefreshToken,
  }) =>
      User(
        id: null,
        spotifyId: spotifyId,
        name: name,
        spotifyRefreshToken: spotifyRefreshToken,
      );

  User<Uuid> withId(Uuid id) {
    return User(
      id: id,
      spotifyId: spotifyId,
      name: name,
      spotifyRefreshToken: spotifyRefreshToken,
    );
  }

  User<ID> copyWith({String? name, String? spotifyRefreshToken}) {
    return User<ID>(
      id: id,
      spotifyId: spotifyId,
      name: name ?? this.name,
      spotifyRefreshToken: spotifyRefreshToken ?? this.spotifyRefreshToken,
    );
  }
}
