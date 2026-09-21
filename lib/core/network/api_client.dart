import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_endpoints.dart';
import '../storage/token_storage.dart';
import 'api_interceptor.dart'; // Onde está o LoggingInterceptor
import 'auth_interceptor.dart';

final dioProvider = Provider<Dio>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.addAll([
    // 1. Gerencia autenticação e refresh token
    AuthInterceptor(tokenStorage),

    // 2. Registra os logs das requisições e respostas
    LoggingInterceptor(),
  ]);

  return dio;
});
