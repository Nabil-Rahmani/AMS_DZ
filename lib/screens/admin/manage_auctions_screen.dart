import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/auction_model.dart';
import '../../data/services/firestore_service.dart';

class ManageAuctionsScreen extends StatefulWidget {
  const ManageAuctionsScreen({super.key});

  @override
  State<ManageAuctionsScreen> createState() => _ManageAuctionsScreenState();
}

class _ManageAuctionsScreenState extends State<ManageAuctionsScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _db = FirestoreService();
  late TabController _tabController;

  final List<Map<String, dynamic>> _tabs = [
    {'label': 'الكل', 'status': null},
    {'label': 'قيد المراجعة', 'status': AuctionStatus.submitted},
    {'label': 'نشط', 'status': AuctionStatus.active},
    {'label': 'منتهي', 'status': AuctionStatus.ended},
    {'label': 'مرفوض', 'status': AuctionStatus.rejected},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Actions
  Future<void> _approve(AuctionModel auction) async {
    final confirm = await _showConfirm(
      title: 'تأكيد الموافقة',
      content: 'هل أنت متأكد من الموافقة على هذا المزاد؟',
      confirmText: 'موافقة',
      confirmColor: Colors.green,
    );
    if (!confirm) return;
    try {
      await _db.approveAuction(auction.id);
      _showSnack('✅ تمت الموافقة على المزاد بنجاح');
    } catch (e) {
      _showSnack('❌ خطأ: $e', isError: true);
    }
  }

  Future<void> _reject(AuctionModel auction) async {
    final reasonCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('رفض المزاد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('المزاد: ${auction.title}'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'سبب الرفض',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('رفض', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _db.rejectAuction(auction.id, reason: reasonCtrl.text.trim());
      _showSnack('✅ تم رفض المزاد بنجاح');
    } catch (e) {
      _showSnack('❌ خطأ: $e', isError: true);
    }
  }

  Future<void> _declareWinner(AuctionModel auction) async {
    final topBid = await _db.getTopBid(auction.id);
    if (topBid == null) {
      _showSnack('لا توجد مزايدات على هذا المزاد');
      return;
    }

    final winnerId = topBid['bidderId'] as String;
    final amount = topBid['amount'];

    // Get winner name
    String winnerName = winnerId;
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(winnerId)
          .get();
      if (userDoc.exists) winnerName = userDoc['name'] ?? winnerId;
    } catch (_) {}

    final confirm = await _showConfirm(
      title: 'تحديد الفائز',
      content:
      "الفائز بالمزاد \"${auction.title}\":\n\n$winnerName\n${amount.toStringAsFixed(2)} DZD",
      confirmText: 'تأكيد',
      confirmColor: const Color(0xFF1565C0),
    );
    if (!confirm) return;
    try {
      await _db.declareWinner(auctionId: auction.id, winnerId: winnerId);
      _showSnack('✅ تم تحديد الفائز بنجاح');
    } catch (e) {
      _showSnack('❌ خطأ: $e', isError: true);
    }
  }

  void _showDetails(AuctionModel auction) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.gavel, color: Color(0xFF1565C0), size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      auction.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              AuctionStatusBadge(status: auction.status),
              const SizedBox(height: 16),
              _DetailRow(
                icon: Icons.description,
                label: 'الوصف',
                value: auction.description,
              ),
              _DetailRow(
                icon: Icons.attach_money,
                label: 'سعر البداية',
                value: '${auction.startingPrice.toStringAsFixed(2)} DZD',
              ),
              _DetailRow(
                icon: Icons.price_check,
                label: 'أعلى سعر حالياً',
                value: auction.currentPrice != null
                    ? '${auction.currentPrice!.toStringAsFixed(2)} DZD'
                    : 'لا توجد مزايدات',
              ),
              if (auction.winnerId != null)
                _DetailRow(
                  icon: Icons.emoji_events,
                  label: 'الفائز',
                  value: auction.winnerId!,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _showConfirm({
    required String title,
    required String content,
    required String confirmText,
    required Color confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              confirmText,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  String _fmt(DateTime? d) {
    if (d == null) return 'غير محدد';
    return '${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'إدارة المزادات',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF1565C0),
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: _tabs
                .map((t) => Tab(text: t['label'] as String))
                .toList(),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: _tabs.map((t) {
            final status = t['status'] as AuctionStatus?;
            return _AuctionListView(
              stream: _db.streamAuctions(status: status),
              onTap: _showDetails,
              onApprove: _approve,
              onReject: _reject,
              onDeclareWinner: _declareWinner,
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _AuctionListView extends StatelessWidget {
  final Stream<List<AuctionModel>> stream;
  final void Function(AuctionModel) onTap;
  final void Function(AuctionModel) onApprove;
  final void Function(AuctionModel) onReject;
  final void Function(AuctionModel) onDeclareWinner;

  const _AuctionListView({
    required this.stream,
    required this.onTap,
    required this.onApprove,
    required this.onReject,
    required this.onDeclareWinner,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AuctionModel>>(
      stream: stream,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('خطأ: ${snap.error}'));
        }
        final list = snap.data ?? [];
        if (list.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text(
                  'لا توجد مزادات',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: list.length,
          itemBuilder: (_, i) => _AuctionCard(
            auction: list[i],
            onTap: () => onTap(list[i]),
            onApprove: () => onApprove(list[i]),
            onReject: () => onReject(list[i]),
            onDeclareWinner: () => onDeclareWinner(list[i]),
          ),
        );
      },
    );
  }
}

class _AuctionCard extends StatelessWidget {
  final AuctionModel auction;
  final VoidCallback onTap;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onDeclareWinner;

  const _AuctionCard({
    required this.auction,
    required this.onTap,
    required this.onApprove,
    required this.onReject,
    required this.onDeclareWinner,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      auction.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AuctionStatusBadge(status: auction.status),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                auction.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.attach_money,
                      size: 16, color: Color(0xFF1565C0)),
                  const SizedBox(width: 4),
                  Text(
                    'البداية: ${auction.startingPrice.toStringAsFixed(2)} DZD',
                    style: const TextStyle(fontSize: 13),
                  ),
                  if (auction.currentPrice != null) ...[
                    const SizedBox(width: 12),
                    const Icon(Icons.trending_up,
                        size: 16, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      '${auction.currentPrice!.toStringAsFixed(2)} DZD',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              _buildCardActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardActions() {
    if (auction.status == AuctionStatus.submitted) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.close, size: 16, color: Colors.red),
              label: const Text(
                'رفض',
                style: TextStyle(color: Colors.red, fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 6),
              ),
              onPressed: onReject,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check, size: 16, color: Colors.white),
              label: const Text(
                'موافقة',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 6),
              ),
              onPressed: onApprove,
            ),
          ),
        ],
      );
    }
    if (auction.status == AuctionStatus.ended && auction.winnerId == null) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.emoji_events, size: 16, color: Colors.white),
          label: const Text(
            'تحديد الفائز',
            style: TextStyle(color: Colors.white, fontSize: 13),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1565C0),
            padding: const EdgeInsets.symmetric(vertical: 6),
          ),
          onPressed: onDeclareWinner,
        ),
      );
    }
    if (auction.status == AuctionStatus.ended && auction.winnerId != null) {
      return const Row(
        children: [
          Icon(Icons.emoji_events, color: Colors.amber, size: 18),
          SizedBox(width: 8),
          Text('تم تحديد الفائز'),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}

class AuctionStatusBadge extends StatelessWidget {
  final AuctionStatus status;

  const AuctionStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusInfo['color']?.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusInfo['color'] ?? Colors.grey,
          width: 0.5,
        ),
      ),
      child: Text(
        statusInfo['label'] as String,
        style: TextStyle(
          fontSize: 11,
          color: statusInfo['color'],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(AuctionStatus status) {
    switch (status) {
      case AuctionStatus.submitted:
        return {'label': 'قيد المراجعة', 'color': Colors.orange};
      case AuctionStatus.active:
        return {'label': 'نشط', 'color': Colors.green};
      case AuctionStatus.ended:
        return {'label': 'منتهي', 'color': Colors.grey};
      case AuctionStatus.rejected:
        return {'label': 'مرفوض', 'color': Colors.red};
      default:
        return {'label': 'غير معروف', 'color': Colors.grey};
    }
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1565C0)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}