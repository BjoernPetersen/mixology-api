import 'package:injectable/injectable.dart';
import 'package:mixology_backend/application/use_cases/auth_finish.dart';
import 'package:mixology_backend/application/use_cases/auth_refresh.dart';
import 'package:mixology_backend/application/use_cases/auth_start.dart';

@injectable
class Application {
  final AuthStart startAuth;
  final AuthFinish finishAuth;
  final AuthRefresh refreshAuth;

  Application(
    this.finishAuth,
    this.startAuth,
    this.refreshAuth,
  );
}
