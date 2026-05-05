// lib/core/services/notification_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final _db    = FirebaseFirestore.instance;
  static final _fcm   = FirebaseMessaging.instance;
  static final _local = FlutterLocalNotificationsPlugin();

  // ══════════════════════════════════════════════════════════════════
  // INIT
  // ══════════════════════════════════════════════════════════════════

  static Future<void> init() async {
    tz.initializeTimeZones();

    // ── Local notifications ──
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios     = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _local.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    // ── Android channel ──
    const channel = AndroidNotificationChannel(
      'auction_channel',
      'إشعارات المزادات',
      description: 'كل إشعارات تطبيق AMS-DZ',
      importance:  Importance.high,
    );
    await _local
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // ── FCM permissions ──
    await _fcm.requestPermission(
      alert:       true,
      badge:       true,
      sound:       true,
      provisional: false,
    );

    // ── Foreground: يظهر الإشعار كـ local notification ──
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification == null) return;
      _local.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'auction_channel',
            'إشعارات المزادات',
            channelDescription: 'كل إشعارات تطبيق AMS-DZ',
            importance: Importance.high,
            priority:   Priority.high,
            icon:       '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    });
  }

  // ══════════════════════════════════════════════════════════════════
  // FCM TOKEN
  // ══════════════════════════════════════════════════════════════════

  /// استدعيها مباشرة بعد تسجيل الدخول
  static Future<void> saveFcmToken(String userId) async {
    try {
      final token = await _fcm.getToken();
      if (token == null) return;
      await _db.collection('users').doc(userId).update({
        'fcmToken':        token,
        'fcmTokenUpdated': FieldValue.serverTimestamp(),
      });
      // ✅ تجديد تلقائي لما يتغير التوكن
      _fcm.onTokenRefresh.listen((newToken) {
        _db.collection('users').doc(userId).update({
          'fcmToken':        newToken,
          'fcmTokenUpdated': FieldValue.serverTimestamp(),
        });
      });
    } catch (_) {}
  }

  /// استدعيها عند تسجيل الخروج
  static Future<void> clearFcmToken(String userId) async {
    try {
      await _db.collection('users').doc(userId).update({
        'fcmToken': FieldValue.delete(),
      });
      await _fcm.deleteToken();
    } catch (_) {}
  }

  // ══════════════════════════════════════════════════════════════════
  // PRIVATE — Firestore in-app sender
  // الـ Cloud Function تسمع على notifications collection
  // وتبعت FCM push تلقائياً لكل document جديد
  // ══════════════════════════════════════════════════════════════════

  static Future<void> _send({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? auctionId,
  }) async {
    await _db.collection('notifications').add({
      'userId':    userId,
      'title':     title,
      'message':   message,
      'type':      type,
      'isRead':    false,
      'createdAt': FieldValue.serverTimestamp(),
      if (auctionId != null) 'auctionId': auctionId,
    });
  }

  // ══════════════════════════════════════════════════════════════════
  // 1. KYC
  // ══════════════════════════════════════════════════════════════════

  static Future<void> onKycSubmitted({
    required String adminId,
    required String sellerName,
    required String sellerId,
  }) async {
    await _send(
      userId:  adminId,
      title:   '📄 وثائق جديدة للمراجعة',
      message: 'البائع $sellerName رفع وثائقه للمراجعة',
      type:    'kycSubmitted',
    );
  }

  static Future<void> onKycApproved({required String sellerId}) async {
    await _send(
      userId:  sellerId,
      title:   '✅ تم قبول حسابك',
      message: 'مبروك! تم قبول حسابك، يمكنك الآن إنشاء مزادات',
      type:    'kycApproved',
    );
  }

  static Future<void> onKycRejected({
    required String sellerId,
    required String reason,
  }) async {
    await _send(
      userId:  sellerId,
      title:   '❌ تم رفض طلبك',
      message: 'تم رفض طلب التحقق. السبب: $reason',
      type:    'kycRejected',
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // 2. AUCTION LIFECYCLE
  // ══════════════════════════════════════════════════════════════════

  static Future<void> onAuctionSubmitted({
    required String adminId,
    required String auctionTitle,
    required String auctionId,
  }) async {
    await _send(
      userId:    adminId,
      title:     '🆕 مزاد جديد للمراجعة',
      message:   '"$auctionTitle" يحتاج مراجعة وموافقة',
      type:      'auctionSubmitted',
      auctionId: auctionId,
    );
  }

  static Future<void> onAuctionApproved({
    required String sellerId,
    required String auctionTitle,
    required String auctionId,
  }) async {
    await _send(
      userId:    sellerId,
      title:     '✅ تم قبول مزادك',
      message:   'تم قبول مزاد "$auctionTitle" وسيُنشر قريباً',
      type:      'auctionApproved',
      auctionId: auctionId,
    );
  }

  static Future<void> onAuctionRejected({
    required String sellerId,
    required String auctionTitle,
    required String auctionId,
    required String reason,
  }) async {
    await _send(
      userId:    sellerId,
      title:     '❌ تم رفض مزادك',
      message:   'تم رفض مزاد "$auctionTitle". السبب: $reason',
      type:      'auctionRejected',
      auctionId: auctionId,
    );
  }

  static Future<void> onPriceAdjusted({
    required String sellerId,
    required String auctionTitle,
    required String auctionId,
    required double newPrice,
    required String note,
  }) async {
    await _send(
      userId:    sellerId,
      title:     '✏️ تم تعديل سعر مزادك',
      message:   'عدّل المسؤول سعر "$auctionTitle" إلى ${newPrice.toStringAsFixed(0)} DZD. ملاحظة: $note',
      type:      'priceAdjusted',
      auctionId: auctionId,
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // 3. CATEGORIES
  // ══════════════════════════════════════════════════════════════════

  static Future<void> saveUserInterests({
    required String userId,
    required List<String> categories,
  }) async {
    await _db.collection('users').doc(userId).update({
      'interests': categories,
    });
  }

  static Future<void> notifyInterestedUsers({
    required String category,
    required String auctionTitle,
    required String auctionId,
    required String organizerId,
  }) async {
    final snap = await _db
        .collection('users')
        .where('interests', arrayContains: category)
        .get();

    final batch = _db.batch();
    for (final doc in snap.docs) {
      if (doc.id == organizerId) continue;
      final notifRef = _db.collection('notifications').doc();
      batch.set(notifRef, {
        'userId':    doc.id,
        'title':     '📢 مزاد جديد في $category',
        'message':   '"$auctionTitle" — مزاد جديد في فئة اهتمامك',
        'type':      'newAuctionCategory',
        'isRead':    false,
        'createdAt': FieldValue.serverTimestamp(),
        'auctionId': auctionId,
      });
    }
    await batch.commit();
  }

  // ══════════════════════════════════════════════════════════════════
  // 4. REMINDERS — Local Notifications
  // ══════════════════════════════════════════════════════════════════

  static Future<void> scheduleAuctionReminders({
    required String auctionId,
    required String auctionTitle,
    required DateTime startTime,
  }) async {
    final now = DateTime.now();
    final reminders = [
      (id: auctionId.hashCode,     title: '📅 باقي يوم على المزاد',  body: '"$auctionTitle" يبدأ غداً',          time: startTime.subtract(const Duration(days: 1))),
      (id: auctionId.hashCode + 1, title: '⏳ باقي ساعة على المزاد', body: '"$auctionTitle" يبدأ بعد ساعة',       time: startTime.subtract(const Duration(hours: 1))),
      (id: auctionId.hashCode + 2, title: '🔥 المزاد قريب يبدأ',     body: '"$auctionTitle" يبدأ بعد 30 دقيقة',  time: startTime.subtract(const Duration(minutes: 30))),
      (id: auctionId.hashCode + 3, title: '🚨 بدأ المزاد الآن',      body: '"$auctionTitle" انطلق — زايد الآن!', time: startTime),
    ];
    for (final r in reminders) {
      if (r.time.isAfter(now)) {
        await _scheduleLocal(id: r.id, title: r.title, body: r.body, time: r.time);
      }
    }
  }

  static Future<void> _scheduleLocal({
    required int id, required String title,
    required String body, required DateTime time,
  }) async {
    await _local.zonedSchedule(
      id, title, body,
      tz.TZDateTime.from(time, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'auction_reminders', 'تذكيرات المزادات',
          channelDescription: 'إشعارات تذكير بمواعيد المزادات',
          importance: Importance.high, priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // 5. BIDDING
  // ══════════════════════════════════════════════════════════════════

  static Future<void> onNewBid({
    required String auctionId,
    required String auctionTitle,
    required String sellerId,
    required String previousBidderId,
    required String newBidderId,
    required double newAmount,
  }) async {
    final batch = _db.batch();
    if (previousBidderId.isNotEmpty && previousBidderId != newBidderId) {
      batch.set(_db.collection('notifications').doc(), {
        'userId':    previousBidderId,
        'title':     '💸 تم تجاوز عرضك',
        'message':   'قدّم شخص آخر عرضاً بـ ${newAmount.toStringAsFixed(0)} DZD في "$auctionTitle"',
        'type':      'bidOutbid',
        'isRead':    false,
        'createdAt': FieldValue.serverTimestamp(),
        'auctionId': auctionId,
      });
    }
    if (sellerId != newBidderId) {
      batch.set(_db.collection('notifications').doc(), {
        'userId':    sellerId,
        'title':     '📈 عرض جديد على مزادك',
        'message':   'تم تقديم عرض بـ ${newAmount.toStringAsFixed(0)} DZD في "$auctionTitle"',
        'type':      'newBid',
        'isRead':    false,
        'createdAt': FieldValue.serverTimestamp(),
        'auctionId': auctionId,
      });
    }
    await batch.commit();
  }

  // ══════════════════════════════════════════════════════════════════
  // 6. END OF AUCTION
  // ══════════════════════════════════════════════════════════════════

  static Future<void> onAuctionEnded({
    required String auctionId,
    required String auctionTitle,
    required String winnerId,
    required String sellerId,
    required double finalPrice,
  }) async {
    final batch = _db.batch();
    batch.set(_db.collection('notifications').doc(), {
      'userId':    winnerId,
      'title':     '🏆 مبروك! فزت في المزاد',
      'message':   'فزت بـ "$auctionTitle" بسعر ${finalPrice.toStringAsFixed(0)} DZD',
      'type':      'winner',
      'isRead':    false,
      'createdAt': FieldValue.serverTimestamp(),
      'auctionId': auctionId,
    });
    batch.set(_db.collection('notifications').doc(), {
      'userId':    sellerId,
      'title':     '💰 تم بيع عنصرك',
      'message':   'تم بيع "$auctionTitle" بسعر ${finalPrice.toStringAsFixed(0)} DZD',
      'type':      'auctionEnded',
      'isRead':    false,
      'createdAt': FieldValue.serverTimestamp(),
      'auctionId': auctionId,
    });
    await batch.commit();
  }

  // ══════════════════════════════════════════════════════════════════
  // STREAM & READ HELPERS
  // ══════════════════════════════════════════════════════════════════

  static Stream<List<Map<String, dynamic>>> streamNotifications(String userId) =>
      _db.collection('notifications')
          .where('userId', isEqualTo: userId)
          .snapshots()
          .map((s) {
        final docs = s.docs.map((d) => {'id': d.id, ...d.data()}).toList();
        docs.sort((a, b) {
          final aTime = a['createdAt'];
          final bTime = b['createdAt'];
          if (aTime == null || bTime == null) return 0;
          return (bTime as Timestamp).compareTo(aTime as Timestamp);
        });
        return docs;
      });

  static Stream<int> streamUnreadCount(String userId) =>
      _db.collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .snapshots()
          .map((s) => s.docs.length);

  static Future<void> markAsRead(String notifId) async {
    await _db.collection('notifications').doc(notifId).update({'isRead': true});
  }

  static Future<void> markAllAsRead(String userId) async {
    final snap = await _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}