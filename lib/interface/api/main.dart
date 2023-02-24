import 'dart:convert';
import 'dart:io';

import 'package:mixology_backend/application/app.dart';
import 'package:mixology_backend/interface/api/auth.dart';
import 'package:shelf_plus/shelf_plus.dart';

class MixologyApi {
  final Application app;
  final RouterPlus _router;

  MixologyApi(this.app) : _router = Router().plus {
    _router.get('/health/live', health);
    _registerAuth();
  }

  void _registerAuth() {
    final api = AuthApi(app);
    _router.get('/auth/login', api.login);
    _router.get('/auth/callback', api.callback);
    _router.get('/auth/refresh', api.refresh);
  }

  Response health(Request request) {
    return Response.ok(jsonEncode({'ok': true}));
  }

  Future<void> serve() async {
    await shelfRun(
      () => _router,
      defaultBindAddress: InternetAddress.anyIPv4,
    );
  }
}
