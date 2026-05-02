import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:auction_app2/shared/models/auction_model.dart';
import 'package:auction_app2/shared/models/user_model.dart';
import 'package:auction_app2/core/routes/app_routes.dart';
import '../../../core/constants/ds_colors.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../widgets/auction_tap_card.dart';
import '../widgets/kyc_status_card.dart';
import '../widgets/stat_mini_card.dart';

class OrganizerDashboardHome extends StatefulWidget {
  const OrganizerDashboardHome({super.key});
  @override
  State<OrganizerDashboardHome> createState() => _OrganizerDashboardHomeState();
}

class _OrganizerDashboardHomeState extends State<OrganizerDashboardHome>
    with SingleTickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  KycStatus? _kycStatus;
  String? _kycRejectionReason;
  bool _hasUploadedDocs = false;
  int _totalAuctions = 0;
  int _activeAuctions = 0;
  double _totalRevenue = 0;
  String _userName = '';
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      final d = doc.data()!;
      setState(() {
        _kycStatus = _parseKyc(d['kycStatus']);
        _kycRejectionReason = d['kycRejectionReason'];
        _hasUploadedDocs =
            d['kycDocuments'] != null && (d['kycDocuments'] as Map).isNotEmpty;
        _userName = d['name'] ?? '';
      });
    }
    final snap = await _db
        .collection('auctions')
        .where('organizerId', isEqualTo: uid)
        .get();
    double rev = 0;
    int active = 0;
    for (final d in snap.docs) {
      final data = d.data();
      if (data['status'] == AuctionStatus.active.name) active++;
      if (data['status'] == AuctionStatus.ended.name) {
        rev += (data['currentPrice'] ?? data['startingPrice'] ?? 0).toDouble();
      }
    }
    setState(() {
      _totalAuctions = snap.docs.length;
      _activeAuctions = active;
      _totalRevenue = rev;
    });
  }

  KycStatus? _parseKyc(dynamic v) {
    if (v == null) return KycStatus.pending;
    switch (v.toString()) {
      case 'approved':
        return KycStatus.approved;
      case 'rejected':
        return KycStatus.rejected;
      default:
        return KycStatus.pending;
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _fmt(DateTime? d) {
    if (d == null) return '—';
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid;
    final kycOk = _kycStatus == KycStatus.approved;
    final firstName = _userName.split(' ').first;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        color: DS.purple,
        backgroundColor: DS.bgCard,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 240,
              pinned: true,
              backgroundColor: DS.bg,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFF5F3FF), Color(0xFFFFFFFF)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    const PurpleOrb(
                        size: 320, alignment: Alignment.topRight, opacity: 0.1),
                    const PurpleOrb(
                        size: 240,
                        alignment: Alignment.bottomLeft,
                        opacity: 0.05),
                    ClipRRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                        child: Container(
                            color: Colors.white.withValues(alpha: 0.1)),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const FadeSlideIn(
                              duration: Duration(milliseconds: 600),
                              child: AmsLogo(size: 36),
                            ),
                            const SizedBox(height: 14),
                            FadeSlideIn(
                              delay: const Duration(milliseconds: 150),
                              child: Text(
                                firstName.isEmpty
                                    ? 'أهلاً بك 👋'
                                    : 'أهلاً، $firstName 👋',
                                style: DS.titleXL.copyWith(height: 1.1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(80),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: FadeSlideIn(
                    delay: const Duration(milliseconds: 200),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: DS.bgCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: DS.purple.withValues(alpha: 0.2),
                            width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: DS.purple.withValues(alpha: 0.05),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        style: const TextStyle(
                            color: DS.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600),
                        textDirection: TextDirection.rtl,
                        decoration: InputDecoration(
                          hintText: 'ابحث في مزادك...',
                          hintStyle: TextStyle(
                              color: DS.textMuted.withValues(alpha: 0.6),
                              fontSize: 14),
                          prefixIcon: const Icon(Icons.search_rounded,
                              color: DS.purple, size: 22),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 10),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close_rounded,
                                      size: 18, color: DS.textMuted),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() => _searchQuery = '');
                                  })
                              : null,
                        ),
                        onChanged: (v) => setState(() => _searchQuery = v),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 100),
                      child: _buildKycBanner(),
                    ),
                    const SizedBox(height: 24),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 200),
                      child: Row(children: [
                        Expanded(
                            child: StatMiniCard(
                          icon: Icons.gavel_rounded,
                          label: 'إجمالي',
                          value: _totalAuctions.toString(),
                          color: DS.purple,
                        )),
                        const SizedBox(width: 10),
                        Expanded(
                            child: StatMiniCard(
                          icon: Icons.play_circle_rounded,
                          label: 'نشط',
                          value: _activeAuctions.toString(),
                          color: DS.success,
                        )),
                        const SizedBox(width: 10),
                        Expanded(
                            child: StatMiniCard(
                          icon: Icons.payments_rounded,
                          label: 'إيراد',
                          value: _totalRevenue > 0
                              ? '${(_totalRevenue / 1000).toStringAsFixed(1)}K'
                              : '0',
                          color: DS.gold,
                        )),
                      ]),
                    ),
                    const SizedBox(height: 28),
                    const FadeSlideIn(
                      delay: Duration(milliseconds: 300),
                      child: DSSection(title: 'مزاداتي'),
                    ),
                    const SizedBox(height: 14),
                    if (uid != null)
                      StreamBuilder<QuerySnapshot>(
                        stream: _db
                            .collection('auctions')
                            .where('organizerId', isEqualTo: uid)
                            .orderBy('createdAt', descending: true)
                            .snapshots(),
                        builder: (ctx, snap) {
                          if (snap.connectionState == ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.only(top: 60),
                              child: Center(
                                  child: CircularProgressIndicator(
                                      color: DS.purple)),
                            );
                          }
                          if (!snap.hasData || snap.data!.docs.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 40),
                              child: DSEmpty(
                                icon: Icons.gavel_rounded,
                                title: 'لا توجد مزادات',
                                subtitle: kycOk
                                    ? 'اضغط + لإضافة مزاد'
                                    : 'أكمل KYC أولاً',
                              ),
                            );
                          }
                          return StaggeredListView(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: snap.data!.docs.length,
                            padding: EdgeInsets.zero,
                            itemBuilder: (_, i) {
                              final doc = snap.data!.docs[i];
                              final data = doc.data() as Map<String, dynamic>;
                              final auction =
                                  AuctionModel.fromMap(data, doc.id);

                              if (_searchQuery.isNotEmpty &&
                                  !auction.title
                                      .toLowerCase()
                                      .contains(_searchQuery.toLowerCase())) {
                                return const SizedBox.shrink();
                              }

                              return _buildAuctionCard(auction);
                            },
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: kycOk
          ? Container(
              decoration: BoxDecoration(
                gradient: DS.purpleGradient,
                borderRadius: BorderRadius.circular(18),
                boxShadow: DS.purpleShadow,
              ),
              child: FloatingActionButton.extended(
                backgroundColor: Colors.transparent,
                elevation: 0,
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.submitAuction),
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: const Text('مزاد جديد +',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            )
          : null,
    );
  }

  Widget _buildKycBanner() {
    if (_kycStatus == KycStatus.approved) {
      return const KycStatusCard(
        color: DS.success,
        icon: Icons.verified_rounded,
        title: 'هويتك موثّقة',
        subtitle: 'يمكنك نشر المزادات بحرية',
        tag: 'معتمد',
      );
    }
    if (_kycStatus == KycStatus.rejected) {
      return KycStatusCard(
        color: DS.error,
        icon: Icons.cancel_rounded,
        title: 'تم رفض طلبك',
        subtitle: _kycRejectionReason != null
            ? 'السبب: $_kycRejectionReason'
            : 'ارفع وثائق جديدة',
        tag: 'مرفوض',
        action: GradientButton(
          label: 'إعادة رفع الوثائق',
          height: 46,
          icon: Icons.upload_file_rounded,
          onPressed: () => Navigator.pushNamed(context, AppRoutes.kycUpload)
              .then((_) => _loadUserData()),
        ),
      );
    }
    return KycStatusCard(
      color: DS.warning,
      icon: Icons.hourglass_top_rounded,
      title:
          _hasUploadedDocs ? 'وثائقك قيد المراجعة' : 'التحقق من الهوية مطلوب',
      subtitle: _hasUploadedDocs
          ? 'انتظر موافقة المسؤول (24-48 ساعة)'
          : 'ارفع وثائقك للبدء في نشر المزادات',
      tag: 'معلّق',
      action: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: DS.warning,
          side: const BorderSide(color: DS.warning),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: Icon(
            _hasUploadedDocs ? Icons.edit_document : Icons.upload_file_rounded,
            size: 16),
        label: Text(_hasUploadedDocs ? 'تحديث الوثائق' : 'رفع وثائق KYC'),
        onPressed: () => Navigator.pushNamed(context, AppRoutes.kycUpload)
            .then((_) => _loadUserData()),
      ),
    );
  }

  Widget _buildAuctionCard(AuctionModel auction) {
    Color color;
    String label;
    switch (auction.status) {
      case AuctionStatus.active:
        color = DS.success;
        label = 'نشط';
        break;
      case AuctionStatus.approved:
        color = DS.purple;
        label = 'مقبول';
        break;
      case AuctionStatus.rejected:
        color = DS.error;
        label = 'مرفوض';
        break;
      case AuctionStatus.ended:
        color = DS.textMuted;
        label = 'منتهي';
        break;
      case AuctionStatus.submitted:
        color = DS.warning;
        label = 'قيد المراجعة';
        break;
      default:
        color = DS.textMuted;
        label = 'مسودة';
    }

    return AuctionTapCard(
      auction: auction,
      statusColor: color,
      statusLabel: label,
      onTap: () => Navigator.pushNamed(context, AppRoutes.trackAuction,
          arguments: auction),
      dateFormatter: _fmt,
    );
  }
}
