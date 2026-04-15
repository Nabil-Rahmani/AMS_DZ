import 'package:cloud_firestore/cloud_firestore.dart';

enum AuctionStatus {
  draft,      // مسودة عند البائع
  submitted,  // أرسله البائع للمراجعة
  approved,   // وافق عليه الأدمين + حدد الوقت
  active,     // المزاد شغال الآن
  ended,      // انتهى المزاد
  rejected,   // رفضه الأدمين
  closed;     // أُغلق نهائياً

  String get label {
    switch (this) {
      case AuctionStatus.draft:      return 'مسودة';
      case AuctionStatus.submitted:  return 'قيد المراجعة';
      case AuctionStatus.approved:   return 'مقبول';
      case AuctionStatus.active:     return 'نشط';
      case AuctionStatus.ended:      return 'منتهي';
      case AuctionStatus.rejected:   return 'مرفوض';
      case AuctionStatus.closed:     return 'مغلق';
    }
  }

  static AuctionStatus fromString(String value) =>
      AuctionStatus.values.firstWhere(
            (e) => e.name == value,
        orElse: () => AuctionStatus.draft,
      );
}

class AuctionModel {
  final String id;
  final String title;
  final String description;
  final AuctionStatus status;
  final String organizerId;
  final String organizerName;

  // السعر — البائع يحدده، الأدمين يعدّله إذا لزم
  final double startingPrice;
  final double? adminAdjustedPrice; // الأدمين عدّل السعر
  final double? currentPrice;
  final double? minBidIncrement;

  // التواريخ — الأدمين يحددها
  final DateTime? inspectionDay;  // يوم المعاينة
  final DateTime? startTime;      // بداية المزاد
  final DateTime? endDateTime;    // نهاية المزاد

  // معلومات إضافية
  final String? category;
  final String? location;
  final String? imageUrl;
  final List<String>? imageUrls;
  final int itemCount;

  // نتيجة المزاد
  final String? winnerId;
  final String? rejectionReason;
  final String? adminNote; // ملاحظة الأدمين على السعر

  final DateTime createdAt;

  AuctionModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.organizerId,
    required this.organizerName,
    required this.startingPrice,
    this.adminAdjustedPrice,
    this.currentPrice,
    this.minBidIncrement,
    this.inspectionDay,
    this.startTime,
    this.endDateTime,
    this.category,
    this.location,
    this.imageUrl,
    this.imageUrls,
    this.itemCount = 1,
    this.winnerId,
    this.rejectionReason,
    this.adminNote,
    required this.createdAt,
  });

  // السعر الفعلي = السعر المعدّل من الأدمين أو السعر الأصلي
  double get effectiveStartingPrice => adminAdjustedPrice ?? startingPrice;

  factory AuctionModel.fromMap(Map<String, dynamic> map, String id) {
    return AuctionModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      status: AuctionStatus.fromString(map['status'] ?? 'draft'),
      organizerId: map['organizerId'] ?? '',
      organizerName: map['organizerName'] ?? '',
      startingPrice: (map['startingPrice'] ?? 0.0).toDouble(),
      adminAdjustedPrice: map['adminAdjustedPrice'] != null
          ? (map['adminAdjustedPrice']).toDouble()
          : null,
      currentPrice: map['currentPrice'] != null
          ? (map['currentPrice']).toDouble()
          : null,
      minBidIncrement: map['minBidIncrement'] != null
          ? (map['minBidIncrement']).toDouble()
          : null,
      inspectionDay: map['inspectionDay'] != null
          ? (map['inspectionDay'] as Timestamp).toDate()
          : null,
      startTime: map['startTime'] != null
          ? (map['startTime'] as Timestamp).toDate()
          : null,
      endDateTime: map['endTime'] != null
          ? (map['endTime'] as Timestamp).toDate()
          : null,
      category: map['category'],
      location: map['location'],
      imageUrl: map['imageUrl'],
      imageUrls: map['imageUrls'] != null
          ? List<String>.from(map['imageUrls'])
          : null,
      itemCount: map['itemCount'] ?? 1,
      winnerId: map['winnerId'],
      rejectionReason: map['rejectionReason'],
      adminNote: map['adminNote'],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  factory AuctionModel.fromFirestore(DocumentSnapshot doc) {
    return AuctionModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'description': description,
    'status': status.name,
    'organizerId': organizerId,
    'organizerName': organizerName,
    'startingPrice': startingPrice,
    if (adminAdjustedPrice != null) 'adminAdjustedPrice': adminAdjustedPrice,
    if (currentPrice != null) 'currentPrice': currentPrice,
    if (minBidIncrement != null) 'minBidIncrement': minBidIncrement,
    if (inspectionDay != null)
      'inspectionDay': Timestamp.fromDate(inspectionDay!),
    if (startTime != null) 'startTime': Timestamp.fromDate(startTime!),
    if (endDateTime != null) 'endTime': Timestamp.fromDate(endDateTime!),
    if (category != null) 'category': category,
    if (location != null) 'location': location,
    if (imageUrl != null) 'imageUrl': imageUrl,
    if (imageUrls != null) 'imageUrls': imageUrls,
    'itemCount': itemCount,
    if (winnerId != null) 'winnerId': winnerId,
    if (rejectionReason != null) 'rejectionReason': rejectionReason,
    if (adminNote != null) 'adminNote': adminNote,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  AuctionModel copyWith({
    String? title,
    String? description,
    AuctionStatus? status,
    double? startingPrice,
    double? adminAdjustedPrice,
    double? currentPrice,
    DateTime? inspectionDay,
    DateTime? startTime,
    DateTime? endDateTime,
    String? category,
    String? location,
    String? imageUrl,
    String? winnerId,
    String? rejectionReason,
    String? adminNote,
  }) {
    return AuctionModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      organizerId: organizerId,
      organizerName: organizerName,
      startingPrice: startingPrice ?? this.startingPrice,
      adminAdjustedPrice: adminAdjustedPrice ?? this.adminAdjustedPrice,
      currentPrice: currentPrice ?? this.currentPrice,
      inspectionDay: inspectionDay ?? this.inspectionDay,
      startTime: startTime ?? this.startTime,
      endDateTime: endDateTime ?? this.endDateTime,
      category: category ?? this.category,
      location: location ?? this.location,
      imageUrl: imageUrl ?? this.imageUrl,
      itemCount: itemCount,
      winnerId: winnerId ?? this.winnerId,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      adminNote: adminNote ?? this.adminNote,
      createdAt: createdAt,
    );
  }
}
