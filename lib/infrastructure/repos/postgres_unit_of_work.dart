import 'package:injectable/injectable.dart';
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
  final Pool<void> _connectionPool;

  PostgresUnitOfWorkProvider(Config config)
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
    return await _connectionPool.runTx(
      (session) async {
        final uow = PostgresUnitOfWork(session);
        return await action(uow);
      },
    );
  }
}
