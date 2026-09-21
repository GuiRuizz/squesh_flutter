abstract class ApiEndpoints {
  static const String baseUrl =
      'http://sua-api.com/api/v1'; // Ou localhost / IP da máquina

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';

  // Posts
  static const String posts = '/posts';
  static String updatePost(String id) => '/posts/$id';
  static String deletePost(String id) => '/posts/$id';

  // Trails
  static const String trails = '/trails';
  static String trailById(String id) => '/trails/$id';
  static String generateTrailItems(String id) => '/trails/$id/generate';
  static String completeTrailItem(String itemId) =>
      '/trails/items/$itemId/complete';
  static String toggleMealCheck(String itemId, int mealIndex) =>
      '/trails/items/$itemId/meals/$mealIndex';
  static String addTrailItem(String trailId) => '/trails/$trailId/items';

  // Shop
  static const String shop = '/shop';
  static String shopItemById(String id) => '/shop/$id';
  static const String shopBuy = '/shop/buy';
  static const String shopInventory = '/shop/inventory';

  // Notifications
  static const String notifications = '/notifications';
  static String markNotificationRead(String id) => '/notifications/$id/read';
  static const String markAllNotificationsRead = '/notifications/read-all';
  static String markNotificationUnread(String id) =>
      '/notifications/$id/unread';

  // Users & Profile
  static const String userMe = '/users/me';
  static const String userStreak = '/users/me/streak';
  static const String userRanking = '/users/ranking';
  static const String updatePassword = '/users/me/password';
}
