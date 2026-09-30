import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';
import '../storage/token_storage.dart';

class AuthInterceptor extends QueuedInterceptor {
  final TokenStorage _tokenStorage;

  AuthInterceptor(this._tokenStorage);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Injeta o accessToken em todas as requisições
    final token = await _tokenStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Se não for erro 401 Unauthorized, repassa o erro
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken == null) {
      return handler.next(err);
    }

    try {
      // Instância limpa do Dio exclusiva para fazer a renovação do token
      final tokenDio = Dio(
        BaseOptions(
          baseUrl: ApiEndpoints.baseUrl,
          connectTimeout: const Duration(seconds: 10),
        ),
      );

      final response = await tokenDio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      final newAccessToken = response.data['token'];
      final newRefreshToken = response.data['refresh_token'];

      // Salva os novos tokens no armazenamento seguro
      await _tokenStorage.saveTokens(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      );

      // Atualiza o cabeçalho da requisição original que havia falhado
      final options = err.requestOptions;
      options.headers['Authorization'] = 'Bearer $newAccessToken';

      // Refaz a requisição usando uma nova instância do Dio
      final retryDio = Dio();
      final clonedResponse = await retryDio.fetch(options);

      return handler.resolve(clonedResponse);
    } catch (e) {
      // Se a renovação falhar (ex: refreshToken expirado), limpa a sessão local
      await _tokenStorage.clearTokens();
      return handler.next(err);
    }
  }
}
