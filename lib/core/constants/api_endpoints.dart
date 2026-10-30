class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl = 'https://dummyjson.com';
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String products = '/products';

  /// Default token expiry in minutes used for both login and refresh requests
  static const int tokenExpiryMins = 60;

  static String productDetail(int id) => '/products/$id';
}
