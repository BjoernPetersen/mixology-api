import 'package:mixology_backend/application/domain/copy_mix_playlist.dart';
import 'package:mixology_backend/application/repos/copy_mix_playlist.dart';
import 'package:postgres/postgres.dart';
import 'package:sane_uuid/uuid.dart';

const tableName = 'copy_mix_playlists';
const columnSourceId = 'source_id';
const columnTargetId = 'target_id';
const columnUserId = 'user_id';
const columnLastMix = 'last_mix';

class PostgresCopyMixPlaylistRepository implements CopyMixPlaylistRepository {
  final Session session;

  PostgresCopyMixPlaylistRepository(this.session);

  CopyMixPlaylist _mixPlaylistFromRow(ResultRow row) {
    final columns = row.toColumnMap();
    final sourceId = columns[columnSourceId];
    final targetId = columns[columnTargetId];
    final userId = Uuid.fromString(columns[columnUserId]);
    final lastMixTimestamp = columns[columnLastMix];

    return CopyMixPlaylist(
      sourceId: sourceId,
      targetId: targetId,
      userId: userId,
      lastMix: lastMixTimestamp,
    );
  }

  @override
  Future<List<CopyMixPlaylist>> findByUserId(Uuid userId) async {
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
  }

  @override
  Future<List<CopyMixPlaylist>> listAll() async {
    final rows = await session.execute(
      '''
        SELECT * FROM $tableName
        ORDER BY $columnSourceId;
        ''',
    );

    if (rows.isEmpty) {
      return [];
    }

    return rows.map(_mixPlaylistFromRow).toList(growable: false);
  }

  @override
  Future<void> insert(CopyMixPlaylist playlist) async {
    await session.execute(
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
      parameters: {
        'sourceId': playlist.sourceId,
        'targetId': playlist.targetId,
        'userId': playlist.userId.toString(),
        'lastMix': playlist.lastMix,
      },
    );
  }

  @override
  Future<void> update({
    required String targetPlaylistId,
    required DateTime lastMix,
  }) async {
    await session.execute(
      '''
        UPDATE $tableName
        SET $columnLastMix = @lastMix
        WHERE $columnTargetId = @id;
        ''',
      parameters: {
        'id': targetPlaylistId,
        'lastMix': lastMix,
      },
    );
  }

  @override
  Future<void> delete({
    required Uuid userId,
    required String targetPlaylistId,
  }) async {
    await session.execute(
      '''
        DELETE FROM $tableName
        WHERE $columnTargetId = @id AND $columnUserId = @userId;
        ''',
      parameters: {
        'id': targetPlaylistId,
        'userId': userId.toString(),
      },
    );
  }
}
