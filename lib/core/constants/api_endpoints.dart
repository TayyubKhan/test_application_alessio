class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl = 'https://dummyjson.com';
  static const String login = '/auth/login';
  static const String products = '/products';

  static String productDetail(int id) => '/products/$id';
}
