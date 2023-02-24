import 'package:injectable/injectable.dart';
import 'package:mixology_backend/application/domain/user.dart';
import 'package:mixology_backend/application/repos/user.dart';
import 'package:mixology_backend/config.dart';
import 'package:postgres/postgres.dart';
import 'package:sane_uuid/uuid.dart';

const tableName = 'users';
const columnId = 'id';
const columnSpotifyId = 'spotify_id';
const columnName = 'name';
const columnSpotifyRefreshToken = 'spotify_refresh_token';

@dev
@prod
@Injectable(as: UserRepository)
class PostgresUserRepository implements UserRepository {
  final DatabaseConfig _config;

  PostgresUserRepository(Config config) : _config = config.database;

  User<Uuid> _userFromRow(Map<String, dynamic> row) {
    final id = row[columnId];
    final spotifyId = row[columnSpotifyId];
    final name = row[columnName];
    final spotifyRefreshToken = row[columnSpotifyRefreshToken];

    return User(
      id: Uuid.fromString(id),
      spotifyId: spotifyId,
      name: name,
      spotifyRefreshToken: spotifyRefreshToken,
    );
  }

  Future<T> useConnection<T>(
    Future<T> Function(PostgreSQLConnection db) action,
  ) async {
    final connection = PostgreSQLConnection(
      _config.host,
      _config.port,
      _config.dbName,
      username: _config.user,
      password: _config.password,
      useSSL: _config.useTls,
    );
    await connection.open();
    try {
      return await action(connection);
    } finally {
      connection.close();
    }
  }

  @override
  Future<User<Uuid>?> findById(Uuid userId) {
    return useConnection((db) async {
      final rows = await db.mappedResultsQuery('''
        SELECT * FROM $tableName
        WHERE $columnId = @userId;
        ''', substitutionValues: {
        'userId': userId.toString(),
      });

      if (rows.isEmpty) {
        return null;
      }

      return _userFromRow(rows.single[tableName]!);
    });
  }

  @override
  Future<User<Uuid>?> findBySpotifyId(String spotifyId) {
    return useConnection((db) async {
      final rows = await db.mappedResultsQuery('''
        SELECT * FROM $tableName
        WHERE $columnSpotifyId = @spotifyId;
        ''', substitutionValues: {
        'spotifyId': spotifyId,
      });

      if (rows.isEmpty) {
        return null;
      }

      return _userFromRow(rows.single[tableName]!);
    });
  }

  @override
  Future<User<Uuid>> insertUser(User<void> user) async {
    final userId = Uuid.v4();
    await useConnection((db) async {
      await db.execute(
        '''
        INSERT INTO $tableName(
          $columnId,
          $columnSpotifyId,
          $columnName,
          $columnSpotifyRefreshToken
        ) VALUES (
          @userId,
          @spotifyId,
          @name,
          @spotifyRefreshToken
        );
        ''',
        substitutionValues: {
          'userId': userId.toString(),
          'spotifyId': user.spotifyId,
          'name': user.name,
          'spotifyRefreshToken': user.spotifyRefreshToken,
        },
      );
    });
    return user.withId(userId);
  }

  @override
  Future<void> updateUser(User<Uuid> user) async {
    await useConnection((db) async {
      await db.execute(
        '''
        UPDATE $tableName
        SET 
          $columnSpotifyId = @spotifyId,
          $columnName = @name,
          $columnSpotifyRefreshToken = @spotifyRefreshToken
        WHERE $columnId = @userId;
        ''',
        substitutionValues: {
          'userId': user.id.toString(),
          'spotifyId': user.spotifyId,
          'name': user.name,
          'spotifyRefreshToken': user.spotifyRefreshToken,
        },
      );
    });
  }
}
