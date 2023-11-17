import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:mixology_backend/application/repos/copy_mix_playlist.dart';
import 'package:mixology_backend/application/repos/mix_playlist.dart';
import 'package:mixology_backend/application/repos/unit_of_work.dart';
import 'package:mixology_backend/application/repos/user.dart';
import 'package:mixology_backend/config.dart';
import 'package:mixology_backend/infrastructure/repos/copy_mix_playlist/postgres.dart';
import 'package:mixology_backend/infrastructure/repos/mix_playlist/postgres.dart';
import 'package:mixology_backend/infrastructure/repos/user_repository/postgres.dart';
import 'package:postgres/postgres.dart';

class PostgresUnitOfWork implements UnitOfWork {
  @override
  final CopyMixPlaylistRepository copyMixPlaylistRepo;

  @override
  final MixPlaylistRepository mixPlaylistRepo;

  @override
  final UserRepository userRepo;

  PostgresUnitOfWork(Session session)
      : copyMixPlaylistRepo = PostgresCopyMixPlaylistRepository(session),
        mixPlaylistRepo = PostgresMixPlaylistRepository(session),
        userRepo = PostgresUserRepository(session);
}

@dev
@prod
@Singleton(as: UnitOfWorkProvider)
class PostgresUnitOfWorkProvider implements UnitOfWorkProvider {
  final Logger _logger;
  final Pool<void> _connectionPool;

  PostgresUnitOfWorkProvider(this._logger, Config config)
      : _connectionPool = Pool.withEndpoints(
          [
            Endpoint(
              host: config.database.host,
              port: config.database.port,
              database: config.database.dbName,
              username: config.database.user,
              password: config.database.password,
            )
          ],
          settings: PoolSettings(
            sslMode: config.database.useTls ? SslMode.require : SslMode.disable,
          ),
        );

  @override
  Future<T> withUnitOfWork<T>(Future<T> Function(UnitOfWork) action) async {
    return await _connectionPool.withConnection(
      (connection) async {
        return await connection.runTx(
          (session) async {
            final uow = PostgresUnitOfWork(session);
            return await action(uow);
          },
        );
      },
    );
  }

  @disposeMethod
  @override
  Future<void> dispose() async {
    await _connectionPool.close();
    _logger.i('Closed PostgresUnitOfWorkProvider');
  }
}
