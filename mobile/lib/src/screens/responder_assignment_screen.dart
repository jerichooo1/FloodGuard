import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../services/auth_service.dart';
import '../services/responder_service.dart';
import '../ui/app_ui.dart';
import 'live_tracking_screen.dart';

class ResponderAssignmentScreen extends StatefulWidget {
  const ResponderAssignmentScreen({
    super.key,
    required this.session,
    required this.assignmentId,
  });
  final AuthSession session;
  final int assignmentId;

  @override
  State<ResponderAssignmentScreen> createState() =>
      _ResponderAssignmentScreenState();
}

class _ResponderAssignmentScreenState extends State<ResponderAssignmentScreen> {
  late final ResponderService service = ResponderService(widget.session);
  ResponderAssignment? assignment;
  StreamSubscription<Position>? locationSubscription;
  bool busy = true;
  bool sharing = false;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    locationSubscription?.cancel();
    super.dispose();
  }

  Future<void> load() async {
    try {
      final value = await service.assignment(widget.assignmentId);
      if (!mounted) return;
      setState(() {
        assignment = value;
        busy = false;
        error = null;
      });
      if (_sharesLocation(value.status)) await _startLocationSharing();
    } catch (e) {
      if (mounted) {
        setState(() {
          busy = false;
          error = '$e'.replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assignment Details')),
      body: busy
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_outlined, size: 52),
                    const SizedBox(height: 12),
                    Text(error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: load,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            )
          : _content(assignment!),
    );
  }

  Widget _content(ResponderAssignment item) {
    final next = _nextStatus(item.status);
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.incidentNumber,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Chip(label: Text(_label(item.status))),
                  ],
                ),
                const SizedBox(height: 14),
                _row(Icons.groups_outlined, item.teamName),
                _row(Icons.place_outlined, item.location),
                _row(
                  Icons.description_outlined,
                  item.description.isEmpty
                      ? 'No description provided.'
                      : item.description,
                ),
                _row(Icons.flag_outlined, '${_label(item.priority)} priority'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Icon(
                  sharing ? Icons.location_on : Icons.location_off,
                  color: sharing ? Colors.green : const Color(0xFF64748B),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    sharing
                        ? 'Live location sharing is active for this incident.'
                        : next == null
                        ? 'Location sharing ended when the response was completed.'
                        : 'Location sharing starts after accepting the assignment.',
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_sharesLocation(item.status)) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => LiveTrackingScreen(
                  session: widget.session,
                  assignmentId: widget.assignmentId,
                  residentMode: false,
                ),
              ),
            ),
            icon: const Icon(Icons.map_outlined),
            label: const Text('Open live map'),
          ),
        ],
        if (next != null) ...[
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: busy ? null : () => _advance(next),
            icon: Icon(
              next == 'completed' ? Icons.task_alt : Icons.arrow_forward,
            ),
            label: Text(_buttonLabel(next)),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
        if (item.status == 'assigned')
          TextButton(
            onPressed: busy ? null : _decline,
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Decline assignment'),
          ),
      ],
    );
  }

  Widget _row(IconData icon, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 21, color: const Color(0xFF0874C9)),
        const SizedBox(width: 10),
        Expanded(child: Text(value, style: const TextStyle(height: 1.4))),
      ],
    ),
  );

  Future<void> _advance(String status) async {
    var notes = '';

    if (status == 'completed') {
      final completionNotes = await _completionNotes();

      if (completionNotes == null) {
        return;
      }

      notes = completionNotes;
    }
    setState(() => busy = true);
    try {
      await service.updateStatus(
        widget.assignmentId,
        status,
        notes: notes.trim(),
      );
      if (status == 'completed' || status == 'declined') {
        await _stopLocationSharing();
      }
      await load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to ${_label(status)}.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _decline() async {
    final confirmed = await showAppConfirmation(
      context,
      title: 'Decline this assignment?',
      message:
          'The barangay dispatch team will need to assign another responder.',
      confirmLabel: 'Decline',
      destructive: true,
    );
    if (confirmed && mounted) await _advance('declined');
  }

  Future<String?> _completionNotes() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Complete response'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: TextFormField(
              controller: controller,
              autofocus: true,
              minLines: 3,
              maxLines: 5,
              maxLength: 1000,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Completion summary',
                hintText: 'Describe the action taken and the final condition.',
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'A completion summary is required.';
                }

                return null;
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () {
              if (!(formKey.currentState?.validate() ?? false)) {
                return;
              }

              Navigator.pop(dialogContext, controller.text.trim());
            },
            icon: const Icon(Icons.task_alt),
            label: const Text('Complete response'),
          ),
        ],
      ),
    );

    controller.dispose();
    return result;
  }

  Future<void> _startLocationSharing() async {
    if (sharing || locationSubscription != null) return;
    if (!await Geolocator.isLocationServiceEnabled()) return;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }
    if (mounted) setState(() => sharing = true);
    locationSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen((position) async {
          try {
            await service.updateLocation(
              assignmentId: widget.assignmentId,
              latitude: position.latitude,
              longitude: position.longitude,
              accuracy: position.accuracy,
            );
          } catch (_) {
            // A later position update retries automatically.
          }
        });
  }

  Future<void> _stopLocationSharing() async {
    await locationSubscription?.cancel();
    locationSubscription = null;
    if (mounted) setState(() => sharing = false);
  }

  bool _sharesLocation(String status) =>
      const ['accepted', 'en_route', 'on_scene'].contains(status);

  String? _nextStatus(String status) => const {
    'assigned': 'accepted',
    'accepted': 'en_route',
    'en_route': 'on_scene',
    'on_scene': 'completed',
  }[status];

  String _buttonLabel(String status) =>
      const {
        'accepted': 'Accept assignment',
        'en_route': 'Start travel',
        'on_scene': 'Mark on scene',
        'completed': 'Complete response',
      }[status] ??
      'Update status';
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
