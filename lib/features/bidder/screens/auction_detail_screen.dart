import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:auction_app2/shared/models/auction_model.dart';
import 'package:auction_app2/shared/models/bid_model.dart';
import '../../../core/constants/ds_colors.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../widgets/detail_countdown_timer.dart';
import '../widgets/bid_history_list.dart';
import '../widgets/bid_bottom_bar.dart';

class AuctionDetailScreen extends StatefulWidget {
  final String auctionId;
  const AuctionDetailScreen({super.key, required this.auctionId});
  @override
  State<AuctionDetailScreen> createState() => _AuctionDetailScreenState();
}

class _AuctionDetailScreenState extends State<AuctionDetailScreen>
    with TickerProviderStateMixin {
  final _bidCtrl = TextEditingController();
  bool _placing = false;
  String? _bidError;

  late AnimationController _contentAnim;
  late Animation<double> _contentFade;

  Stream<AuctionModel?> _auctionStream() =>
      FirebaseFirestore.instance.collection('auctions').doc(widget.auctionId)
          .snapshots().map((d) => d.exists ? AuctionModel.fromMap(d.data()!, d.id) : null);

  Stream<List<BidModel>> _bidsStream() =>
      FirebaseFirestore.instance.collection('bids')
          .where('auctionId', isEqualTo: widget.auctionId)
          .orderBy('amount', descending: true).limit(20)
          .snapshots().map((s) => s.docs.map((d) => BidModel.fromMap(d.data(), d.id)).toList());

  @override
  void initState() {
    super.initState();
    _contentAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _contentFade = CurvedAnimation(parent: _contentAnim, curve: Curves.easeOutCubic);
    _contentAnim.forward();
  }

  @override
  void dispose() { _bidCtrl.dispose(); _contentAnim.dispose(); super.dispose(); }

  Future<void> _placeBid(AuctionModel auction) async {
    setState(() => _bidError = null);
    final amount = double.tryParse(_bidCtrl.text.trim());
    if (amount == null) { setState(() => _bidError = 'أدخل مبلغاً صحيحاً'); return; }
    if (amount <= (auction.currentPrice ?? 0)) {
      setState(() => _bidError = 'يجب أن يكون المبلغ أكبر من ${(auction.currentPrice ?? 0).toStringAsFixed(0)} DZD');
      return;
    }
    final confirmed = await _confirmDialog(amount, auction);
    if (!confirmed) return;
    setState(() => _placing = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final batch = FirebaseFirestore.instance.batch();
      final bidRef = FirebaseFirestore.instance.collection('bids').doc();
      batch.set(bidRef, {'auctionId': widget.auctionId, 'bidderId': uid, 'amount': amount, 'timestamp': FieldValue.serverTimestamp(), 'status': 'active'});
      batch.update(FirebaseFirestore.instance.collection('auctions').doc(widget.auctionId), {'currentPrice': amount});
      await batch.commit(); _bidCtrl.clear();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ تم تسجيل المزايدة بنجاح')));
    } catch (e) { setState(() => _bidError = 'فشل: $e'); }
    finally { if (mounted) setState(() => _placing = false); }
  }

  Future<bool> _confirmDialog(double amount, AuctionModel auction) async {
    return await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(backgroundColor: Colors.transparent, child: ClipRRect(borderRadius: BorderRadius.circular(28), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), child: Container(padding: const EdgeInsets.all(28), decoration: BoxDecoration(color: DS.bgModal.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(28), border: Border.all(color: DS.border.withValues(alpha: 0.5))), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 60, height: 60, decoration: BoxDecoration(shape: BoxShape.circle, gradient: DS.goldGradient, boxShadow: DS.goldShadow), child: const Icon(Icons.gavel_rounded, color: Colors.white, size: 28)),
        const SizedBox(height: 18), Text('تأكيد المزايدة', style: DS.titleM), const SizedBox(height: 8), Text(auction.title, style: DS.body, textAlign: TextAlign.center), const SizedBox(height: 20),
        Container(width: double.infinity, padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: DS.goldSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: DS.borderGold)), child: Text('${amount.toStringAsFixed(0)} DZD', style: DS.titleL.copyWith(color: DS.goldLight), textAlign: TextAlign.center)),
        const SizedBox(height: 24),
        Row(children: [Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء'))), const SizedBox(width: 12), Expanded(child: GradientButton(label: 'تأكيد', isGold: true, height: 48, onPressed: () => Navigator.pop(context, true)))])
      ]))))),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(backgroundColor: DS.bg, body: StreamBuilder<AuctionModel?>(stream: _auctionStream(), builder: (ctx, snap) {
      if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: DS.purple));
      final auction = snap.data;
      if (auction == null) return const Center(child: Text('المزاد غير موجود', style: TextStyle(color: DS.textSecondary)));
      final isActive = auction.status == AuctionStatus.active;
      return Stack(children: [
        CustomScrollView(physics: const BouncingScrollPhysics(), slivers: [
          SliverAppBar(expandedHeight: 320, pinned: true, stretch: true, backgroundColor: DS.bg, leading: GestureDetector(onTap: () => Navigator.pop(context), child: Container(margin: const EdgeInsets.all(8), decoration: BoxDecoration(color: DS.bg.withValues(alpha: 0.5), shape: BoxShape.circle, border: Border.all(color: DS.border.withValues(alpha: 0.4))), child: ClipOval(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: DS.textPrimary))))), flexibleSpace: FlexibleSpaceBar(stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground], background: Stack(fit: StackFit.expand, children: [
            auction.imageUrl != null && auction.imageUrl!.isNotEmpty ? Image.network(auction.imageUrl!, fit: BoxFit.cover) : Container(decoration: const BoxDecoration(gradient: DS.headerGradient), child: Center(child: Icon(Icons.gavel_rounded, size: 80, color: DS.gold.withValues(alpha: 0.4)))),
            Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, DS.bg.withValues(alpha: 0.2), DS.bg.withValues(alpha: 0.8), DS.bg], begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: const [0.0, 0.35, 0.7, 1.0]))),
          ]))),
          SliverToBoxAdapter(child: FadeTransition(opacity: _contentFade, child: Padding(padding: EdgeInsets.fromLTRB(20, 0, 20, isActive ? 140 : 100), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [_badgeForStatus(auction.status), const Spacer(), if (auction.category != null) Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: DS.bgElevated, borderRadius: BorderRadius.circular(20), border: Border.all(color: DS.border)), child: Text(auction.category!, style: DS.bodySmall.copyWith(fontWeight: FontWeight.w600)))]), const SizedBox(height: 12),
            FadeSlideIn(delay: const Duration(milliseconds: 150), child: Text(auction.title, style: DS.titleXL)), const SizedBox(height: 8),
            FadeSlideIn(delay: const Duration(milliseconds: 250), child: Text(auction.description, style: DS.body)), const SizedBox(height: 20),
            FadeSlideIn(delay: const Duration(milliseconds: 350), child: Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(gradient: const LinearGradient(colors: [DS.purpleDeep, DS.bgCard], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(20), border: Border.all(color: DS.purple.withValues(alpha: 0.2))), child: Row(children: [
              Expanded(child: DSPriceTag(label: 'السعر الحالي', amount: '${(auction.currentPrice ?? auction.startingPrice).toStringAsFixed(0)} DZD', isGold: true, large: true)),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('السعر الابتدائي', style: DS.label), const SizedBox(height: 3), Text('${auction.startingPrice.toStringAsFixed(0)} DZD', style: DS.bodySmall.copyWith(color: DS.textSecondary)), if (isActive && auction.endDateTime != null) ...[const SizedBox(height: 10), DetailCountdownTimer(endTime: auction.endDateTime!)]]),
            ]))),
            const SizedBox(height: 24),
            FadeSlideIn(delay: const Duration(milliseconds: 450), child: const DSSection(title: 'سجل المزايدات')), const SizedBox(height: 12),
            FadeSlideIn(delay: const Duration(milliseconds: 500), child: BidHistoryList(bidsStream: _bidsStream())),
          ])))),
        ]),
        if (isActive) BidBottomBar(controller: _bidCtrl, isPlacing: _placing, bidError: _bidError, onBidPressed: () => _placeBid(auction), onChanged: (v) { if (_bidError != null) setState(() => _bidError = null); }),
      ]);
    })));
  }

  Widget _badgeForStatus(AuctionStatus s) {
    switch (s) {
      case AuctionStatus.active: return const DarkBadge(label: 'مباشر الآن', color: DS.success, dot: true, pulse: true);
      case AuctionStatus.approved: return const DarkBadge(label: 'قادم', color: DS.purple, dot: true);
      case AuctionStatus.ended: return const DarkBadge(label: 'منتهي', color: DS.textMuted);
      default: return DarkBadge(label: s.label, color: DS.textMuted);
    }
  }
}
