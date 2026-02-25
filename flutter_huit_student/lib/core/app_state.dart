import 'package:flutter/material.dart';
import '../data/models.dart';
import '../data/mock_data.dart';
import '../data/api_service.dart';

// ──────────────────────────────────────────────
//  App State – manages auth + appointments
// ──────────────────────────────────────────────
class AppState extends ChangeNotifier {
  final ApiService _api = ApiService();

  // ── Auth ──────────────────────────────────────────────────
  String _studentId = '21110001'; // Mã số sinh viên
  String _studentName = 'Nguyễn Văn An';
  String _studentClass = 'DHCNTT17A';
  String _faculty = 'Công nghệ thông tin';
  String _email = 'an.nv21@huit.edu.vn';
  String _phone = '0901234567';
  bool _isLoggedIn = false;

  String get studentId => _studentId;
  String get studentName => _studentName;
  String get studentClass => _studentClass;
  String get faculty => _faculty;
  String get email => _email;
  String get phone => _phone;
  bool get isLoggedIn => _isLoggedIn;

  // ── Navigation State ──────────────────────────────────────
  int _currentTab = 0;
  int get currentTab => _currentTab;

  void setTab(int index) {
    _currentTab = index;
    notifyListeners();
  }

  Future<void> login(String id, String password) async {
    try {
      final profile = await _api.login(id, password);
      _studentId = profile['studentId'] ?? '';
      _studentName = profile['fullName'] ?? '';
      _email = profile['email'] ?? '';
      _phone = profile['phone'] ?? '';
      _isLoggedIn = true;
      notifyListeners();
      _loadAppointments();
      _loadFeedbacks();
    } catch (e) {
      // Simulate login for offline mock testing if backend fails,
      // but in real app, we throw or show error. For now, let's just
      // check if it's the exact mock credential or throw
      if (id == '21110001' && password.length >= 6) {
        _studentId = id;
        _studentName = 'Nguyễn Văn An';
        _isLoggedIn = true;
        notifyListeners();
        _loadAppointments();
        _loadFeedbacks();
      } else {
        rethrow;
      }
    }
  }

  void logout() {
    _isLoggedIn = false;
    notifyListeners();
  }

  Future<void> updateProfile(
      {required String email, required String phone}) async {
    try {
      await _api.updateProfile(mssv: _studentId, email: email, phone: phone);
      _email = email;
      _phone = phone;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // ── Appointments ──────────────────────────────────────────
  List<Appointment> _appointments = List.of(mockAppointments);
  bool _loadingAppointments = false;

  List<Appointment> get appointments => _appointments;
  bool get loadingAppointments => _loadingAppointments;

  Future<void> _loadAppointments() async {
    _loadingAppointments = true;
    notifyListeners();
    try {
      final result = await _api.getMyAppointments(_studentId);
      _appointments = result;
    } catch (_) {
      // Use mock data on error (offline mode)
      _appointments = List.of(mockAppointments);
    } finally {
      _loadingAppointments = false;
      notifyListeners();
    }
  }

  Future<void> refreshAppointments() => _loadAppointments();

  void addAppointment(Appointment apt) {
    _appointments = [apt, ..._appointments];
    notifyListeners();
  }

  // ── Documents ─────────────────────────────────────────────
  List<AppDocument> _documents = List.of(mockDocuments);
  List<AppDocument> get documents => _documents;

  // ── Feedbacks ─────────────────────────────────────────────
  List<FeedbackItem> _feedbacks = List.of(mockFeedbackHistory);
  bool _loadingFeedbacks = false;

  List<FeedbackItem> get feedbacks => _feedbacks;
  bool get loadingFeedbacks => _loadingFeedbacks;

  Future<void> _loadFeedbacks() async {
    _loadingFeedbacks = true;
    notifyListeners();
    try {
      final result = await _api.getFeedbackList(_studentId);
      _feedbacks = result.reversed.toList();
    } catch (e) {
      print('Load feedback error: $e');
      // Offline mode
      _feedbacks = [];
    } finally {
      if (_loadingFeedbacks) {
        _loadingFeedbacks = false;
        notifyListeners();
      }
    }
  }

  Future<void> refreshFeedbacks() => _loadFeedbacks();

  Future<void> submitFeedback(
      String title, String content, int type, int? requestId) async {
    await _api.submitFeedback(
      mssv: _studentId,
      title: title,
      content: content,
      type: type,
      requestId: requestId,
    );
    await _loadFeedbacks();
  }
}
