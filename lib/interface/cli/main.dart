import 'package:args/command_runner.dart';
import 'package:mixology_backend/application/app.dart';
import 'package:mixology_backend/init.dart';
import 'package:mixology_backend/interface/api/main.dart';

Future<void> main(List<String> args) async {
  final runner = CommandRunner('server', '')
    ..addCommand(_RunApi())
    ..addCommand(_Mix());

  await runner.run(args);
}

class _RunApi extends Command<void> {
  @override
  String get name => 'run-api';

  @override
  String get description => 'Serves the API';

  @override
  Future<void> run() async {
    final MixologyApi api = initialize();
    await api.serve();
  }
}

class _Mix extends Command<void> {
  @override
  String get name => 'mix';

  @override
  String get description => 'Mixes playlists for enrolled users';

  @override
  Future<void> run() async {
    final app = initialize<Application>();
    await app.mixPlaylists();
  }
}
