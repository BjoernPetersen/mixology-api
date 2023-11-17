import 'package:injectable/injectable.dart';
import 'package:mixology_backend/application/domain/mix_playlist.dart';
import 'package:mixology_backend/application/repos/mix_playlist.dart';
import 'package:mixology_backend/config.dart';
import 'package:mixology_backend/infrastructure/repos/postgres_mixin.dart';
import 'package:postgres/postgres.dart';
import 'package:sane_uuid/uuid.dart';

const tableName = 'mix_playlists';
const columnId = 'id';
const columnUserId = 'user_id';
const columnName = 'name';
const columnLastMix = 'last_mix';

@Injectable(as: MixPlaylistRepository)
class PostgresMixPlaylistRepository
    with PostgresMixin
    implements MixPlaylistRepository {
  @override
  final DatabaseConfig config;

  PostgresMixPlaylistRepository(Config config) : config = config.database;

  MixPlaylist _mixPlaylistFromRow(ResultRow row) {
    final columns = row.toColumnMap();
    final id = columns[columnId];
    final userId = Uuid.fromString(columns[columnUserId]);
    final name = columns[columnName];
    final lastMixTimestamp = columns[columnLastMix];

    return MixPlaylist(
      id: id,
      userId: userId,
      name: name,
      lastMix: lastMixTimestamp,
    );
  }

  @override
  Future<List<MixPlaylist>> findByUserId(Uuid userId) {
    return withSession((session) async {
      final rows = await session.execute(
        '''
        SELECT * FROM $tableName
        WHERE $columnUserId = @userId;
        ''',
        parameters: {
          'userId': userId.toString(),
        },
      );

      if (rows.isEmpty) {
        return [];
      }

      return rows.map(_mixPlaylistFromRow).toList(growable: false);
    });
  }

  @override
  Future<List<MixPlaylist>> listAll() {
    return withSession((session) async {
      final rows = await session.execute(
        '''
        SELECT * FROM $tableName
        ORDER BY $columnId;
        ''',
      );

      if (rows.isEmpty) {
        return [];
      }

      return rows.map(_mixPlaylistFromRow).toList(growable: false);
    });
  }

  @override
  Future<void> insert(MixPlaylist playlist) async {
    await withSession((session) async {
      await session.execute(
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
        parameters: {
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
    await withSession((session) async {
      await session.execute(
        '''
        UPDATE $tableName
        SET 
          $columnName = @name,
          $columnLastMix = @lastMix
        WHERE $columnId = @id;
        ''',
        parameters: {
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
    await withSession((session) async {
      await session.execute(
        '''
        DELETE FROM $tableName
        WHERE $columnId = @id AND $columnUserId = @userId;
        ''',
        parameters: {
          'id': playlistId,
          'userId': userId.toString(),
        },
      );
    });
  }
}
