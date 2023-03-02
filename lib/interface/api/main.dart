import 'dart:convert';
import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:mixology_backend/application/app.dart';
import 'package:mixology_backend/interface/api/account.dart';
import 'package:mixology_backend/interface/api/auth.dart';
import 'package:mixology_backend/interface/api/copy_mix_playlist.dart';
import 'package:mixology_backend/interface/api/cors.dart';
import 'package:mixology_backend/interface/api/exceptions.dart';
import 'package:mixology_backend/interface/api/mix_playlist.dart';
import 'package:mixology_backend/interface/api/spotify.dart';
import 'package:shelf_plus/shelf_plus.dart';

@injectable
class MixologyApi {
  final Application app;
  final AuthMiddleware authMiddleware;
  final RouterPlus _router;

  MixologyApi(
    this.app,
    this.authMiddleware,
  ) : _router = Router().plus {
    _router.use(ExceptionHandlingMiddleware());
    _router.get('/health/live', health);

    _registerAuth();

    _registerAccount(authMiddleware);
    _registerSpotify(authMiddleware);

    _registerMixPlaylist(authMiddleware);
    _registerCopyMixPlaylist(authMiddleware);
  }

  void _registerAuth() {
    final api = AuthApi(app);
    _router.get('/auth/login', api.login);
    _router.get('/auth/callback', api.callback);
    _router.get('/auth/refresh', api.refresh);
  }

  void _registerAccount(Middleware middleware) {
    final api = AccountApi(app);
    _router.delete('/account', api.deleteAccount, use: middleware);
    _router.get('/account', api.getAccount, use: middleware);
  }

  void _registerSpotify(Middleware middleware) {
    final api = SpotifyApi(app);
    _router.get('/spotify/accessToken', api.getAccessToken, use: middleware);
  }

  void _registerMixPlaylist(Middleware middleware) {
    final api = MixPlaylistApi(app);
    _router.put('/mix/<playlistId>', api.addPlaylist, use: middleware);
    _router.delete('/mix/<playlistId>', api.deletePlaylist, use: middleware);
    _router.get('/mix', api.listPlaylists, use: middleware);
  }

  void _registerCopyMixPlaylist(Middleware middleware) {
    final api = CopyMixPlaylistApi(app);
    _router.put(
      '/copyMix',
      api.addPlaylist,
      use: middleware,
    );
    _router.delete(
      '/copyMix/<playlistId>',
      api.deletePlaylist,
      use: middleware,
    );
    _router.get(
      '/copyMix',
      api.listPlaylists,
      use: middleware,
    );
  }

  Response health(Request request) {
    return Response.ok(jsonEncode({'ok': true}));
  }

  Future<void> serve() async {
    await shelfRun(
      () => corsMiddleware().addHandler(_router),
      defaultBindAddress: InternetAddress.anyIPv4,
    );
  }
}
