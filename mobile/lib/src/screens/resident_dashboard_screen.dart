import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../config/api_config.dart';
import '../services/auth_service.dart';
import '../services/community_post_service.dart';
import '../services/public_monitoring_service.dart';
import '../ui/app_ui.dart';
import 'community_post_details_screen.dart';
import 'create_community_post_screen.dart';
import 'live_tracking_screen.dart';
import 'welcome_screen.dart';

class ResidentDashboardScreen extends StatefulWidget {
  const ResidentDashboardScreen({super.key, required this.session});
  final AuthSession session;

  @override
  State<ResidentDashboardScreen> createState() =>
      _ResidentDashboardScreenState();
}

class _ResidentDashboardScreenState extends State<ResidentDashboardScreen> {
  int tab = 0;
  bool loading = true;
  bool signingOut = false;
  String? error;
  List<Map<String, dynamic>> posts = [];
  List<Map<String, dynamic>> reports = [];
  List<Map<String, dynamic>> notifications = [];
  MonitoringSnapshot? monitoring;

  Map<String, String> get headers => {
    'Authorization': 'Bearer ${widget.session.token}',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        loading = true;
        error = null;
      });
    }
    try {
      final responses = await Future.wait([
        const CommunityPostService().list(widget.session),
        http.get(Uri.parse(ApiConfig.residentReports), headers: headers),
        http.get(Uri.parse(ApiConfig.residentNotifications), headers: headers),
        _loadMonitoring(),
      ]);
      posts = responses[0] as List<Map<String, dynamic>>;
      reports = _rows(responses[1] as http.Response);
      notifications = _rows(responses[2] as http.Response);
      monitoring = responses[3] as MonitoringSnapshot?;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  List<Map<String, dynamic>> _rows(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message']?.toString() ?? 'Unable to load data.');
    }
    return (body['data'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  Future<MonitoringSnapshot?> _loadMonitoring() async {
    try {
      return await PublicMonitoringService().fetchLatest();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unread = notifications
        .where((item) => item['is_read'] != true)
        .length;
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(switch (tab) {
            0 => 'Resident Dashboard',
            1 => 'My Posts',
            2 => 'Incident Reports',
            _ => 'Notifications',
          }),
          actions: [
            IconButton(
              onPressed: signingOut ? null : _logout,
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Sign out',
            ),
          ],
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : error != null
            ? _MessageState(message: error!, onRetry: _load)
            : RefreshIndicator(
                onRefresh: _load,
                child: switch (tab) {
                  0 => _dashboard(unread),
                  1 => _postList(),
                  2 => _reportList(),
                  _ => _notificationList(),
                },
              ),
        floatingActionButton: tab == 1
            ? FloatingActionButton.extended(
                onPressed: _openPostForm,
                icon: const Icon(Icons.post_add_outlined),
                label: const Text('Create post'),
              )
            : tab == 2
            ? FloatingActionButton.extended(
                onPressed: _openReportForm,
                icon: const Icon(Icons.add_a_photo_outlined),
                label: const Text('Report incident'),
              )
            : null,
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (value) {
            if (value == 4) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => LiveTrackingScreen(
                    session: widget.session,
                    residentMode: true,
                  ),
                ),
              );
              return;
            }
            setState(() => tab = value);
          },
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            const NavigationDestination(
              icon: Icon(Icons.dynamic_feed_outlined),
              selectedIcon: Icon(Icons.dynamic_feed),
              label: 'Posts',
            ),
            const NavigationDestination(
              icon: Icon(Icons.description_outlined),
              selectedIcon: Icon(Icons.description),
              label: 'Reports',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: unread > 0,
                label: Text('$unread'),
                child: const Icon(Icons.notifications_outlined),
              ),
              selectedIcon: Badge(
                isLabelVisible: unread > 0,
                label: Text('$unread'),
                child: const Icon(Icons.notifications),
              ),
              label: 'Alerts',
            ),
            const NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map),
              label: 'Tracking',
            ),
          ],
        ),
      ),
    );
  }

  Widget _dashboard(int unread) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
    children: [
      AppPageHeader(
        eyebrow: 'Resident account',
        title: 'Hello, ${widget.session.name.split(' ').first}',
        subtitle: 'Share community updates, request barangay assistance, and follow active responses.',
        icon: Icons.home_outlined,
        color: AppColors.teal,
        useLogo: true,
      ),
      const SizedBox(height: 16),
      _monitoringCard(),
      const SizedBox(height: 20),
      const Text(
        'Your activity',
        style: TextStyle(
          color: AppColors.navy,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 12),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.2,
        children: [
          AppStatCard(
            label: 'Community posts',
            value: '${posts.length}',
            icon: Icons.dynamic_feed_outlined,
            color: AppColors.blue,
            onTap: () => setState(() => tab = 1),
          ),
          AppStatCard(
            label: 'Incident reports',
            value: '${reports.length}',
            icon: Icons.description_outlined,
            color: AppColors.teal,
            onTap: () => setState(() => tab = 2),
          ),
          AppStatCard(
            label: 'Unread alerts',
            value: '$unread',
            icon: Icons.notifications_outlined,
            color: const Color(0xFFF59E0B),
            onTap: () => setState(() => tab = 3),
          ),
          AppStatCard(
            label: 'Live response',
            value: 'View',
            icon: Icons.map_outlined,
            color: const Color(0xFF7C3AED),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => LiveTrackingScreen(
                  session: widget.session,
                  residentMode: true,
                ),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'What would you like to do?',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: _openReportForm,
                icon: const Icon(Icons.emergency_outlined),
                label: const Text('Request barangay response'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _openPostForm,
                icon: const Icon(Icons.post_add_outlined),
                label: const Text('Share a community update'),
              ),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _monitoringCard() {
    final data = monitoring;
    if (data == null) {
      return const Card(
        child: ListTile(
          contentPadding: EdgeInsets.all(16),
          leading: Icon(Icons.sensors_off_outlined, color: AppColors.muted),
          title: Text(
            'Monitoring temporarily unavailable',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text('Pull down to check the station again.'),
        ),
      );
    }
    final level = data.alertLevel.toLowerCase();
    final color = switch (level) {
      'critical' => AppColors.danger,
      'warning' => const Color(0xFFF59E0B),
      'normal' => const Color(0xFF059669),
      _ => AppColors.muted,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const FloodGuardLogo(size: 46, padding: 5),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Spillway monitoring',
                        style: TextStyle(
                          color: AppColors.navy,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Latest station condition',
                        style: TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    level.toUpperCase(),
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _reading(
                    Icons.water_drop_outlined,
                    'Water level',
                    data.waterLevel == null
                        ? 'Unavailable'
                        : '${data.waterLevel!.toStringAsFixed(1)} cm',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _reading(
                    Icons.umbrella_outlined,
                    'Rain',
                    data.rainDetected == null
                        ? 'Unavailable'
                        : data.rainDetected!
                        ? 'Detected'
                        : 'No rain',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _reading(
                    Icons.air,
                    'Wind',
                    data.windSpeed == null
                        ? 'Unavailable'
                        : '${data.windSpeed!.toStringAsFixed(1)} m/s',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _reading(
                    data.northBarrierStatus.toLowerCase() == 'closed' ||
                            data.southBarrierStatus.toLowerCase() == 'closed'
                        ? Icons.block_outlined
                        : Icons.check_circle_outline,
                    'Bridge',
                    data.northBarrierStatus.toLowerCase() == 'closed' ||
                            data.southBarrierStatus.toLowerCase() == 'closed'
                        ? 'Closed'
                        : data.northBarrierStatus.toLowerCase() == 'open' &&
                              data.southBarrierStatus.toLowerCase() == 'open'
                        ? 'Open'
                        : 'Unavailable',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  data.isOnline ? Icons.wifi : Icons.wifi_off,
                  color: data.isOnline ? AppColors.teal : AppColors.muted,
                  size: 18,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    data.isOnline
                        ? 'Station online • ${data.lastUpdated ?? 'Live data'}'
                        : 'Station offline • Showing the latest available reading',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _reading(IconData icon, String label, String value) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFF7FAFD),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.blue),
        const SizedBox(height: 9),
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );

  Widget _postList() {
    if (posts.isEmpty) {
      return const _ScrollableEmpty(
        icon: Icons.dynamic_feed_outlined,
        title: 'No posts yet',
        text: 'Tap Create post to share an update for barangay review.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: posts.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, index) {
        final post = posts[index];
        return Card(
          child: ListTile(
            onTap: () async {
              final id = int.tryParse('${post['id']}');
              if (id == null) return;
              final changed = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => CommunityPostDetailsScreen(
                    session: widget.session,
                    postId: id,
                  ),
                ),
              );
              if (changed == true) await _load();
            },
            contentPadding: const EdgeInsets.all(16),
            leading: const CircleAvatar(child: Icon(Icons.campaign_outlined)),
            title: Text(
              post['title']?.toString() ?? 'Community post',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${post['post_number'] ?? ''}'),
                  const SizedBox(height: 3),
                  Text(_formatPhTimestamp(post['submitted_at'])),
                  const SizedBox(height: 6),
                  const Text(
                    'Tap to view details',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            trailing: _StatusChip('${post['status'] ?? 'submitted'}'),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Widget _reportList() {
    if (reports.isEmpty) {
      return const _ScrollableEmpty(
        icon: Icons.description_outlined,
        title: 'No incident reports yet',
        text: 'Tap Report incident when barangay assistance is needed.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: reports.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, index) {
        final report = reports[index];
        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: const CircleAvatar(child: Icon(Icons.flood)),
            title: Text(
              report['report_number']?.toString() ?? 'Flood report',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Text(
                '${report['location_description'] ?? ''}\n${report['submitted_at'] ?? ''}',
              ),
            ),
            trailing: _StatusChip('${report['status'] ?? 'submitted'}'),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Widget _notificationList() {
    if (notifications.isEmpty) {
      return const _ScrollableEmpty(
        icon: Icons.notifications_none,
        title: 'No notifications',
        text: 'Flood alerts and report updates will appear here.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: notifications.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, index) {
        final item = notifications[index];
        final read = item['is_read'] == true;
        return Card(
          child: ListTile(
            onTap: () => _markRead(item),
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: read
                  ? const Color(0xFFE2E8F0)
                  : const Color(0xFFFFE7B0),
              child: Icon(
                Icons.notifications,
                color: read ? const Color(0xFF64748B) : const Color(0xFFD97706),
              ),
            ),
            title: Text(
              item['title']?.toString() ?? 'FloodGuard notification',
              style: TextStyle(
                fontWeight: read ? FontWeight.w600 : FontWeight.w900,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Text('${item['body'] ?? ''}\n${item['created_at'] ?? ''}'),
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Future<void> _markRead(Map<String, dynamic> item) async {
    if (item['is_read'] == true) return;
    final response = await http.post(
      Uri.parse(ApiConfig.readNotification),
      headers: {...headers, 'Content-Type': 'application/json'},
      body: jsonEncode({'notification_id': item['id']}),
    );
    if (response.statusCode == 200 && mounted) {
      setState(() => item['is_read'] = true);
    }
  }

  Future<void> _openReportForm() async {
    final submitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SubmitReportScreen(session: widget.session),
      ),
    );
    if (submitted == true) await _load();
  }

  Future<void> _openPostForm() async {
    final submitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateCommunityPostScreen(session: widget.session),
      ),
    );
    if (submitted == true) await _load();
  }

  Future<void> _logout() async {
    final confirmed = await showAppConfirmation(
      context,
      title: 'Sign out of FloodGuard?',
      message:
          'You will need to sign in again to view your reports and alerts.',
      confirmLabel: 'Sign out',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    setState(() => signingOut = true);
    try {
      await AuthService().logout(widget.session);
    } finally {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (route) => false,
        );
      }
    }
  }
}

String _formatPhTimestamp(dynamic value) {
  final raw = value?.toString().trim() ?? '';
  if (raw.isEmpty) return 'Time not available';
  final parsed = DateTime.tryParse(raw.replaceFirst(' ', 'T'));
  if (parsed == null) return '$raw PHT';
  final hour = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
  final minute = parsed.minute.toString().padLeft(2, '0');
  final period = parsed.hour >= 12 ? 'PM' : 'AM';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[parsed.month - 1]} ${parsed.day}, ${parsed.year}, '
      '$hour:$minute $period PHT';
}

class SubmitReportScreen extends StatefulWidget {
  const SubmitReportScreen({super.key, required this.session});
  final AuthSession session;
  @override
  State<SubmitReportScreen> createState() => _SubmitReportScreenState();
}

class _SubmitReportScreenState extends State<SubmitReportScreen> {
  final key = GlobalKey<FormState>();
  final location = TextEditingController();
  final description = TextEditingController();
  XFile? photo;
  Position? position;
  bool danger = false, busy = false;

  @override
  void dispose() {
    location.dispose();
    description.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    final selected = await ImagePicker().pickImage(
      source: source,
      imageQuality: 78,
      maxWidth: 1600,
    );
    if (selected != null && mounted) setState(() => photo = selected);
  }

  Future<void> _locate() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Turn on location services, then try again.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission was not granted.');
      }
      final current = await Geolocator.getCurrentPosition();
      if (mounted) setState(() => position = current);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!key.currentState!.validate()) return;
    if (photo == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Add a flood photo first.')));
      return;
    }
    setState(() => busy = true);
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.residentReports),
      );
      request.headers['Authorization'] = 'Bearer ${widget.session.token}';
      request.fields.addAll({
        'location_description': location.text.trim(),
        'flood_description': description.text.trim(),
        'immediate_danger': danger ? 'true' : 'false',
      });
      if (position != null) {
        request.fields['latitude'] = '${position!.latitude}';
        request.fields['longitude'] = '${position!.longitude}';
      }
      request.files.add(
        await http.MultipartFile.fromPath('photo', photo!.path),
      );
      final response = await http.Response.fromStream(await request.send());
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 201 || body['success'] != true) {
        throw Exception(
          body['message']?.toString() ?? 'Unable to submit report.',
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(body['message']?.toString() ?? 'Report submitted.'),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Report Incident')),
    body: SafeArea(
      child: Form(
        key: key,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const AppPageHeader(
              eyebrow: 'Emergency assistance',
              title: 'Report a flood incident',
              subtitle: 'Give responders a clear location, current photo, and concise description.',
              icon: Icons.emergency_outlined,
              color: Color(0xFFDC2626),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: location,
              decoration: const InputDecoration(
                labelText: 'Location description',
                prefixIcon: Icon(Icons.place_outlined),
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Describe the location.'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: description,
              minLines: 4,
              maxLines: 7,
              decoration: const InputDecoration(
                labelText: 'Flood condition',
                alignLabelWithHint: true,
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Describe the flood condition.'
                  : null,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Immediate danger'),
              subtitle: const Text(
                'People, vehicles, or property are currently at risk.',
              ),
              value: danger,
              onChanged: (v) => setState(() => danger = v),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pick(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pick(ImageSource.gallery),
                    icon: const Icon(Icons.photo_outlined),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),
            if (photo != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Photo: ${photo!.name}',
                  style: const TextStyle(color: Color(0xFF059669)),
                ),
              ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _locate,
              icon: const Icon(Icons.my_location),
              label: Text(
                position == null
                    ? 'Use current GPS location'
                    : 'GPS location captured',
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: busy ? null : _submit,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  busy ? 'Submitting...' : 'Request barangay response',
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.value);
  final String value;
  @override
  Widget build(BuildContext context) => Chip(
    label: Text(
      value.replaceAll('_', ' ').toUpperCase(),
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
    ),
  );
}

class _ScrollableEmpty extends StatelessWidget {
  const _ScrollableEmpty({
    required this.icon,
    required this.title,
    required this.text,
  });
  final IconData icon;
  final String title;
  final String text;
  @override
  Widget build(BuildContext context) => ListView(
    children: [
      const SizedBox(height: 120),
      Icon(icon, size: 55, color: const Color(0xFF94A3B8)),
      const SizedBox(height: 15),
      Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 6),
      Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFF64748B)),
      ),
    ],
  );
}

class _MessageState extends StatelessWidget {
  const _MessageState({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 15),
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
