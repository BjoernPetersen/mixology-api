import 'package:injectable/injectable.dart';
import 'package:mixology_backend/application/ports/spotify_api.dart';
import 'package:mixology_backend/application/repos/user.dart';
import 'package:sane_uuid/uuid.dart';
import 'package:spotify_api/spotify_api.dart';

@injectable
class GetAccessToken {
  final UserRepository userRepository;
  final SpotifyApiProvider apiProvider;

  GetAccessToken(this.userRepository, this.apiProvider);

  Future<TokenInfo> call(Uuid userId) async {
    final user = await userRepository.findById(userId);
    if (user == null) {
      throw ArgumentError.value(userId, 'userId', 'user does not exist');
    }

    final api = apiProvider.provideForRefreshToken(
      user.spotifyRefreshToken,
    );

    final accessToken = await api.rawAccessToken;
    return TokenInfo(
      value: accessToken,
      expiration: DateTime.now().add(Duration(minutes: 10)),
    );
  }
}
