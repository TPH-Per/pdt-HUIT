import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();

  factory FCMService() {
    return _instance;
  }

  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final Dio _dio = Dio();

  late String _deviceToken;

  Future<void> initialize(String studentId, String backendUrl) async {

    // Request notification permissions
    NotificationSettings settings =
        await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      print('FCM: Permission denied');
      return;
    }

    // Get and store FCM token
    _deviceToken = await _firebaseMessaging.getToken() ?? '';
    await _secureStorage.write(key: 'fcm_token', value: _deviceToken);

    // Upload token to backend
    await _uploadTokenToBackend(backendUrl);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    // Initialize local notifications
    await _initializeLocalNotifications();
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInitSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iosInitSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  Future<void> _uploadTokenToBackend(String backendUrl) async {
    try {
      final jwtToken = await _secureStorage.read(key: 'jwt_token');
      if (jwtToken == null) return;

      await _dio.post(
        '$backendUrl/api/student/device-token',
        data: {'deviceToken': _deviceToken, 'deviceType': 'ANDROID'},
        options: Options(
          headers: {'Authorization': 'Bearer $jwtToken'},
        ),
      );
    } catch (e) {
      print('FCM: Error uploading token to backend: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    print('FCM: Foreground message: ${message.notification?.title}');
    _showNotification(message);
  }

  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    print('FCM: Background message: ${message.notification?.title}');
    _instance._showNotification(message);
  }

  Future<void> _showNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'pdt_huit_notifications',
      'PDT-HUIT Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      const Uuid().v4().hashCode,
      message.notification?.title,
      message.notification?.body,
      notificationDetails,
      payload: message.data['deepLink'],
    );
  }

  Future<String?> getToken() async {
    return await _secureStorage.read(key: 'fcm_token');
  }

  Future<void> refreshToken(String backendUrl) async {
    final newToken = await _firebaseMessaging.getToken();
    if (newToken != null && newToken != _deviceToken) {
      _deviceToken = newToken;
      await _secureStorage.write(key: 'fcm_token', value: _deviceToken);
      await _uploadTokenToBackend(backendUrl);
    }
  }

  Future<void> logout() async {
    await _firebaseMessaging.deleteToken();
    await _secureStorage.delete(key: 'fcm_token');
  }
}
