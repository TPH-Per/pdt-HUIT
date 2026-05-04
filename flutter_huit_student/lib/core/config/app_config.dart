class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8081/api',
  );

  static const String wsUrl = String.fromEnvironment(
    'WS_URL',
    defaultValue: 'http://127.0.0.1:8081',
  );

  static String get studentApiUrl => '$apiBaseUrl/student';
  static String get publicApiUrl => '$apiBaseUrl/public';
  static String get wsEndpoint => '$wsUrl/ws';
}
