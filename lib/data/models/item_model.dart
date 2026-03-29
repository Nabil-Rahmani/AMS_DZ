import 'package:cloud_firestore/cloud_firestore.dart';

enum ItemStatus { pending, open, sold, unsold }

class ItemModel {
  final String id;
  final String auctionId;
  final String title;
  final String description;
  final double startingPrice;
  final double currentBid;
  final double minimumIncrement;
  final ItemStatus status;
  final List<String> imageUrls;

  ItemModel({
    required this.id,
    required this.auctionId,
    required this.title,
    required this.description,
    required this.startingPrice,
    required this.currentBid,
    required this.minimumIncrement,
    required this.status,
    required this.imageUrls,
  });

  factory ItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ItemModel(
      id: doc.id,
      auctionId: data['auctionId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      startingPrice: (data['startingPrice'] ?? 0).toDouble(),
      currentBid: (data['currentBid'] ?? 0).toDouble(),
      minimumIncrement: (data['minimumIncrement'] ?? 100).toDouble(),
      status: ItemStatus.values.firstWhere(
            (e) => e.name == data['status'],
        orElse: () => ItemStatus.pending,
      ),
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
    'auctionId': auctionId,
    'title': title,
    'description': description,
    'startingPrice': startingPrice,
    'currentBid': currentBid,
    'minimumIncrement': minimumIncrement,
    'status': status.name,
    'imageUrls': imageUrls,
  };
}
