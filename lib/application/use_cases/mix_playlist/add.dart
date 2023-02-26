import 'package:injectable/injectable.dart';
import 'package:mixology_backend/application/domain/mix_playlist.dart';
import 'package:mixology_backend/application/ports/spotify_api.dart';
import 'package:mixology_backend/application/repos/mix_playlist.dart';
import 'package:mixology_backend/application/repos/user.dart';
import 'package:sane_uuid/uuid.dart';

@injectable
class AddMixPlaylist {
  final UserRepository userRepository;
  final SpotifyApiProvider apiProvider;
  final MixPlaylistRepository repo;

  AddMixPlaylist(
    this.userRepository,
    this.apiProvider,
    this.repo,
  );

  Future<void> call({
    required Uuid userId,
    required String playlistId,
  }) async {
    final user = await userRepository.findById(userId);
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

    await repo.insert(MixPlaylist(
      id: playlist.id,
      userId: userId,
      name: playlist.name,
      lastMix: null,
    ));
  }
}
