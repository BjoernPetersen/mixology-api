import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:mixology_backend/init.config.dart';

@InjectableInit(
  throwOnMissingDependencies: true,
)
T initialize<T extends Object>() =>
    GetIt.asNewInstance().init(environment: Environment.prod).get<T>();
