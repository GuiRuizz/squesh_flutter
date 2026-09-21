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

  // POST /api/v1/trails/:id/generate
  Future<Response> generateInfiniteItems(String id) async {
    return await _dio.post(ApiEndpoints.generateTrailItems(id));
  }

  // POST /api/v1/trails/items/:itemId/complete
  Future<Response> completeTrailItem(String itemId) async {
    return await _dio.post(ApiEndpoints.completeTrailItem(itemId));
  }

  // PATCH /api/v1/trails/items/:itemId/meals/:mealIndex
  Future<Response> toggleMealCheck(String itemId, int mealIndex) async {
    return await _dio.patch(ApiEndpoints.toggleMealCheck(itemId, mealIndex));
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
