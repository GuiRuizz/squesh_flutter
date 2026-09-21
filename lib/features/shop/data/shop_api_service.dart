import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';

final shopApiServiceProvider = Provider<ShopApiService>((ref) {
  return ShopApiService(ref.watch(dioProvider));
});

class ShopApiService {
  final Dio _dio;

  ShopApiService(this._dio);

  // GET /api/v1/shop
  Future<Response> getItems() async {
    return await _dio.get(ApiEndpoints.shop);
  }

  // GET /api/v1/shop/:id
  Future<Response> getItemById(String id) async {
    return await _dio.get(ApiEndpoints.shopItemById(id));
  }

  // POST /api/v1/shop/buy
  Future<Response> buyItem(Map<String, dynamic> data) async {
    return await _dio.post(ApiEndpoints.shopBuy, data: data);
  }

  // GET /api/v1/shop/inventory
  Future<Response> getUserInventory() async {
    return await _dio.get(ApiEndpoints.shopInventory);
  }
}
