import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:auction_app2/shared/models/auction_model.dart';
import 'package:auction_app2/core/services/notification_service.dart';
import 'package:auction_app2/core/services/favourites_service.dart';
import '../../../core/constants/ds_colors.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../auth/screens/profile_page.dart';
import '../../notifications/notifications_screen.dart';
import '../../wallet/wallet_screen.dart';
import '../widgets/bidder_auction_card.dart';
import '../widgets/auction_filter_sheet.dart';
import 'my_bids_screen.dart';

class BrowseAuctionsScreen extends StatefulWidget {
  const BrowseAuctionsScreen({super.key});
  @override
  State<BrowseAuctionsScreen> createState() => _BrowseAuctionsScreenState();
}

class _BrowseAuctionsScreenState extends State<BrowseAuctionsScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _pages = [
    const _AuctionsHome(),
    const NotificationsScreen(),
    const WalletScreen(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: DS.bg,
        body: IndexedStack(index: _selectedIndex, children: _pages),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: DS.success,
            border: Border(top: BorderSide(color: DS.success)),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              navigationBarTheme: NavigationBarThemeData(
                backgroundColor:  DS.success,
                surfaceTintColor: Colors.transparent,
                shadowColor:      Colors.transparent,
                indicatorColor:   Colors.white.withValues(alpha: 0.2),
                elevation:        0,
                labelTextStyle: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700);
                  }
                  return TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11);
                }),
                iconTheme: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const IconThemeData(color: Colors.white);
                  }
                  return IconThemeData(color: Colors.white.withValues(alpha: 0.6));
                }),
              ),
            ),
            child: NavigationBar(
              backgroundColor:  DS.success,
              surfaceTintColor: Colors.transparent,
              shadowColor:      Colors.transparent,
              elevation:        0,
              selectedIndex:    _selectedIndex,
              onDestinationSelected: (i) => setState(() => _selectedIndex = i),
              indicatorColor: Colors.white.withValues(alpha: 0.2),
              destinations: [
                const NavigationDestination(
                  icon:         Icon(Icons.gavel_rounded, color: Colors.white60),
                  selectedIcon: Icon(Icons.gavel_rounded, color: Colors.white),
                  label:        'المزادات',
                ),
                NavigationDestination(
                  icon: StreamBuilder<int>(
                    stream: NotificationService.streamUnreadCount(uid),
                    builder: (_, snap) {
                      final count = snap.data ?? 0;
                      return Badge(
                        isLabelVisible:  count > 0,
                        label:           Text('$count'),
                        backgroundColor: DS.error,
                        child: const Icon(Icons.notifications_outlined, color: Colors.white60),
                      );
                    },
                  ),
                  selectedIcon: StreamBuilder<int>(
                    stream: NotificationService.streamUnreadCount(uid),
                    builder: (_, snap) {
                      final count = snap.data ?? 0;
                      return Badge(
                        isLabelVisible:  count > 0,
                        label:           Text('$count'),
                        backgroundColor: DS.error,
                        child: const Icon(Icons.notifications_rounded, color: Colors.white),
                      );
                    },
                  ),
                  label: 'الإشعارات',
                ),
                const NavigationDestination(
                  icon:         Icon(Icons.account_balance_wallet_outlined, color: Colors.white60),
                  selectedIcon: Icon(Icons.account_balance_wallet_rounded, color: Colors.white),
                  label:        'محفظتي',
                ),
                const NavigationDestination(
                  icon:         Icon(Icons.person_outline_rounded, color: Colors.white60),
                  selectedIcon: Icon(Icons.person_rounded, color: Colors.white),
                  label:        'حسابي',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── صفحة المزادات الرئيسية ────────────────────────────
class _AuctionsHome extends StatefulWidget {
  const _AuctionsHome();
  @override
  State<_AuctionsHome> createState() => _AuctionsHomeState();
}

class _AuctionsHomeState extends State<_AuctionsHome> with TickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  String _query    = '';
  String _category = 'الكل';
  late TabController _tabCtrl;

  // ✅ 4 تبويبات
  final _statusTabs = [
    {'label': 'نشط',    'value': 'active',     'icon': Icons.bolt_rounded,      'color': DS.success},
    {'label': 'قادم',   'value': 'approved',   'icon': Icons.schedule_rounded,   'color': DS.purple},
    {'label': 'منتهي',  'value': 'ended',      'icon': Icons.flag_rounded,       'color': DS.textMuted},
    {'label': 'مفضلتي', 'value': 'favourites', 'icon': Icons.favorite_rounded,   'color': DS.error},
  ];

  final List<String> _cats = [
    'الكل', 'عقارات', 'سيارات', 'إلكترونيات', 'أثاث', 'معدات', 'أخرى'
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _statusTabs.length, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AuctionFilterSheet(
        initialCategory: _category,
        categories: _cats,
        onApply: (c) => setState(() => _category = c),
      ),
    );
  }

  Stream<List<AuctionModel>> _stream(String status) {
    return FirebaseFirestore.instance
        .collection('auctions')
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => AuctionModel.fromMap(d.data(), d.id)).toList());
  }

  List<AuctionModel> _filter(List<AuctionModel> list) {
    return list.where((a) {
      final matchQ = _query.isEmpty || a.title.toLowerCase().contains(_query.toLowerCase());
      final matchC = _category == 'الكل' || a.category == _category;
      return matchQ && matchC;
    }).toList();
  }

  bool get _isFavTab => _tabCtrl.index == 3;

  @override
  Widget build(BuildContext context) {
    return NestedScrollView(
      headerSliverBuilder: (ctx, inner) => [
        SliverAppBar(
          expandedHeight: 220,
          floating:       false,
          pinned:         true,
          backgroundColor: DS.bg,
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(children: [
              const PurpleOrb(size: 260, alignment: Alignment.topLeft,     opacity: 0.5),
              const PurpleOrb(size: 180, alignment: Alignment.bottomRight, opacity: 0.2),
              SafeArea(child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const FadeSlideIn(duration: Duration(milliseconds: 600), child: AmsLogo(size: 40)),
                ]),
              )),
            ]),
          ),
          actions: [
            IconButton(
              icon: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: DS.bgCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: DS.border),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4)],
                ),
                child: const Icon(Icons.history_rounded, size: 18, color: DS.textSecondary),
              ),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const MyBidsScreen())),
            ),
            const SizedBox(width: 8),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(130),
            child: Column(children: [

              // ── Search ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: FadeSlideIn(
                  delay: const Duration(milliseconds: 150),
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: DS.bgCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: DS.purple.withValues(alpha: 0.3), width: 1.5),
                      boxShadow: [BoxShadow(color: DS.purple.withValues(alpha: 0.08), blurRadius: 15, offset: const Offset(0, 4))],
                    ),
                    child: TextField(
                      controller:    _searchCtrl,
                      style: const TextStyle(color: DS.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                      textDirection: TextDirection.rtl,
                      decoration: InputDecoration(
                        hintText:       'ابحث عن مزادات بالاسم...',
                        hintStyle:      TextStyle(color: DS.textMuted.withValues(alpha: 0.7), fontSize: 14),
                        prefixIcon:     const Icon(Icons.search_rounded, color: DS.purple, size: 22),
                        border:         InputBorder.none,
                        enabledBorder:  InputBorder.none,
                        focusedBorder:  InputBorder.none,
                        filled:         false,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18, color: DS.textMuted),
                          onPressed: () { _searchCtrl.clear(); setState(() => _query = ''); },
                        )
                            : null,
                      ),
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),
                ),
              ),

              // ── Filter — يختفي في تبويب المفضلة ──
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _isFavTab
                    ? const SizedBox(key: ValueKey('empty'), height: 48)
                    : Container(
                  key: const ValueKey('filter'),
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(children: [
                    Expanded(child: GestureDetector(
                      onTap: _showFilterModal,
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: DS.bgCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: DS.border),
                        ),
                        child: Row(children: [
                          const Icon(Icons.tune_rounded, size: 16, color: DS.purple),
                          const SizedBox(width: 8),
                          Text('تصفية الفئات', style: DS.body.copyWith(fontWeight: FontWeight.w600, color: DS.purple)),
                          const Spacer(),
                          if (_category != 'الكل')
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: DS.purple, borderRadius: BorderRadius.circular(20)),
                              child: Text(_category, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                            ),
                          const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: DS.textMuted),
                        ]),
                      ),
                    )),
                  ]),
                ),
              ),

              const SizedBox(height: 8),

              // ── TabBar ──
              Container(
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: DS.divider))),
                child: TabBar(
                  controller: _tabCtrl,
                  tabs: _statusTabs.map((t) => Tab(
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(t['icon'] as IconData, size: 14),
                      const SizedBox(width: 5),
                      Text(t['label'] as String),
                    ]),
                  )).toList(),
                ),
              ),
            ]),
          ),
        ),
      ],

      // ✅ TabBarView بدل StreamBuilder مباشر
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _AuctionsList(stream: _stream('active'),   filter: _filter),
          _AuctionsList(stream: _stream('approved'), filter: _filter),
          _AuctionsList(stream: _stream('ended'),    filter: _filter),
          _FavouritesList(query: _query),              // ✅ مفضلتي
        ],
      ),
    );
  }
}

