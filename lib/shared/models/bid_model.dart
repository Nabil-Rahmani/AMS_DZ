import 'package:cloud_firestore/cloud_firestore.dart';
class BidModel {
  final String? id;
  final String auctionId;
  final String bidderId;
  final double amount;
  final DateTime? timestamp;
  final String status; // active, winning, outbid

  BidModel({
    this.id,
    required this.auctionId,
    required this.bidderId,
    required this.amount,
    this.timestamp,
    this.status = 'active',
  });

  factory BidModel.fromMap(Map<String, dynamic> map, String id) {
    return BidModel(
      id: id,
      auctionId: map['auctionId'] ?? '',
      bidderId: map['bidderId'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      timestamp: (map['timestamp'] as Timestamp?)?.toDate(),
      status: map['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'auctionId': auctionId,
      'bidderId': bidderId,
      'amount': amount,
      'timestamp': timestamp != null ? Timestamp.fromDate(timestamp!) : FieldValue.serverTimestamp(),
      'status': status,
    };
  }
}
