import 'package:injectable/injectable.dart';
import 'package:meta/meta.dart';
import 'package:mixology_backend/application/domain/user.dart';
import 'package:mixology_backend/application/ports/spotify_api.dart';
import 'package:mixology_backend/application/ports/token_factory.dart';
import 'package:mixology_backend/application/repos/user.dart';
import 'package:spotify_api/spotify_api.dart' hide User;

@injectable
class AuthFinish {
  final SpotifyApiProvider spotifyProvider;
  final TokenFactory tokenFactory;
  final UserAuthorizationFlow authFlow;
  final UserRepository userRepo;

  AuthFinish(
    this.authFlow,
    this.spotifyProvider,
    this.tokenFactory,
    this.userRepo,
  );

  Future<TokenPair> call(UserAuthorizationCallbackBody callbackBody) async {
    final spotifyRefreshToken = await authFlow.handleCallback(
      callback: callbackBody,
      userContext: null,
    );

    final api = spotifyProvider.provideForRefreshToken(spotifyRefreshToken);
    final me = await api.users.getCurrentUsersProfile();

    var user = await userRepo.findBySpotifyId(me.id);
    final name = me.displayName ?? me.id;
    if (user == null) {
      final newUser = User.register(
        spotifyId: me.id,
        name: name,
        spotifyRefreshToken: spotifyRefreshToken,
      );
      user = await userRepo.insertUser(newUser);
    } else {
      await userRepo.updateUser(user.copyWith(
        name: name,
        spotifyRefreshToken: spotifyRefreshToken,
      ));
    }

    return TokenPair(
      accessToken: await tokenFactory.generateAccessToken(
        userId: user.id,
        spotifyId: user.spotifyId,
      ),
      refreshToken: await tokenFactory.generateRefreshToken(
        userId: user.id,
        spotifyId: user.spotifyId,
      ),
    );
  }
}

@immutable
class TokenPair {
  final String accessToken;
  final String refreshToken;

  TokenPair({
    required this.accessToken,
    required this.refreshToken,
  });
}
