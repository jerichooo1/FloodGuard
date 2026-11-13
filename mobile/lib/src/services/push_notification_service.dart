import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  static const AndroidNotificationChannel _warningChannel =
      AndroidNotificationChannel(
        'floodguard_warning',
        'Flood warnings',
        description: 'Warning-level FloodGuard alerts.',
        importance: Importance.high,
      );

  static const AndroidNotificationChannel _criticalChannel =
      AndroidNotificationChannel(
        'floodguard_critical',
        'Critical flood alerts',
        description: 'Urgent critical FloodGuard alerts.',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _residentAccessToken;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;

  Future<void> initialize() async {
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _localNotifications.initialize(settings: initializationSettings);

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(_warningChannel);
    await androidPlugin?.createNotificationChannel(_criticalChannel);

    _foregroundSubscription ??= FirebaseMessaging.onMessage.listen(
      _showForegroundNotification,
    );
    _tokenRefreshSubscription ??= _messaging.onTokenRefresh.listen((token) {
      final accessToken = _residentAccessToken;
      if (accessToken != null && accessToken.isNotEmpty) {
        unawaited(_registerToken(accessToken, token));
      }
    });
  }

  Future<void> registerResidentDevice(String accessToken) async {
    _residentAccessToken = accessToken;
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    final deviceToken = await _messaging.getToken();
    if (deviceToken == null || deviceToken.isEmpty) return;
    await _registerToken(accessToken, deviceToken);
  }

  Future<void> revokeResidentDevice(String accessToken) async {
    final deviceToken = await _messaging.getToken();
    if (deviceToken == null || deviceToken.isEmpty) {
      _residentAccessToken = null;
      return;
    }
    try {
      await http
          .delete(
            Uri.parse(ApiConfig.residentPushDevices),
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'device_token': deviceToken}),
          )
          .timeout(const Duration(seconds: 15));
    } finally {
      _residentAccessToken = null;
    }
  }

  Future<void> _registerToken(String accessToken, String deviceToken) async {
    final response = await http
        .post(
          Uri.parse(ApiConfig.residentPushDevices),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'device_token': deviceToken,
            'platform': Platform.isAndroid ? 'android' : 'ios',
            'device_name': Platform.isAndroid
                ? 'FloodGuard Android device'
                : 'FloodGuard iOS device',
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Unable to register this device for notifications.');
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title']?.toString();
    final body = notification?.body ?? message.data['body']?.toString();
    if (title == null && body == null) return;

    final critical = message.data['alert_level']?.toString() == 'critical';
    final channel = critical ? _criticalChannel : _warningChannel;
    await _localNotifications.show(
      id:
          message.messageId?.hashCode ??
          DateTime.now().millisecondsSinceEpoch.remainder(2147483647),
      title: title ?? 'FloodGuard alert',
      body: body ?? '',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: channel.importance,
          priority: critical ? Priority.max : Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }
}
