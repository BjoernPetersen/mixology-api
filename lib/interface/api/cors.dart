import 'dart:io';

import 'package:shelf/shelf.dart';

const _corsHeaders = {
  'Access-Control-Allow-Credentials': 'true',
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, Authorization',
  'Access-Control-Allow-Methods': 'GET,PUT,POST,DELETE,PATCH,OPTIONS',
};

Middleware corsMiddleware() {
  Response? handleOptions(Request request) {
    if (request.method == 'OPTIONS') {
      return Response(HttpStatus.ok, headers: _corsHeaders);
    } else {
      return null;
    }
  }

  Response addCorsHeader(Response response) {
    return response.change(headers: _corsHeaders);
  }

  return createMiddleware(
    requestHandler: handleOptions,
    responseHandler: addCorsHeader,
  );
}
