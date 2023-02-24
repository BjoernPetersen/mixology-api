import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:mixology_backend/application/app.dart';
import 'package:mixology_backend/init.config.dart';

@InjectableInit(
  throwOnMissingDependencies: true,
)
Application initialize() => GetIt.asNewInstance()
    .init(environment: Environment.prod)
    .get<Application>();
