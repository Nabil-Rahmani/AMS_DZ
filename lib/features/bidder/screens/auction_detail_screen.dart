import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:auction_app2/shared/models/auction_model.dart';
import 'package:auction_app2/shared/models/bid_model.dart';
import 'package:auction_app2/core/services/firebase/firestore_service.dart';
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
  bool _depositPaying = false;
  String? _bidError;
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

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
  void dispose() {
    _bidCtrl.dispose();
    _contentAnim.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _openGallery(List<String> images, int index) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _GalleryScreen(images: images, initialIndex: index),
    ));
  }

  Future<void> _openMap(String location) async {
    final encoded = Uri.encodeComponent(location);
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

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
      batch.set(bidRef, {
        'auctionId': widget.auctionId,
        'bidderId': uid,
        'amount': amount,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'active',
      });
      batch.update(
        FirebaseFirestore.instance.collection('auctions').doc(widget.auctionId),
        {'currentPrice': amount},
      );
      await batch.commit();
      _bidCtrl.clear();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ تم تسجيل المزايدة بنجاح')),
      );
    } catch (e) {
      setState(() => _bidError = 'فشل: $e');
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  Future<void> _payDeposit(AuctionModel auction) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    if (auction.hasUserPaidDeposit(uid)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ أنت مشارك بالفعل في هذا المزاد')),
      );
      return;
    }
    final deposit = auction.deposit;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: DS.bgModal.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: DS.border),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: DS.purple.withValues(alpha: 0.1),
                    border: Border.all(color: DS.purple.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.lock_rounded, color: DS.purple, size: 28),
                ),
                const SizedBox(height: 18),
                Text('دفع الضمان', style: DS.titleM),
                const SizedBox(height: 8),
                Text('للمشاركة في هذا المزاد يجب دفع ضمان',
                    style: DS.body, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: DS.purple.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: DS.purple.withValues(alpha: 0.2)),
                  ),
                  child: Column(children: [
                    Text('مبلغ الضمان', style: DS.label),
                    const SizedBox(height: 4),
                    Text('${deposit.toStringAsFixed(0)} DZD',
                        style: DS.titleL.copyWith(color: DS.purple)),
                    Text('(10% من السعر الابتدائي)', style: DS.label),
                  ]),
                ),
                const SizedBox(height: 8),
                Text('سيُرجع إليك الضمان إذا لم تفز',
                    style: DS.bodySmall.copyWith(color: DS.textMuted),
                    textAlign: TextAlign.center),
                const SizedBox(height: 24),
                Row(children: [
                  Expanded(child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('إلغاء'),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: GradientButton(
                    label: 'دفع الضمان',
                    height: 48,
                    onPressed: () => Navigator.pop(context, true),
                  )),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
    if (confirmed != true) return;
    setState(() => _depositPaying = true);
    try {
      await FirestoreService().payDeposit(
        auctionId: auction.id,
        userId: uid,
        depositAmount: deposit,
      );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ تم دفع الضمان، أنت مشارك رسمي!')),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ $e'), backgroundColor: DS.error),
      );
    } finally {
      if (mounted) setState(() => _depositPaying = false);
    }
  }

  Future<bool> _confirmDialog(double amount, AuctionModel auction) async {
    return await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: DS.bgModal.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: DS.border.withValues(alpha: 0.5)),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: DS.goldGradient,
                    boxShadow: DS.goldShadow,
                  ),
                  child: const Icon(Icons.gavel_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 18),
                Text('تأكيد المزايدة', style: DS.titleM),
                const SizedBox(height: 8),
                Text(auction.title, style: DS.body, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: DS.goldSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: DS.borderGold),
                  ),
                  child: Text('${amount.toStringAsFixed(0)} DZD',
                      style: DS.titleL.copyWith(color: DS.goldLight),
                      textAlign: TextAlign.center),
                ),
                const SizedBox(height: 24),
                Row(children: [
                  Expanded(child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('إلغاء'),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: GradientButton(
                    label: 'تأكيد',
                    isGold: true,
                    height: 48,
                    onPressed: () => Navigator.pop(context, true),
                  )),
                ]),
              ]),
            ),
          ),
        ),
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: DS.bg,
        body: StreamBuilder<AuctionModel?>(
          stream: _auctionStream(),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: DS.purple));
            }
            final auction = snap.data;
            if (auction == null) {
              return const Center(child: Text('المزاد غير موجود',
                  style: TextStyle(color: DS.textSecondary)));
            }
            final isActive = auction.status == AuctionStatus.active;

            final List<String> allImages = [
              if (auction.imageUrl != null && auction.imageUrl!.isNotEmpty) auction.imageUrl!,
              ...?auction.imageUrls,
            ];

            return Stack(children: [
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [

                  // ── SliverAppBar ──
                  SliverAppBar(
                    expandedHeight: 320,
                    pinned: true,
                    stretch: true,
                    backgroundColor: DS.bg,
                    leading: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: DS.bg.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                          border: Border.all(color: DS.border.withValues(alpha: 0.4)),
                        ),
                        child: ClipOval(child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: const Icon(Icons.arrow_back_ios_new_rounded,
                              size: 16, color: DS.textPrimary),
                        )),
                      ),
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      stretchModes: const [StretchMode.zoomBackground],
                      background: allImages.isEmpty
                          ? Container(
                        decoration: const BoxDecoration(gradient: DS.headerGradient),
                        child: Center(child: Icon(Icons.gavel_rounded, size: 80,
                            color: DS.gold.withValues(alpha: 0.4))),
                      )
                          : Stack(children: [
                        PageView.builder(
                          controller: _pageController,
                          itemCount: allImages.length,
                          onPageChanged: (i) => setState(() => _currentImageIndex = i),
                          itemBuilder: (_, i) => GestureDetector(
                            onTap: () => _openGallery(allImages, i),
                            child: Image.network(allImages[i], fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: DS.bgCard,
                                child: const Center(child: Icon(Icons.broken_image_rounded,
                                    color: DS.textMuted, size: 48)),
                              ),
                            ),
                          ),
                        ),
                        Container(decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, DS.bg.withValues(alpha: 0.8), DS.bg],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.4, 0.8, 1.0],
                          ),
                        )),
                        if (allImages.length > 1)
                          Positioned(
                            bottom: 16, left: 0, right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(allImages.length, (i) =>
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    margin: const EdgeInsets.symmetric(horizontal: 3),
                                    width: _currentImageIndex == i ? 20 : 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: _currentImageIndex == i ? DS.purple : DS.border,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  )),
                            ),
                          ),
                        if (allImages.length > 1)
                          Positioned(
                            top: 50, left: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: Colors.black54,
                                  borderRadius: BorderRadius.circular(20)),
                              child: Text('${_currentImageIndex + 1}/${allImages.length}',
                                  style: const TextStyle(color: Colors.white, fontSize: 12)),
                            ),
                          ),
                        Positioned(
                          top: 50, right: 16,
                          child: GestureDetector(
                            onTap: () => _openGallery(allImages, _currentImageIndex),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.black54,
                                  borderRadius: BorderRadius.circular(20)),
                              child: const Icon(Icons.fullscreen_rounded,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),

                  // ── Content ──
                  SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: _contentFade,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(20, 0, 20, isActive ? 140 : 100),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                          Row(children: [
                            _badgeForStatus(auction.status),
                            const Spacer(),
                            if (auction.category != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: DS.bgElevated,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: DS.border),
                                ),
                                child: Text(auction.category!,
                                    style: DS.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                              ),
                          ]),
                          const SizedBox(height: 12),
                          FadeSlideIn(delay: const Duration(milliseconds: 150),
                              child: Text(auction.title, style: DS.titleXL)),
                          const SizedBox(height: 8),
                          FadeSlideIn(delay: const Duration(milliseconds: 250),
                              child: Text(auction.description, style: DS.body)),
                          const SizedBox(height: 20),

                          // ✅ Thumbnail strip
                          if (allImages.length > 1) ...[
                            SizedBox(
                              height: 72,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: allImages.length,
                                itemBuilder: (_, i) => GestureDetector(
                                  onTap: () {
                                    _pageController.animateToPage(i,
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut);
                                    setState(() => _currentImageIndex = i);
                                  },
                                  onLongPress: () => _openGallery(allImages, i),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.only(left: 8),
                                    width: 72, height: 72,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _currentImageIndex == i ? DS.purple : DS.border,
                                        width: _currentImageIndex == i ? 2.5 : 1,
                                      ),
                                      boxShadow: _currentImageIndex == i ? [
                                        BoxShadow(color: DS.purple.withValues(alpha: 0.3),
                                            blurRadius: 8, offset: const Offset(0, 2))
                                      ] : null,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(allImages[i], fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Icon(
                                            Icons.broken_image_rounded, color: DS.textMuted),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // ✅ Dynamic Details حسب الفئة
                          if (auction.details != null && auction.details!.isNotEmpty) ...[
                            _CategoryDetailsWidget(
                              category: auction.category ?? '',
                              details: auction.details!,
                            ),
                            const SizedBox(height: 20),
                          ],

                          // ✅ معلومات المزاد (يوم المعاينة + الموقع)
                          if (auction.inspectionDay != null || auction.location != null) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: DS.bgCard,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: DS.border),
                              ),
                              child: Column(children: [
                                if (auction.inspectionDay != null) ...[
                                  Row(children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: DS.purple.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(Icons.event_rounded, color: DS.purple, size: 18),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text('يوم المعاينة', style: DS.label),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${auction.inspectionDay!.day}/${auction.inspectionDay!.month}/${auction.inspectionDay!.year}',
                                        style: DS.titleS,
                                      ),
                                    ]),
                                  ]),
                                  if (auction.location != null)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      child: Divider(color: DS.border, height: 1),
                                    ),
                                ],
                                if (auction.location != null)
                                  GestureDetector(
                                    onTap: () => _openMap(auction.location!),
                                    child: Row(children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: DS.error.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(Icons.location_on_rounded,
                                            color: DS.error, size: 18),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('الموقع', style: DS.label),
                                          const SizedBox(height: 2),
                                          Text(auction.location!,
                                              style: DS.titleS.copyWith(color: DS.purple)),
                                        ],
                                      )),
                                      Icon(Icons.open_in_new_rounded, color: DS.purple, size: 16),
                                    ]),
                                  ),
                              ]),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // Price card
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 350),
                            child: Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [DS.purpleDeep, DS.bgCard],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: DS.purple.withValues(alpha: 0.2)),
                              ),
                              child: Row(children: [
                                Expanded(child: DSPriceTag(
                                  label: 'السعر الحالي',
                                  amount: '${(auction.currentPrice ?? auction.startingPrice).toStringAsFixed(0)} DZD',
                                  isGold: true,
                                  large: true,
                                )),
                                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                  Text('السعر الابتدائي', style: DS.label),
                                  const SizedBox(height: 3),
                                  Text('${auction.startingPrice.toStringAsFixed(0)} DZD',
                                      style: DS.bodySmall.copyWith(color: DS.textSecondary)),
                                  if (isActive && auction.endDateTime != null) ...[
                                    const SizedBox(height: 10),
                                    DetailCountdownTimer(endTime: auction.endDateTime!),
                                  ],
                                ]),
                              ]),
                            ),
                          ),
                          const SizedBox(height: 24),
                          FadeSlideIn(delay: const Duration(milliseconds: 450),
                              child: const DSSection(title: 'سجل المزايدات')),
                          const SizedBox(height: 12),
                          FadeSlideIn(delay: const Duration(milliseconds: 500),
                              child: BidHistoryList(bidsStream: _bidsStream())),
                        ]),
                      ),
                    ),
                  ),
                ],
              ),

              // ── Bottom Bar ──
              if (isActive)
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('auctions').doc(widget.auctionId).snapshots(),
                  builder: (_, auctionSnap) {
                    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
                    final data = auctionSnap.data?.data() as Map<String, dynamic>?;
                    final depositPaidBy = List<String>.from(data?['depositPaidBy'] ?? []);
                    final hasPaid = depositPaidBy.contains(uid);

                    if (!hasPaid) {
                      return Positioned(
                        bottom: 0, left: 0, right: 0,
                        child: Container(
                          padding: EdgeInsets.fromLTRB(16, 12, 16,
                              MediaQuery.of(context).padding.bottom + 16),
                          decoration: const BoxDecoration(
                            color: DS.bg,
                            border: Border(top: BorderSide(color: DS.border)),
                          ),
                          child: GradientButton(
                            label: _depositPaying
                                ? 'جاري الدفع...'
                                : 'دفع الضمان للمشاركة — ${auction.deposit.toStringAsFixed(0)} DZD',
                            height: 54,
                            onPressed: _depositPaying ? null : () => _payDeposit(auction),
                          ),
                        ),
                      );
                    }

                    return BidBottomBar(
                      controller: _bidCtrl,
                      isPlacing: _placing,
                      bidError: _bidError,
                      onBidPressed: () => _placeBid(auction),
                      onChanged: (v) {
                        if (_bidError != null) setState(() => _bidError = null);
                      },
                    );
                  },
                ),
            ]);
          },
        ),
      ),
    );
  }

  Widget _badgeForStatus(AuctionStatus s) {
    switch (s) {
      case AuctionStatus.active:
        return const DarkBadge(label: 'مباشر الآن', color: DS.success, dot: true, pulse: true);
      case AuctionStatus.approved:
        return const DarkBadge(label: 'قادم', color: DS.purple, dot: true);
      case AuctionStatus.ended:
        return const DarkBadge(label: 'منتهي', color: DS.textMuted);
      default:
        return DarkBadge(label: s.label, color: DS.textMuted);
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ✅ DYNAMIC DETAILS WIDGET
// ══════════════════════════════════════════════════════════════════════════════
class _CategoryDetailsWidget extends StatelessWidget {
  final String category;
  final Map<String, dynamic> details;

  const _CategoryDetailsWidget({required this.category, required this.details});

  @override
  Widget build(BuildContext context) {
    final config = _getCategoryConfig(category);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DS.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DS.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header ──
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: DS.purple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(config.icon, color: DS.purple, size: 18),
          ),
          const SizedBox(width: 10),
          Text(config.title, style: DS.titleS),
        ]),
        const SizedBox(height: 14),
        const Divider(color: DS.border, height: 1),
        const SizedBox(height: 14),

        // ── Fields ──
        ...config.fields.map((field) {
          final value = details[field.key];
          if (value == null || value.toString().isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              Text(field.emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text('${field.label}:', style: DS.label.copyWith(color: DS.textSecondary)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${value}${field.unit != null ? ' ${field.unit}' : ''}',
                  style: DS.titleS.copyWith(fontSize: 13),
                  textAlign: TextAlign.left,
                ),
              ),
            ]),
          );
        }),
      ]),
    );
  }

  _CategoryConfig _getCategoryConfig(String category) {
    final cat = category.toLowerCase();

    if (cat.contains('سيارة') || cat.contains('مركبة') || cat.contains('car')) {
      return _CategoryConfig(
        icon: Icons.directions_car_rounded,
        title: 'معلومات السيارة',
        fields: [
          _Field('brand',        '🚘', 'الماركة'),
          _Field('model',        '🚗', 'الموديل'),
          _Field('year',         '📅', 'سنة الصنع'),
          _Field('engine',       '⚙️', 'المحرك'),
          _Field('fuel',         '⛽', 'الوقود'),
          _Field('mileage',      '📏', 'المسافة', unit: 'كم'),
          _Field('transmission', '🔄', 'ناقل الحركة'),
          _Field('color',        '🎨', 'اللون'),
          _Field('condition',    '✅', 'الحالة'),
        ],
      );
    }

    if (cat.contains('عقار') || cat.contains('شقة') || cat.contains('بيت') || cat.contains('real')) {
      return _CategoryConfig(
        icon: Icons.home_rounded,
        title: 'معلومات العقار',
        fields: [
          _Field('type',     '🏢', 'النوع'),
          _Field('location', '📍', 'الموقع'),
          _Field('area',     '📐', 'المساحة', unit: 'م²'),
          _Field('rooms',    '🛏', 'عدد الغرف'),
          _Field('floor',    '🏗', 'الطابق'),
          _Field('age',      '📅', 'عمر البناء', unit: 'سنة'),
          _Field('condition','✅', 'الحالة'),
        ],
      );
    }

    if (cat.contains('إلكترون') || cat.contains('جهاز') || cat.contains('tech') || cat.contains('laptop') || cat.contains('هاتف')) {
      return _CategoryConfig(
        icon: Icons.devices_rounded,
        title: 'المواصفات التقنية',
        fields: [
          _Field('type',      '🖥', 'النوع'),
          _Field('brand',     '🏷', 'الماركة'),
          _Field('model',     '📱', 'الموديل'),
          _Field('ram',       '🧠', 'RAM',      unit: 'GB'),
          _Field('storage',   '💾', 'التخزين'),
          _Field('processor', '⚡', 'المعالج'),
          _Field('screen',    '🖥', 'الشاشة'),
          _Field('condition', '✅', 'الحالة'),
        ],
      );
    }

    if (cat.contains('أثاث') || cat.contains('furniture')) {
      return _CategoryConfig(
        icon: Icons.chair_rounded,
        title: 'معلومات الأثاث',
        fields: [
          _Field('type',      '🪑', 'النوع'),
          _Field('material',  '🪵', 'المادة'),
          _Field('color',     '🎨', 'اللون'),
          _Field('dimensions','📐', 'الأبعاد'),
          _Field('condition', '✅', 'الحالة'),
        ],
      );
    }

    if (cat.contains('مجوهرات') || cat.contains('ذهب') || cat.contains('jewelry')) {
      return _CategoryConfig(
        icon: Icons.diamond_rounded,
        title: 'معلومات المجوهرات',
        fields: [
          _Field('type',      '💍', 'النوع'),
          _Field('material',  '✨', 'المادة'),
          _Field('weight',    '⚖️', 'الوزن', unit: 'غ'),
          _Field('carat',     '💎', 'العيار'),
          _Field('condition', '✅', 'الحالة'),
        ],
      );
    }

    // Default — يعرض كل الـ fields اللي فيها قيمة
    return _CategoryConfig(
      icon: Icons.info_outline_rounded,
      title: 'تفاصيل إضافية',
      fields: details.keys.map((k) => _Field(k, 'ℹ️', k)).toList(),
    );
  }
}

