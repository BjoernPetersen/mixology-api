import 'package:injectable/injectable.dart';
import 'package:mixology_backend/application/domain/mix_playlist.dart';
import 'package:mixology_backend/application/repos/mix_playlist.dart';
import 'package:mixology_backend/config.dart';
import 'package:postgres/postgres.dart';
import 'package:sane_uuid/uuid.dart';

const tableName = 'mix_playlists';
const columnId = 'id';
const columnUserId = 'user_id';
const columnName = 'name';
const columnLastMix = 'last_mix';

@Injectable(as: MixPlaylistRepository)
class PostgresMixPlaylistRepository implements MixPlaylistRepository {
  final DatabaseConfig _config;

  PostgresMixPlaylistRepository(Config config) : _config = config.database;

  MixPlaylist _mixPlaylistFromRow(Map<String, dynamic> row) {
    final id = row[columnId];
    final userId = Uuid.fromString(row[columnUserId]);
    final name = row[columnName];
    final lastMixTimestamp = row[columnLastMix];

    return MixPlaylist(
      id: id,
      userId: userId,
      name: name,
      lastMix: lastMixTimestamp,
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
  Future<List<MixPlaylist>> findByUserId(Uuid userId) {
    return useConnection((db) async {
      final rows = await db.mappedResultsQuery(
        '''
        SELECT * FROM $tableName
        WHERE $columnUserId = @userId;
        ''',
        substitutionValues: {
          'userId': userId.toString(),
        },
      );

      if (rows.isEmpty) {
        return [];
      }

      return rows
          .map((e) => _mixPlaylistFromRow(e[tableName]!))
          .toList(growable: false);
    });
  }

  @override
  Future<List<MixPlaylist>> listAll() {
    return useConnection((db) async {
      final rows = await db.mappedResultsQuery(
        '''
        SELECT * FROM $tableName
        ORDER BY $columnId;
        ''',
      );

      if (rows.isEmpty) {
        return [];
      }

      return rows
          .map((e) => _mixPlaylistFromRow(e[tableName]!))
          .toList(growable: false);
    });
  }

  @override
  Future<void> insert(MixPlaylist playlist) async {
    await useConnection((db) async {
      await db.execute(
        '''
        INSERT INTO $tableName(
          $columnId,
          $columnUserId,
          $columnName,
          $columnLastMix
        ) VALUES (
          @id,
          @userId,
          @name,
          @lastMix
        ) ON CONFLICT DO NOTHING;
        ''',
        substitutionValues: {
          'id': playlist.id,
          'userId': playlist.userId.toString(),
          'name': playlist.name,
          'lastMix': playlist.lastMix,
        },
      );
    });
  }

  @override
  Future<void> update({
    required String id,
    required String name,
    required DateTime lastMix,
  }) async {
    await useConnection((db) async {
      await db.execute(
        '''
        UPDATE $tableName
        SET 
          $columnName = @name,
          $columnLastMix = @lastMix
        WHERE $columnId = @id;
        ''',
        substitutionValues: {
          'id': id,
          'name': name,
          'lastMix': lastMix,
        },
      );
    });
  }

  @override
  Future<void> delete({
    required Uuid userId,
    required String playlistId,
  }) async {
    await useConnection((db) async {
      await db.execute(
        '''
        DELETE FROM $tableName
        WHERE $columnId = @id AND $columnUserId = @userId;
        ''',
        substitutionValues: {
          'id': playlistId,
          'userId': userId.toString(),
        },
      );
    });
  }
}
