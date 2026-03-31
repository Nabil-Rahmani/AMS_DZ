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
    {'label': 'مقبول', 'status': AuctionStatus.approved},
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

  // ── الموافقة البسيطة (بدون تحديد وقت بعد) ─────────────────────
  Future<void> _approve(AuctionModel auction) async {
    final confirm = await _showConfirm(
      title: 'تأكيد الموافقة',
      content: 'هل أنت متأكد من الموافقة على هذا المزاد؟\nيمكنك لاحقاً تحديد يوم المعاينة وتاريخ المزاد.',
      confirmText: 'موافقة',
      confirmColor: Colors.green,
    );
    if (!confirm) return;
    try {
      await _db.approveAuction(auction.id);
      _showSnack('✅ تمت الموافقة على المزاد');
    } catch (e) {
      _showSnack('❌ خطأ: $e', isError: true);
    }
  }

  // ── تحديد الجدول الزمني ────────────────────────────────────────
  Future<void> _setSchedule(AuctionModel auction) async {
    DateTime? inspectionDay;
    DateTime? startTime;
    DateTime? endTime;

    await showDialog(
      context: context,
      builder: (ctx) => _ScheduleDialog(
        auction: auction,
        onSave: (inspection, start, end) {
          inspectionDay = inspection;
          startTime = start;
          endTime = end;
        },
      ),
    );

    if (inspectionDay == null || startTime == null || endTime == null) return;

    try {
      await _db.setAuctionSchedule(
        auctionId: auction.id,
        organizerId: auction.organizerId,
        inspectionDay: inspectionDay!,
        startTime: startTime!,
        endTime: endTime!,
      );
      _showSnack('✅ تم تحديد الجدول الزمني وإشعار البائع');
    } catch (e) {
      _showSnack('❌ خطأ: $e', isError: true);
    }
  }

  // ── تعديل السعر ────────────────────────────────────────────────
  Future<void> _adjustPrice(AuctionModel auction) async {
    final priceCtrl = TextEditingController(
      text: (auction.adminAdjustedPrice ?? auction.startingPrice)
          .toStringAsFixed(2),
    );
    final noteCtrl = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تعديل السعر الابتدائي'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('السعر الأصلي: ${auction.startingPrice.toStringAsFixed(2)} DZD',
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'السعر الجديد (DZD)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                labelText: 'سبب التعديل',
                border: OutlineInputBorder(),
                hintText: 'اكتب سبب تعديل السعر...',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تأكيد',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final newPrice = double.tryParse(priceCtrl.text.trim());
    if (newPrice == null) {
      _showSnack('❌ سعر غير صحيح', isError: true);
      return;
    }

    try {
      await _db.adjustAuctionPrice(
        auctionId: auction.id,
        organizerId: auction.organizerId,
        newPrice: newPrice,
        adminNote: noteCtrl.text.trim().isEmpty
            ? 'تعديل من المسؤول'
            : noteCtrl.text.trim(),
      );
      _showSnack('✅ تم تعديل السعر وإشعار البائع');
    } catch (e) {
      _showSnack('❌ خطأ: $e', isError: true);
    }
  }

  // ── تفعيل المزاد ───────────────────────────────────────────────
  Future<void> _activate(AuctionModel auction) async {
    if (auction.startTime == null || auction.inspectionDay == null) {
      _showSnack('❌ حدد يوم المعاينة وتاريخ المزاد أولاً', isError: true);
      return;
    }
    final confirm = await _showConfirm(
      title: 'تفعيل المزاد',
      content: 'سيتم نشر المزاد وإتاحته للمزايدين. هل أنت متأكد؟',
      confirmText: 'تفعيل',
      confirmColor: Colors.green,
    );
    if (!confirm) return;
    try {
      await _db.activateAuction(auction.id);
      _showSnack('✅ تم تفعيل المزاد بنجاح');
    } catch (e) {
      _showSnack('❌ خطأ: $e', isError: true);
    }
  }

  // ── الرفض ──────────────────────────────────────────────────────
  Future<void> _reject(AuctionModel auction) async {
    final reasonCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('رفض المزاد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
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
              child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child:
            const Text('رفض', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _db.rejectAuction(auction.id,
          reason: reasonCtrl.text.trim());
      _showSnack('✅ تم رفض المزاد');
    } catch (e) {
      _showSnack('❌ خطأ: $e', isError: true);
    }
  }

  // ── تحديد الفائز ───────────────────────────────────────────────
  Future<void> _declareWinner(AuctionModel auction) async {
    final topBid = await _db.getTopBid(auction.id);
    if (topBid == null) {
      _showSnack('لا توجد مزايدات على هذا المزاد');
      return;
    }
    final winnerId = topBid['bidderId'] as String;
    final amount = topBid['amount'];
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
      'الفائز: $winnerName\nالمبلغ: ${amount.toStringAsFixed(2)} DZD',
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
              child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmText,
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إدارة المزادات',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF1565C0),
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: _tabs.map((t) => Tab(text: t['label'] as String)).toList(),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: _tabs.map((t) {
            final status = t['status'] as AuctionStatus?;
            return _AuctionListView(
              stream: _db.streamAuctions(status: status),
              onApprove: _approve,
              onReject: _reject,
              onSetSchedule: _setSchedule,
              onAdjustPrice: _adjustPrice,
              onActivate: _activate,
              onDeclareWinner: _declareWinner,
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── قائمة المزادات ────────────────────────────────────────────────────────
class _AuctionListView extends StatelessWidget {
  final Stream<List<AuctionModel>> stream;
  final void Function(AuctionModel) onApprove;
  final void Function(AuctionModel) onReject;
  final void Function(AuctionModel) onSetSchedule;
  final void Function(AuctionModel) onAdjustPrice;
  final void Function(AuctionModel) onActivate;
  final void Function(AuctionModel) onDeclareWinner;

  const _AuctionListView({
    required this.stream,
    required this.onApprove,
    required this.onReject,
    required this.onSetSchedule,
    required this.onAdjustPrice,
    required this.onActivate,
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
                Text('لا توجد مزادات',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: list.length,
          itemBuilder: (_, i) => _AuctionCard(
            auction: list[i],
            onApprove: () => onApprove(list[i]),
            onReject: () => onReject(list[i]),
            onSetSchedule: () => onSetSchedule(list[i]),
            onAdjustPrice: () => onAdjustPrice(list[i]),
            onActivate: () => onActivate(list[i]),
            onDeclareWinner: () => onDeclareWinner(list[i]),
          ),
        );
      },
    );
  }
}

// ── بطاقة المزاد ──────────────────────────────────────────────────────────
class _AuctionCard extends StatelessWidget {
  final AuctionModel auction;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onSetSchedule;
  final VoidCallback onAdjustPrice;
  final VoidCallback onActivate;
  final VoidCallback onDeclareWinner;

  const _AuctionCard({
    required this.auction,
    required this.onApprove,
    required this.onReject,
    required this.onSetSchedule,
    required this.onAdjustPrice,
    required this.onActivate,
    required this.onDeclareWinner,
  });

  String _fmt(DateTime? d) {
    if (d == null) return 'غير محدد';
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── العنوان والحالة ──────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(auction.title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                AuctionStatusBadge(status: auction.status),
              ],
            ),
            const SizedBox(height: 6),
            Text(auction.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 10),

            // ── السعر ────────────────────────────────────────
            Row(
              children: [
                const Icon(Icons.attach_money,
                    size: 16, color: Color(0xFF1565C0)),
                const SizedBox(width: 4),
                Text('${auction.startingPrice.toStringAsFixed(2)} DZD',
                    style: const TextStyle(fontSize: 13)),
                if (auction.adminAdjustedPrice != null) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.edit, size: 14, color: Colors.orange),
                  Text(
                    ' → ${auction.adminAdjustedPrice!.toStringAsFixed(2)} DZD',
                    style: const TextStyle(
                        fontSize: 13, color: Colors.orange),
                  ),
                ],
              ],
            ),

            // ── يوم المعاينة وتاريخ المزاد ───────────────────
            if (auction.inspectionDay != null ||
                auction.startTime != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.visibility,
                      size: 14, color: Colors.purple),
                  const SizedBox(width: 4),
                  Text('معاينة: ${_fmt(auction.inspectionDay)}',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.purple)),
                  const SizedBox(width: 12),
                  const Icon(Icons.gavel, size: 14, color: Colors.green),
                  const SizedBox(width: 4),
                  Text('مزاد: ${_fmt(auction.startTime)}',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.green)),
                ],
              ),
            ],

            const SizedBox(height: 10),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    // submitted → موافقة أو رفض
    if (auction.status == AuctionStatus.submitted) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.close, size: 16, color: Colors.red),
              label: const Text('رفض',
                  style: TextStyle(color: Colors.red, fontSize: 13)),
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 6)),
              onPressed: onReject,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check, size: 16, color: Colors.white),
              label: const Text('موافقة',
                  style: TextStyle(color: Colors.white, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 6)),
              onPressed: onApprove,
            ),
          ),
        ],
      );
    }

    // approved → تحديد الجدول + تعديل السعر + تفعيل
    if (auction.status == AuctionStatus.approved) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.price_change,
                      size: 16, color: Color(0xFF1565C0)),
                  label: const Text('تعديل السعر',
                      style: TextStyle(
                          color: Color(0xFF1565C0), fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                      padding:
                      const EdgeInsets.symmetric(vertical: 6)),
                  onPressed: onAdjustPrice,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_month,
                      size: 16, color: Colors.purple),
                  label: const Text('تحديد الموعد',
                      style:
                      TextStyle(color: Colors.purple, fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.purple),
                      padding:
                      const EdgeInsets.symmetric(vertical: 6)),
                  onPressed: onSetSchedule,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow,
                  size: 16, color: Colors.white),
              label: const Text('تفعيل المزاد',
                  style: TextStyle(color: Colors.white, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 8)),
              onPressed: onActivate,
            ),
          ),
        ],
      );
    }

    // ended → تحديد الفائز
    if (auction.status == AuctionStatus.ended &&
        auction.winnerId == null) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.emoji_events,
              size: 16, color: Colors.white),
          label: const Text('تحديد الفائز',
              style: TextStyle(color: Colors.white, fontSize: 13)),
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              padding: const EdgeInsets.symmetric(vertical: 8)),
          onPressed: onDeclareWinner,
        ),
      );
    }

    if (auction.status == AuctionStatus.ended &&
        auction.winnerId != null) {
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

// ── Badge الحالة ─────────────────────────────────────────────────────────
class AuctionStatusBadge extends StatelessWidget {
  final AuctionStatus status;
  const AuctionStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final info = _info(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (info['color'] as Color).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: info['color'] as Color, width: 0.5),
      ),
      child: Text(info['label'] as String,
          style: TextStyle(
              fontSize: 11,
              color: info['color'] as Color,
              fontWeight: FontWeight.w500)),
    );
  }

  Map<String, dynamic> _info(AuctionStatus s) {
    switch (s) {
      case AuctionStatus.submitted:
        return {'label': 'قيد المراجعة', 'color': Colors.orange};
      case AuctionStatus.approved:
        return {'label': 'مقبول', 'color': Colors.blue};
      case AuctionStatus.active:
        return {'label': 'نشط', 'color': Colors.green};
      case AuctionStatus.ended:
        return {'label': 'منتهي', 'color': Colors.grey};
      case AuctionStatus.rejected:
        return {'label': 'مرفوض', 'color': Colors.red};
      default:
        return {'label': s.label, 'color': Colors.grey};
    }
  }
}

