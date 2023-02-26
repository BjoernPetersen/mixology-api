import 'package:meta/meta.dart';
import 'package:sane_uuid/uuid.dart';

abstract class TokenFactory {
  Future<String> generateRefreshToken({
    required Uuid userId,
    required String spotifyId,
  });

  Future<String> generateAccessToken({
    required Uuid userId,
    required String spotifyId,
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
  // Nullable for backwards compatibility
  final String? spotifyId;

  TokenContent({
    required this.expiration,
    required this.userId,
    required this.spotifyId,
  });
}
