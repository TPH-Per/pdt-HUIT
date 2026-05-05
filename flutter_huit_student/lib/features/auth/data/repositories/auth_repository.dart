import '../../../../core/storage/secure_storage.dart';
import '../../../../data/api_service.dart';

class AuthRepository {
  final ApiService apiService;
  final SecureStorage secureStorage;

  AuthRepository({
    required this.apiService,
    required this.secureStorage,
  });

  Future<Map<String, dynamic>> login(String mssv, String password) async {
    try {
      final result = await apiService.login(mssv, password);
      return result;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> saveToken(String token) async {
    await SecureStorage.saveToken(token);
  }

  Future<String?> getToken() async {
    return await SecureStorage.getToken();
  }

  Future<void> saveRefreshToken(String refreshToken) async {
    await SecureStorage.saveRefreshToken(refreshToken);
  }

  Future<String?> getRefreshToken() async {
    return await SecureStorage.getRefreshToken();
  }

  Future<void> saveStudentId(String studentId) async {
    await SecureStorage.saveStudentId(studentId);
  }

  Future<String?> getStudentId() async {
    return await SecureStorage.getStudentId();
  }

  Future<void> logout() async {
    await SecureStorage.clearAll();
  }
}
