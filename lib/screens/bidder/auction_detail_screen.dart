
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/auction_model.dart';
import '../../data/models/bid_model.dart';


class AuctionDetailScreen extends StatefulWidget {
  final String auctionId;
  const AuctionDetailScreen({super.key, required this.auctionId});

  @override
  State<AuctionDetailScreen> createState() => _AuctionDetailScreenState();
}

class _AuctionDetailScreenState extends State<AuctionDetailScreen> {
  final _bidController = TextEditingController();
  bool _placing = false;
  String? _bidError;

  Stream<AuctionModel?> _auctionStream() {
    return FirebaseFirestore.instance
        .collection('auctions')
        .doc(widget.auctionId)
        .snapshots()
        .map((doc) => doc.exists ? AuctionModel.fromMap(doc.data()!, doc.id) : null);
  }

  Stream<List<BidModel>> _bidsStream() {
    return FirebaseFirestore.instance
        .collection('bids')
        .where('auctionId', isEqualTo: widget.auctionId)
        .orderBy('amount', descending: true)
        .limit(20)
        .snapshots()
        .map((snap) => snap.docs.map((d) => BidModel.fromMap(d.data(), d.id)).toList());
  }

  Future<void> _placeBid(AuctionModel auction) async {
    setState(() => _bidError = null);
    final raw = _bidController.text.trim();
    double? amount = double.tryParse(raw);

    if (amount == null) {
      setState(() => _bidError = 'Please enter a valid amount.');
      return;
    }
    if (amount <= (auction.currentPrice ?? 0)) {
      setState(() => _bidError = 'Bid must be higher than current price (${auction.currentPrice?.toStringAsFixed(2)} DZD).');
      return;
    }

    final confirmed = await _confirmDialog(amount, auction);
    if (!confirmed) return;

    setState(() => _placing = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final batch = FirebaseFirestore.instance.batch();

      // Add bid document
      final bidRef = FirebaseFirestore.instance.collection('bids').doc();
      batch.set(bidRef, {
        'auctionId': widget.auctionId,
        'bidderId': uid,
        'amount': amount,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'active',
      });

      // Update auction currentPrice
      final auctionRef = FirebaseFirestore.instance.collection('auctions').doc(widget.auctionId);
      batch.update(auctionRef, {'currentPrice': amount});

      await batch.commit();

      _bidController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Bid placed successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() => _bidError = 'Failed to place bid: $e');
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  Future<bool> _confirmDialog(double amount, AuctionModel auction) async {
    return await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Bid'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Auction: ${auction.title}'),
            const SizedBox(height: 8),
            Text('Your bid: ${amount.toStringAsFixed(2)} DZD',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E), fontSize: 16)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: StreamBuilder<AuctionModel?>(
        stream: _auctionStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final auction = snap.data;
          if (auction == null) return const Center(child: Text('Auction not found.'));

          final isActive = auction.status == AuctionStatus.active;
          final uid = FirebaseAuth.instance.currentUser?.uid;

          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(auction),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoCard(auction),
                      const SizedBox(height: 16),
                      if (isActive) _buildBidSection(auction),
                      const SizedBox(height: 16),
                      _buildBidHistory(auction),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(AuctionModel auction) {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: const Color(0xFF1A237E),
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(auction.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        background: auction.imageUrl != null && auction.imageUrl!.isNotEmpty
            ? Image.network(auction.imageUrl!, fit: BoxFit.cover)
            : Container(
          color: const Color(0xFF1A237E),
          child: const Icon(Icons.gavel, size: 80, color: Colors.white24),
        ),
      ),
    );
  }

