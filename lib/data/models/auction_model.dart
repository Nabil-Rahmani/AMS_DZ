import 'package:cloud_firestore/cloud_firestore.dart';

enum AuctionStatus {
  draft,
  submitted,
  approved,
  active,
  ended,
  pending,
  closed,
  rejected;

  String get label {
    switch (this) {
      case AuctionStatus.draft: return 'Draft';
      case AuctionStatus.submitted: return 'Submitted';
      case AuctionStatus.approved: return 'Approved';
      case AuctionStatus.active: return 'Active';
      case AuctionStatus.ended: return 'Ended';
      case AuctionStatus.rejected: return 'Rejected';
      case AuctionStatus.pending: return 'Pending';
      case AuctionStatus.closed: return 'Closed';
    }
  }

  static AuctionStatus fromString(String value) => AuctionStatus.values.firstWhere(
        (e) => e.name == value,
    orElse: () => AuctionStatus.draft,
  );
}

class AuctionModel {
  final String id;
  final String title;
  final String description;
  final AuctionStatus status;
  final double startingPrice;
  final DateTime? startTime;
  final DateTime? endDateTime;
  final DateTime createdAt;
  final String organizerId;
  final String organizerName;
  final String? winnerId;
  final String? rejectionReason;
  final int itemCount;
  final String? imageUrl;
  final String? category;
  final String? location;
  final double? minBidIncrement;



  AuctionModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.startingPrice,
    this.startTime,
    this.endDateTime,
    required this.createdAt,
    required this.organizerId,
    required this.organizerName,
    this.winnerId,
    this.rejectionReason,
    required this.itemCount,
    required this.imageUrl,
    this.category,
    this.location,
    this.minBidIncrement,
  });

  factory AuctionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AuctionModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      status: AuctionStatus.fromString(data['status'] ?? 'draft'),
      startingPrice: (data['startingPrice'] ?? 0).toDouble(),
      startTime: (data['startTime'] as Timestamp?)?.toDate(),
      endDateTime: (data['endTime'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      organizerId: data['organizerId'] ?? '',
      organizerName: data['organizerName'] ?? 'Unknown',
      winnerId: data['winnerId'],
      rejectionReason: data['rejectionReason'],
      itemCount: data['itemCount'] ?? 0,
      imageUrl: data['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'description': description,
    'status': status.name,
    'startingPrice': startingPrice,
    'startTime': startTime != null ? Timestamp.fromDate(startTime!) : null,
    'endTime': endDateTime != null ? Timestamp.fromDate(endDateTime!) : null,
    'createdAt': Timestamp.fromDate(createdAt),
    'organizerId': organizerId,
    'organizerName': organizerName,
    'winnerId': winnerId,
    'rejectionReason': rejectionReason,
    'itemCount': itemCount,
  };
  factory AuctionModel.fromMap(Map<String, dynamic> map, String id) {
    return AuctionModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      status: AuctionStatus.values.firstWhere(
            (e) => e.name == map['status'],
        orElse: () => AuctionStatus.pending,
      ),
      startingPrice: (map['startingPrice'] ?? 0.0).toDouble(),
      startTime: map['startTime'] != null
          ? (map['startTime'] as Timestamp).toDate()
          : null,
      endDateTime: map['endTime'] != null
          ? (map['endTime'] as Timestamp).toDate()
          : null,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      organizerId: map['organizerId'] ?? '',
      organizerName: map['organizerName'] ?? '',
      winnerId: map['winnerId'],
      rejectionReason: map['rejectionReason'],
      imageUrl: map['imageUrl'],
      itemCount: map['itemCount'] ?? 0, // أضف هذا الحقل إن كان موجوداً
    );


  }

  get currentPrice => null;
}
