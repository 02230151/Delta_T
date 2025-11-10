import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  // Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    await _createNotificationChannel();

    _isInitialized = true;
  }

  // Create notification channel for Android
  Future<void> _createNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      'delta_t_notifications',
      'Delta T Notifications',
      description: 'Notifications for study sessions and app updates',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  // Show a notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Request permissions on Android 13+
    final androidImplementation = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      final granted = await androidImplementation.requestNotificationsPermission();
      if (granted != true) {
        debugPrint('Notification permission not granted');
        return;
      }
    }

    // Request permissions on iOS
    final iosImplementation = _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (iosImplementation != null) {
      final granted = await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      if (granted != true) {
        debugPrint('iOS notification permission not granted');
        return;
      }
    }

    const androidDetails = AndroidNotificationDetails(
      'delta_t_notifications', // Channel ID - must match the channel created
      'Delta T Notifications', // Channel name
      channelDescription: 'Notifications for study sessions and app updates',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      showWhen: true,
      ongoing: false,
      autoCancel: true,
      enableLights: true,
      color: const Color(0xFF8B9FDE),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notifications.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
      debugPrint('Notification shown: $title - $body');
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // Handle notification tap if needed
  }

  // Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}

