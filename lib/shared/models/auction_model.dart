import 'package:cloud_firestore/cloud_firestore.dart';

enum AuctionStatus {
  draft,
  submitted,
  approved,
  active,
  ended,
  rejected,
  closed;

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

  final double startingPrice;
  final double? adminAdjustedPrice;
  final double? currentPrice;
  final double? minBidIncrement;

  final DateTime? inspectionDay;
  final DateTime? startTime;
  final DateTime? endDateTime;

  final String? category;
  final String? location;
  final String? imageUrl;
  final List<String>? imageUrls;
  final int itemCount;

  final String? winnerId;
  final String? rejectionReason;
  final String? adminNote;

  final DateTime createdAt;

  final double? depositAmount;
  final List<String>? depositPaidBy;

  // ✅ Dynamic Details حسب الفئة
  final Map<String, dynamic>? details;

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
    this.depositAmount,
    this.depositPaidBy,
    this.details,
  });

  double get effectiveStartingPrice => adminAdjustedPrice ?? startingPrice;
  double get deposit => (adminAdjustedPrice ?? startingPrice) * 0.1;
  bool hasUserPaidDeposit(String uid) => depositPaidBy?.contains(uid) ?? false;

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
          ? (map['adminAdjustedPrice']).toDouble() : null,
      currentPrice: map['currentPrice'] != null
          ? (map['currentPrice']).toDouble() : null,
      minBidIncrement: map['minBidIncrement'] != null
          ? (map['minBidIncrement']).toDouble() : null,
      inspectionDay: map['inspectionDay'] != null
          ? (map['inspectionDay'] as Timestamp).toDate() : null,
      startTime: map['startTime'] != null
          ? (map['startTime'] as Timestamp).toDate() : null,
      endDateTime: map['endTime'] != null
          ? (map['endTime'] as Timestamp).toDate() : null,
      category: map['category'],
      location: map['location'],
      imageUrl: map['imageUrl'],
      imageUrls: map['imageUrls'] != null
          ? List<String>.from(map['imageUrls']) : null,
      itemCount: map['itemCount'] ?? 1,
      winnerId: map['winnerId'],
      rejectionReason: map['rejectionReason'],
      adminNote: map['adminNote'],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate() : DateTime.now(),
      depositAmount: map['depositAmount'] != null
          ? (map['depositAmount']).toDouble() : null,
      depositPaidBy: map['depositPaidBy'] != null
          ? List<String>.from(map['depositPaidBy']) : null,
      // ✅
      details: map['details'] != null
          ? Map<String, dynamic>.from(map['details']) : null,
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
    if (inspectionDay != null) 'inspectionDay': Timestamp.fromDate(inspectionDay!),
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
    if (depositAmount != null) 'depositAmount': depositAmount,
    if (depositPaidBy != null) 'depositPaidBy': depositPaidBy,
    if (details != null) 'details': details,
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
    Map<String, dynamic>? details,
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
      details: details ?? this.details,
    );
  }
}