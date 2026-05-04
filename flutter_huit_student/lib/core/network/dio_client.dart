import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../storage/secure_storage.dart';

class DioClient {
  static DioClient? _instance;
  late Dio _dio;

  DioClient._() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    _setupInterceptors();
  }

  static DioClient get instance {
    _instance ??= DioClient._();
    return _instance!;
  }

  void _setupInterceptors() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await SecureStorage.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          try {
            final refreshToken = await SecureStorage.getRefreshToken();
            if (refreshToken != null) {
              final newToken = await _refreshToken(refreshToken);
              if (newToken != null) {
                await SecureStorage.saveToken(newToken);
                error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
                final opts = Options(method: error.requestOptions.method);
                final clonedReq = await _dio.request(
                  error.requestOptions.path,
                  options: opts,
                  data: error.requestOptions.data,
                  queryParameters: error.requestOptions.queryParameters,
                );
                return handler.resolve(clonedReq);
              }
            }
          } catch (e) {
            await SecureStorage.clearAll();
          }
        }
        return handler.next(error);
      },
    ));
  }

  Future<String?> _refreshToken(String refreshToken) async {
    try {
      final response = await _dio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      if (response.statusCode == 200) {
        return response.data['token'];
      }
    } catch (e) {
      print('Refresh token failed: $e');
    }
    return null;
  }

  Dio get dio => _dio;
}
