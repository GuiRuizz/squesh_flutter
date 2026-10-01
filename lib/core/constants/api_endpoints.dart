import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract class ApiEndpoints {
  // Lê a URL base do arquivo .env (com fallback para localhost)
  static String get baseUrl =>
      dotenv.env['API_URL'] ?? 'http://localhost:8080/api/v1';

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';

  // Posts
  static const String posts = '/posts';
  static const String postsFeed = '/posts/feed';
  static String postComments(String id) => '/posts/$id/comments';
  static String postLikes(String id) => '/posts/$id/likes';
  static String likePost(String id) => '/posts/$id/like';
  static String updatePost(String id) => '/posts/$id';
  static String deletePost(String id) => '/posts/$id';

  // Follow
  static String followUser(String id) => '/users/$id/follow';
  static String userFollowers(String id) => '/users/$id/followers';
  static String userFollowing(String id) => '/users/$id/following';

  // Uploads (URL assinada — o arquivo NUNCA passa pelo servidor)
  static const String uploadsPresign = '/uploads/presign';

  // Trails
  static const String trails = '/trails';
  static String trailById(String id) => '/trails/$id';
  static String generateTrailItems(String id) => '/trails/$id/generate';
  static String completeTrailItem(String itemId) =>
      '/trails/items/$itemId/complete';

  // Marca/desmarca UMA etapa interna do item (refeição do dia ou exercício
  // da sessão). O item sem etapas usa completeTrailItem acima.
  static String toggleTrailStep(String itemId) => '/trails/items/$itemId/steps';
  static String addTrailItem(String trailId) => '/trails/$trailId/items';

  // Minhas trilhas
  static String activeTrail([String? type]) =>
      (type == null || type.isEmpty)
          ? '/trails/me/active'
          : '/trails/me/active?type=$type';
  static const String completedTrails = '/trails/me/completed';
  static const String generateCompleteTrail = '/trails/generate';

  // Todas as trilhas com progresso individual (alimenta os cards da Home)
  static String myTrails([String? type]) =>
      (type == null || type.isEmpty) ? '/trails/me' : '/trails/me?type=$type';

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
  static const String userPreferences = '/users/me/preferences';
  static const String userMyPosts = '/users/me/posts';

  // Assinatura, formas de pagamento e enderecos (tela de Configuracoes)
  static const String plans = '/plans';
  static const String userSubscription = '/users/me/subscription';
  static const String userPaymentMethods = '/users/me/payment-methods';
  static String userPaymentMethod(String id) => '/users/me/payment-methods/$id';
  static const String userAddresses = '/users/me/addresses';
  static String userAddress(String id) => '/users/me/addresses/$id';
}