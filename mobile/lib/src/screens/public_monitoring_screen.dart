import 'package:flutter/material.dart';

import '../services/public_monitoring_service.dart';

class PublicMonitoringScreen extends StatefulWidget {
  const PublicMonitoringScreen({super.key});

  @override
  State<PublicMonitoringScreen> createState() => _PublicMonitoringScreenState();
}

class _PublicMonitoringScreenState extends State<PublicMonitoringScreen> {
  final _service = PublicMonitoringService();
  late Future<MonitoringSnapshot> _snapshot;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    _snapshot = _service.fetchLatest();
  }

  Future<void> _pullToRefresh() async {
    setState(() {
      _refresh();
    });
    await _snapshot;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Live Monitoring',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: FutureBuilder<MonitoringSnapshot>(
        future: _snapshot,
        builder: (context, state) {
          if (state.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.hasError) {
            return _ErrorState(
              message: state.error.toString(),
              onRetry: () => setState(() {
                _refresh();
              }),
            );
          }
          final data = state.requireData;
          return RefreshIndicator(
            onRefresh: _pullToRefresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
              children: [
                _ConditionCard(data: data),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.18,
                  children: [
                    _ReadingCard(
                      icon: Icons.water_drop_outlined,
                      label: 'Water level',
                      value: data.waterLevel == null
                          ? 'Unavailable'
                          : '${data.waterLevel!.toStringAsFixed(1)} cm',
                    ),
                    _ReadingCard(
                      icon: Icons.umbrella_outlined,
                      label: 'Rain',
                      value: data.rainDetected == null
                          ? 'Unavailable'
                          : (data.rainDetected! ? 'Detected' : 'No rain'),
                    ),
                    _ReadingCard(
                      icon: Icons.air,
                      label: 'Wind speed',
                      value: data.windSpeed == null
                          ? 'Unavailable'
                          : '${data.windSpeed!.toStringAsFixed(1)} m/s',
                    ),
                    _ReadingCard(
                      icon: Icons.battery_5_bar_outlined,
                      label: 'Battery',
                      value: data.battery == null
                          ? 'Unavailable'
                          : '${data.battery}%',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(17),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Monitoring station',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(data.stationName),
                        const SizedBox(height: 5),
                        Text(
                          data.location,
                          style: const TextStyle(color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Device: ${data.deviceId}',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ConditionCard extends StatelessWidget {
  const _ConditionCard({required this.data});
  final MonitoringSnapshot data;

  @override
  Widget build(BuildContext context) {
    final alert = data.alertLevel.toUpperCase();
    final color = switch (data.alertLevel.toLowerCase()) {
      'critical' => const Color(0xFFDC2626),
      'warning' => const Color(0xFFF59E0B),
      'normal' => const Color(0xFF059669),
      _ => const Color(0xFF64748B),
    };
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                data.isOnline ? 'STATION ONLINE' : 'STATION OFFLINE',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Icon(
                data.isOnline ? Icons.wifi : Icons.wifi_off,
                color: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            alert,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            data.lastUpdated == null
                ? 'Waiting for a sensor update'
                : 'Last update: ${data.lastUpdated}',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _ReadingCard extends StatelessWidget {
  const _ReadingCard({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF0874C9)),
          const Spacer(),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
        ],
      ),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 52, color: Color(0xFF64748B)),
          const SizedBox(height: 15),
          const Text(
            'Unable to load monitoring data',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ],
      ),
    ),
  );
}
