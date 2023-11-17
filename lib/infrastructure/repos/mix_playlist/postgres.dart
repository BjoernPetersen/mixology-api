import 'package:mixology_backend/application/domain/mix_playlist.dart';
import 'package:mixology_backend/application/repos/mix_playlist.dart';
import 'package:mixology_backend/infrastructure/repos/postgres_utils.dart';
import 'package:postgres/postgres.dart';
import 'package:sane_uuid/uuid.dart';

const tableName = 'mix_playlists';
const columnId = 'id';
const columnUserId = 'user_id';
const columnName = 'name';
const columnLastMix = 'last_mix';

class PostgresMixPlaylistRepository implements MixPlaylistRepository {
  final Session _session;

  PostgresMixPlaylistRepository(this._session);

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
  Future<List<MixPlaylist>> findByUserId(Uuid userId) async {
    final rows = await _session.executePrepared(
      '''
        SELECT * FROM $tableName
        WHERE $columnUserId = @userId:uuid;
        ''',
      parameters: {
        'userId': userId.toString(),
      },
    );

    if (rows.isEmpty) {
      return [];
    }

    return rows.map(_mixPlaylistFromRow).toList(growable: false);
  }

  @override
  Future<List<MixPlaylist>> listAll() async {
    final rows = await _session.execute(
      '''
        SELECT * FROM $tableName
        ORDER BY $columnId;
        ''',
    );

    if (rows.isEmpty) {
      return [];
    }

    return rows.map(_mixPlaylistFromRow).toList(growable: false);
  }

  @override
  Future<void> insert(MixPlaylist playlist) async {
    await _session.executePrepared(
      '''
        INSERT INTO $tableName(
          $columnId,
          $columnUserId,
          $columnName,
          $columnLastMix
        ) VALUES (
          @id:text,
          @userId:uuid,
          @name:text,
          @lastMix:timestamptz
        ) ON CONFLICT DO NOTHING;
        ''',
      parameters: {
        'id': playlist.id,
        'userId': playlist.userId.toString(),
        'name': playlist.name,
        'lastMix': playlist.lastMix,
      },
    );
  }

  @override
  Future<void> update({
    required String id,
    required String name,
    required DateTime lastMix,
  }) async {
    await _session.executePrepared(
      '''
        UPDATE $tableName
        SET 
          $columnName = @name:text,
          $columnLastMix = @lastMix:timestamptz
        WHERE $columnId = @id:text;
        ''',
      parameters: {
        'id': id,
        'name': name,
        'lastMix': lastMix,
      },
    );
  }

  @override
  Future<void> delete({
    required Uuid userId,
    required String playlistId,
  }) async {
    await _session.executePrepared(
      '''
        DELETE FROM $tableName
        WHERE $columnId = @id:text AND $columnUserId = @userId:uuid;
        ''',
      parameters: {
        'id': playlistId,
        'userId': userId.toString(),
      },
    );
  }
}
