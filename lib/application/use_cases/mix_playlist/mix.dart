import 'dart:math';

import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:mixology_backend/application/domain/mix_playlist.dart';
import 'package:mixology_backend/application/ports/spotify_api.dart';
import 'package:mixology_backend/application/repos/mix_playlist.dart';
import 'package:mixology_backend/application/repos/user.dart';
import 'package:mixology_backend/interface/api/util.dart';
import 'package:mutex/mutex.dart';
import 'package:spotify_api/spotify_api.dart';

@injectable
class MixPlaylists {
  final Logger logger;
  final MixPlaylistRepository playlistRepo;
  final UserRepository userRepo;
  final SpotifyApiProvider apiProvider;
  final Mutex _mutex;
  final Map<Uuid, SpotifyWebApi> _clients;

  MixPlaylists(
    this.apiProvider,
    this.playlistRepo,
    this.userRepo,
    this.logger,
  )   : _mutex = Mutex(),
        _clients = {};

  Future<SpotifyWebApi> _getApi(Uuid userId) async {
    return _mutex.protect(() async {
      SpotifyWebApi? client = _clients[userId];
      if (client == null) {
        final user = await userRepo.findById(userId);
        if (user == null) {
          throw ArgumentError.value(userId, 'userId', 'unknown user');
        }

        client = apiProvider.provideForRefreshToken(user.spotifyRefreshToken);
      }

      return client;
    });
  }

  Future<void> call() async {
    logger.i('Mixing playlists');
    final playlists = await playlistRepo.listAll();

    try {
      MixPlaylist? lastPlaylist;
      for (final playlist in playlists) {
        if (playlist.id == lastPlaylist?.id) {
          logger.d('Skipping duplicate playlist ${playlist.id}');
          continue;
        }

        try {
          final api = await _getApi(playlist.userId);
          await _mixPlaylist(api, playlist.id);
        } catch (e) {
          logger.e('Could not mix playlist ${playlist.id}', e);
          continue;
        }

        logger.i('Mixed playlist ${playlist.id}');
        lastPlaylist = playlist;
      }
    } finally {
      for (final api in _clients.values) {
        api.close();
      }
    }
    logger.i('Done.');
  }

  Future<void> _mixPlaylist(
    SpotifyWebApi api,
    String id,
  ) async {
    final playlist = await api.playlists.getPlaylist(id);

    if (playlist == null) {
      throw ArgumentError.value(id, 'playlistId', 'playlist does not exist');
    }

    final random = Random();
    final playlistSize = playlist.tracks.total;
    String snapshotId = playlist.snapshotId;
    // Perform a Fisher-Yates shuffle
    for (var i = playlistSize - 1; i >= 0; i -= 1) {
      final j = random.nextInt(i + 1);
      if (j == i) {
        continue;
      }
      snapshotId = await api.playlists.swapItems(
        lower: j,
        higher: i,
        playlistId: playlist.id,
        snapshotId: snapshotId,
      );
    }

    await playlistRepo.update(
      id: id,
      name: playlist.name,
      lastMix: DateTime.now().toUtc(),
    );
  }
}

extension on SpotifyPlaylistApi {
  Future<String> swapItems({
    required int higher,
    required int lower,
    required String playlistId,
    required String snapshotId,
  }) async {
    snapshotId = await reorderPlaylistItems(
      playlistId: playlistId,
      snapshotId: snapshotId,
      rangeStart: lower,
      insertBefore: higher,
    );
    return await reorderPlaylistItems(
      playlistId: playlistId,
      snapshotId: snapshotId,
      rangeStart: higher,
      insertBefore: lower,
    );
  }
}
