import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../services/auth_service.dart';
import '../services/community_post_service.dart';
import '../ui/app_ui.dart';

class CreateCommunityPostScreen extends StatefulWidget {
  const CreateCommunityPostScreen({super.key, required this.session});

  final AuthSession session;

  @override
  State<CreateCommunityPostScreen> createState() =>
      _CreateCommunityPostScreenState();
}

class _CreateCommunityPostScreenState extends State<CreateCommunityPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _content = TextEditingController();
  final _location = TextEditingController();
  final _service = const CommunityPostService();

  String _category = 'spillway_update';
  XFile? _photo;
  Position? _position;
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final selected = await ImagePicker().pickImage(
      source: source,
      imageQuality: 78,
      maxWidth: 1600,
    );
    if (selected != null && mounted) {
      setState(() => _photo = selected);
    }
  }

  Future<void> _captureLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission was not granted.');
      }
      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() => _position = position);
      }
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
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_photo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a photograph to your post.')),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final message = await _service.create(
        session: widget.session,
        category: _category,
        title: _title.text.trim(),
        content: _content.text.trim(),
        photoPath: _photo!.path,
        locationName: _location.text,
        latitude: _position?.latitude,
        longitude: _position?.longitude,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Public Post')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const AppPageHeader(
                eyebrow: 'Community update',
                title: 'Create a public post',
                subtitle: 'Share a useful local update. Barangay personnel will review it before publication.',
                icon: Icons.campaign_outlined,
                color: AppColors.teal,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'spillway_update',
                    child: Text('Spillway update'),
                  ),
                  DropdownMenuItem(
                    value: 'flood_update',
                    child: Text('Flood update'),
                  ),
                  DropdownMenuItem(
                    value: 'road_condition',
                    child: Text('Road condition'),
                  ),
                  DropdownMenuItem(
                    value: 'community_update',
                    child: Text('Community update'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _category = value);
                  }
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(
                  labelText: 'Post title',
                  prefixIcon: Icon(Icons.title),
                ),
                maxLength: 150,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a post title.'
                    : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _content,
                minLines: 5,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'What is happening?',
                  alignLabelWithHint: true,
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Describe the update.'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _location,
                decoration: const InputDecoration(
                  labelText: 'Location name (optional)',
                  prefixIcon: Icon(Icons.place_outlined),
                ),
                maxLength: 180,
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickPhoto(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Camera'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickPhoto(ImageSource.gallery),
                      icon: const Icon(Icons.photo_outlined),
                      label: const Text('Gallery'),
                    ),
                  ),
                ],
              ),
              if (_photo != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Photo: ${_photo!.name}',
                    style: const TextStyle(color: Color(0xFF059669)),
                  ),
                ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _captureLocation,
                icon: const Icon(Icons.my_location),
                label: Text(
                  _position == null
                      ? 'Attach current GPS location'
                      : 'GPS location attached',
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _busy ? null : _submit,
                icon: const Icon(Icons.send_outlined),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(_busy ? 'Submitting...' : 'Submit for review'),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'This post will become public only after barangay approval.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
