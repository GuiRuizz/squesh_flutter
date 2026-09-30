import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';

final trailsApiServiceProvider = Provider<TrailsApiService>((ref) {
  return TrailsApiService(ref.watch(dioProvider));
});

class TrailsApiService {
  final Dio _dio;

  TrailsApiService(this._dio);

  // GET /api/v1/trails
  Future<Response> listTrails() async {
    return await _dio.get(ApiEndpoints.trails);
  }

  // GET /api/v1/trails/:id
  Future<Response> getTrailById(String id) async {
    return await _dio.get(ApiEndpoints.trailById(id));
  }

  // GET /api/v1/trails/me/active (opcional ?type=workout|nutrition)
  Future<Response> getMyActiveTrail([String? type]) async {
    return await _dio.get(ApiEndpoints.activeTrail(type));
  }

  // GET /api/v1/trails/me (todas as trilhas com progresso; opcional ?type=)
  Future<Response> getMyTrails([String? type]) async {
    return await _dio.get(ApiEndpoints.myTrails(type));
  }

  // GET /api/v1/trails/me/completed
  Future<Response> getMyCompletedTrails() async {
    return await _dio.get(ApiEndpoints.completedTrails);
  }

  // POST /api/v1/trails/generate
  Future<Response> generateCompleteTrail(Map<String, dynamic> data) async {
    return await _dio.post(ApiEndpoints.generateCompleteTrail, data: data);
  }

  // POST /api/v1/trails/:id/generate
  Future<Response> generateInfiniteItems(String id) async {
    return await _dio.post(ApiEndpoints.generateTrailItems(id));
  }

  // POST /api/v1/trails/items/:itemId/complete
  Future<Response> completeTrailItem(String itemId) async {
    return await _dio.post(ApiEndpoints.completeTrailItem(itemId));
  }

  // PATCH /api/v1/trails/items/:itemId/meals
  //
  // [mealIndex] é a refeição do dia (obrigatório quando o dia tem refeições).
  // [checked] é o estado desejado; sem ele o backend alterna.
  Future<Response> toggleMealCheck(
    String itemId, {
    int? mealIndex,
    bool? checked,
  }) async {
    return await _dio.patch(
      ApiEndpoints.toggleMealCheck(itemId),
      data: {'meal_index': ?mealIndex, 'checked': ?checked},
    );
  }

  // ADMIN: POST /api/v1/trails
  Future<Response> createTrail(Map<String, dynamic> data) async {
    return await _dio.post(ApiEndpoints.trails, data: data);
  }

  // ADMIN: POST /api/v1/trails/:id/items
  Future<Response> addItemToTrail(String id, Map<String, dynamic> data) async {
    return await _dio.post(ApiEndpoints.addTrailItem(id), data: data);
  }
}