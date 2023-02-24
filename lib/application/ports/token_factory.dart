import 'package:meta/meta.dart';
import 'package:sane_uuid/uuid.dart';

abstract class TokenFactory {
  Future<String> generateRefreshToken({
    required Uuid userId,
  });

  Future<String> generateAccessToken({
    required Uuid userId,
  });

  Future<TokenContent?> checkRefreshTokenValidity({
    required String refreshToken,
  });

  Future<Uuid?> checkAccessTokenValidity({
    required String accessToken,
  });
}

@immutable
class TokenContent {
  final DateTime expiration;
  final Uuid userId;

  TokenContent({
    required this.expiration,
    required this.userId,
  });
}
