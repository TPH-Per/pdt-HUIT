import '../config/app_config.dart';
import '../storage/secure_storage.dart';

class QueueWsService {
  static final QueueWsService _instance = QueueWsService._internal();
  bool _connected = false;

  QueueWsService._internal();

  factory QueueWsService() {
    return _instance;
  }

  bool get isConnected => _connected;

  Future<void> connect() async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null) {
        throw Exception('No authentication token available');
      }

      _connected = true;
      print('WebSocket connecting to ${AppConfig.wsEndpoint}');
      print('Authorization header: Bearer $token');
    } catch (e) {
      print('WebSocket connection error: $e');
      rethrow;
    }
  }

  void subscribe(String destination, void Function(dynamic) onMessage) {
    if (!_connected) {
      throw Exception('WebSocket not connected');
    }
    print('Subscribing to: $destination');
  }

  void send({
    required String destination,
    required String body,
  }) {
    if (!_connected) {
      throw Exception('WebSocket not connected');
    }
    print('Sending to $destination: $body');
  }

  void disconnect() {
    if (_connected) {
      _connected = false;
      print('WebSocket disconnected');
    }
  }
}