// ── قائمة مزادات عادية ───────────────────────────────
class _AuctionsList extends StatelessWidget {
  final Stream<List<AuctionModel>>                       stream;
  final List<AuctionModel> Function(List<AuctionModel>) filter;
  const _AuctionsList({required this.stream, required this.filter});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AuctionModel>>(
      stream: stream,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: DS.purple));
        }
        final list = filter(snap.data ?? []);
        if (list.isEmpty) {
          return const DSEmpty(
            icon:     Icons.gavel_rounded,
            title:    'لا توجد مزادات',
            subtitle: 'جرّب فئة أو بحثاً مختلفاً',
          );
        }
        return StaggeredListView(
          padding:     const EdgeInsets.fromLTRB(20, 16, 20, 100),
          itemCount:   list.length,
          baseDelayMs: 80,
          staggerMs:   70,
          itemBuilder: (_, i) => BidderAuctionCard(auction: list[i]),
        );
      },
    );
  }
}

// ✅ قائمة المفضلة ─────────────────────────────────────
class _FavouritesList extends StatelessWidget {
  final String query;
  const _FavouritesList({required this.query});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Set<String>>(
      stream: FavouritesService.streamIds(),
      builder: (ctx, favSnap) {
        if (favSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: DS.error));
        }
        final favIds = favSnap.data ?? {};

