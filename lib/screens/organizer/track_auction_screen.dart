import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/auction_model.dart';
class TrackAuctionScreen extends StatefulWidget {
  final AuctionModel auction;

  const TrackAuctionScreen({super.key, required this.auction});

  @override
  State<TrackAuctionScreen> createState() => _TrackAuctionScreenState();
}

class _TrackAuctionScreenState extends State<TrackAuctionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─── Helpers ──────────────────────────────────────────────────
  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return const Color(0xFF2E7D32);
      case 'approved':
        return const Color(0xFF1565C0);
      case 'submitted':
        return const Color(0xFFF57F17);
      case 'ended':
        return Colors.grey;
      case 'rejected':
        return const Color(0xFFC62828);
      case 'draft':
        return Colors.blueGrey;
      default:
        return Colors.blueGrey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'active':
        return 'نشط';
      case 'approved':
        return 'موافق عليه';
      case 'submitted':
        return 'قيد المراجعة';
      case 'ended':
        return 'منتهي';
      case 'rejected':
        return 'مرفوض';
      case 'draft':
        return 'مسودة';
      default:
        return status;
    }
  }

  String _formatTimestamp(DateTime? dt) {
    if (dt == null) return '-';

    return '${dt.day}/${dt.month}/${dt.year} '
        '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Duration _remaining() {
    if (widget.auction.endDateTime == null) return Duration.zero;
    final now = DateTime.now();
    final end = widget.auction.endDateTime!;
    if (end.isBefore(now)) return Duration.zero;
    return end.difference(now);
  }

  String _formatDuration(Duration d) {
    if (d == Duration.zero) return 'انتهى';
    final days = d.inDays;
    final hours = d.inHours % 24;
    final minutes = d.inMinutes % 60;
    if (days > 0) return '${days}ي  ${hours}س  ${minutes}د';
    if (hours > 0) return '${hours}س  ${minutes}د';
    return '${minutes}د';
  }

  // ─── Header ───────────────────────────────────────────────────
  Widget _buildHeader() {
    final status = widget.auction.status.name;
    final statusColor = _statusColor(status);
    final remaining = _remaining();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status badge
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _statusLabel(status),
              style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12),
            ),
          ),
          const SizedBox(height: 10),

          // Title
          Text(
            widget.auction.title,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, height: 1.3),
          ),
          const SizedBox(height: 6),

          Text(
            widget.auction.category ?? '—',
            style:
            TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),

          const SizedBox(height: 16),

          // Stats row
          Row(
            children: [
              _headerStat(
                'السعر الحالي',
                '${widget.auction.currentPrice.toStringAsFixed(0)} DZD',
                Icons.price_change_rounded,
                const Color(0xFF1565C0),
              ),
              const SizedBox(width: 12),
              _headerStat(
                'الوقت المتبقي',
                _formatDuration(remaining),
                Icons.timer_rounded,
                remaining == Duration.zero
                    ? Colors.grey
                    : const Color(0xFFF57F17),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerStat(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 10, color: Colors.grey.shade600)),
                  Text(value,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Tab 1: تفاصيل المزاد ─────────────────────────────────────
  Widget _buildDetailsTab() {
    final a = widget.auction;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _detailCard('📋 معلومات عامة', [
          _detailRow('العنوان', a.title),
          _detailRow('الفئة', a.category ?? '—'),
          _detailRow('الموقع', a.location ?? '—'),
          _detailRow('الوصف', a.description ?? '—'),
        ]),
        const SizedBox(height: 12),
        _detailCard('💰 التسعير', [
          _detailRow('السعر الابتدائي',
              '${a.startingPrice.toStringAsFixed(0)} DZD'),
          _detailRow('السعر الحالي',
              '${a.currentPrice.toStringAsFixed(0)} DZD'),
          _detailRow('الحد الأدنى للزيادة',
              '${a.minBidIncrement?.toStringAsFixed(0) } DZD'),
        ]),
        const SizedBox(height: 12),
        _detailCard('📅 التواريخ', [
          _detailRow('تاريخ الإنشاء', _formatTimestamp(a.createdAt)),
          _detailRow('تاريخ البداية', _formatTimestamp(a.startTime)),
          _detailRow('تاريخ النهاية', _formatTimestamp(a.endDateTime)),
        ]),
        const SizedBox(height: 12),
        _detailCard('📊 الحالة', [
          _detailRow('الحالة الحالية', _statusLabel(a.status.name)),
          if (a.winnerId != null)
            _detailRow('الفائز', a.winnerId!),
        ]),
      ],
    );
  }

  Widget _detailCard(String title, List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF1565C0))),
          const Divider(height: 16),
          ...rows,
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: TextStyle(
                    color: Colors.grey.shade600, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  // ─── Tab 2: المزايدات ─────────────────────────────────────────
  Widget _buildBidsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bids')
          .where('auctionId', isEqualTo: widget.auction.id)
          .orderBy('amount', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.gavel_rounded,
                    size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text('لا توجد مزايدات بعد',
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 15)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final bid = docs[i].data() as Map<String, dynamic>;
            final isTop = i == 0;
            final amount =
                (bid['amount'] as num?)?.toDouble() ?? 0;
            final bidderId = bid['bidderId'] as String? ?? '—';
            final ts = bid['createdAt'] as Timestamp?;

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isTop
                    ? const Color(0xFFFFF8E1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isTop
                      ? const Color(0xFFF57F17)
                      : Colors.grey.shade200,
                  width: isTop ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Row(
                children: [
                  // Rank
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isTop
                          ? const Color(0xFFF57F17)
                          : Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        isTop ? '🥇' : '${i + 1}',
                        style: TextStyle(
                            fontSize: isTop ? 16 : 13,
                            fontWeight: FontWeight.bold,
                            color: isTop
                                ? Colors.white
                                : Colors.grey.shade700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bidderId.length > 16
                              ? '${bidderId.substring(0, 16)}...'
                              : bidderId,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13),
                        ),
                        if (ts != null)
                          Text(
                            _formatTimestamp(ts.toDate()),
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    '${amount.toStringAsFixed(0)} DZD',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isTop
                            ? const Color(0xFFF57F17)
                            : const Color(0xFF1565C0)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ─── Tab 3: الفائز ────────────────────────────────────────────
  Widget _buildWinnerTab() {
    final status = widget.auction.status.name;
    final winnerId = widget.auction.winnerId;

    if (status != 'ended') {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              status == 'active'
                  ? Icons.hourglass_top_rounded
                  : Icons.lock_clock_rounded,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              status == 'active'
                  ? 'المزاد لا يزال نشطاً'
                  : 'لم يُعلَن عن الفائز بعد',
              style: TextStyle(
                  color: Colors.grey.shade500, fontSize: 15),
            ),
            const SizedBox(height: 6),
            Text(
              'سيظهر الفائز بعد انتهاء المزاد.',
              style: TextStyle(
                  color: Colors.grey.shade400, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (winnerId == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sentiment_dissatisfied_rounded,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('لم يتم إعلان فائز',
                style: TextStyle(
                    color: Colors.grey.shade500, fontSize: 15)),
          ],
        ),
      );
    }

    // Load winner info
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(winnerId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data =
        snapshot.data?.data() as Map<String, dynamic>?;
        final name = data?['name'] as String? ?? 'غير معروف';
        final email = data?['email'] as String? ?? '—';
        final winnerBidId = widget.auction.winnerId;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Winner card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.emoji_events_rounded,
                      color: Color(0xFFFFD54F), size: 56),
                  const SizedBox(height: 10),
                  const Text('🎉 الفائز بالمزاد',
                      style: TextStyle(
                          color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(email,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'السعر الفائز: ${widget.auction.currentPrice.toStringAsFixed(0)} DZD',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),

            if (winnerBidId != null) ...[
              const SizedBox(height: 16),
              _detailCard('📄 تفاصيل المزايدة الفائزة', [
                _detailRow('رقم المزايدة', winnerBidId),
                _detailRow('المبلغ',
                    '${widget.auction.currentPrice.toStringAsFixed(0)} DZD'),
              ]),
            ],
          ],
        );
      },
    );
  }

  // ─── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'متابعة المزاد',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87),
        ),
        leading: const BackButton(color: Colors.black87),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF1565C0),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF1565C0),
          tabs: const [
            Tab(text: 'التفاصيل'),
            Tab(text: 'المزايدات'),
            Tab(text: 'الفائز'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDetailsTab(),
                _buildBidsTab(),
                _buildWinnerTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
