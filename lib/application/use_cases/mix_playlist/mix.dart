import 'dart:math';

import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:mixology_backend/application/domain/mix_playlist.dart';
import 'package:mixology_backend/application/ports/spotify_api.dart';
import 'package:mixology_backend/application/repos/unit_of_work.dart';
import 'package:mixology_backend/interface/api/util.dart';
import 'package:mutex/mutex.dart';
import 'package:sentry/sentry.dart';
import 'package:spotify_api/spotify_api.dart';

@injectable
class MixPlaylists {
  final Logger logger;
  final SpotifyApiProvider apiProvider;
  final UnitOfWorkProvider uowProvider;
  final Mutex _mutex;
  final Map<Uuid, SpotifyWebApi> _clients;

  MixPlaylists(
    this.apiProvider,
    this.uowProvider,
    this.logger,
  )   : _mutex = Mutex(),
        _clients = {};

  Future<SpotifyWebApi> _getApi(UnitOfWork uow, Uuid userId) async {
    return _mutex.protect(() async {
      var client = _clients[userId];
      if (client == null) {
        final user = await uow.userRepo.findById(userId);
        if (user == null) {
          throw ArgumentError.value(userId, 'userId', 'unknown user');
        }

        client = apiProvider.provideForRefreshToken(user.spotifyRefreshToken);
      }

      return client;
    });
  }

  Future<void> call() async {
    await uowProvider.withUnitOfWork((uow) async {
      logger.i('Mixing playlists');
      final playlists = await uow.mixPlaylistRepo.listAll();

      try {
        MixPlaylist? lastPlaylist;
        for (final playlist in playlists) {
          logger.i('Now mixing playlist ${playlist.id}');

          if (playlist.id == lastPlaylist?.id) {
            logger.i('Skipping duplicate playlist ${playlist.id}');
            continue;
          }

          uowProvider.withUnitOfWork((uow) async {
            try {
              final api = await _getApi(uow, playlist.userId);
              await _mixPlaylist(uow, api, playlist.id);
              lastPlaylist = playlist;
            } on SpotifyApiException catch (e, stack) {
              logger.e(
                'Could not mix playlist ${playlist.id} for user ${playlist.userId}',
                error: e,
                stackTrace: stack,
              );
              await Sentry.captureException(e, stackTrace: stack);

              if (e is AuthorizationException || e is AuthenticationException) {
                logger.i('Continuing due to likely permission/auth problems');
              } else {
                rethrow;
              }
            }
          });
        }
      } finally {
        for (final api in _clients.values) {
          api.close();
        }
      }
      logger.i('Done.');
    });
  }

  Future<void> _mixPlaylist(
    UnitOfWork uow,
    SpotifyWebApi api,
    String id,
  ) async {
    final playlist = await api.playlists.getPlaylist(id);

    if (playlist == null) {
      throw ArgumentError.value(id, 'playlistId', 'playlist does not exist');
    }

    final random = Random();
    final playlistSize = playlist.tracks.total;
    logger.i('Playlist contains $playlistSize tracks');

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

    await uow.mixPlaylistRepo.update(
      id: id,
      name: playlist.name,
      lastMix: DateTime.now().toUtc(),
    );
  }
}
