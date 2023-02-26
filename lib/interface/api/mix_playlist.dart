import 'dart:io';

import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:mixology_backend/application/app.dart';
import 'package:mixology_backend/interface/api/util.dart';
import 'package:shelf/shelf.dart';

part 'mix_playlist.g.dart';

class MixPlaylistApi {
  final Application app;

  MixPlaylistApi(this.app);

  Future<MixPlaylistsResponse> listPlaylists(Request request) async {
    final playlists = await app.listMixPlaylistsForUser(
      request.principal.userId,
    );
    return MixPlaylistsResponse([
      for (final playlist in playlists)
        MixPlaylistResponse(
          id: playlist.id,
          name: playlist.name,
          lastMix: playlist.lastMix,
        )
    ]);
  }

  Future<Response> addPlaylist(Request request, String playlistId) async {
    await app.addMixPlaylist(
      userId: request.principal.userId,
      playlistId: playlistId,
    );
    return Response(HttpStatus.noContent);
  }

  Future<Response> deletePlaylist(Request request, String playlistId) async {
    await app.deleteMixPlaylist(
      userId: request.principal.userId,
      playlistId: playlistId,
    );
    return Response(HttpStatus.noContent);
  }
}

@immutable
@JsonSerializable(createFactory: false)
class MixPlaylistsResponse {
  final List<MixPlaylistResponse> playlists;

  MixPlaylistsResponse(this.playlists);
}

@immutable
@JsonSerializable(createFactory: false)
class MixPlaylistResponse {
  final String id;
  final String name;
  final DateTime? lastMix;

  MixPlaylistResponse({
    required this.id,
    required this.name,
    required this.lastMix,
  });
}
