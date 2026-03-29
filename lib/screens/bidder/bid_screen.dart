import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/bid_model.dart';
import '../../data/models/auction_model.dart';
import '../bidder/auction_detail_screen.dart';

class MyBidsScreen extends StatefulWidget {
  const MyBidsScreen({super.key});

  @override
  State<MyBidsScreen> createState() => _MyBidsScreenState();
}

class _MyBidsScreenState extends State<MyBidsScreen> {
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  Stream<List<Map<String, dynamic>>> _myBidsStream() {
    return FirebaseFirestore.instance
        .collection('bids')
        .where('bidderId', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .asyncMap((snap) async {
      final List<Map<String, dynamic>> results = [];
      for (final doc in snap.docs) {
        final bid = BidModel.fromMap(doc.data(), doc.id);
        // Fetch auction info
        final auctionDoc = await FirebaseFirestore.instance
            .collection('auctions')
            .doc(bid.auctionId)
            .get();
        AuctionModel? auction;
        if (auctionDoc.exists) {
          auction = AuctionModel.fromMap(auctionDoc.data()!, auctionDoc.id);
        }
        results.add({'bid': bid, 'auction': auction});
      }
      return results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('My Bids', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _myBidsStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.gavel, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text("You haven't placed any bids yet.",
                      style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                ],
              ),
            );
          }

          // Group by auction
          final Map<String, List<Map<String, dynamic>>> grouped = {};
          for (final item in items) {
            final bid = item['bid'] as BidModel;
            grouped.putIfAbsent(bid.auctionId, () => []).add(item);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: grouped.entries.map((entry) {
              final auctionItems = entry.value;
              final auction = auctionItems.first['auction'] as AuctionModel?;
              final bids = auctionItems.map((e) => e['bid'] as BidModel).toList();
              final highestMyBid = bids.map((b) => b.amount).reduce((a, b) => a > b ? a : b);
              final isWinner = auction != null &&
                  auction.status == AuctionStatus.ended &&
                  auction.currentPrice == highestMyBid;

              return _AuctionBidGroup(
                auction: auction,
                bids: bids,
                isWinner: isWinner,
                onTap: auction != null
                    ? () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AuctionDetailScreen(auctionId: auction.id!)),
                )
                    : null,
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

// ─── Grouped Card per Auction ─────────────────────────────────────────────────

class _AuctionBidGroup extends StatelessWidget {
  final AuctionModel? auction;
  final List<BidModel> bids;
  final bool isWinner;
  final VoidCallback? onTap;

  const _AuctionBidGroup({
    required this.auction,
    required this.bids,
    required this.isWinner,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final highestBid = bids.map((b) => b.amount).reduce((a, b) => a > b ? a : b);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isWinner ? Border.all(color: Colors.amber, width: 2) : null,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isWinner ? const Color(0xFFFFF8E1) : const Color(0xFFE8EAF6),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      auction?.title ?? 'Unknown Auction',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  if (isWinner)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(20)),
                      child: const Text('🏆 Winner', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    )
                  else if (auction != null)
                    _StatusMini(status: auction!.status),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _SmallTile(label: 'Your Highest Bid', value: '${highestBid.toStringAsFixed(2)} DZD', highlight: true),
                      const SizedBox(width: 12),
                      if (auction != null)
                        _SmallTile(label: 'Current Price', value: '${auction!.currentPrice.toStringAsFixed(2)} DZD'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Your ${bids.length} bid(s):', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  ...bids.map((bid) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                        Text(
                          '${bid.amount.toStringAsFixed(2)} DZD',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const Spacer(),
                        if (bid.timestamp != null)
                          Text(
                            _fmt(bid.timestamp!),
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

class _StatusMini extends StatelessWidget {
  final AuctionStatus status;
  const _StatusMini({required this.status});
  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case AuctionStatus.active: color = Colors.green; label = 'Live'; break;
      case AuctionStatus.ended: color = Colors.red; label = 'Ended'; break;
      case AuctionStatus.approved: color = Colors.orange; label = 'Upcoming'; break;
      default: color = Colors.grey; label = status.name;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}

class _SmallTile extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  const _SmallTile({required this.label, required this.value, this.highlight = false});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: highlight ? const Color(0xFFE8EAF6) : const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: highlight ? const Color(0xFF1A237E) : Colors.black87,
              )),
        ]),
      ),
    );
  }
}
