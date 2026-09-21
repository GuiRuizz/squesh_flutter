import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';

final notificationApiServiceProvider = Provider<NotificationApiService>((ref) {
  return NotificationApiService(ref.watch(dioProvider));
});

class NotificationApiService {
  final Dio _dio;

  NotificationApiService(this._dio);

  // GET /api/v1/notifications
  Future<Response> getUserNotifications() async {
    return await _dio.get(ApiEndpoints.notifications);
  }

  // PATCH /api/v1/notifications/:id/read
  Future<Response> markAsRead(String id) async {
    return await _dio.patch(ApiEndpoints.markNotificationRead(id));
  }

  // PATCH /api/v1/notifications/read-all
  Future<Response> markAllAsRead() async {
    return await _dio.patch(ApiEndpoints.markAllNotificationsRead);
  }

  // PATCH /api/v1/notifications/:id/unread
  Future<Response> markAsUnread(String id) async {
    return await _dio.patch(ApiEndpoints.markNotificationUnread(id));
  }
}
