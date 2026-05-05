import 'package:hive_flutter/hive_flutter.dart';

class HiveCache {
  static const String _requestsBoxName = 'requests_cache';
  static const String _appointmentsBoxName = 'appointments_cache';
  static const String _usersBoxName = 'users_cache';

  static final HiveCache _instance = HiveCache._internal();

  HiveCache._internal();

  factory HiveCache() {
    return _instance;
  }

  Future<void> initialize() async {
    try {
      await Hive.initFlutter();
      await Hive.openBox(_requestsBoxName);
      await Hive.openBox(_appointmentsBoxName);
      await Hive.openBox(_usersBoxName);
    } catch (e) {
      print('HiveCache initialization error: $e');
    }
  }

  Future<void> saveRequests(List<Map<String, dynamic>> requests) async {
    try {
      final box = Hive.box(_requestsBoxName);
      await box.clear();
      await box.put('requests', requests);
    } catch (e) {
      print('Save requests error: $e');
    }
  }

  List<Map<String, dynamic>>? getRequests() {
    try {
      final box = Hive.box(_requestsBoxName);
      final data = box.get('requests');
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
    } catch (e) {
      print('Get requests error: $e');
    }
    return null;
  }

  Future<void> saveAppointments(
      List<Map<String, dynamic>> appointments) async {
    try {
      final box = Hive.box(_appointmentsBoxName);
      await box.clear();
      await box.put('appointments', appointments);
    } catch (e) {
      print('Save appointments error: $e');
    }
  }

  List<Map<String, dynamic>>? getAppointments() {
    try {
      final box = Hive.box(_appointmentsBoxName);
      final data = box.get('appointments');
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
    } catch (e) {
      print('Get appointments error: $e');
    }
    return null;
  }

  Future<void> saveUser(String studentId, Map<String, dynamic> user) async {
    try {
      final box = Hive.box(_usersBoxName);
      await box.put(studentId, user);
    } catch (e) {
      print('Save user error: $e');
    }
  }

  Map<String, dynamic>? getUser(String studentId) {
    try {
      final box = Hive.box(_usersBoxName);
      final data = box.get(studentId);
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
    } catch (e) {
      print('Get user error: $e');
    }
    return null;
  }

  Future<void> clearAll() async {
    try {
      await Hive.box(_requestsBoxName).clear();
      await Hive.box(_appointmentsBoxName).clear();
      await Hive.box(_usersBoxName).clear();
    } catch (e) {
      print('Clear cache error: $e');
    }
  }
}
