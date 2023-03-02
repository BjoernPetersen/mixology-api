import 'package:injectable/injectable.dart';
import 'package:mixology_backend/application/domain/copy_mix_playlist.dart';
import 'package:mixology_backend/application/repos/copy_mix_playlist.dart';
import 'package:mixology_backend/config.dart';
import 'package:postgres/postgres.dart';
import 'package:sane_uuid/uuid.dart';

const tableName = 'copy_mix_playlists';
const columnSourceId = 'source_id';
const columnTargetId = 'target_id';
const columnUserId = 'user_id';
const columnLastMix = 'last_mix';

@Injectable(as: CopyMixPlaylistRepository)
class PostgresCopyMixPlaylistRepository implements CopyMixPlaylistRepository {
  final DatabaseConfig _config;

  PostgresCopyMixPlaylistRepository(Config config) : _config = config.database;

  CopyMixPlaylist _mixPlaylistFromRow(Map<String, dynamic> row) {
    final sourceId = row[columnSourceId];
    final targetId = row[columnTargetId];
    final userId = Uuid.fromString(row[columnUserId]);
    final lastMixTimestamp = row[columnLastMix];

    return CopyMixPlaylist(
      sourceId: sourceId,
      targetId: targetId,
      userId: userId,
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
  Future<List<CopyMixPlaylist>> findByUserId(Uuid userId) {
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
  Future<List<CopyMixPlaylist>> listAll() {
    return useConnection((db) async {
      final rows = await db.mappedResultsQuery(
        '''
        SELECT * FROM $tableName
        ORDER BY $columnSourceId;
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
  Future<void> insert(CopyMixPlaylist playlist) async {
    await useConnection((db) async {
      await db.execute(
        '''
        INSERT INTO $tableName(
          $columnSourceId,
          $columnTargetId,
          $columnUserId,
          $columnLastMix
        ) VALUES (
          @sourceId,
          @targetId,
          @userId,
          @lastMix
        ) ON CONFLICT DO NOTHING;
        ''',
        substitutionValues: {
          'sourceId': playlist.sourceId,
          'targetId': playlist.targetId,
          'userId': playlist.userId.toString(),
          'lastMix': playlist.lastMix,
        },
      );
    });
  }

  @override
  Future<void> update({
    required String targetPlaylistId,
    required DateTime lastMix,
  }) async {
    await useConnection((db) async {
      await db.execute(
        '''
        UPDATE $tableName
        SET $columnLastMix = @lastMix
        WHERE $columnTargetId = @id;
        ''',
        substitutionValues: {
          'id': targetPlaylistId,
          'lastMix': lastMix,
        },
      );
    });
  }

  @override
  Future<void> delete({
    required Uuid userId,
    required String targetPlaylistId,
  }) async {
    await useConnection((db) async {
      await db.execute(
        '''
        DELETE FROM $tableName
        WHERE $columnTargetId = @id AND $columnUserId = @userId;
        ''',
        substitutionValues: {
          'id': targetPlaylistId,
          'userId': userId.toString(),
        },
      );
    });
  }
}
