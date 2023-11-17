import 'package:injectable/injectable.dart';
import 'package:mixology_backend/application/domain/mix_playlist.dart';
import 'package:mixology_backend/application/ports/spotify_api.dart';
import 'package:mixology_backend/application/repos/unit_of_work.dart';
import 'package:sane_uuid/uuid.dart';

@injectable
class AddMixPlaylist {
  final UnitOfWorkProvider uowProvider;
  final SpotifyApiProvider apiProvider;

  AddMixPlaylist(
    this.apiProvider,
    this.uowProvider,
  );

  Future<void> call({
    required Uuid userId,
    required String playlistId,
  }) async {
    await uowProvider.withUnitOfWork((uow) async {
      final user = await uow.userRepo.findById(userId);
      if (user == null) {
        throw ArgumentError.value(userId, 'userId', 'user not found');
      }

      final api = apiProvider.provideForRefreshToken(user.spotifyRefreshToken);
      final playlist = await api.playlists.getPlaylist(playlistId);

      if (playlist == null) {
        throw ArgumentError.value(playlistId, 'playlistId', 'does not exist');
      }

      if (!playlist.isCollaborative && playlist.owner.id != user.spotifyId) {
        throw ArgumentError.value(
          playlistId,
          'playlistId',
          'cannot remix this playlist',
        );
      }

      await uow.mixPlaylistRepo.insert(
        MixPlaylist(
          id: playlist.id,
          userId: userId,
          name: playlist.name,
          lastMix: null,
        ),
      );
    });
  }
}
