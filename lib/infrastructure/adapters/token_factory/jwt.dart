import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:injectable/injectable.dart';
import 'package:mixology_backend/application/ports/token_factory.dart';
import 'package:mixology_backend/config.dart';
import 'package:sane_uuid/uuid.dart';

@Injectable(as: TokenFactory)
class JwtTokenFactory implements TokenFactory {
  final SecretKey _accessTokenKey;
  final SecretKey _refreshTokenKey;

  JwtTokenFactory(Config config)
      : _accessTokenKey = SecretKey(config.accessTokenJwtKey),
        _refreshTokenKey = SecretKey(config.refreshTokenJwtKey);

  @override
  Future<Uuid?> checkAccessTokenValidity({
    required String accessToken,
  }) async {
    final userId = JWT.tryVerify(accessToken, _accessTokenKey)?.subject;
    return userId == null ? null : Uuid.fromString(userId);
  }

  @override
  Future<TokenContent?> checkRefreshTokenValidity({
    required String refreshToken,
  }) async {
    final jwt = JWT.tryVerify(refreshToken, _refreshTokenKey);
    if (jwt == null) {
      return null;
    }

    return TokenContent(
      expiration: DateTime.fromMillisecondsSinceEpoch(
        Duration(seconds: jwt.payload['exp']).inMilliseconds,
      ),
      userId: Uuid.fromString(jwt.subject!),
    );
  }

  @override
  Future<String> generateAccessToken({
    required Uuid userId,
  }) async {
    final jwt = JWT(
      {},
      subject: userId.toString(),
    );
    return jwt.sign(
      _accessTokenKey,
      expiresIn: const Duration(minutes: 20),
    );
  }

  @override
  Future<String> generateRefreshToken({
    required Uuid userId,
  }) async {
    final jwt = JWT(
      {},
      subject: userId.toString(),
    );
    return jwt.sign(
      _refreshTokenKey,
      expiresIn: const Duration(days: 60),
    );
  }
}
