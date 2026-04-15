import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:auction_app2/shared/models/bid_model.dart';
import 'package:auction_app2/shared/models/auction_model.dart';
import '../widgets/bid_stats_row.dart';
import '../widgets/auction_bid_group.dart';
import 'auction_detail_screen.dart';
import '../../../core/constants/ds_colors.dart';
import '../../../core/widgets/ds_widgets.dart';

class MyBidsScreen extends StatefulWidget {
  const MyBidsScreen({super.key});
  @override
  State<MyBidsScreen> createState() => _MyBidsScreenState();
}

class _MyBidsScreenState extends State<MyBidsScreen> {
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  Stream<List<Map<String, dynamic>>> _myBidsStream() {
    return FirebaseFirestore.instance
        .collection('bids').where('bidderId', isEqualTo: uid)
        .orderBy('timestamp', descending: true).snapshots()
        .asyncMap((snap) async {
      final List<Map<String, dynamic>> results = [];
      for (final doc in snap.docs) {
        final bid = BidModel.fromMap(doc.data(), doc.id);
        final auctionDoc = await FirebaseFirestore.instance.collection('auctions').doc(bid.auctionId).get();
        AuctionModel? auction;
        if (auctionDoc.exists) auction = AuctionModel.fromMap(auctionDoc.data()!, auctionDoc.id);
        results.add({'bid': bid, 'auction': auction});
      }
      return results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: DS.bg,
        appBar: DarkAppBar(
          title: 'مزايداتي',
          leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => Navigator.pop(context)),
        ),
        body: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _myBidsStream(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: DS.purple));
            final items = snap.data ?? [];
            if (items.isEmpty) return const DSEmpty(icon: Icons.gavel_rounded, title: 'لا توجد مزايدات بعد', subtitle: 'تصفح المزادات وابدأ المزايدة!');

            final Map<String, List<Map<String, dynamic>>> grouped = {};
            for (final item in items) {
              final bid = item['bid'] as BidModel;
              grouped.putIfAbsent(bid.auctionId, () => []).add(item);
            }

            int totalBids = items.length;
            int wonAuctions = 0;
            for (final entry in grouped.entries) {
              final auctionItems = entry.value;
              final auction = auctionItems.first['auction'] as AuctionModel?;
              final bids = auctionItems.map((e) => e['bid'] as BidModel).toList();
              final highest = bids.map((b) => b.amount).reduce((a, b) => a > b ? a : b);
              if (auction != null && auction.status == AuctionStatus.ended && auction.currentPrice == highest) wonAuctions++;
            }

            return Column(children: [
              BidStatsRow(totalBids: totalBids, wonAuctions: wonAuctions, totalParticipated: grouped.length),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: grouped.entries.map((entry) {
                    final auctionItems = entry.value;
                    final auction = auctionItems.first['auction'] as AuctionModel?;
                    final bids = auctionItems.map((e) => e['bid'] as BidModel).toList();
                    final highestMyBid = bids.map((b) => b.amount).reduce((a, b) => a > b ? a : b);
                    final isWinner = auction != null && auction.status == AuctionStatus.ended && auction.currentPrice == highestMyBid;
                    return AuctionBidGroup(
                      auction: auction, bids: bids, isWinner: isWinner,
                      onTap: auction != null ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => AuctionDetailScreen(auctionId: auction.id))) : null,
                    );
                  }).toList(),
                ),
              ),
            ]);
          },
        ),
      ),
    );
  }
}
