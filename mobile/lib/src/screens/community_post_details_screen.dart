import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/community_post_service.dart';
import '../config/api_config.dart';

class CommunityPostDetailsScreen extends StatefulWidget {
  const CommunityPostDetailsScreen({
    super.key,
    required this.session,
    required this.postId,
  });

  final AuthSession session;
  final int postId;

  @override
  State<CommunityPostDetailsScreen> createState() =>
      _CommunityPostDetailsScreenState();
}

class _CommunityPostDetailsScreenState
    extends State<CommunityPostDetailsScreen> {
  final _service = const CommunityPostService();
  Map<String, dynamic>? _post;
  String? _error;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final post = await _service.show(widget.session, widget.postId);
      if (mounted) {
        setState(() => _post = post);
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Details'),
        actions: [
          if (_post?['can_delete'] == true)
            IconButton(
              onPressed: _deleting ? null : _confirmDelete,
              tooltip: 'Delete post',
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            )
          : _post == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${_post!['post_number']}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              _StatusChip('${_post!['status']}'),
                            ],
                          ),
                          const SizedBox(height: 18),
                          if ((_post!['photos'] as List? ?? const [])
                              .isNotEmpty) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.network(
                                '${ApiConfig.residentPostPhoto}?id=${(_post!['photos'] as List).first['id']}',
                                headers: {
                                  'Authorization':
                                      'Bearer ${widget.session.token}',
                                },
                                width: double.infinity,
                                height: 230,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      height: 150,
                                      alignment: Alignment.center,
                                      color: Colors.grey.shade100,
                                      child: const Text('Unable to load photo'),
                                    ),
                              ),
                            ),
                            const SizedBox(height: 18),
                          ],
                          Text(
                            '${_post!['title']}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text('${_post!['content']}'),
                          if ((_post!['location_name'] ?? '')
                              .toString()
                              .isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                const Icon(Icons.place_outlined, size: 19),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text('${_post!['location_name']}'),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),
                          _DetailRow(
                            label: 'Category',
                            value: _label('${_post!['category']}'),
                          ),
                          _DetailRow(
                            label: 'Submitted',
                            value: _phTime(_post!['submitted_at']),
                          ),
                          if (_post!['reviewed_at'] != null)
                            _DetailRow(
                              label: 'Reviewed',
                              value: _phTime(_post!['reviewed_at']),
                            ),
                          if (_post!['published_at'] != null)
                            _DetailRow(
                              label: 'Published',
                              value: _phTime(_post!['published_at']),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if ((_post!['review_notes'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: const Icon(Icons.rate_review_outlined),
                        title: const Text('Barangay review notes'),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 7),
                          child: Text('${_post!['review_notes']}'),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  const Text(
                    'Status History',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  ...(_post!['status_history'] as List? ?? const []).map((
                    item,
                  ) {
                    final row = item as Map<String, dynamic>;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.history),
                      title: Text(
                        '${row['new_status']}'
                            .replaceAll('_', ' ')
                            .toUpperCase(),
                      ),
                      subtitle: Text(
                        '${row['notes'] ?? ''}\n${_phTime(row['created_at'])}',
                      ),
                      isThreeLine: row['notes'] != null,
                    );
                  }),
                  if (_post?['can_delete'] == true) ...[
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: _deleting ? null : _confirmDelete,
                      icon: _deleting
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.delete_outline),
                      label: Text(_deleting ? 'Deleting…' : 'Delete post'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade200),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this post?'),
        content: const Text(
          'This permanently removes the post and its review history. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      final message = await _service.delete(widget.session, widget.postId);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  String _label(String value) {
    if (value.isEmpty || value == 'null') return 'Not provided';
    return value
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  String _phTime(dynamic value) {
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) return 'Not available';
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
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.status);

  final String status;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
      ),
    );
  }
}
