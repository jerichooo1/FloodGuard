import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class MonitoringSnapshot {
  const MonitoringSnapshot({
    required this.deviceId,
    required this.stationName,
    required this.location,
    required this.isOnline,
    required this.waterLevel,
    required this.windSpeed,
    required this.northBarrierStatus,
    required this.southBarrierStatus,
    required this.alertLevel,
    required this.rainDetected,
    required this.battery,
    required this.lastUpdated,
  });

  final String deviceId;
  final String stationName;
  final String location;
  final bool isOnline;
  final double? waterLevel;
  final double? windSpeed;
  final String northBarrierStatus;
  final String southBarrierStatus;
  final String alertLevel;
  final bool? rainDetected;
  final double? battery;
  final String? lastUpdated;

  factory MonitoringSnapshot.fromJson(Map<String, dynamic> json) {
    double? number(dynamic value) => value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '');

    return MonitoringSnapshot(
      deviceId: json['device_id']?.toString() ?? 'FG-STATION-001',
      stationName:
          json['station_name']?.toString() ??
          'Spillway Bridge Monitoring Station',
      location:
          json['location']?.toString() ??
          'Barangay San Isidro, Rodriguez, Rizal',
      isOnline: json['online'] == true,
      waterLevel: number(json['water_level_cm']),
      windSpeed: number(json['wind_speed_mps']),
      northBarrierStatus: json['bridge_status'] is Map
          ? (json['bridge_status']['north']?.toString() ?? 'unknown')
          : 'unknown',
      southBarrierStatus: json['bridge_status'] is Map
          ? (json['bridge_status']['south']?.toString() ?? 'unknown')
          : 'unknown',
      alertLevel: json['alert_level']?.toString() ?? 'unavailable',
      rainDetected: json['rain_detected'] is bool
          ? json['rain_detected'] as bool
          : null,
      battery: number(json['battery_percent']),
      lastUpdated:
          json['last_update']?.toString() ?? json['last_updated']?.toString(),
    );
  }
}

class PublicMonitoringService {
  Future<MonitoringSnapshot> fetchLatest() async {
    final response = await http
        .get(Uri.parse(ApiConfig.publicLatest))
        .timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) {
      throw Exception('Server returned HTTP ${response.statusCode}.');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['success'] != true) {
      throw Exception('The monitoring API returned an invalid response.');
    }

    final data = decoded['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('No monitoring data was returned.');
    }

    return MonitoringSnapshot.fromJson(data);
  }
}