class _CategoryConfig {
  final IconData icon;
  final String title;
  final List<_Field> fields;
  const _CategoryConfig({required this.icon, required this.title, required this.fields});
}

class _Field {
  final String key;
  final String emoji;
  final String label;
  final String? unit;
  const _Field(this.key, this.emoji, this.label, {this.unit});
}

// ══════════════════════════════════════════════════════════════════════════════
// FULLSCREEN GALLERY
// ══════════════════════════════════════════════════════════════════════════════
class _GalleryScreen extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  const _GalleryScreen({required this.images, required this.initialIndex});

  @override
  State<_GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<_GalleryScreen> {
  late int _current;
  late PageController _ctrl;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _ctrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('${_current + 1} / ${widget.images.length}',
            style: const TextStyle(color: Colors.white)),
      ),
      body: PageView.builder(
        controller: _ctrl,
        itemCount: widget.images.length,
        onPageChanged: (i) => setState(() => _current = i),
        itemBuilder: (_, i) => InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Center(
            child: Image.network(
              widget.images[i],
              fit: BoxFit.contain,
              loadingBuilder: (_, child, progress) => progress == null
                  ? child
                  : const Center(child: CircularProgressIndicator(color: Colors.white)),
              errorBuilder: (_, __, ___) => const Icon(
                  Icons.broken_image_rounded, color: Colors.white54, size: 64),
            ),
          ),
        ),
      ),
    );
  }
}