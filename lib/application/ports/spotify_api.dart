import 'package:spotify_api/spotify_api.dart';

abstract class SpotifyApiProvider {
  SpotifyWebApi provideForRefreshToken(String refreshToken);
}
