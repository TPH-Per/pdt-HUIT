class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8081/api',
  );

  static const String wsUrl = String.fromEnvironment(
    'WS_URL',
    defaultValue: 'http://127.0.0.1:8081',
  );

  // Timeouts (milliseconds)
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;
  static const int sendTimeout = 30000;

  // Secure storage keys
  static const String storageKeyJwtToken = 'jwt_token';
  static const String storageKeyRefreshToken = 'refresh_token';
  static const String storageKeyStudentId = 'student_id';

  static String get studentApiUrl => '$apiBaseUrl/student';
  static String get publicApiUrl => '$apiBaseUrl/public';
  static String get wsEndpoint => '$wsUrl/ws';
}
