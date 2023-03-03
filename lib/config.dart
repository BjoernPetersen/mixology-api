import 'package:dotenv/dotenv.dart';
import 'package:injectable/injectable.dart';

class SpotifyAppConfig {
  final String clientId;
  final String clientSecret;
  final String redirectUri;

  SpotifyAppConfig({
    required this.clientId,
    required this.clientSecret,
    required this.redirectUri,
  });

  factory SpotifyAppConfig.fromEnv(DotEnv env) {
    return SpotifyAppConfig(
      clientId: env['CLIENT_ID']!,
      clientSecret: env['CLIENT_SECRET']!,
      redirectUri: env['REDIRECT_URI']!,
    );
  }
}

class DatabaseConfig {
  final String host;
  final int port;
  final String dbName;
  final String user;
  final String password;
  final bool useTls;

  DatabaseConfig({
    required this.host,
    required this.port,
    required this.dbName,
    required this.user,
    required this.password,
    required this.useTls,
  });

  factory DatabaseConfig.fromEnv(DotEnv env) {
    return DatabaseConfig(
      host: env['DB_HOST'] ?? 'localhost',
      port: int.parse(env['DB_PORT'] ?? '5432'),
      dbName: env['DB_NAME'] ?? 'postgres',
      user: env['DB_USER'] ?? 'postgres',
      password: env['DB_PASSWORD'] ?? 'pw',
      useTls: env['DB_USE_TLS'] == 'true',
    );
  }
}

@singleton
class Config {
  final String accessTokenJwtKey;
  final String refreshTokenJwtKey;
  final String oauthJwtKey;
  final DatabaseConfig database;
  final String? sentryDsn;
  final SpotifyAppConfig spotifyConfig;

  Config({
    required this.accessTokenJwtKey,
    required this.refreshTokenJwtKey,
    required this.oauthJwtKey,
    required this.database,
    required this.sentryDsn,
    required this.spotifyConfig,
  });

  @factoryMethod
  factory Config.fromEnv() {
    final env = DotEnv(includePlatformEnvironment: true);
    env.load();
    return Config(
      accessTokenJwtKey: env['ACCESS_JWT_KEY']!,
      refreshTokenJwtKey: env['REFRESH_JWT_KEY']!,
      oauthJwtKey: env['OAUTH_JWT_KEY']!,
      database: DatabaseConfig.fromEnv(env),
      sentryDsn: env['SENTRY_DSN'],
      spotifyConfig: SpotifyAppConfig.fromEnv(env),
    );
  }
}
