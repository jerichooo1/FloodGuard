import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'push_notification_service.dart';

enum AccountRole { resident, responder }

class AuthSession {
  const AuthSession({
    required this.token,
    required this.name,
    required this.email,
    required this.role,
  });
  final String token;
  final String name;
  final String email;
  final AccountRole role;
}

class PasswordResetRequest {
  const PasswordResetRequest({required this.message});

  final String message;
}

class PasswordResetVerification {
  const PasswordResetVerification({
    required this.message,
    required this.resetToken,
  });

  final String message;
  final String resetToken;
}

class ResidentRegistrationResult {
  const ResidentRegistrationResult({
    required this.message,
    required this.emailSent,
  });

  final String message;
  final bool emailSent;
}

class AuthService {
  static const _storage = FlutterSecureStorage();

  Future<AuthSession> login({
    required AccountRole role,
    required String email,
    required String password,
  }) async {
    final endpoint = role == AccountRole.resident
        ? ApiConfig.residentLogin
        : ApiConfig.responderLogin;
    final response = await http
        .post(
          Uri.parse(endpoint),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email.trim(), 'password': password}),
        )
        .timeout(const Duration(seconds: 15));
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message']?.toString() ?? 'Sign in failed.');
    }
    final token = body['access_token']?.toString() ?? '';
    final user = body['user'] is Map<String, dynamic>
        ? body['user'] as Map<String, dynamic>
        : <String, dynamic>{};
    if (token.isEmpty) {
      throw Exception('The server did not return an access token.');
    }
    final session = AuthSession(
      token: token,
      name: user['full_name']?.toString() ?? 'FloodGuard User',
      email: user['email']?.toString() ?? email.trim(),
      role: role,
    );
    await _storage.write(key: 'access_token', value: token);
    await _storage.write(key: 'account_role', value: role.name);
    await _storage.write(key: 'account_name', value: session.name);
    await _storage.write(key: 'account_email', value: session.email);

    if (role == AccountRole.resident) {
      try {
        await PushNotificationService.instance.registerResidentDevice(token);
      } catch (_) {
        // Notification registration must not prevent sign-in.
      }
    }

    return session;
  }

  Future<AuthSession?> restoreSession() async {
    final token = await _storage.read(key: 'access_token');
    final roleName = await _storage.read(key: 'account_role');
    if (token == null || token.isEmpty || roleName == null) return null;

    final role = AccountRole.values.cast<AccountRole?>().firstWhere(
      (value) => value?.name == roleName,
      orElse: () => null,
    );
    if (role == null) {
      await _storage.deleteAll();
      return null;
    }

    final session = AuthSession(
      token: token,
      name: await _storage.read(key: 'account_name') ?? 'FloodGuard User',
      email: await _storage.read(key: 'account_email') ?? '',
      role: role,
    );

    if (role == AccountRole.resident) {
      try {
        await PushNotificationService.instance.registerResidentDevice(token);
      } catch (_) {
        // A network error must not discard a valid saved session.
      }
    }

    return session;
  }

  Future<ResidentRegistrationResult> registerResident({
    required String fullName,
    required String email,
    required String mobileNumber,
    required String address,
    required String password,
    required bool notificationConsent,
    required String proofPath,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(ApiConfig.residentRegister),
    );
    request.fields.addAll({
      'full_name': fullName.trim(),
      'email': email.trim(),
      'mobile_number': mobileNumber.trim(),
      'address_line': address.trim(),
      'password': password,
      'push_notifications_enabled': notificationConsent ? 'true' : 'false',
    });
    request.files.add(
      await http.MultipartFile.fromPath('residency_proof', proofPath),
    );
    final streamed = await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamed);
    final body = _jsonBody(response);
    if (response.statusCode != 201 || body['success'] != true) {
      throw Exception(body['message']?.toString() ?? 'Registration failed.');
    }
    return ResidentRegistrationResult(
      message: body['message']?.toString() ?? 'Account created.',
      emailSent: body['email_sent'] == true,
    );
  }

  Future<String> verifyResidentEmail({
    required String email,
    required String code,
  }) async {
    final response = await http
        .post(
          Uri.parse(ApiConfig.residentVerifyEmail),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email.trim(), 'code': code.trim()}),
        )
        .timeout(const Duration(seconds: 15));
    final body = _jsonBody(response);
    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(
        body['message']?.toString() ?? 'Unable to verify the email.',
      );
    }
    return body['message']?.toString() ?? 'Email verified.';
  }

  Future<String> resendResidentVerification(String email) async {
    final response = await http
        .post(
          Uri.parse(ApiConfig.residentResendVerification),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email.trim()}),
        )
        .timeout(const Duration(seconds: 15));
    final body = _jsonBody(response);
    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(
        body['message']?.toString() ??
            'Unable to resend the verification code.',
      );
    }
    return body['message']?.toString() ?? 'A new code was sent.';
  }

  Future<PasswordResetRequest> requestPasswordReset(String email) async {
    final response = await http
        .post(
          Uri.parse(ApiConfig.residentForgotPassword),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email.trim()}),
        )
        .timeout(const Duration(seconds: 15));
    final body = _jsonBody(response);
    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(
        body['message']?.toString() ?? 'Unable to request a password reset.',
      );
    }
    return PasswordResetRequest(
      message:
          body['message']?.toString() ??
          'A password-reset code has been prepared.',
    );
  }

  Future<PasswordResetVerification> verifyPasswordResetCode({
    required String email,
    required String code,
  }) async {
    final response = await http
        .post(
          Uri.parse(ApiConfig.residentVerifyResetCode),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email.trim(), 'code': code.trim()}),
        )
        .timeout(const Duration(seconds: 15));
    final body = _jsonBody(response);
    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(
        body['message']?.toString() ?? 'Unable to verify the code.',
      );
    }
    final resetToken = body['reset_token']?.toString() ?? '';
    if (resetToken.isEmpty) {
      throw Exception('The server did not create a password-reset session.');
    }
    return PasswordResetVerification(
      message: body['message']?.toString() ?? 'Code verified.',
      resetToken: resetToken,
    );
  }

  Future<String> resetPassword({
    required String resetToken,
    required String password,
  }) async {
    final response = await http
        .post(
          Uri.parse(ApiConfig.residentResetPassword),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'reset_token': resetToken, 'password': password}),
        )
        .timeout(const Duration(seconds: 15));
    final body = _jsonBody(response);
    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(
        body['message']?.toString() ?? 'Unable to reset the password.',
      );
    }
    return body['message']?.toString() ?? 'Password changed.';
  }

  Future<void> logout(AuthSession session) async {
    if (session.role == AccountRole.resident) {
      try {
        await PushNotificationService.instance.revokeResidentDevice(
          session.token,
        );
      } catch (_) {
        // Continue signing out if device revocation temporarily fails.
      }
    }

    final endpoint = session.role == AccountRole.resident
        ? ApiConfig.residentLogout
        : ApiConfig.responderLogout;
    try {
      await http
          .post(
            Uri.parse(endpoint),
            headers: {'Authorization': 'Bearer ${session.token}'},
          )
          .timeout(const Duration(seconds: 10));
    } finally {
      await _storage.deleteAll();
    }
  }

  Map<String, dynamic> _jsonBody(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {
      // The caller receives a clear error instead of a JSON parsing exception.
    }
    throw Exception('The server returned an invalid response.');
  }
}
