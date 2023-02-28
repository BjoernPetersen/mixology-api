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
      var client = _clients[userId];
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
        logger.i('Now mixing playlist ${playlist.id}');

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
    // Perform a modified Fisher-Yates shuffle.
    // Instead of swapping elements, we just move the item from the lower index
    // to the higher index (which starts "after" the end of the list).
    //
    // If we were working on an array, this would be awful, because the items in
    // the list after the lower index would have to shift one index to the left,
    // but we can think of the playlist as a linked list, were this operation is
    // cheap. In return for doing this, we only have to perform one API call per
    // item, instead of two for a swap.
    //
    // This should still result in a random permutation, since every
    // item that has not been moved yet gets the same random chance to be
    // assigned for each i.
    var snapshotId = playlist.snapshotId;
    for (var i = playlistSize; i >= 1; i -= 1) {
      // 0 <= j < i
      final j = random.nextInt(i);
      if (j == i + 1) {
        // Inserting item 2 before item 3 is a no-op.
        continue;
      }
      snapshotId = await api.playlists.reorderPlaylistItems(
        rangeStart: j,
        insertBefore: i,
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
