import 'package:injectable/injectable.dart';
import 'package:mixology_backend/application/domain/copy_mix_playlist.dart';
import 'package:mixology_backend/application/ports/spotify_api.dart';
import 'package:mixology_backend/application/repos/unit_of_work.dart';
import 'package:sane_uuid/uuid.dart';
import 'package:spotify_api/spotify_api.dart';

@injectable
class AddCopyMixPlaylist {
  final UnitOfWorkProvider uowProvider;
  final SpotifyApiProvider apiProvider;

  AddCopyMixPlaylist(
    this.uowProvider,
    this.apiProvider,
  );

  Future<void> call({
    required Uuid userId,
    required String? sourceId,
  }) async {
    await uowProvider.withUnitOfWork((uow) async {
      final user = await uow.userRepo.findById(userId);
      if (user == null) {
        throw ArgumentError.value(userId, 'userId', 'user not found');
      }

      final api = apiProvider.provideForRefreshToken(user.spotifyRefreshToken);

      final String playlistName;
      if (sourceId == null) {
        playlistName = 'Liked Songs';
      } else {
        final playlist = await api.playlists.getPlaylist(sourceId);

        if (playlist == null) {
          throw ArgumentError.value(sourceId, 'playlistId', 'does not exist');
        }

        if (!playlist.isCollaborative && playlist.owner.id != user.spotifyId) {
          throw ArgumentError.value(
            sourceId,
            'playlistId',
            'cannot remix this playlist',
          );
        }

        playlistName = playlist.name;
      }

      final existing = await uow.copyMixPlaylistRepo.findByUserId(userId);
      if (existing.any((p) => p.sourceId == sourceId)) {
        return;
      }

      final targetPlaylist = await api.playlists.createPlaylist(
        userId: user.spotifyId,
        name: '[Mixed] $playlistName',
        visibility: PlaylistVisibility.private,
        description:
            'Regularly shuffled version of your $playlistName playlist.',
      );

      await uow.copyMixPlaylistRepo.insert(
        CopyMixPlaylist(
          sourceId: sourceId,
          targetId: targetPlaylist.id,
          userId: userId,
          lastMix: null,
        ),
      );
    });
  }
}
