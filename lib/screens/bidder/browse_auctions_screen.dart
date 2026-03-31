import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/auction_model.dart';
import 'bid_screen.dart';
import 'auction_detail_screen.dart';
import 'dart:async';

class BrowseAuctionsScreen extends StatefulWidget {
  const BrowseAuctionsScreen({super.key});

  @override
  State<BrowseAuctionsScreen> createState() => _BrowseAuctionsScreenState();
}

class _BrowseAuctionsScreenState extends State<BrowseAuctionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'الكل';
  String _selectedStatus = 'active';

  final List<String> _categories = [
    'الكل', 'عقارات', 'سيارات', 'إلكترونيات', 'أثاث', 'معدات صناعية', 'أخرى'
  ];

  final List<Map<String, String>> _statusOptions = [
    {'label': 'نشط', 'value': 'active'},
    {'label': 'قادم', 'value': 'approved'},
    {'label': 'منتهي', 'value': 'ended'},
  ];

  Stream<List<AuctionModel>> _auctionsStream() {
    Query query = FirebaseFirestore.instance
        .collection('auctions')
        .where('status', isEqualTo: _selectedStatus)
        .orderBy('createdAt', descending: true);

    return query.snapshots().map((snap) => snap.docs
        .map((doc) =>
        AuctionModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  List<AuctionModel> _filterAuctions(List<AuctionModel> auctions) {
    return auctions.where((a) {
      final matchesSearch = _searchQuery.isEmpty ||
          a.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          a.description.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory =
          _selectedCategory == 'الكل' || a.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          title: const Text('تصفح المزادات',
              style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF1565C0),
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: 'مزايداتي',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyBidsScreen()),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            _buildSearchAndFilter(),
            _buildStatusTabs(),
            Expanded(child: _buildAuctionList()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      color: const Color(0xFF1565C0),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            textDirection: TextDirection.rtl,
            decoration: InputDecoration(
              hintText: 'ابحث عن مزاد...',
              hintStyle: const TextStyle(color: Colors.white60),
              prefixIcon:
              const Icon(Icons.search, color: Colors.white60),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.white60),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              )
                  : null,
              filled: true,
              fillColor: Colors.white.withOpacity(0.15),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = _categories[i];
                final selected = cat == _selectedCategory;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white
                          : Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(cat,
                        style: TextStyle(
                          color: selected
                              ? const Color(0xFF1565C0)
                              : Colors.white,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 13,
                        )),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTabs() {
    return Container(
      color: Colors.white,
      child: Row(
        children: _statusOptions.map((s) {
          final selected = s['value'] == _selectedStatus;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedStatus = s['value']!),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: selected
                          ? const Color(0xFF1565C0)
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Text(
                  s['label']!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected
                        ? const Color(0xFF1565C0)
                        : Colors.grey,
                    fontWeight: selected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAuctionList() {
    return StreamBuilder<List<AuctionModel>>(
      stream: _auctionsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('خطأ: ${snapshot.error}'));
        }
        final all = snapshot.data ?? [];
        final auctions = _filterAuctions(all);

        if (auctions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.gavel, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text('لا توجد مزادات',
                    style: TextStyle(
                        color: Colors.grey[500], fontSize: 16)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: auctions.length,
          itemBuilder: (_, i) => _AuctionCard(auction: auctions[i]),
        );
      },
    );
  }
}

// ─── بطاقة المزاد ────────────────────────────────────────────────────────────
class _AuctionCard extends StatelessWidget {
  final AuctionModel auction;
  const _AuctionCard({required this.auction});

  String _fmt(DateTime? d) {
    if (d == null) return 'غير محدد';
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isActive = auction.status == AuctionStatus.active;
    final isEnded = auction.status == AuctionStatus.ended;
    final isUpcoming = auction.status == AuctionStatus.approved;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => AuctionDetailScreen(auctionId: auction.id)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // صورة
            ClipRRect(
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(16)),
              child: auction.imageUrl != null &&
                  auction.imageUrl!.isNotEmpty
                  ? Image.network(auction.imageUrl!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover)
                  : Container(
                height: 160,
                color: const Color(0xFFE8EAF6),
                child: const Center(
                    child: Icon(Icons.image,
                        size: 48, color: Color(0xFF9FA8DA))),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // الحالة والفئة
                  Row(
                    children: [
                      _StatusBadge(status: auction.status),
                      const Spacer(),
                      if (auction.category != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8EAF6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(auction.category!,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF3949AB))),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // العنوان
                  Text(auction.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(auction.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Colors.grey[600], fontSize: 13)),
                  const SizedBox(height: 10),

                  // السعر
                  Row(
                    children: [
                      const Icon(Icons.attach_money,
                          size: 16, color: Color(0xFF1565C0)),
                      Text(
                        'السعر الابتدائي: ${auction.effectiveStartingPrice.toStringAsFixed(0)} DZD',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1565C0)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // يوم المعاينة (للمزادات القادمة)
                  if (isUpcoming && auction.inspectionDay != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.visibility,
                            size: 14, color: Colors.purple),
                        const SizedBox(width: 4),
                        Text(
                          'يوم المعاينة: ${_fmt(auction.inspectionDay)}',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.purple),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],

                  // الوقت
                  Row(
                    children: [
                      if (isActive && auction.endDateTime != null) ...[
                        const Icon(Icons.timer,
                            size: 14, color: Colors.orange),
                        const SizedBox(width: 4),
                        _CountdownTimer(endTime: auction.endDateTime!),
                      ],
                      if (isEnded)
                        const Text('منتهي',
                            style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold)),
                      if (isUpcoming && auction.startTime != null) ...[
                        const Icon(Icons.calendar_today,
                            size: 14, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          'تاريخ المزاد: ${_fmt(auction.startTime)}',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.green),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Badge الحالة ─────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final AuctionStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case AuctionStatus.active:
        color = Colors.green;
        label = '● مباشر';
        break;
      case AuctionStatus.approved:
        color = Colors.orange;
        label = '⏳ قادم';
        break;
      case AuctionStatus.ended:
        color = Colors.red;
        label = 'منتهي';
        break;
      default:
        color = Colors.grey;
        label = status.label;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold)),
    );
  }
}

// ─── العد التنازلي ────────────────────────────────────────────────────────────
class _CountdownTimer extends StatefulWidget {
  final DateTime endTime;
  const _CountdownTimer({required this.endTime});

  @override
  State<_CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<_CountdownTimer> {
  late Duration _remaining;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(_updateRemaining);
    });
  }

  void _updateRemaining() {
    _remaining = widget.endTime.difference(DateTime.now());
    if (_remaining.isNegative) {
      _remaining = Duration.zero;
      _timer.cancel();
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_remaining.inSeconds == 0) {
      return const Text('منتهي',
          style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 13));
    }
    final h = _remaining.inHours.toString().padLeft(2, '0');
    final m = (_remaining.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    final isUrgent = _remaining.inMinutes < 10;
    return Text('$h:$m:$s',
        style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: isUrgent ? Colors.red : Colors.orange));
  }
}
