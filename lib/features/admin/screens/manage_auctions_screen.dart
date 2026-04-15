import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:auction_app2/shared/models/auction_model.dart';
import 'package:auction_app2/core/services/firebase/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/ds_colors.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../widgets/admin_auction_card.dart';
import '../widgets/admin_auction_list.dart';
import '../widgets/auction_schedule_dialog.dart';

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
    {'label': 'الكل', 'status': null, 'icon': Icons.list_rounded, 'color': DS.textSecondary},
    {'label': 'قيد المراجعة', 'status': AuctionStatus.submitted, 'icon': Icons.hourglass_top_rounded, 'color': DS.warning},
    {'label': 'مقبول', 'status': AuctionStatus.approved, 'icon': Icons.check_circle_rounded, 'color': DS.info},
    {'label': 'نشط', 'status': AuctionStatus.active, 'icon': Icons.bolt_rounded, 'color': DS.success},
    {'label': 'منتهي', 'status': AuctionStatus.ended, 'icon': Icons.flag_rounded, 'color': DS.textMuted},
    {'label': 'مرفوض', 'status': AuctionStatus.rejected, 'icon': Icons.cancel_rounded, 'color': DS.error},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  Future<void> _approve(AuctionModel auction) async {
    final confirm = await _showConfirm(title: 'تأكيد الموافقة', content: 'الموافقة على "${auction.title}"؟\nيمكنك لاحقاً تحديد الجدول الزمني.', confirmText: 'موافقة', confirmColor: DS.success);
    if (!confirm) return;
    try { await _db.approveAuction(auction.id); _showSnack('تمت الموافقة على المزاد ✅'); } catch (e) { _showSnack('خطأ: $e', isError: true); }
  }

  Future<void> _setSchedule(AuctionModel auction) async {
    DateTime? inspectionDay, startTime, endTime;
    await showDialog(context: context, builder: (ctx) => AuctionScheduleDialog(auction: auction, onSave: (i, s, e) { inspectionDay = i; startTime = s; endTime = e; }));
    if (inspectionDay == null || startTime == null || endTime == null) return;
    try { await _db.setAuctionSchedule(auctionId: auction.id, organizerId: auction.organizerId, inspectionDay: inspectionDay!, startTime: startTime!, endTime: endTime!); _showSnack('تم تحديد الجدول وإشعار البائع ✅'); } catch (e) { _showSnack('خطأ: $e', isError: true); }
  }

  Future<void> _adjustPrice(AuctionModel auction) async {
    final priceCtrl = TextEditingController(text: (auction.adminAdjustedPrice ?? auction.startingPrice).toStringAsFixed(2));
    final noteCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(backgroundColor: Colors.transparent, child: ClipRRect(borderRadius: BorderRadius.circular(24), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), child: Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: DS.bgModal.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(24), border: Border.all(color: DS.border)), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('تعديل السعر الابتدائي', style: DS.titleM),
        const SizedBox(height: 16),
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: DS.bgElevated, borderRadius: BorderRadius.circular(12)), child: Text('السعر الأصلي: ${auction.startingPrice.toStringAsFixed(0)} DZD', style: const TextStyle(color: DS.textSecondary, fontSize: 13))),
        const SizedBox(height: 14),
        TextField(controller: priceCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), textDirection: TextDirection.ltr, decoration: const InputDecoration(labelText: 'السعر الجديد (DZD)', prefixIcon: Icon(Icons.payments_rounded))),
        const SizedBox(height: 12),
        TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'سبب التعديل', hintText: 'اكتب سبب تعديل السعر...'), maxLines: 2),
        const SizedBox(height: 20),
        Row(children: [Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء'))), const SizedBox(width: 12), Expanded(child: GradientButton(label: 'تأكيد', height: 48, onPressed: () => Navigator.pop(context, true)))])
      ]))))),
    );
    if (confirm != true) return;
    final newPrice = double.tryParse(priceCtrl.text.trim());
    if (newPrice == null) { _showSnack('سعر غير صحيح', isError: true); return; }
    try { await _db.adjustAuctionPrice(auctionId: auction.id, organizerId: auction.organizerId, newPrice: newPrice, adminNote: noteCtrl.text.trim().isEmpty ? 'تعديل من المسؤول' : noteCtrl.text.trim()); _showSnack('تم تعديل السعر وإشعار البائع ✅'); } catch (e) { _showSnack('خطأ: $e', isError: true); }
  }

  Future<void> _activate(AuctionModel auction) async {
    if (auction.startTime == null || auction.inspectionDay == null) { _showSnack('حدد يوم المعاينة وتاريخ المزاد أولاً', isError: true); return; }
    final confirm = await _showConfirm(title: 'تفعيل المزاد', content: 'سيتم نشر المزاد وإتاحته للمزايدين.', confirmText: 'تفعيل', confirmColor: DS.success);
    if (!confirm) return;
    try { await _db.activateAuction(auction.id); _showSnack('تم تفعيل المزاد ✅'); } catch (e) { _showSnack('خطأ: $e', isError: true); }
  }

  Future<void> _reject(AuctionModel auction) async {
    final reasonCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(backgroundColor: Colors.transparent, child: ClipRRect(borderRadius: BorderRadius.circular(24), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), child: Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: DS.bgModal.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(24), border: Border.all(color: DS.error.withValues(alpha: 0.3))), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: DS.errorSurface, shape: BoxShape.circle, border: Border.all(color: DS.error.withValues(alpha: 0.3))), child: const Icon(Icons.cancel_rounded, color: DS.error, size: 28)),
        const SizedBox(height: 14), Text('رفض المزاد', style: DS.titleM), Text(auction.title, style: DS.body, textAlign: TextAlign.center), const SizedBox(height: 16),
        TextField(controller: reasonCtrl, decoration: const InputDecoration(labelText: 'سبب الرفض'), maxLines: 3), const SizedBox(height: 20),
        Row(children: [Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء'))), const SizedBox(width: 12), Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: DS.error), onPressed: () => Navigator.pop(context, true), child: const Text('رفض', style: TextStyle(color: Colors.white))))])
      ]))))),
    );
    if (confirm != true) return;
    try { await _db.rejectAuction(auction.id, reason: reasonCtrl.text.trim()); _showSnack('تم رفض المزاد'); } catch (e) { _showSnack('خطأ: $e', isError: true); }
  }

  Future<void> _declareWinner(AuctionModel auction) async {
    final topBid = await _db.getTopBid(auction.id);
    if (topBid == null) { _showSnack('لا توجد مزايدات'); return; }
    final winnerId = topBid['bidderId'] as String;
    final confirm = await _showConfirm(title: 'تحديد الفائز', content: 'المبلغ: ${topBid['amount'].toStringAsFixed(0)} DZD', confirmText: 'تأكيد', confirmColor: DS.gold);
    if (!confirm) return;
    try { await _db.declareWinner(auctionId: auction.id, winnerId: winnerId); _showSnack('تم تحديد الفائز ✅'); } catch (e) { _showSnack('خطأ: $e', isError: true); }
  }

  Future<void> _delete(AuctionModel auction) async {
    final confirm = await _showConfirm(title: 'حذف المزاد نهائياً', content: 'هل أنت متأكد من حذف "${auction.title}"؟', confirmText: 'حذف', confirmColor: DS.error);
    if (!confirm) return;
    try { await _db.deleteAuction(auction.id); _showSnack('تم حذف المزاد بنجاح 🗑️'); } catch (e) { _showSnack('خطأ: $e', isError: true); }
  }

  Future<bool> _showConfirm({required String title, required String content, required String confirmText, required Color confirmColor}) async {
    final result = await showDialog<bool>(context: context, builder: (_) => Dialog(backgroundColor: Colors.transparent, child: ClipRRect(borderRadius: BorderRadius.circular(24), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), child: Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: DS.bgModal.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(24), border: Border.all(color: DS.border)), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(title, style: DS.titleM), const SizedBox(height: 10), Text(content, style: DS.body, textAlign: TextAlign.center), const SizedBox(height: 20), Row(children: [Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء'))), const SizedBox(width: 12), Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: confirmColor), onPressed: () => Navigator.pop(context, true), child: Text(confirmText, style: const TextStyle(color: Colors.white))))])]))))));
    return result ?? false;
  }

  void _showSnack(String msg, {bool isError = false}) { if (!mounted) return; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: isError ? DS.error : DS.success)); }

  @override
  Widget build(BuildContext context) {
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(backgroundColor: DS.bg, body: Column(children: [
      Container(height: 180, decoration: const BoxDecoration(gradient: DS.headerGradient), child: Stack(children: [
        const Positioned(top: -60, left: -60, child: PurpleOrb(size: 200, opacity: 0.25)),
        SafeArea(bottom: false, child: Column(children: [
          Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 0), child: Row(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: DS.purple.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.gavel_rounded, color: DS.purple, size: 22)), const SizedBox(width: 14), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('إدارة المزادات', style: DS.titleL), Text('مراجعة، موافقة وجدولة المزادات', style: DS.bodySmall)])])),
          const Spacer(),
          TabBar(controller: _tabController, isScrollable: true, tabAlignment: TabAlignment.start, indicatorColor: DS.purple, indicatorWeight: 4, indicatorSize: TabBarIndicatorSize.label, labelColor: DS.textPrimary, unselectedLabelColor: DS.textMuted, labelStyle: DS.label.copyWith(fontSize: 13, fontWeight: FontWeight.w700), unselectedLabelStyle: DS.label.copyWith(fontSize: 13), dividerColor: Colors.transparent, padding: const EdgeInsets.symmetric(horizontal: 12), tabs: _tabs.map((t) => Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(t['icon'] as IconData, size: 14), const SizedBox(width: 6), Text(t['label'] as String)]))).toList())
        ]))
      ])),
      Expanded(child: TabBarView(controller: _tabController, children: _tabs.map((t) => AdminAuctionList(stream: _db.streamAuctions(status: t['status'] as AuctionStatus?), onApprove: _approve, onReject: _reject, onSetSchedule: _setSchedule, onAdjustPrice: _adjustPrice, onActivate: _activate, onDeclareWinner: _declareWinner, onDelete: _delete)).toList()))
    ])));
  }
}
