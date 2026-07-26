/// Paths of the AgriChain backend, relative to [AppConfig.apiBaseUrl].
class ApiEndpoints {
  const ApiEndpoints._();

  // Authentication
  static const String registerFarmer = '/auth/register/farmer';
  static const String login = '/auth/login';
  static const String users = '/auth/users';

  // Products
  static const String products = '/products';
}
