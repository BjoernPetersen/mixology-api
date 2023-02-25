import 'dart:io';

import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:mixology_backend/application/app.dart';
import 'package:mixology_backend/interface/api/util.dart';
import 'package:shelf/shelf.dart';

part 'account.g.dart';

class AccountApi {
  final Application app;

  AccountApi(this.app);

  Future<Response> deleteAccount(Request request) async {
    final userId = request.principal.userId;
    await app.deleteAccount(userId);
    return Response(HttpStatus.noContent);
  }

  Future<AccountInfoResponse> getAccount(Request request) async {
    final userId = request.principal.userId;
    final info = await app.getAccount(userId);

    if (info == null) {
      throw NotFoundException(id: userId.toString(), kind: 'user');
    }

    return AccountInfoResponse(
      id: info.id.toString(),
      name: info.name,
      spotifyId: info.spotifyId,
    );
  }
}

@immutable
@JsonSerializable(createFactory: false)
class AccountInfoResponse {
  final String id;
  final String name;
  final String spotifyId;

  AccountInfoResponse({
    required this.id,
    required this.name,
    required this.spotifyId,
  });

  Json toJson() => _$AccountInfoResponseToJson(this);
}
