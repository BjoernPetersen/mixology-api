import 'dart:io';

import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:mixology_backend/application/app.dart';
import 'package:mixology_backend/interface/api/util.dart';
import 'package:shelf/shelf.dart';

part 'copy_mix_playlist.g.dart';

class CopyMixPlaylistApi {
  final Application app;

  CopyMixPlaylistApi(this.app);

  Future<CopyMixPlaylistsResponse> listPlaylists(Request request) async {
    final playlists = await app.listCopyMixPlaylistsForUser(
      request.principal.userId,
    );
    return CopyMixPlaylistsResponse([
      for (final playlist in playlists)
        CopyMixPlaylistResponse(
          sourceId: playlist.sourceId,
          targetId: playlist.targetId,
          lastMix: playlist.lastMix,
        )
    ]);
  }

  Future<Response> addPlaylist(Request request, String? playlistId) async {
    await app.addCopyMixPlaylist(
      userId: request.principal.userId,
      sourceId: playlistId,
    );
    return Response(HttpStatus.noContent);
  }

  Future<Response> deletePlaylist(Request request, String? playlistId) async {
    await app.deleteCopyMixPlaylist(
      userId: request.principal.userId,
      sourceId: playlistId,
    );
    return Response(HttpStatus.noContent);
  }
}

@immutable
@JsonSerializable(createFactory: false)
class CopyMixPlaylistsResponse {
  final List<CopyMixPlaylistResponse> playlists;

  CopyMixPlaylistsResponse(this.playlists);

  Json toJson() => _$CopyMixPlaylistsResponseToJson(this);
}

@immutable
@JsonSerializable(createFactory: false)
class CopyMixPlaylistResponse {
  final String? sourceId;
  final String targetId;
  final DateTime? lastMix;

  CopyMixPlaylistResponse({
    required this.sourceId,
    required this.targetId,
    required this.lastMix,
  });

  Json toJson() => _$CopyMixPlaylistResponseToJson(this);
}
