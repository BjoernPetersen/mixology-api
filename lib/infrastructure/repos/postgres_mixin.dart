import 'package:meta/meta.dart';
import 'package:mixology_backend/config.dart';
import 'package:postgres/postgres.dart';

abstract mixin class PostgresMixin {
  @visibleForOverriding
  DatabaseConfig get config;

  Future<T> withConnection<T>(
    Future<T> Function(Connection db) action,
  ) async {
    final connection = await Connection.open(
      Endpoint(
        host: config.host,
        port: config.port,
        database: config.dbName,
        username: config.user,
        password: config.password,
      ),
      settings: ConnectionSettings(
        sslMode: config.useTls ? SslMode.require : SslMode.disable,
      ),
    );

    try {
      return await action(connection);
    } finally {
      connection.close();
    }
  }

  Future<T> withTransaction<T>(
    Future<T> Function(Session session) action,
  ) async {
    return await withConnection((connection) => connection.runTx(action));
  }

  Future<T> withSession<T>(
    Future<T> Function(Session session) action,
  ) async {
    return await withConnection((connection) => connection.runTx(action));
  }
}