        if (favIds.isEmpty) {
          return const DSEmpty(
            icon:     Icons.favorite_border_rounded,
            title:    'لا توجد مفضلة',
            subtitle: 'اضغط ❤️ على أي مزاد لإضافته',
          );
        }

        // Firestore whereIn يقبل 30 عنصر كحد أقصى
        final ids = favIds.take(30).toList();

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('auctions')
              .where(FieldPath.documentId, whereIn: ids)
              .snapshots(),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: DS.error));
            }
            var list = (snap.data?.docs ?? [])
                .map((d) => AuctionModel.fromMap(d.data() as Map<String, dynamic>, d.id))
                .toList();

            if (query.isNotEmpty) {
              list = list.where((a) =>
                  a.title.toLowerCase().contains(query.toLowerCase())).toList();
            }

            if (list.isEmpty) {
              return const DSEmpty(
                icon:     Icons.search_off_rounded,
                title:    'لا توجد نتائج',
                subtitle: 'جرّب بحثاً مختلفاً',
              );
            }

            return StaggeredListView(
              padding:     const EdgeInsets.fromLTRB(20, 16, 20, 100),
              itemCount:   list.length,
              baseDelayMs: 80,
              staggerMs:   70,
              itemBuilder: (_, i) => BidderAuctionCard(auction: list[i]),
            );
          },
        );
      },
    );
  }
}