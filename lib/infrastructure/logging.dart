import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@module
abstract class LoggingModule {
  @singleton
  Logger provideLogger() {
    final logger = Logger(
      filter: ProductionFilter(),
      printer: SimplePrinter(),
      level: Level.info,
    );
    return logger;
  }
}
