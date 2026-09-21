import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';

class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 1,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.dateAndTime,
    ),
  );

  // Getter para verificar se está em ambiente de desenvolvimento
  static bool get _isDev => dotenv.env['ENV'] == 'DEV';

  static void debug(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    if (_isDev) {
      _logger.d(message, error: error, stackTrace: stackTrace);
    }
  }

  static void info(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    if (_isDev) {
      _logger.i(message, error: error, stackTrace: stackTrace);
    }
  }

  static void warning(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    if (_isDev) {
      _logger.w(message, error: error, stackTrace: stackTrace);
    }
  }

  static void error(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    if (_isDev) {
      _logger.e(message, error: error, stackTrace: stackTrace);
    }
  }
}