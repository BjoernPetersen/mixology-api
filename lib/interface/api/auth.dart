import 'package:injectable/injectable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:mixology_backend/application/app.dart';
import 'package:mixology_backend/application/ports/token_factory.dart';
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

  Future<RefreshResponse> refresh(Request request) async {
    final refreshToken = _getTokenFromHeader(request);
    final tokens = await app.refreshAuth(
      refreshToken: refreshToken,
    );
    if (tokens == null) {
      throw UnauthorizedException();
    }

    return RefreshResponse(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
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

String _getTokenFromHeader(Request request) {
  final authHeader = request.headers['Authorization'];
  final prefixLength = 'Bearer '.length;
  if (authHeader == null || authHeader.length < prefixLength) {
    throw UnauthorizedException();
  }
  return authHeader.substring(prefixLength);
}

@injectable
class AuthMiddleware {
  final TokenFactory _tokenFactory;

  AuthMiddleware(this._tokenFactory);

  Future<Response> _authenticate(Request request, Handler next) async {
    final token = _getTokenFromHeader(request);
    final userId = await _tokenFactory.checkAccessTokenValidity(
      accessToken: token,
    );

    if (userId == null) {
      throw UnauthorizedException();
    }

    final newRequest = request.change(
      context: {
        'principal': Principal(userId: userId),
      },
    );

    return await next(newRequest);
  }

  Handler call(Handler next) {
    return (request) => _authenticate(request, next);
  }
}
