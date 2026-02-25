import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';

// ──────────────────────────────────────────────
//  API Service – Connects to Spring Boot backend
//  Base URL: http://127.0.0.1:8081/api/student
// ──────────────────────────────────────────────
class ApiService {
  static const String _baseUrl = 'http://127.0.0.1:8081/api/student';

  // Generic GET
  Future<dynamic> _get(String endpoint) async {
    final response = await http.get(
      Uri.parse('$_baseUrl$endpoint'),
      headers: {'Content-Type': 'application/json'},
    );
    final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (jsonResponse['success'] == false)
        throw Exception(jsonResponse['message'] ?? 'Lỗi không xác định');
      return jsonResponse['data'];
    }
    throw Exception(
        jsonResponse['message'] ?? 'Lỗi HTTP ${response.statusCode}');
  }

  // Generic POST
  Future<dynamic> _post(String endpoint, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$_baseUrl$endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (jsonResponse['success'] == false)
        throw Exception(jsonResponse['message'] ?? 'Lỗi không xác định');
      return jsonResponse['data'];
    }
    throw Exception(
        jsonResponse['message'] ?? 'Lỗi HTTP ${response.statusCode}');
  }

  // Generic PUT
  Future<dynamic> _put(String endpoint, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse('$_baseUrl$endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (jsonResponse['success'] == false)
        throw Exception(jsonResponse['message'] ?? 'Lỗi không xác định');
      return jsonResponse['data'];
    }
    throw Exception(
        jsonResponse['message'] ?? 'Lỗi HTTP ${response.statusCode}');
  }

  // ── Auth ──────────────────────────────────────────────────
  Future<Map<String, dynamic>> login(String mssv, String password) async {
    final data = await _post('/auth/login', {
      'mssv': mssv,
      'password': password,
    });
    return data as Map<String, dynamic>;
  }

  // ── Categories (Formerly Specialties) ──────────────────────
  Future<List<Specialty>> getSpecialties() async {
    final data = await _get('/categories');
    return (data as List).map((e) => Specialty.fromJson(e)).toList();
  }

  // ── Services (Formerly Procedures) ────────────────────────
  Future<List<Procedure>> getProcedures(int categoryId) async {
    final data = await _get('/services?categoryId=$categoryId');
    return (data as List).map((e) => Procedure.fromJson(e)).toList();
  }

  // ── Time Slots ────────────────────────────────────────────
  Future<List<TimeSlot>> getAvailableSlots(int serviceId, String date) async {
    final data = await _get(
        '/appointments/available-slots?serviceId=$serviceId&date=$date');
    final slots = data['slots'] as List;
    return slots.map((e) => TimeSlot.fromJson(e)).toList();
  }

  // ── Create Appointment ────────────────────────────────────
  Future<Appointment> createAppointment({
    required int procedureId,
    required String appointmentDate,
    required String appointmentTime,
    required String citizenName,
    required String citizenId,
    required String phoneNumber,
    String? notes,
  }) async {
    final data = await _post('/appointments', {
      'serviceId': procedureId,
      'appointmentDate': appointmentDate,
      'appointmentTime': appointmentTime,
      'studentName': citizenName,
      'studentId': citizenId,
      'phoneNumber': phoneNumber,
    });
    return Appointment.fromJson(data);
  }

  // ── Get Appointments ──────────────────────────────────────
  Future<List<Appointment>> getMyAppointments(String mssv) async {
    final data = await _get('/appointments?mssv=$mssv');
    return (data as List).map((e) => Appointment.fromJson(e)).toList();
  }

  // ── Get Appointment Detail ────────────────────────────────
  Future<Appointment> getAppointmentDetail(int id, String mssv) async {
    final data = await _get('/appointments/$id?mssv=$mssv');
    return Appointment.fromJson(data);
  }

  // ── Feedback ──────────────────────────────────────────────
  Future<List<FeedbackItem>> getFeedbackList(String mssv) async {
    final data = await _get('/feedback?mssv=$mssv');
    return (data as List).map((e) => FeedbackItem.fromJson(e)).toList();
  }

  Future<void> submitFeedback({
    required String mssv,
    required String title,
    required String content,
    required int type,
    int? requestId,
  }) async {
    await _post('/feedback', {
      'mssv': mssv,
      'title': title,
      'content': content,
      'type': type,
      if (requestId != null) 'requestId': requestId,
    });
  }

  // ── Profile ──────────────────────────────────────────────────
  Future<void> updateProfile({
    required String mssv,
    required String email,
    required String phone,
  }) async {
    await _put('/profile', {
      'mssv': mssv,
      'email': email,
      'phone': phone,
    });
  }
}
