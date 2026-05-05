import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:auction_app2/shared/models/auction_model.dart';
import '../../../core/constants/ds_colors.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../widgets/track_auction_components.dart';

class TrackAuctionScreen extends StatefulWidget {
  final AuctionModel auction;
  const TrackAuctionScreen({super.key, required this.auction});
  @override
  State<TrackAuctionScreen> createState() => _TrackAuctionScreenState();
}

class _TrackAuctionScreenState extends State<TrackAuctionScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _headerAnim;
  late Animation<double> _headerFade;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _headerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _headerFade = CurvedAnimation(
      parent: _headerAnim,
      curve: Curves.easeOutCubic,
    );
    _headerAnim.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _headerAnim.dispose();
    super.dispose();
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'active':
        return DS.success;
      case 'approved':
        return DS.info;
      case 'submitted':
        return DS.warning;
      case 'ended':
        return DS.textMuted;
      case 'rejected':
        return DS.error;
      default:
        return DS.textMuted;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
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
      default:
        return s;
    }
  }

  String _fmt(DateTime? dt) {
    if (dt == null) return '—';
    return '${dt.day}/${dt.month}/${dt.year}  ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Duration _remaining() {
    if (widget.auction.endDateTime == null) return Duration.zero;
    final r = widget.auction.endDateTime!.difference(DateTime.now());
    return r.isNegative ? Duration.zero : r;
  }

  String _formatDuration(Duration d) {
    if (d == Duration.zero) return 'انتهى';
    final days = d.inDays;
    final hours = d.inHours % 24;
    final minutes = d.inMinutes % 60;
    if (days > 0) return '$daysي  $hoursس  $minutesد';
    if (hours > 0) return '$hoursس  $minutesد';
    return '$minutesد';
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.auction.status.name;
    final statusColor = _statusColor(status);
    final remaining = _remaining();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: DS.bg,
        body: Column(
          children: [
            FadeTransition(
              opacity: _headerFade,
              child: Container(
                padding: const EdgeInsets.only(bottom: 20),
                decoration: const BoxDecoration(gradient: DS.headerGradient),
                child: Stack(
                  children: [
                    const Positioned(
                      top: -100,
                      right: -100,
                      child: PurpleOrb(
                        size: 350,
                        opacity: 0.35,
                        alignment: Alignment.topRight,
                      ),
                    ),
                    const Positioned(
                      bottom: 0,
                      left: -50,
                      child: PurpleOrb(
                        size: 250,
                        opacity: 0.15,
                        alignment: Alignment.bottomLeft,
                      ),
                    ),
                    SafeArea(
                      bottom: false,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: DS.bgElevated.withValues(
                                        alpha: 0.4,
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: DS.border),
                                    ),
                                    child: const Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                      size: 16,
                                      color: DS.textPrimary,
                                    ),
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'متابعة حالة المزاد',
                                    style: DS.titleM,
                                  ),
                                ),
                                DarkBadge(
                                  label: _statusLabel(status),
                                  color: statusColor,
                                  dot: status == 'active',
                                  pulse: true,
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Hero(
                                  tag: 'auction_title_${widget.auction.id}',
                                  child: Material(
                                    color: Colors.transparent,
                                    child: Text(
                                      widget.auction.title,
                                      style: DS.titleL.copyWith(
                                        fontSize: 24,
                                        height: 1.3,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (widget.auction.category != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: DS.purple.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: DS.purple.withValues(alpha: 0.2),
                                      ),
                                    ),
                                    child: Text(
                                      widget.auction.category!,
                                      style: DS.bodySmall.copyWith(
                                        color: DS.purple,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 32),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'السعر الأعلى حالياً',
                                            style: DS.label.copyWith(
                                              color: DS.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Text(
                                                (widget.auction.currentPrice ??
                                                        0)
                                                    .toStringAsFixed(0),
                                                style: DS.displayLarge.copyWith(
                                                  color: DS.goldLight,
                                                  letterSpacing: -2,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'DZD',
                                                style: DS.label.copyWith(
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (status == 'active' &&
                                        widget.auction.endDateTime != null)
                                      GlassCard(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        borderRadius: 16,
                                        backgroundColor: remaining.inMinutes <
                                                30
                                            ? DS.error.withValues(alpha: 0.1)
                                            : DS.bgElevated.withValues(
                                                alpha: 0.5,
                                              ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              'ينتهي في',
                                              style: DS.label.copyWith(
                                                fontSize: 10,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            DSCountdown(
                                              time: _formatDuration(remaining),
                                              isUrgent:
                                                  remaining.inMinutes < 30,
                                              large: true,
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              height: 54,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: DS.bgCard.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: DS.border),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: DS.purple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  indicatorPadding: const EdgeInsets.all(6),
                  dividerColor: Colors.transparent,
                  labelColor: DS.purple,
                  unselectedLabelColor: DS.textSecondary,
                  tabs: const [
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.info_outline_rounded, size: 14),
                          SizedBox(width: 6),
                          Text('التفاصيل'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.gavel_rounded, size: 14),
                          SizedBox(width: 6),
                          Text('المزايدات'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.emoji_events_rounded, size: 14),
                          SizedBox(width: 6),
                          Text('الفائز'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
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
      ),
    );
  }

  Widget _buildDetailsTab() {
    final auction = widget.auction;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FadeSlideIn(
          child: DetailCard(
            title: 'معلومات المزاد',
            icon: Icons.info_outline_rounded,
            children: [
              DetailRow(label: 'العنوان', value: auction.title),
              DetailRow(label: 'الفئة', value: auction.category ?? '—'),
              DetailRow(label: 'الوصف', value: auction.description),
            ],
          ),
        ),
        const SizedBox(height: 12),
        FadeSlideIn(
          delay: const Duration(milliseconds: 80),
          child: DetailCard(
            title: 'التسعير',
            icon: Icons.payments_rounded,
            children: [
              DetailRow(
                label: 'السعر الابتدائي',
                value: '${auction.startingPrice.toStringAsFixed(0)} DZD',
              ),
              if (auction.adminAdjustedPrice != null)
                DetailRow(
                  label: 'السعر المعدَّل',
                  value:
                      '${auction.adminAdjustedPrice!.toStringAsFixed(0)} DZD',
                  highlight: true,
                ),
              DetailRow(
                label: 'السعر الحالي',
                value: '${(auction.currentPrice ?? 0).toStringAsFixed(0)} DZD',
                highlight: true,
              ),
              if (auction.adminNote != null)
                DetailRow(label: 'ملاحظة المسؤول', value: auction.adminNote!),
            ],
          ),
        ),
        const SizedBox(height: 12),
        FadeSlideIn(
          delay: const Duration(milliseconds: 160),
          child: DetailCard(
            title: 'الجدول الزمني',
            icon: Icons.calendar_month_rounded,
            children: [
              DetailRow(
                label: 'يوم المعاينة',
                value: _fmt(auction.inspectionDay),
              ),
              DetailRow(label: 'بداية المزاد', value: _fmt(auction.startTime)),
              DetailRow(
                label: 'نهاية المزاد',
                value: _fmt(auction.endDateTime),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBidsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bids')
          .where('auctionId', isEqualTo: widget.auction.id)
          .orderBy('amount', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: DS.purple),
          );
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const DSEmpty(
            icon: Icons.gavel_rounded,
            title: 'لا توجد مزايدات بعد',
            subtitle: 'ستظهر المزايدات هنا عند بداية المزاد',
          );
        }
        return StaggeredListView(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          staggerMs: 55,
          itemBuilder: (context, i) {
            final bid = docs[i].data() as Map<String, dynamic>;
            final isTop = i == 0;
            final amount = (bid['amount'] as num?)?.toDouble() ?? 0;
            final bidderId = bid['bidderId'] as String? ?? '—';
            final ts = bid['timestamp'] as Timestamp?;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isTop ? DS.goldSurface : DS.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isTop ? DS.borderGold : DS.border,
                  width: isTop ? 1.5 : 1,
                ),
                boxShadow: isTop ? DS.goldShadow : DS.cardShadow,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: isTop ? DS.goldGradient : null,
                      color:
                          isTop ? null : DS.bgElevated.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(14),
                      border: isTop ? null : Border.all(color: DS.border),
                      boxShadow: isTop ? DS.goldShadow : [],
                    ),
                    child: Center(
                      child: Text(
                        isTop ? '🥇' : '${i + 1}',
                        style: TextStyle(
                          fontSize: isTop ? 18 : 14,
                          fontWeight: FontWeight.w900,
                          color: isTop ? Colors.white : DS.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bidderId.length > 18
                              ? '${bidderId.substring(0, 18)}...'
                              : bidderId,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: isTop ? DS.goldLight : DS.textPrimary,
                          ),
                        ),
                        if (ts != null)
                          Text(
                            _fmt(ts.toDate()),
                            style: DS.bodySmall.copyWith(
                              color: DS.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${amount.toStringAsFixed(0)} DZD',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: isTop ? DS.goldLight : DS.purple,
                        ),
                      ),
                      if (isTop)
                        Text(
                          'الأعلى',
                          style: DS.bodySmall.copyWith(
                            color: DS.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWinnerTab() {
    final status = widget.auction.status.name;
    final winnerId = widget.auction.winnerId;
    if (status != 'ended') {
      return DSEmpty(
        icon: status == 'active'
            ? Icons.hourglass_top_rounded
            : Icons.lock_clock_rounded,
        title: status == 'active'
            ? 'المزاد لا يزال نشطاً'
            : 'لم يُعلَن عن الفائز بعد',
        subtitle: 'سيظهر الفائز بعد انتهاء المزاد.',
      );
    }
    if (winnerId == null) {
      return const DSEmpty(
        icon: Icons.sentiment_dissatisfied_rounded,
        title: 'لم يتم إعلان فائز',
        subtitle: 'انتظر تحديد الفائز من المسؤول',
      );
    }
    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('users').doc(winnerId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: DS.purple),
          );
        }
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final name = data?['name'] as String? ?? 'غير معروف';
        final email = data?['email'] as String? ?? '—';
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FadeSlideIn(
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: DS.goldGradient,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: DS.goldShadow,
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Icon(
                        Icons.emoji_events_rounded,
                        color: Colors.white,
                        size: 58,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '🎉 الفائز الرسمي بالمزاد',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      email,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 32),
                    GlassCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      borderRadius: 20,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'السعر النهائي',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.auction.currentPrice?.toStringAsFixed(0)} DZD',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const FadeSlideIn(
              delay: Duration(milliseconds: 200),
              child: DSSection(title: 'ملف المزايد'),
            ),
            const SizedBox(height: 12),
            FadeSlideIn(
              delay: const Duration(milliseconds: 300),
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                borderRadius: 20,
                child: Row(
                  children: [
                    DSAvatar(name: name, radius: 26, color: DS.gold),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: DS.titleS),
                          Text(
                            'مزايد موثق ✅',
                            style: DS.bodySmall.copyWith(color: DS.success),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: DS.purple,
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
