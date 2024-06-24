import 'package:injectable/injectable.dart';
import 'package:mixology_backend/application/ports/spotify_api.dart';
import 'package:mixology_backend/config.dart';
import 'package:spotify_api/spotify_api.dart';

@Injectable(as: SpotifyApiProvider)
class SimpleSpotifyApiProvider implements SpotifyApiProvider {
  final SpotifyAppConfig _config;

  SimpleSpotifyApiProvider(Config config) : _config = config.spotifyConfig;

  @override
  SpotifyWebApi provideForRefreshToken(String refreshToken) {
    return SpotifyWebApi(
      refresher: AuthorizationCodeRefresher.withoutPkce(
        clientId: _config.clientId,
        clientSecret: _config.clientSecret,
        refreshTokenStorage: MemoryRefreshTokenStorage(refreshToken),
      ),
    );
  }
}
