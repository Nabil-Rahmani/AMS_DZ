import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📩 إشعار في الخلفية: ${message.notification?.title}');
}

class FirebaseMessagingService {
  static final _messaging = FirebaseMessaging.instance;
  static final _local     = FlutterLocalNotificationsPlugin();

  // ✅ flag باش ما نعيدوش الـ init أكثر من مرة
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // 1. طلب إذن الإشعارات
    await _messaging.requestPermission(
      alert:       true,
      badge:       true,
      sound:       true,
      provisional: false,
    );

    // 2. إعداد الإشعارات المحلية
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios     = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    // 3. إعداد Android channel
    const channel = AndroidNotificationChannel(
      'high_importance_channel',
      'إشعارات AMS-DZ',
      description: 'إشعارات المزادات والتحديثات',
      importance:  Importance.high,
    );
    await _local
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 4. إشعارات Foreground
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;
      _local.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'إشعارات AMS-DZ',
            importance: Importance.high,
            priority:   Priority.high,
            icon:       '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    });

    // 5. Handler الخلفية
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 6. تحديث الـ token تلقائياً
    _messaging.onTokenRefresh.listen(_updateToken);
  }

  // ✅ يتستدعى مرة واحدة بعد تسجيل الدخول
  static Future<void> onLogin() async {
    await _saveToken();
  }

  static Future<void> onLogout() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _messaging.deleteToken();
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'fcmToken': FieldValue.delete()});
  }

  static Future<void> _saveToken() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final token = await _messaging.getToken();
    if (token == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'fcmToken':        token,
      'fcmTokenUpdated': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> _updateToken(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'fcmToken':        token,
      'fcmTokenUpdated': FieldValue.serverTimestamp(),
    });
  }
}
