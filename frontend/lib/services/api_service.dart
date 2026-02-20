import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:salah_tracker/models/prayer_log.dart';
import 'package:salah_tracker/models/user.dart';

/// HTTP service for communicating with the FastAPI backend.
class ApiService {
  final String baseUrl;
  String? _authToken;

  ApiService({String? baseUrl})
    : baseUrl = baseUrl ?? dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000' {
    print('ApiService initialized with baseUrl: ${this.baseUrl}');
  }

  void setAuthToken(String token) {
    _authToken = token;
  }

  Map<String, String> get _headers {
    final h = <String, String>{'Content-Type': 'application/json'};
    if (_authToken != null) {
      h['Authorization'] = 'Bearer $_authToken';
    }
    return h;
  }

  // ─── Auth ──────────────────────────────────────────────────────────

  Future<AppUser> googleLogin(String idToken) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/google-login'),
      headers: _headers,
      body: jsonEncode({'id_token': idToken}),
    );
    if (response.statusCode == 200) {
      return AppUser.fromJson(jsonDecode(response.body));
    }
    throw Exception('Login failed: ${response.body}');
  }

  Future<AppUser> getMe() async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return AppUser.fromJson(jsonDecode(response.body));
    }
    throw Exception('Get user failed: ${response.body}');
  }

  Future<AppUser> updatePerformanceStartDate(DateTime date) async {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final response = await http.put(
      Uri.parse('$baseUrl/auth/performance-start-date'),
      headers: _headers,
      body: jsonEncode({'performance_start_date': dateStr}),
    );
    if (response.statusCode == 200) {
      return AppUser.fromJson(jsonDecode(response.body));
    }
    throw Exception('Update start date failed: ${response.body}');
  }

  // ─── Prayer Logs ──────────────────────────────────────────────────

  Future<PrayerLog> getLog(DateTime date) async {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final response = await http.get(
      Uri.parse('$baseUrl/logs/$dateStr'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return PrayerLog.fromJson(jsonDecode(response.body));
    }
    throw Exception('Get log failed: ${response.statusCode}');
  }

  Future<PrayerLog> createOrUpdateLog(PrayerLog log) async {
    final response = await http.post(
      Uri.parse('$baseUrl/logs/'),
      headers: _headers,
      body: jsonEncode(log.toJson()),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return PrayerLog.fromJson(jsonDecode(response.body));
    }
    throw Exception('Create log failed: ${response.body}');
  }

  Future<List<PrayerLog>> getLogsRange(DateTime start, DateTime end) async {
    final startStr =
        '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
    final endStr =
        '${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';
    final response = await http.get(
      Uri.parse('$baseUrl/logs/range/?start=$startStr&end=$endStr'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => PrayerLog.fromJson(json)).toList();
    }
    throw Exception('Get logs range failed: ${response.body}');
  }

  Future<List<PrayerLog>> batchSync(List<PrayerLog> logs) async {
    final response = await http.post(
      Uri.parse('$baseUrl/logs/sync'),
      headers: _headers,
      body: jsonEncode({'logs': logs.map((l) => l.toJson()).toList()}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> syncedLogs = data['logs'];
      return syncedLogs.map((json) => PrayerLog.fromJson(json)).toList();
    }
    throw Exception('Batch sync failed: ${response.body}');
  }

  // ─── Performance ──────────────────────────────────────────────────

  Future<Map<String, dynamic>> getPerformance(
    DateTime start,
    DateTime end,
  ) async {
    final startStr =
        '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
    final endStr =
        '${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';
    final response = await http.get(
      Uri.parse('$baseUrl/performance/?start=$startStr&end=$endStr'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Get performance failed: ${response.body}');
  }
}
