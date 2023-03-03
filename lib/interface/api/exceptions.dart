import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:mixology_backend/interface/api/util.dart';
import 'package:sentry/sentry.dart';
import 'package:shelf/shelf.dart';

part 'exceptions.g.dart';

class ExceptionHandlingMiddleware {
  Future<Response> _handle(Request request, Handler next) async {
    try {
      return await next(request);
    } on NotFoundException catch (e) {
      return Response.notFound(jsonEncode(e.toJson()));
    } on UnauthorizedException {
      return Response.unauthorized(null);
    } catch(e, stack) {
      Sentry.captureException(e, stackTrace: stack).ignore();
      rethrow;
    }
  }

  Handler call(Handler next) {
    return (request) => _handle(request, next);
  }
}

@immutable
@JsonSerializable(createFactory: false, includeIfNull: false)
class NotFoundException implements Exception {
  final String? kind;
  final String id;

  const NotFoundException({
    this.kind,
    required this.id,
  });

  Json toJson() => _$NotFoundExceptionToJson(this);
}

class UnauthorizedException implements Exception {}
