class ApiConfig {
  ApiConfig._();

  // Android Emulator -> Windows/XAMPP host.
  static const String baseUrl = 'https://floodguard.site';
  static const String publicLatest =
      '$baseUrl/api/v1/public/monitoring/latest.php';
  static const String residentLogin = '$baseUrl/api/v1/mobile/auth/login.php';
  static const String residentRegister =
      '$baseUrl/api/v1/mobile/auth/register.php';
  static const String residentForgotPassword =
      '$baseUrl/api/v1/mobile/auth/forgot_password.php';
  static const String residentVerifyResetCode =
      '$baseUrl/api/v1/mobile/auth/verify_reset_code.php';
  static const String residentResetPassword =
      '$baseUrl/api/v1/mobile/auth/reset_password.php';
  static const String residentVerifyEmail =
      '$baseUrl/api/v1/mobile/auth/verify_email.php';
  static const String residentResendVerification =
      '$baseUrl/api/v1/mobile/auth/resend_verification.php';
  static const String responderLogin =
      '$baseUrl/api/v1/responder/auth/login.php';
  static const String residentLogout = '$baseUrl/api/v1/mobile/auth/logout.php';
  static const String responderLogout =
      '$baseUrl/api/v1/responder/auth/logout.php';
  static const String residentReports =
      '$baseUrl/api/v1/mobile/reports/index.php';
  static const String residentPosts = '$baseUrl/api/v1/mobile/posts/index.php';
  static const String createResidentPost =
      '$baseUrl/api/v1/mobile/posts/store.php';
  static const String residentPostDetails =
      '$baseUrl/api/v1/mobile/posts/show.php';
  static const String residentPostPhoto =
      '$baseUrl/api/v1/mobile/posts/photo.php';
  static const String deleteResidentPost =
      '$baseUrl/api/v1/mobile/posts/delete.php';
  static const String residentNotifications =
      '$baseUrl/api/v1/mobile/push/notifications.php';
  static const String residentPushDevices =
      '$baseUrl/api/v1/mobile/push/devices.php';
  static const String readNotification = '$baseUrl/api/v1/mobile/push/read.php';
  static const String responderAssignments =
      '$baseUrl/api/v1/responder/assignments/index.php';
  static const String responderAssignment =
      '$baseUrl/api/v1/responder/assignments/show.php';
  static const String responderUpdateStatus =
      '$baseUrl/api/v1/responder/assignments/update_status.php';
  static const String responderUpdateLocation =
      '$baseUrl/api/v1/responder/location/update.php';
  static const String residentLocationConsent =
      '$baseUrl/api/v1/mobile/location/consent.php';
  static const String residentUpdateLocation =
      '$baseUrl/api/v1/mobile/location/update.php';
  static const String activeResidentTracking =
      '$baseUrl/api/v1/mobile/tracking/active.php';
  static const String trackingLatest = '$baseUrl/api/v1/tracking/latest.php';
}
