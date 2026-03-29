import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  verificationApproved,
  verificationRejected,
  auctionApproved,
  auctionRejected,
  auctionStarted,
  auctionEnded,
  youWon,
  paymentConfirmed,
}

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final NotificationType type;
  final bool read;
  final DateTime timestamp;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.read,
    required this.timestamp,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: NotificationType.values.firstWhere(
            (e) => e.name == data['type'],
        orElse: () => NotificationType.auctionApproved,
      ),
      read: data['read'] ?? false,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'title': title,
    'message': message,
    'type': type.name,
    'read': read,
    'timestamp': Timestamp.fromDate(timestamp),
  };
}
