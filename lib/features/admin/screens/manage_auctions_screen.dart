import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:auction_app2/shared/models/auction_model.dart';
import 'package:auction_app2/core/services/firebase/firestore_service.dart';
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
    {'label': 'الكل',        'status': null,                     'icon': Icons.list_rounded,          'color': DS.textSecondary},
    {'label': 'قيد المراجعة','status': AuctionStatus.submitted,  'icon': Icons.hourglass_top_rounded, 'color': DS.warning},
    {'label': 'مقبول',       'status': AuctionStatus.approved,   'icon': Icons.check_circle_rounded,  'color': DS.info},
    {'label': 'نشط',         'status': AuctionStatus.active,     'icon': Icons.bolt_rounded,          'color': DS.success},
    {'label': 'منتهي',       'status': AuctionStatus.ended,      'icon': Icons.flag_rounded,          'color': DS.textMuted},
    {'label': 'مرفوض',       'status': AuctionStatus.rejected,   'icon': Icons.cancel_rounded,        'color': DS.error},
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

  Future<void> _approve(AuctionModel auction) async {
    final confirm = await _showConfirm(
      title:        'تأكيد الموافقة',
      content:      'الموافقة على "${auction.title}"؟\nيمكنك لاحقاً تحديد الجدول الزمني.',
      confirmText:  'موافقة',
      confirmColor: DS.success,
    );
    if (!confirm) return;
    try {
      await _db.approveAuction(auction);
      _showSnack('تمت الموافقة على المزاد ✅');
    } catch (e) {
      _showSnack('خطأ: $e', isError: true);
    }
  }

  Future<void> _setSchedule(AuctionModel auction) async {
    DateTime? inspectionDay, startTime, endTime;
    await showDialog(
      context: context,
      builder: (ctx) => AuctionScheduleDialog(
        auction: auction,
        onSave: (i, s, e) {
          inspectionDay = i;
          startTime     = s;
          endTime       = e;
        },
      ),
    );
    if (inspectionDay == null || startTime == null || endTime == null) return;
    try {
      await _db.setAuctionSchedule(
        auctionId:     auction.id,
        organizerId:   auction.organizerId,
        auctionTitle:  auction.title,
        inspectionDay: inspectionDay!,
        startTime:     startTime!,
        endTime:       endTime!,
      );
      _showSnack('تم تحديد الجدول وإشعار البائع ✅');
    } catch (e) {
      _showSnack('خطأ: $e', isError: true);
    }
  }

  Future<void> _adjustPrice(AuctionModel auction) async {
    final priceCtrl = TextEditingController(
      text: (auction.adminAdjustedPrice ?? auction.startingPrice).toStringAsFixed(2),
    );
    final noteCtrl = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: DS.bgModal.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: DS.border),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('تعديل السعر الابتدائي', style: DS.titleM),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: DS.bgElevated,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'السعر الأصلي: ${auction.startingPrice.toStringAsFixed(0)} DZD',
                    style: const TextStyle(color: DS.textSecondary, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(
                    labelText: 'السعر الجديد (DZD)',
                    prefixIcon: Icon(Icons.payments_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(
                    labelText: 'سبب التعديل',
                    hintText:  'اكتب سبب تعديل السعر...',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('إلغاء'),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: GradientButton(
                    label: 'تأكيد', height: 48,
                    onPressed: () => Navigator.pop(context, true),
                  )),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );

    if (confirm != true) return;
    final newPrice = double.tryParse(priceCtrl.text.trim());
    if (newPrice == null) { _showSnack('سعر غير صحيح', isError: true); return; }
    try {
      await _db.adjustAuctionPrice(
        auctionId:    auction.id,
        organizerId:  auction.organizerId,
        auctionTitle: auction.title,
        newPrice:     newPrice,
        adminNote:    noteCtrl.text.trim().isEmpty ? 'تعديل من المسؤول' : noteCtrl.text.trim(),
      );
      _showSnack('تم تعديل السعر وإشعار البائع ✅');
    } catch (e) {
      _showSnack('خطأ: $e', isError: true);
    }
  }

  Future<void> _activate(AuctionModel auction) async {
    if (auction.startTime == null || auction.inspectionDay == null) {
      _showSnack('حدد يوم المعاينة وتاريخ المزاد أولاً', isError: true);
      return;
    }
    final confirm = await _showConfirm(
      title:        'تفعيل المزاد',
      content:      'سيتم نشر المزاد وإتاحته للمزايدين.',
      confirmText:  'تفعيل',
      confirmColor: DS.success,
    );
    if (!confirm) return;
    try {
      await _db.activateAuction(auction);
      _showSnack('تم تفعيل المزاد ✅');
    } catch (e) {
      _showSnack('خطأ: $e', isError: true);
    }
  }

  Future<void> _reject(AuctionModel auction) async {
    final reasonCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: DS.bgModal.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: DS.error.withValues(alpha: 0.3)),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: DS.errorSurface, shape: BoxShape.circle,
                    border: Border.all(color: DS.error.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.cancel_rounded, color: DS.error, size: 28),
                ),
                const SizedBox(height: 14),
                Text('رفض المزاد', style: DS.titleM),
                Text(auction.title, style: DS.body, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonCtrl,
                  decoration: const InputDecoration(labelText: 'سبب الرفض'),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('إلغاء'),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: ElevatedButton(
                    style:     ElevatedButton.styleFrom(backgroundColor: DS.error),
                    onPressed: () => Navigator.pop(context, true),
                    child:     const Text('رفض', style: TextStyle(color: Colors.white)),
                  )),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
    if (confirm != true) return;
    try {
      await _db.rejectAuction(auction, reason: reasonCtrl.text.trim());
      _showSnack('تم رفض المزاد');
    } catch (e) {
      _showSnack('خطأ: $e', isError: true);
    }
  }

  Future<void> _declareWinner(AuctionModel auction) async {
    final topBid = await _db.getTopBid(auction.id);
    if (topBid == null) { _showSnack('لا توجد مزايدات'); return; }
    final winnerId = topBid['bidderId'] as String;
    final confirm  = await _showConfirm(
      title:        'تحديد الفائز',
      content:      'المبلغ: ${topBid['amount'].toStringAsFixed(0)} DZD',
      confirmText:  'تأكيد',
      confirmColor: DS.gold,
    );
    if (!confirm) return;
    try {
      await _db.declareWinner(auction: auction, winnerId: winnerId);
      _showSnack('تم تحديد الفائز ✅');
    } catch (e) {
      _showSnack('خطأ: $e', isError: true);
    }
  }

  // ✅ إرجاع الضمانات مع Dialog اختيار الطريقة
  Future<void> _refundDeposits(AuctionModel auction) async {
    if (auction.winnerId == null) {
      _showSnack('حدد الفائز أولاً قبل إرجاع الضمانات', isError: true);
      return;
    }

    final depositPaidBy = auction.depositPaidBy ?? [];
    final losers = depositPaidBy.where((uid) => uid != auction.winnerId).toList();

    if (losers.isEmpty) {
      _showSnack('لا يوجد مزايدون لإرجاع ضماناتهم');
      return;
    }

    // ✅ Dialog اختيار طريقة الإرجاع
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _RefundMethodDialog(
        depositAmount: auction.deposit,
        losersCount:   losers.length,
      ),
    );

    if (result == null) return;

    try {
      await _db.refundDeposits(
        auctionId:          auction.id,
        winnerId:           auction.winnerId!,
        depositAmount:      auction.deposit,
        refundMethod:       result['method'],
        bankAccountNumber:  result['bankAccountNumber'],
        bankName:           result['bankName'],
      );
      _showSnack('تم إرجاع الضمانات بنجاح ✅');
    } catch (e) {
      _showSnack('خطأ: $e', isError: true);
    }
  }

  Future<void> _delete(AuctionModel auction) async {
    final confirm = await _showConfirm(
      title:        'حذف المزاد نهائياً',
      content:      'هل أنت متأكد من حذف "${auction.title}"؟',
      confirmText:  'حذف',
      confirmColor: DS.error,
    );
    if (!confirm) return;
    try {
      await _db.deleteAuction(auction.id);
      _showSnack('تم حذف المزاد بنجاح 🗑️');
    } catch (e) {
      _showSnack('خطأ: $e', isError: true);
    }
  }

  Future<bool> _showConfirm({
    required String title,
    required String content,
    required String confirmText,
    required Color  confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: DS.bgModal.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: DS.border),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(title, style: DS.titleM),
                const SizedBox(height: 10),
                Text(content, style: DS.body, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('إلغاء'),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: ElevatedButton(
                    style:     ElevatedButton.styleFrom(backgroundColor: confirmColor),
                    onPressed: () => Navigator.pop(context, true),
                    child:     Text(confirmText, style: const TextStyle(color: Colors.white)),
                  )),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
    return result ?? false;
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: isError ? DS.error : DS.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: DS.bg,
        body: Column(children: [
          Container(
            height: 180,
            decoration: const BoxDecoration(gradient: DS.headerGradient),
            child: Stack(children: [
              const Positioned(
                top: -60, left: -60,
                child: PurpleOrb(size: 200, opacity: 0.25),
              ),
              SafeArea(
                bottom: false,
                child: Column(children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: DS.purple.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.gavel_rounded, color: DS.purple, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('إدارة المزادات', style: DS.titleL),
                        Text('مراجعة، موافقة وجدولة المزادات', style: DS.bodySmall),
                      ]),
                    ]),
                  ),
                  const Spacer(),
                  TabBar(
                    controller:           _tabController,
                    isScrollable:         true,
                    tabAlignment:         TabAlignment.start,
                    indicatorColor:       DS.purple,
                    indicatorWeight:      4,
                    indicatorSize:        TabBarIndicatorSize.label,
                    labelColor:           DS.textPrimary,
                    unselectedLabelColor: DS.textMuted,
                    labelStyle:           DS.label.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
                    unselectedLabelStyle: DS.label.copyWith(fontSize: 13),
                    dividerColor:         Colors.transparent,
                    padding:              const EdgeInsets.symmetric(horizontal: 12),
                    tabs: _tabs.map((t) => Tab(
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(t['icon'] as IconData, size: 14),
                        const SizedBox(width: 6),
                        Text(t['label'] as String),
                      ]),
                    )).toList(),
                  ),
                ]),
              ),
            ]),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _tabs.map((t) => AdminAuctionList(
                stream:          _db.streamAuctions(status: t['status'] as AuctionStatus?),
                onApprove:       _approve,
                onReject:        _reject,
                onSetSchedule:   _setSchedule,
                onAdjustPrice:   _adjustPrice,
                onActivate:      _activate,
                onDeclareWinner: _declareWinner,
                onRefundDeposits: _refundDeposits, // ✅ جديد
                onDelete:        _delete,
              )).toList(),
            ),
          ),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ✅ Dialog اختيار طريقة الإرجاع
