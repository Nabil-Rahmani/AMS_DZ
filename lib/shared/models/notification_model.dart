// lib/shared/models/notification_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  kycSubmitted,      // بائع رفع وثائق
  kycApproved,       // قبول KYC
  kycRejected,       // رفض KYC
  auctionSubmitted,  // مزاد جديد للمراجعة
  auctionApproved,   // قبول مزاد
  auctionRejected,   // رفض مزاد
  priceAdjusted,     // تعديل سعر
  newBid,            // عرض جديد
  bidOutbid,         // تم تجاوز عرضك
  auctionStarted,    // بدأ المزاد
  auctionEnded,      // انتهى المزاد
  winner,            // فائز
  depositPaid,       // دفع ضمان
  depositRefunded,   // إرجاع ضمان
  newAuctionCategory,// مزاد جديد في فئة مهتم بها
  reminderDay,       // تذكير قبل يوم
  reminderHour,      // تذكير قبل ساعة
  reminderThirty,    // تذكير قبل 30 دقيقة
}

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;
  final String? auctionId;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.auctionId,
  });

  factory NotificationModel.fromMap(String id, Map<String, dynamic> m) =>
      NotificationModel(
        id:        id,
        userId:    m['userId'] ?? '',
        title:     m['title'] ?? '',
        message:   m['message'] ?? '',
        type:      NotificationType.values.byName(m['type'] ?? 'newBid'),
        isRead:    m['isRead'] ?? false,
        createdAt: (m['createdAt'] as Timestamp).toDate(),
        auctionId: m['auctionId'],
      );

  Map<String, dynamic> toMap() => {
    'userId':    userId,
    'title':     title,
    'message':   message,
    'type':      type.name,
    'isRead':    isRead,
    'createdAt': FieldValue.serverTimestamp(),
    if (auctionId != null) 'auctionId': auctionId,
  };
}