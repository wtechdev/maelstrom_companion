import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_exception.dart';
import '../models/project.dart';
import '../models/timesheet_entry.dart';
import '../models/timer_status.dart';
import '../models/week_summary.dart';

class ApiClient {
  final String baseUrl;
  final String token;
  final http.Client _http;

  ApiClient({
    required this.baseUrl,
    required this.token,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

  Future<Map<String, dynamic>> _get(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _http.get(uri, headers: _headers);
    return _parseResponse(response);
  }

  Future<Map<String, dynamic>> _post(String path, [Map<String, dynamic>? body]) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _http.post(
      uri,
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _parseResponse(response);
  }

  Map<String, dynamic> _parseResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    String msg = 'Errore ${response.statusCode}';
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      msg = body['message'] as String? ?? msg;
    } catch (_) {}
    throw ApiException(statusCode: response.statusCode, message: msg);
  }

  /// Login companion: verifica email+password e restituisce il token personale.
  /// Non richiede autenticazione Bearer — usa solo il baseUrl.
  static Future<Map<String, dynamic>> login({
    required String baseUrl,
    required String email,
    required String password,
    http.Client? httpClient,
  }) async {
    final client = httpClient ?? http.Client();
    final uri = Uri.parse('$baseUrl/api/v1/companion/login');
    final response = await client.post(
      uri,
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    String msg = 'Errore ${response.statusCode}';
    try {
      msg = (jsonDecode(response.body) as Map<String, dynamic>)['message'] as String? ?? msg;
    } catch (_) {}
    throw ApiException(statusCode: response.statusCode, message: msg);
  }

  Future<Map<String, dynamic>> getProfilo() => _get('/api/v1/me');

  Future<List<Project>> getProjects() async {
    final data = await _get('/api/v1/me/projects');
    final list = data['data'] as List<dynamic>? ?? [];
    return list.map((e) => Project.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<TimesheetEntry>> getTimesheetOggi() async {
    final oggi = DateTime.now().toIso8601String().split('T')[0];
    final data = await _get('/api/v1/me/timesheet?da=$oggi&a=$oggi');
    final list = data['data'] as List<dynamic>? ?? [];
    return list.map((e) => TimesheetEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<WeekSummary> getTimesheetWeek({DateTime? weekStart}) async {
    String path = '/api/v1/me/timesheet/week';
    if (weekStart != null) {
      path += '?week=${weekStart.toIso8601String().split('T')[0]}';
    }
    // Il backend restituisce i dati direttamente, senza wrapper 'data'
    final data = await _get(path);
    return WeekSummary.fromJson(data);
  }

  Future<TimerStatus> getTimerStatus() async {
    final data = await _get('/api/v1/me/timer/status');
    // risposta: {"active":false} oppure {"active":true,"project_id":...}
    final payload = data['data'] as Map<String, dynamic>? ?? data;
    return TimerStatus.fromJson(payload);
  }

  Future<TimerStatus> startTimer(int projectId) async {
    final data = await _post('/api/v1/me/timer/start', {'project_id': projectId});
    final payload = data['data'] as Map<String, dynamic>? ?? data;
    return TimerStatus.fromJson(payload);
  }

  Future<void> stopTimer() => _post('/api/v1/me/timer/stop');

  void dispose() => _http.close();
}
