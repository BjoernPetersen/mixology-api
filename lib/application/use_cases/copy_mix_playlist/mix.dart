import 'dart:math';

import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:mixology_backend/application/ports/spotify_api.dart';
import 'package:mixology_backend/application/repos/copy_mix_playlist.dart';
import 'package:mixology_backend/application/repos/user.dart';
import 'package:mutex/mutex.dart';
import 'package:quiver/iterables.dart';
import 'package:sane_uuid/uuid.dart';
import 'package:sentry/sentry.dart';
import 'package:spotify_api/spotify_api.dart';

@injectable
class CopyMixPlaylists {
  final Logger logger;
  final CopyMixPlaylistRepository playlistRepo;
  final UserRepository userRepo;
  final SpotifyApiProvider apiProvider;
  final Mutex _mutex;
  final Map<Uuid, SpotifyWebApi> _clients;

  CopyMixPlaylists(
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
      for (final playlist in playlists) {
        final playlistName = playlist.sourceId ?? 'Saved Tracks';
        logger.i(
          'Now mixing playlist $playlistName for user ${playlist.userId}',
        );

        try {
          final api = await _getApi(playlist.userId);
          await _mixPlaylist(api, playlist.sourceId, playlist.targetId);
        } on SpotifyApiException catch (e, stack) {
          logger.e(
            'Could not mix playlist $playlistName for user ${playlist.userId}',
            e,
            stack,
          );
          await Sentry.captureException(e, stackTrace: stack);

          if (e is AuthorizationException ||
              e is AuthenticationException ||
              e is RefreshException) {
            logger.i('Continuing due to likely permission/auth problems');
            continue;
          }

          rethrow;
        }
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
    String? sourceId,
    String targetId,
  ) async {
    final trackIds = await _loadTrackIds(api: api, playlistId: sourceId);

    final random = Random();
    final playlistSize = trackIds.length;
    // Perform a Fisher-Yates shuffle.
    for (var i = playlistSize - 1; i >= 1; i -= 1) {
      final j = random.nextInt(i + 1);
      if (j == i) {
        // Inserting item 2 before item 3 is a no-op.
        continue;
      }
      trackIds.swap(i, j);
    }

    logger.i('Clearing target playlist $targetId');
    await api.playlists.replacePlaylistItems(playlistId: targetId, uris: []);

    logger.i('Re-inserting all ${trackIds.length} tracks in random order');
    for (final chunk in partition(trackIds, 100)) {
      await api.playlists.addItemsToPlaylist(
        playlistId: targetId,
        uris: [for (final id in chunk) 'spotify:track:$id'],
      );
    }

    await playlistRepo.update(
      targetPlaylistId: targetId,
      lastMix: DateTime.now().toUtc(),
    );
  }

  Future<List<String>> _loadTrackIds({
    required SpotifyWebApi api,
    required String? playlistId,
  }) async {
    if (playlistId == null) {
      final paginator = await api.paginator(
        await api.tracks.getSavedTracks(limit: 50),
      );
      return await paginator.all().map((e) => e.track.id).toList();
    } else {
      final paginator = await api.paginator(
        await api.playlists.getPlaylistItems(playlistId, limit: 50),
      );
      return await paginator.all().map((e) => e.track.id).toList();
    }
  }
}

extension _Swapping<T> on List<T> {
  void swap(int a, int b) {
    final itemA = this[a];
    this[a] = this[b];
    this[b] = itemA;
  }
}
