import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  late FlutterLocalNotificationsPlugin _localNotifications;
  bool _isInitialized = false;

  Future<void> init() async {
    // Настройка локальных уведомлений только для Android/iOS
    if (Platform.isAndroid || Platform.isIOS) {
      _localNotifications = FlutterLocalNotificationsPlugin();
      
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const settings = InitializationSettings(android: android, iOS: ios);
      await _localNotifications.initialize(settings);
      _isInitialized = true;
      print('✅ Локальные уведомления инициализированы (Android/iOS)');
    } else {
      print('ℹ️ Локальные уведомления не поддерживаются на этой платформе');
      _isInitialized = false;
    }

    // Firebase только для Android/iOS (Windows не поддерживается)
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        final messaging = FirebaseMessaging.instance;
        await messaging.requestPermission();

        final token = await messaging.getToken();
        print('📱 FCM Token: $token');

        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          print('📩 Уведомление получено: ${message.notification?.title}');
          _showNotification(
            title: message.notification?.title ?? 'Veil',
            body: message.notification?.body ?? 'Новое сообщение',
            payload: message.data.toString(),
          );
        });
      } catch (e) {
        print('⚠️ Ошибка Firebase Messaging: $e');
      }
    } else {
      print('ℹ️ Firebase Messaging не поддерживается на этой платформе');
    }
  }

  /// Показать уведомление (Android/iOS)
  Future<void> _showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized || !(Platform.isAndroid || Platform.isIOS)) {
      return;
    }

    const android = AndroidNotificationDetails(
      'veil_channel',
      'Veil Уведомления',
      importance: Importance.max,
      priority: Priority.high,
      color: Color(0xFF6C5CE7),
      icon: '@mipmap/ic_launcher',
    );

    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(android: android, iOS: ios);
    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Показать уведомление на Windows (лог)
  void showWindowsNotification(String title, String body) {
    print('🔔 Windows уведомление: $title - $body');
    // Для реальных уведомлений на Windows используй пакет windows_notification
  }

  /// ТЕСТОВОЕ УВЕДОМЛЕНИЕ
  void testNotification() {
    print('🧪 Тест уведомления запущен');
    
    if (Platform.isAndroid || Platform.isIOS) {
      if (!_isInitialized) {
        print('⚠️ Уведомления не инициализированы');
        return;
      }
      _showNotification(
        title: '🧪 Тест уведомления',
        body: 'Если вы видите это — уведомления работают! 🎉',
      );
    } else {
      showWindowsNotification(
        '🧪 Тест уведомления',
        'Если вы видите это — уведомления работают! 🎉',
      );
    }
  }

  bool get isInitialized => _isInitialized;
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📩 Фоновое уведомление: ${message.notification?.title}');
}