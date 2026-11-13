import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../services/auth_service.dart';
import '../services/tracking_service.dart';

class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({
    super.key,
    required this.session,
    this.assignmentId,
    required this.residentMode,
  });
  final AuthSession session;
  final int? assignmentId;
  final bool residentMode;

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  late final TrackingService service = TrackingService(widget.session);
  TrackingSnapshot? snapshot;
  Timer? poller;
  StreamSubscription<Position>? residentLocation;
  bool loading = true;
  bool changingConsent = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
    poller = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _load(silent: true),
    );
  }

  @override
  void dispose() {
    poller?.cancel();
    residentLocation?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    try {
      final value = widget.assignmentId == null
          ? await service.activeResidentTracking()
          : await service.latest(widget.assignmentId!);
      if (!mounted) return;
      setState(() {
        snapshot = value;
        loading = false;
        error = null;
      });
      if (widget.residentMode &&
          value?.residentSharing == true &&
          residentLocation == null) {
        await _startResidentUpdates(value!.assignmentId);
      }
      if (value != null && !value.active && residentLocation != null) {
        await residentLocation?.cancel();
        residentLocation = null;
      }
    } catch (e) {
      if (!mounted || silent) return;
      setState(() {
        loading = false;
        error = '$e'.replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _toggleConsent(bool enabled) async {
    final current = snapshot;
    if (current == null) return;
    setState(() => changingConsent = true);
    try {
      if (enabled) await _ensureLocationPermission();
      await service.setResidentConsent(current.assignmentId, enabled);
      if (enabled) {
        await _startResidentUpdates(current.assignmentId);
      } else {
        await residentLocation?.cancel();
        residentLocation = null;
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => changingConsent = false);
    }
  }

  Future<void> _ensureLocationPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('Enable location services first.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission is required to share your position.',
      );
    }
  }

  Future<void> _startResidentUpdates(int assignmentId) async {
    if (residentLocation != null) return;
    await _ensureLocationPermission();
    final first = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    await service.updateResidentLocation(
      assignmentId,
      first.latitude,
      first.longitude,
      first.accuracy,
    );
    residentLocation =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen((position) async {
          try {
            await service.updateResidentLocation(
              assignmentId,
              position.latitude,
              position.longitude,
              position.accuracy,
            );
          } catch (_) {}
        });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Live Response Tracking')),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : error != null
        ? _message(error!)
        : snapshot == null
        ? _message('No active response is connected to your reports.')
        : _content(snapshot!),
  );

  Widget _content(TrackingSnapshot value) {
    final points = [
      value.resident,
      value.responder,
    ].whereType<TrackingPoint>().toList();
    final center = points.isNotEmpty
        ? LatLng(points.first.latitude, points.first.longitude)
        : const LatLng(14.7310, 121.1410);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          value.incidentNumber,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(
          _label(value.status),
          style: const TextStyle(color: Color(0xFF64748B)),
        ),
        if (widget.residentMode && value.active) ...[
          const SizedBox(height: 12),
          Card(
            child: SwitchListTile(
              value: value.residentSharing,
              onChanged: changingConsent ? null : _toggleConsent,
              title: const Text('Share my live location'),
              subtitle: const Text(
                'Only the assigned response team can view it. Sharing stops when the response ends.',
              ),
              secondary: const Icon(Icons.location_on_outlined),
            ),
          ),
        ],
        const SizedBox(height: 12),
        SizedBox(
          height: 430,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: FlutterMap(
              options: MapOptions(initialCenter: center, initialZoom: 16),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.floodguard.floodguard_mobile',
                ),
                MarkerLayer(
                  markers: [
                    if (value.resident != null)
                      Marker(
                        point: LatLng(
                          value.resident!.latitude,
                          value.resident!.longitude,
                        ),
                        width: 52,
                        height: 52,
                        child: const Tooltip(
                          message: 'Resident',
                          child: Icon(
                            Icons.person_pin_circle,
                            size: 46,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    if (value.responder != null)
                      Marker(
                        point: LatLng(
                          value.responder!.latitude,
                          value.responder!.longitude,
                        ),
                        width: 52,
                        height: 52,
                        child: const Tooltip(
                          message: 'Responder',
                          child: Icon(
                            Icons.emergency,
                            size: 42,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                  ],
                ),
                RichAttributionWidget(
                  attributions: const [
                    TextSourceAttribution('OpenStreetMap contributors'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _legend(
          Icons.person_pin_circle,
          Colors.orange,
          value.residentSharing
              ? 'Resident location'
              : 'Resident location not shared',
        ),
        _legend(
          Icons.emergency,
          Colors.blue,
          value.responder == null
              ? 'Waiting for responder location'
              : 'Responder location',
        ),
      ],
    );
  }

  Widget _legend(IconData icon, Color color, String text) => ListTile(
    dense: true,
    leading: Icon(icon, color: color),
    title: Text(text),
  );

  Widget _message(String text) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.location_searching_outlined,
            size: 52,
            color: Color(0xFF64748B),
          ),
          const SizedBox(height: 14),
          Text(text, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('Check again'),
          ),
        ],
      ),
    ),
  );
  String _label(String value) => value
      .replaceAll('_', ' ')
      .split(' ')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}