// ── Dialog تحديد الجدول ──────────────────────────────────────────────────
class _ScheduleDialog extends StatefulWidget {
  final AuctionModel auction;
  final void Function(DateTime, DateTime, DateTime) onSave;

  const _ScheduleDialog({required this.auction, required this.onSave});

  @override
  State<_ScheduleDialog> createState() => _ScheduleDialogState();
}

class _ScheduleDialogState extends State<_ScheduleDialog> {
  DateTime? _inspectionDay;
  DateTime? _startTime;
  DateTime? _endTime;

  Future<DateTime?> _pickDateTime(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return null;
    if (!context.mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return null;
    return DateTime(
        date.year, date.month, date.day, time.hour, time.minute);
  }

  String _fmt(DateTime? d) {
    if (d == null) return 'اضغط للاختيار';
    return '${d.day}/${d.month}/${d.year}  ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('جدول المزاد: ${widget.auction.title}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // يوم المعاينة
          _DateTile(
            icon: Icons.visibility,
            label: 'يوم المعاينة',
            value: _fmt(_inspectionDay),
            color: Colors.purple,
            onTap: () async {
              final d = await _pickDateTime(context);
              if (d != null) setState(() => _inspectionDay = d);
            },
          ),
          const SizedBox(height: 10),
          // بداية المزاد
          _DateTile(
            icon: Icons.play_arrow,
            label: 'بداية المزاد',
            value: _fmt(_startTime),
            color: Colors.green,
            onTap: () async {
              final d = await _pickDateTime(context);
              if (d != null) setState(() => _startTime = d);
            },
          ),
          const SizedBox(height: 10),
          // نهاية المزاد
          _DateTile(
            icon: Icons.stop,
            label: 'نهاية المزاد',
            value: _fmt(_endTime),
            color: Colors.red,
            onTap: () async {
              final d = await _pickDateTime(context);
              if (d != null) setState(() => _endTime = d);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0)),
          onPressed: () {
            if (_inspectionDay == null ||
                _startTime == null ||
                _endTime == null) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('يرجى تحديد جميع التواريخ'),
                backgroundColor: Colors.red,
              ));
              return;
            }
            widget.onSave(_inspectionDay!, _startTime!, _endTime!);
            Navigator.pop(context);
          },
          child: const Text('حفظ', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

class _DateTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;

  const _DateTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w600)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
