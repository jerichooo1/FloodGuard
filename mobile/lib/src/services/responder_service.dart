import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_service.dart';

class ResponderAssignment {
  const ResponderAssignment({
    required this.id,
    required this.incidentNumber,
    required this.status,
    required this.priority,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.description,
    required this.teamName,
    this.notes,
    this.immediateDanger = false,
  });

  final int id;
  final String incidentNumber;
  final String status;
  final String priority;
  final String location;
  final double latitude;
  final double longitude;
  final String description;
  final String teamName;
  final String? notes;
  final bool immediateDanger;

  factory ResponderAssignment.fromJson(Map<String, dynamic> json) {
    return ResponderAssignment(
      id: _asInt(json['assignment_id']),
      incidentNumber: json['incident_number']?.toString() ?? 'Incident',
      status: json['assignment_status']?.toString() ?? 'assigned',
      priority: json['priority']?.toString() ?? 'normal',
      location: json['location_description']?.toString() ?? 'Unknown location',
      latitude: _asDouble(json['latitude']),
      longitude: _asDouble(json['longitude']),
      description: json['flood_description']?.toString() ?? '',
      teamName: json['team_name']?.toString() ?? 'Response Team',
      notes: json['notes']?.toString(),
      immediateDanger:
          json['immediate_danger'] == true || json['immediate_danger'] == 1,
    );
  }

  static int _asInt(dynamic value) => int.tryParse(value.toString()) ?? 0;
  static double _asDouble(dynamic value) =>
      double.tryParse(value.toString()) ?? 0;
}

class ResponderService {
  ResponderService(this.session);
  final AuthSession session;

  Map<String, String> get _headers => {
    'Authorization': 'Bearer ${session.token}',
    'Content-Type': 'application/json',
  };

  Future<List<ResponderAssignment>> assignments() async {
    final response = await http
        .get(Uri.parse(ApiConfig.responderAssignments), headers: _headers)
        .timeout(const Duration(seconds: 15));
    final body = _body(response);
    final rows = body['data'] as List<dynamic>? ?? const [];
    return rows
        .whereType<Map<String, dynamic>>()
        .map(ResponderAssignment.fromJson)
        .toList();
  }

  Future<ResponderAssignment> assignment(int id) async {
    final uri = Uri.parse(ApiConfig.responderAssignment)
        .replace(queryParameters: {'id': '$id'});
    final response = await http
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 15));
    final body = _body(response);
    return ResponderAssignment.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<void> updateStatus(int id, String status, {String notes = ''}) async {
    final response = await http
        .post(
          Uri.parse(ApiConfig.responderUpdateStatus),
          headers: _headers,
          body: jsonEncode({
            'assignment_id': id,
            'status': status,
            'notes': notes,
          }),
        )
        .timeout(const Duration(seconds: 15));
    _body(response);
  }

  Future<void> updateLocation({
    required int assignmentId,
    required double latitude,
    required double longitude,
    double? accuracy,
  }) async {
    final response = await http
        .post(
          Uri.parse(ApiConfig.responderUpdateLocation),
          headers: _headers,
          body: jsonEncode({
            'assignment_id': assignmentId,
            'latitude': latitude,
            'longitude': longitude,
            'accuracy_meters': accuracy,
          }),
        )
        .timeout(const Duration(seconds: 15));
    _body(response);
  }

  Map<String, dynamic> _body(http.Response response) {
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        decoded['success'] != true) {
      throw Exception(decoded['message']?.toString() ?? 'Request failed.');
    }
    return decoded;
  }
}