  Widget _buildInfoCard(AuctionModel auction) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatusChip(status: auction.status),
              const Spacer(),
              if (auction.category != null)
                Text(auction.category!, style: const TextStyle(color: Color(0xFF3949AB), fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 12),
          Text(auction.description, style: TextStyle(color: Colors.grey[700], height: 1.5)),
          const Divider(height: 24),
          Row(
            children: [
              _InfoTile(label: 'Starting Price', value: '${auction.startingPrice.toStringAsFixed(2)} DZD'),
              const SizedBox(width: 12),
              _InfoTile(
                label: 'Current Bid',
                value: '${auction.currentPrice?.toStringAsFixed(2)} DZD',
                highlight: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _InfoTile(label: 'Start', value: formatDateTime(auction.startTime!)),
              const SizedBox(width: 12),
              _InfoTile(label: 'End', value: formatDateTime(auction.endDateTime!)),
            ],
          ),
          if (auction.status == AuctionStatus.active) ...[
            const SizedBox(height: 12),
            Center(child: _CountdownTimerLarge(endTime: auction.endDateTime!)),
          ],
        ],
      ),
    );
  }

  Widget _buildBidSection(AuctionModel auction) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Place Your Bid', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          TextField(
            controller: _bidController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: 'Enter amount (DZD)',
              prefixIcon: const Icon(Icons.attach_money),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              errorText: _bidError,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _placing ? null : () => _placeBid(auction),
              icon: _placing
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.gavel),
              label: Text(_placing ? 'Placing...' : 'Place Bid'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBidHistory(AuctionModel auction) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Bid History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        StreamBuilder<List<BidModel>>(
          stream: _bidsStream(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final bids = snap.data ?? [];
            if (bids.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: const Center(child: Text('No bids yet. Be the first!', style: TextStyle(color: Colors.grey))),
              );
            }
            return Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))]),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: bids.length,
                separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
                itemBuilder: (_, i) {
                  final bid = bids[i];
                  final isTop = i == 0;
                  final uid = FirebaseAuth.instance.currentUser?.uid;
                  final isMe = bid.bidderId == uid;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isTop ? const Color(0xFF1A237E) : Colors.grey[200],
                      child: Text(
                        '#${i + 1}',
                        style: TextStyle(color: isTop ? Colors.white : Colors.grey[700], fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    title: Text(
                      isMe ? 'You' : 'Bidder ${bid.bidderId.substring(0, 6)}...',
                      style: TextStyle(fontWeight: isTop ? FontWeight.bold : FontWeight.normal),
                    ),
                    subtitle: bid.timestamp != null ? Text(formatDateTime(bid.timestamp!), style: const TextStyle(fontSize: 11)) : null,
                    trailing: Text(
                      '${bid.amount.toStringAsFixed(2)} DZD',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isTop ? const Color(0xFF1A237E) : Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
        const SizedBox(height: 80),
      ],
    );
  }




  String formatDateTime(DateTime date) {
    return "${date.day}-${date.month}-${date.year}";
  }
 }

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final AuctionStatus status;
  const _StatusChip({required this.status});
  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case AuctionStatus.active: color = Colors.green; label = '● Live'; break;
      case AuctionStatus.approved: color = Colors.orange; label = '⏳ Upcoming'; break;
      case AuctionStatus.ended: color = Colors.red; label = 'Ended'; break;
      default: color = Colors.grey; label = status.name;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  const _InfoTile({required this.label, required this.value, this.highlight = false});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: highlight ? const Color(0xFFE8EAF6) : const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: highlight ? const Color(0xFF1A237E) : Colors.black87,
                )),
          ],
        ),
      ),
    );
  }
}

class _CountdownTimerLarge extends StatefulWidget {
  final DateTime endTime;
  const _CountdownTimerLarge({required this.endTime});
  @override
  State<_CountdownTimerLarge> createState() => _CountdownTimerLargeState();
}

class _CountdownTimerLargeState extends State<_CountdownTimerLarge> {
  late Duration _remaining;
  @override
  void initState() {
    super.initState();
    _update();
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(_update);
      return _remaining.inSeconds > 0;
    });
  }
  void _update() {
    _remaining = widget.endTime.difference(DateTime.now());
    if (_remaining.isNegative) _remaining = Duration.zero;
  }
  @override
  Widget build(BuildContext context) {
    final h = _remaining.inHours.toString().padLeft(2, '0');
    final m = (_remaining.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    final isUrgent = _remaining.inMinutes < 10;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.timer, color: isUrgent ? Colors.red : const Color(0xFF1A237E)),
        const SizedBox(width: 8),
        Text(
          '$h h  $m m  $s s',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isUrgent ? Colors.red : const Color(0xFF1A237E),
          ),
        ),
      ],
    );
  }
}
