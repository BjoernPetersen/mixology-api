import 'package:injectable/injectable.dart';
import 'package:mixology_backend/config.dart';
import 'package:spotify_api/spotify_api.dart';

@module
abstract class UserAuthorizationModule {
  UserAuthorizationFlow provideUserAuthorizationFlow(
    AuthorizationStateManager stateManager,
    Config config,
  ) {
    final appConfig = config.spotifyConfig;
    return AuthorizationCodeUserAuthorization(
      clientId: appConfig.clientId,
      redirectUri: Uri.parse(appConfig.redirectUri),
      stateManager: stateManager,
      clientSecret: appConfig.clientSecret,
    );
  }
}
