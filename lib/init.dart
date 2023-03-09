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
      options.tracesSampleRate = 1.0;
    });
  }

  try {
    await withT(getIt());
  } catch (e, stack) {
    await Sentry.captureException(e, stackTrace: stack);
  } finally {
    await Sentry.close();
  }
}
