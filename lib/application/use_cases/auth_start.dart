import 'package:injectable/injectable.dart' as injectable;
import 'package:spotify_api/spotify_api.dart';

@injectable.injectable
class AuthStart {
  final UserAuthorizationFlow authFlow;

  AuthStart(this.authFlow);

  Future<Uri> call() async {
    // TODO: maybe we could find something as a user-context
    return await authFlow.generateAuthorizationUrl(
      scopes: [Scope.userTopRead],
      userContext: null,
    );
  }
}
