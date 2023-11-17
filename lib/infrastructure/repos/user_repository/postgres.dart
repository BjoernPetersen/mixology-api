import 'package:mixology_backend/application/domain/user.dart';
import 'package:mixology_backend/application/repos/user.dart';
import 'package:mixology_backend/infrastructure/repos/postgres_utils.dart';
import 'package:postgres/postgres.dart';
import 'package:sane_uuid/uuid.dart';

const tableName = 'users';
const columnId = 'id';
const columnSpotifyId = 'spotify_id';
const columnName = 'name';
const columnSpotifyRefreshToken = 'spotify_refresh_token';

class PostgresUserRepository implements UserRepository {
  final Session _session;

  PostgresUserRepository(this._session);

  User<Uuid> _userFromRow(ResultRow row) {
    final columns = row.toColumnMap();
    final id = columns[columnId];
    final spotifyId = columns[columnSpotifyId];
    final name = columns[columnName];
    final spotifyRefreshToken = columns[columnSpotifyRefreshToken];

    return User(
      id: Uuid.fromString(id),
      spotifyId: spotifyId,
      name: name,
      spotifyRefreshToken: spotifyRefreshToken,
    );
  }

  @override
  Future<User<Uuid>?> findById(Uuid userId) async {
    final rows = await _session.executePrepared(
      '''
      SELECT * FROM $tableName
      WHERE $columnId = @userId:uuid;
      ''',
      parameters: {
        'userId': userId.toString(),
      },
    );

    if (rows.isEmpty) {
      return null;
    }

    return _userFromRow(rows.single);
  }

  @override
  Future<User<Uuid>?> findBySpotifyId(String spotifyId) async {
    final rows = await _session.executePrepared(
      '''
        SELECT * FROM $tableName
        WHERE $columnSpotifyId = @spotifyId:text;
        ''',
      parameters: {
        'spotifyId': spotifyId,
      },
    );

    if (rows.isEmpty) {
      return null;
    }

    return _userFromRow(rows.single);
  }

  @override
  Future<User<Uuid>> insertUser(User<void> user) async {
    final userId = Uuid.v4();
    await _session.executePrepared(
      '''
        INSERT INTO $tableName(
          $columnId,
          $columnSpotifyId,
          $columnName,
          $columnSpotifyRefreshToken
        ) VALUES (
          @userId:uuid,
          @spotifyId:text,
          @name:text,
          @spotifyRefreshToken:text
        );
        ''',
      parameters: {
        'userId': userId.toString(),
        'spotifyId': user.spotifyId,
        'name': user.name,
        'spotifyRefreshToken': user.spotifyRefreshToken,
      },
    );
    return user.withId(userId);
  }

  @override
  Future<void> updateUser(User<Uuid> user) async {
    await _session.executePrepared(
      '''
        UPDATE $tableName
        SET 
          $columnSpotifyId = @spotifyId:text,
          $columnName = @name:text,
          $columnSpotifyRefreshToken = @spotifyRefreshToken:text
        WHERE $columnId = @userId:uuid;
        ''',
      parameters: {
        'userId': user.id.toString(),
        'spotifyId': user.spotifyId,
        'name': user.name,
        'spotifyRefreshToken': user.spotifyRefreshToken,
      },
    );
  }

  @override
  Future<void> deleteUser(Uuid userId) async {
    await _session.execute(
      '''
        DELETE FROM $tableName
        WHERE $columnId = @userId:uuid;
        ''',
      parameters: {
        'userId': userId.toString(),
      },
    );
  }
}
