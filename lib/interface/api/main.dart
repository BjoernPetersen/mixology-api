import 'dart:convert';
import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:mixology_backend/application/app.dart';
import 'package:mixology_backend/interface/api/account.dart';
import 'package:mixology_backend/interface/api/auth.dart';
import 'package:mixology_backend/interface/api/exceptions.dart';
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
