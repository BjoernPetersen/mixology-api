import 'dart:math';

import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:mixology_backend/application/domain/copy_mix_playlist.dart';
import 'package:mixology_backend/application/ports/spotify_api.dart';
import 'package:mixology_backend/application/repos/unit_of_work.dart';
import 'package:mutex/mutex.dart';
import 'package:quiver/iterables.dart';
import 'package:sane_uuid/uuid.dart';
import 'package:sentry/sentry.dart';
import 'package:spotify_api/spotify_api.dart';

@injectable
class CopyMixPlaylists {
  final Logger logger;
  final SpotifyApiProvider apiProvider;
  final Mutex _mutex;
  final Map<Uuid, SpotifyWebApi> _clients;
  final UnitOfWorkProvider uowProvider;

  CopyMixPlaylists(
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
    logger.i('Mixing playlists');

    final transaction = Sentry.startTransaction(
      'copy_mix_playlist.mix',
      'task',
    );

    try {
      await _mixPlaylists(transaction);
    } catch (e, stack) {
      transaction.throwable = e;
      transaction.status = SpanStatus.internalError();
      await Sentry.captureException(e, stackTrace: stack);
    } finally {
      await transaction.finish();
      for (final api in _clients.values) {
        api.close();
      }
    }

    logger.i('Done.');
  }

  Future<void> _mixPlaylists(ISentrySpan transaction) async {
    final listAllSpan = transaction.startChild('listAll');
    final List<CopyMixPlaylist> playlists;
    try {
      playlists = await uowProvider.withUnitOfWork((uow) async {
        return await uow.copyMixPlaylistRepo.listAll();
      });
    } catch (e) {
      transaction.throwable = e;
      transaction.status = SpanStatus.internalError();
      rethrow;
    } finally {
      await listAllSpan.finish();
    }

    for (final playlist in playlists) {
      await uowProvider.withUnitOfWork((uow) async {
        final playlistName = playlist.sourceId ?? 'Saved Tracks';
        final span = transaction.startChild(
          'mixPlaylist',
          description: 'Mixing $playlistName for ${playlist.userId}',
        );
        logger.i(
          'Now mixing playlist $playlistName for user ${playlist.userId}',
        );

        try {
          final api = await _getApi(uow, playlist.userId);
          await _mixPlaylist(uow, api, playlist.sourceId, playlist.targetId);
        } on SpotifyApiException catch (e) {
          span.status = SpanStatus.internalError();
          logger.e(
            'Could not mix playlist $playlistName for user ${playlist.userId}',
          );

          if (e is AuthorizationException ||
              e is AuthenticationException ||
              e is RefreshException) {
            logger.i('Continuing due to likely permission/auth problems');
            span.status = SpanStatus.unauthenticated();
          } else {
            rethrow;
          }
        } finally {
          await span.finish();
        }
      });
    }
  }

  Future<void> _mixPlaylist(
    UnitOfWork uow,
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

    await uow.copyMixPlaylistRepo.update(
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
