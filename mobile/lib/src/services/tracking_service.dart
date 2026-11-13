import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_service.dart';

class TrackingPoint {
  const TrackingPoint({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.recordedAt,
  });
  final double latitude;
  final double longitude;
  final double? accuracy;
  final String? recordedAt;

  factory TrackingPoint.fromJson(Map<String, dynamic> json) => TrackingPoint(
    latitude: double.tryParse('${json['latitude']}') ?? 0,
    longitude: double.tryParse('${json['longitude']}') ?? 0,
    accuracy: double.tryParse('${json['accuracy_meters']}'),
    recordedAt: json['recorded_at']?.toString(),
  );
}

class TrackingSnapshot {
  const TrackingSnapshot({
    required this.assignmentId,
    required this.incidentNumber,
    required this.status,
    required this.residentSharing,
    this.resident,
    this.responder,
  });
  final int assignmentId;
  final String incidentNumber;
  final String status;
  final bool residentSharing;
  final TrackingPoint? resident;
  final TrackingPoint? responder;

  bool get active =>
      const ['accepted', 'en_route', 'on_scene'].contains(status);

  factory TrackingSnapshot.fromJson(Map<String, dynamic> json) =>
      TrackingSnapshot(
        assignmentId: int.tryParse('${json['assignment_id']}') ?? 0,
        incidentNumber: json['incident_number']?.toString() ?? 'Incident',
        status: json['assignment_status']?.toString() ?? 'assigned',
        residentSharing:
            json['resident_sharing_enabled'] == true ||
            json['resident_sharing_enabled'] == 1,
        resident: json['resident_location'] is Map<String, dynamic>
            ? TrackingPoint.fromJson(
                json['resident_location'] as Map<String, dynamic>,
              )
            : null,
        responder: json['responder_location'] is Map<String, dynamic>
            ? TrackingPoint.fromJson(
                json['responder_location'] as Map<String, dynamic>,
              )
            : null,
      );
}

class TrackingService {
  TrackingService(this.session);
  final AuthSession session;

  Map<String, String> get _headers => {
    'Authorization': 'Bearer ${session.token}',
    'Content-Type': 'application/json',
  };

  Future<TrackingSnapshot?> activeResidentTracking() async {
    final response = await http
        .get(Uri.parse(ApiConfig.activeResidentTracking), headers: _headers)
        .timeout(const Duration(seconds: 15));
    final body = _body(response);
    final data = body['data'];
    return data is Map<String, dynamic>
        ? TrackingSnapshot.fromJson(data)
        : null;
  }

  Future<TrackingSnapshot> latest(int assignmentId) async {
    final uri = Uri.parse(ApiConfig.trackingLatest)
        .replace(queryParameters: {'assignment_id': '$assignmentId'});
    final response = await http
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 15));
    return TrackingSnapshot.fromJson(
      _body(response)['data'] as Map<String, dynamic>,
    );
  }

  Future<void> setResidentConsent(int assignmentId, bool enabled) async {
    final response = await http
        .post(
          Uri.parse(ApiConfig.residentLocationConsent),
          headers: _headers,
          body: jsonEncode({'assignment_id': assignmentId, 'enabled': enabled}),
        )
        .timeout(const Duration(seconds: 15));
    _body(response);
  }

  Future<void> updateResidentLocation(
    int assignmentId,
    double latitude,
    double longitude,
    double accuracy,
  ) async {
    final response = await http
        .post(
          Uri.parse(ApiConfig.residentUpdateLocation),
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
      throw Exception(
        decoded['message']?.toString() ?? 'Tracking request failed.',
      );
    }
    return decoded;
  }
}
