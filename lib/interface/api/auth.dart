import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:mixology_backend/application/app.dart';
import 'package:mixology_backend/interface/api/util.dart';
import 'package:shelf_plus/shelf_plus.dart';
import 'package:spotify_api/spotify_api.dart';

part 'auth.g.dart';

class AuthApi {
  final Application app;

  AuthApi(this.app);

  Future<LoginResponse> login(Request request) async {
    final loginUrl = await app.startAuth();
    return LoginResponse(loginUrl.toString());
  }

  Future<TokenPairResponse> callback(Request request) async {
    final data = UserAuthorizationCallbackBody.fromJson(
      request.url.queryParameters,
    );
    // TODO error handling
    final result = await app.finishAuth(data);
    return TokenPairResponse(
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
    );
  }

  Future<Response> refresh(Request request) async {
    final authHeader = request.headers['Authorization'];
    final prefixLength = 'Bearer '.length;
    if (authHeader == null || authHeader.length < prefixLength) {
      return Response.unauthorized(null);
    }
    final refreshToken = authHeader.substring(prefixLength);
    final tokens = await app.refreshAuth(
      refreshToken: refreshToken,
    );
    if (tokens == null) {
      return Response.unauthorized(null);
    }

    return Response.ok(
      jsonEncode(
        RefreshResponse(
          accessToken: tokens.accessToken,
          refreshToken: tokens.refreshToken,
        ).toJson(),
      ),
    );
  }
}

@immutable
@JsonSerializable(createFactory: false)
class LoginResponse {
  final String loginUrl;

  LoginResponse(this.loginUrl);

  Json toJson() => _$LoginResponseToJson(this);
}

@immutable
@JsonSerializable(createFactory: false, includeIfNull: false)
class RefreshResponse {
  final String accessToken;
  final String? refreshToken;

  RefreshResponse({
    required this.accessToken,
    required this.refreshToken,
  });

  Json toJson() => _$RefreshResponseToJson(this);
}

@immutable
@JsonSerializable(createFactory: false)
class TokenPairResponse {
  final String accessToken;
  final String refreshToken;

  TokenPairResponse({
    required this.accessToken,
    required this.refreshToken,
  });

  Json toJson() => _$TokenPairResponseToJson(this);
}
