import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:mixology_backend/config.dart';
import 'package:mixology_backend/init.config.dart';
import 'package:sentry/sentry.dart';

@InjectableInit(
  throwOnMissingDependencies: true,
)
Future<void> initialized<T extends Object>(
  FutureOr<void> Function(T) withT,
) async {
  final getIt = GetIt.asNewInstance().init(environment: Environment.prod);

  final sentryDsn = getIt<Config>().sentryDsn;
  if (sentryDsn != null) {
    await Sentry.init((options) {
      options.dsn = sentryDsn;
    });
  }

  final completer = Completer<void>();
  await runZonedGuarded(
    () async {
      await withT(getIt());
      completer.complete();
    },
    (error, stack) async {
      completer.completeError(error, stack);
      await Sentry.captureException(error, stackTrace: stack);
    },
  );

  await completer.future;
}
