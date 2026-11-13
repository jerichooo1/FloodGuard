import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_service.dart';

class CommunityPostService {
  const CommunityPostService();

  Map<String, String> _headers(AuthSession session) => {
    'Authorization': 'Bearer ${session.token}',
  };

  Future<List<Map<String, dynamic>>> list(AuthSession session) async {
    final response = await http.get(
      Uri.parse(ApiConfig.residentPosts),
      headers: _headers(session),
    );
    final body = _decode(response);
    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message']?.toString() ?? 'Unable to load posts.');
    }
    return (body['data'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  Future<Map<String, dynamic>> show(AuthSession session, int id) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.residentPostDetails}?id=$id'),
      headers: _headers(session),
    );
    final body = _decode(response);
    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message']?.toString() ?? 'Unable to load post.');
    }
    return body['data'] as Map<String, dynamic>;
  }

  Future<String> delete(AuthSession session, int id) async {
    final response = await http.delete(
      Uri.parse(ApiConfig.deleteResidentPost),
      headers: {..._headers(session), 'Content-Type': 'application/json'},
      body: jsonEncode({'post_id': id}),
    );
    final body = _decode(response);
    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message']?.toString() ?? 'Unable to delete post.');
    }
    return body['message']?.toString() ?? 'Your post was deleted.';
  }

  Future<String> create({
    required AuthSession session,
    required String category,
    required String title,
    required String content,
    required String photoPath,
    String? locationName,
    double? latitude,
    double? longitude,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(ApiConfig.createResidentPost),
    );
    request.headers.addAll(_headers(session));
    request.fields.addAll({
      'category': category,
      'title': title,
      'content': content,
      if (locationName != null && locationName.trim().isNotEmpty)
        'location_name': locationName.trim(),
      if (latitude != null) 'latitude': '$latitude',
      if (longitude != null) 'longitude': '$longitude',
    });
    request.files.add(await http.MultipartFile.fromPath('photo', photoPath));

    final response = await http.Response.fromStream(await request.send());
    final body = _decode(response);
    if (response.statusCode != 201 || body['success'] != true) {
      throw Exception(body['message']?.toString() ?? 'Unable to submit post.');
    }
    return body['message']?.toString() ??
        'Your post was submitted for barangay review.';
  }

  Map<String, dynamic> _decode(http.Response response) {
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw Exception('The server returned an invalid response.');
    }
  }
}
