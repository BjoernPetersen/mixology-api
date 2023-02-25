import 'package:injectable/injectable.dart';
import 'package:mixology_backend/application/use_cases/account/delete.dart';
import 'package:mixology_backend/application/use_cases/account/get.dart';
import 'package:mixology_backend/application/use_cases/auth_finish.dart';
import 'package:mixology_backend/application/use_cases/auth_refresh.dart';
import 'package:mixology_backend/application/use_cases/auth_start.dart';

@injectable
class Application {
  final AuthStart startAuth;
  final AuthFinish finishAuth;
  final AuthRefresh refreshAuth;

  final DeleteAccount deleteAccount;
  final GetAccount getAccount;

  Application(
    this.finishAuth,
    this.refreshAuth,
    this.startAuth,
    this.deleteAccount,
    this.getAccount,
  );
}
