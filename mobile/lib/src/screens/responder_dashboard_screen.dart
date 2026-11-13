import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/responder_service.dart';
import '../ui/app_ui.dart';
import 'responder_assignment_screen.dart';
import 'welcome_screen.dart';

class ResponderDashboardScreen extends StatefulWidget {
  const ResponderDashboardScreen({super.key, required this.session});
  final AuthSession session;

  @override
  State<ResponderDashboardScreen> createState() =>
      _ResponderDashboardScreenState();
}

class _ResponderDashboardScreenState extends State<ResponderDashboardScreen> {
  late final ResponderService service = ResponderService(widget.session);
  late Future<List<ResponderAssignment>> future = service.assignments();
  bool signingOut = false;

  void reload() => setState(() => future = service.assignments());

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Responder Dashboard'),
          actions: [
            IconButton(
              onPressed: signingOut ? null : _logout,
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            reload();
            await future;
          },
          child: FutureBuilder<List<ResponderAssignment>>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return ListView(
                  children: [
                    const SizedBox(height: 140),
                    const Icon(
                      Icons.cloud_off,
                      size: 54,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${snapshot.error}'.replaceFirst('Exception: ', ''),
                      textAlign: TextAlign.center,
                    ),
                    TextButton(
                      onPressed: reload,
                      child: const Text('Try again'),
                    ),
                  ],
                );
              }
              final items = snapshot.data ?? const [];
              if (items.isEmpty) {
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    AppPageHeader(
                      eyebrow: 'Responder account',
                      title: 'Ready, ${widget.session.name.split(' ').first}',
                      subtitle: 'New barangay assignments and status updates appear here.',
                      icon: Icons.health_and_safety_outlined,
                      color: const Color(0xFFF59E0B),
                      useLogo: true,
                    ),
                    const SizedBox(height: 70),
                    const Icon(
                      Icons.assignment_turned_in_outlined,
                      size: 58,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No assignments yet',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Pull down to check again.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                itemCount: items.length + 1,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    final active = items
                        .where((item) => item.status != 'completed')
                        .length;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppPageHeader(
                          eyebrow: 'Responder account',
                          title:
                              'Welcome, ${widget.session.name.split(' ').first}',
                          subtitle:
                              '$active active ${active == 1 ? 'assignment' : 'assignments'} • Pull down to refresh dispatches.',
                          icon: Icons.health_and_safety_outlined,
                          color: const Color(0xFFF59E0B),
                          useLogo: true,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Your assignments',
                          style: TextStyle(
                            color: AppColors.navy,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    );
                  }
                  final item = items[index - 1];
                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        child: Icon(
                          item.immediateDanger
                              ? Icons.warning_amber
                              : Icons.emergency_outlined,
                        ),
                      ),
                      title: Text(
                        item.incidentNumber,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 7),
                        child: Text(
                          '${item.location}\n${_label(item.status)} • ${_label(item.priority)}',
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ResponderAssignmentScreen(
                              session: widget.session,
                              assignmentId: item.id,
                            ),
                          ),
                        );
                        reload();
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  String _label(String value) => value
      .replaceAll('_', ' ')
      .split(' ')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');

  Future<void> _logout() async {
    final confirmed = await showAppConfirmation(
      context,
      title: 'End this responder session?',
      message: 'Sign out only when you are finished. Active location sharing is managed by each assignment.',
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