// ══════════════════════════════════════════════════════════════════════════════
class _RefundMethodDialog extends StatefulWidget {
  final double depositAmount;
  final int    losersCount;
  const _RefundMethodDialog({required this.depositAmount, required this.losersCount});
  @override
  State<_RefundMethodDialog> createState() => _RefundMethodDialogState();
}

class _RefundMethodDialogState extends State<_RefundMethodDialog> {
  String _method = 'wallet'; // 'wallet' أو 'bank'
  final _bankAccountCtrl = TextEditingController();
  final _bankNameCtrl    = TextEditingController();

  @override
  void dispose() {
    _bankAccountCtrl.dispose();
    _bankNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final netAmount = widget.depositAmount - FirestoreService.subscriptionFee;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: DS.bgModal.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: DS.border),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [

                // ── Header ──
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: DS.purple.withValues(alpha: 0.1),
                    border: Border.all(color: DS.purple.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.account_balance_wallet_rounded, color: DS.purple, size: 26),
                ),
                const SizedBox(height: 14),
                Text('إرجاع الضمانات', style: DS.titleM),
                const SizedBox(height: 6),
                Text(
                  'عدد المزايدين: ${widget.losersCount}',
                  style: DS.body,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // ── تفاصيل المبلغ ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: DS.bgElevated,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: DS.border),
                  ),
                  child: Column(children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('مبلغ الضمان', style: DS.label),
                      Text('${widget.depositAmount.toStringAsFixed(0)} DZD',
                          style: DS.titleS),
                    ]),
                    const SizedBox(height: 6),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('رسوم الاشتراك', style: DS.label),
                      Text('- ${FirestoreService.subscriptionFee.toStringAsFixed(0)} DZD',
                          style: DS.titleS.copyWith(color: DS.error)),
                    ]),
                    Divider(color: DS.border, height: 16),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('صافي الإرجاع', style: DS.label),
                      Text('${netAmount.toStringAsFixed(0)} DZD',
                          style: DS.titleS.copyWith(color: DS.success)),
                    ]),
                  ]),
                ),
                const SizedBox(height: 20),

                // ── اختيار الطريقة ──
                Text('طريقة الإرجاع', style: DS.label),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _MethodOption(
                    icon:     Icons.account_balance_wallet_rounded,
                    label:    'المحفظة',
                    subtitle: 'فوري',
                    selected: _method == 'wallet',
                    color:    DS.purple,
                    onTap:    () => setState(() => _method = 'wallet'),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _MethodOption(
                    icon:     Icons.account_balance_rounded,
                    label:    'حساب بنكي',
                    subtitle: '3-5 أيام',
                    selected: _method == 'bank',
                    color:    DS.gold,
                    onTap:    () => setState(() => _method = 'bank'),
                  )),
                ]),

                // ── بيانات البنك ──
                if (_method == 'bank') ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _bankNameCtrl,
                    style: TextStyle(color: DS.textPrimary),
                    decoration: InputDecoration(
                      labelText:   'اسم البنك',
                      prefixIcon:  Icon(Icons.account_balance_rounded, color: DS.gold),
                      filled:      true,
                      fillColor:   DS.bgField,
                      border:      OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: DS.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: DS.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: DS.gold, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _bankAccountCtrl,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(color: DS.textPrimary),
                    decoration: InputDecoration(
                      labelText:   'رقم الحساب',
                      prefixIcon:  Icon(Icons.credit_card_rounded, color: DS.gold),
                      filled:      true,
                      fillColor:   DS.bgField,
                      border:      OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: DS.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: DS.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: DS.gold, width: 1.5),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                Row(children: [
                  Expanded(child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء'),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: GradientButton(
                    label:    'تأكيد الإرجاع',
                    height:   48,
                    isGold:   _method == 'bank',
                    onPressed: () {
                      if (_method == 'bank' && _bankAccountCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('أدخل رقم الحساب البنكي')),
                        );
                        return;
                      }
                      Navigator.pop(context, {
                        'method':            _method,
                        'bankAccountNumber': _bankAccountCtrl.text.trim(),
                        'bankName':          _bankNameCtrl.text.trim(),
                      });
                    },
                  )),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _MethodOption extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   subtitle;
  final bool     selected;
  final Color    color;
  final VoidCallback onTap;

  const _MethodOption({
    required this.icon, required this.label, required this.subtitle,
    required this.selected, required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color:        selected ? color.withValues(alpha: 0.08) : DS.bgElevated,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(
          color: selected ? color : DS.border,
          width: selected ? 2 : 1,
        ),
      ),
      child: Column(children: [
        Icon(icon, color: selected ? color : DS.textMuted, size: 24),
        const SizedBox(height: 6),
        Text(label,    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
            color: selected ? color : DS.textPrimary)),
        Text(subtitle, style: TextStyle(fontSize: 10, color: DS.textMuted)),
      ]),
    ),
  );
}