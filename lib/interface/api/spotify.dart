import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:mixology_backend/application/app.dart';
import 'package:mixology_backend/interface/api/util.dart';
import 'package:shelf/shelf.dart';

part 'spotify.g.dart';

class SpotifyApi {
  final Application app;

  SpotifyApi(this.app);

  Future<AccessTokenResponse> getAccessToken(Request request) async {
    final token = await app.getAccessToken(request.principal.userId);
    return AccessTokenResponse(
      token: token.accessToken,
      expiresAt: token.expiration,
    );
  }
}

@immutable
@JsonSerializable(createFactory: false)
class AccessTokenResponse {
  final String token;
  final DateTime expiresAt;

  AccessTokenResponse({
    required this.token,
    required this.expiresAt,
  });

  Json toJson() => _$AccessTokenResponseToJson(this);
}
