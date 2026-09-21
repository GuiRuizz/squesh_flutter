import 'package:dio/dio.dart';
import '../utils/app_logger.dart';

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    AppLogger.info('🚀 [REQ] [${options.method}] -> ${options.uri}');
    if (options.data != null) {
      AppLogger.debug('📦 Body: ${options.data}');
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    AppLogger.info(
      '✅ [RES] [${response.statusCode}] <- ${response.requestOptions.uri}',
    );
    AppLogger.debug('📄 Response: ${response.data}');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final statusCode = err.response?.statusCode ?? 'NO_CODE';
    final url = err.requestOptions.uri;

    AppLogger.error(
      '❌ [ERR] [$statusCode] -> $url\n'
      'Mensagem: ${err.message}\n'
      'Resposta: ${err.response?.data}',
      err,
      err.stackTrace,
    );

    super.onError(err, handler);
  }
}
