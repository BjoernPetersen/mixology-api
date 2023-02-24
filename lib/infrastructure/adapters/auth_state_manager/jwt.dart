import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:injectable/injectable.dart';
import 'package:mixology_backend/config.dart';
import 'package:spotify_api/spotify_api.dart';

@Injectable(as: AuthorizationStateManager)
class JwtAuthStateManager implements AuthorizationStateManager {
  final SecretKey _key;

  JwtAuthStateManager({
    required Config config,
  }) : _key = SecretKey(config.oauthJwtKey);

  @override
  Future<String> createState({
    required String? userContext,
  }) async {
    final jwt = JWT({
      if (userContext != null) 'userContext': userContext,
    });
    return jwt.sign(
      _key,
      expiresIn: const Duration(minutes: 5),
    );
  }

  @override
  Future<bool> validateState({
    required String state,
    required String? userContext,
  }) async {
    final jwt = JWT.tryVerify(state, _key);

    if (jwt == null) {
      return false;
    }

    return userContext == jwt.payload['userContext'];
  }
}
