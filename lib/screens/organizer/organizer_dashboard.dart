import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/auction_model.dart';
import '../../data/models/user_model.dart';
import '../../routes/app_routes.dart';

class OrganizerDashboard extends StatefulWidget {
  const OrganizerDashboard({super.key});

  @override
  State<OrganizerDashboard> createState() => _OrganizerDashboardState();
}

class _OrganizerDashboardState extends State<OrganizerDashboard> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  KycStatus? _kycStatus;
  String? _kycRejectionReason;
  bool _hasUploadedDocs = false;
  int _totalAuctions = 0;
  int _activeAuctions = 0;
  double _totalRevenue = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final userDoc = await _firestore.collection('users').doc(uid).get();
    if (userDoc.exists) {
      final data = userDoc.data()!;
      setState(() {
        _kycStatus = _parseKyc(data['kycStatus']);
        _kycRejectionReason = data['kycRejectionReason'];
        _hasUploadedDocs = data['kycDocuments'] != null &&
            (data['kycDocuments'] as Map).isNotEmpty;
      });
    }

    final auctionsSnap = await _firestore
        .collection('auctions')
        .where('organizerId', isEqualTo: uid)
        .get();

    double revenue = 0;
    int active = 0;
    for (var doc in auctionsSnap.docs) {
      final data = doc.data();
      if (data['status'] == AuctionStatus.active.name) active++;
      if (data['status'] == AuctionStatus.ended.name) {
        revenue +=
            (data['currentPrice'] ?? data['startingPrice'] ?? 0).toDouble();
      }
    }

    setState(() {
      _totalAuctions = auctionsSnap.docs.length;
      _activeAuctions = active;
      _totalRevenue = revenue;
    });
  }

  KycStatus? _parseKyc(dynamic val) {
    if (val == null) return KycStatus.pending;
    switch (val.toString()) {
      case 'approved': return KycStatus.approved;
      case 'rejected': return KycStatus.rejected;
      default: return KycStatus.pending;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid;
    final kycApproved = _kycStatus == KycStatus.approved;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        title: const Text('لوحة تحكم البائع',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await _auth.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildKycBanner(),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildStatCard('إجمالي المزادات',
                      _totalAuctions.toString(), Icons.gavel, Colors.blue),
                  const SizedBox(width: 12),
                  _buildStatCard('النشطة',
                      _activeAuctions.toString(), Icons.play_circle, Colors.green),
                  const SizedBox(width: 12),
                  _buildStatCard('الإيرادات',
                      '${_totalRevenue.toStringAsFixed(0)} DZD',
                      Icons.attach_money, Colors.orange),
                ],
              ),
              const SizedBox(height: 20),
              const Text('مزاداتي',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1565C0))),
              const SizedBox(height: 10),
              if (uid != null)
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('auctions')
                      .where('organizerId', isEqualTo: uid)
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          children: [
                            const SizedBox(height: 40),
                            Icon(Icons.inbox_outlined,
                                size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text('لا توجد مزادات بعد',
                                style: TextStyle(color: Colors.grey.shade500)),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final doc = snapshot.data!.docs[index];
                        final auction = AuctionModel.fromMap(
                            doc.data() as Map<String, dynamic>, doc.id);
                        return _buildAuctionCard(auction);
                      },
                    );
                  },
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: kycApproved
          ? FloatingActionButton.extended(
        onPressed: () =>
            Navigator.pushNamed(context, AppRoutes.submitAuction),
        backgroundColor: const Color(0xFF1565C0),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('مزاد جديد',
            style: TextStyle(color: Colors.white)),
      )
          : null,
    );
  }

  Widget _buildKycBanner() {
    // ✅ معتمد
    if (_kycStatus == KycStatus.approved) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.verified, color: Colors.green.shade700),
            const SizedBox(width: 8),
            Text('تم التحقق من هويتك ✅ — يمكنك نشر المزادات',
                style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    // ❌ مرفوض — مع زر إعادة الرفع
    if (_kycStatus == KycStatus.rejected) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cancel, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Text('تم رفض طلب التحقق ❌',
                    style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w600)),
              ],
            ),
            if (_kycRejectionReason != null) ...[
              const SizedBox(height: 4),
              Text('السبب: $_kycRejectionReason',
                  style:
                  TextStyle(color: Colors.red.shade600, fontSize: 12)),
            ],
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.upload_file, color: Colors.white),
                label: const Text('إعادة رفع الوثائق',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                onPressed: () => Navigator.pushNamed(
                    context, AppRoutes.kycUpload).then((_) => _loadUserData()),
              ),
            ),
          ],
        ),
      );
    }

    // ⏳ pending
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.hourglass_top, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _hasUploadedDocs
                      ? 'وثائقك قيد المراجعة — انتظر موافقة المسؤول'
                      : 'لم يتم رفع الوثائق بعد — ارفع وثائقك للمراجعة',
                  style: TextStyle(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: Icon(
                _hasUploadedDocs ? Icons.edit_document : Icons.upload_file,
                color: const Color(0xFF1565C0),
              ),
              label: Text(
                _hasUploadedDocs ? 'تحديث الوثائق' : 'رفع وثائق KYC',
                style: const TextStyle(color: Color(0xFF1565C0)),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF1565C0)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pushNamed(
                  context, AppRoutes.kycUpload)
                  .then((_) => _loadUserData()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color)),
            const SizedBox(height: 2),
            Text(title,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildAuctionCard(AuctionModel auction) {
    Color statusColor;
    String statusLabel;
    switch (auction.status) {
      case AuctionStatus.active:
        statusColor = Colors.green;
        statusLabel = 'نشط';
        break;
      case AuctionStatus.approved:
        statusColor = Colors.blue;
        statusLabel = 'مقبول';
        break;
      case AuctionStatus.rejected:
        statusColor = Colors.red;
        statusLabel = 'مرفوض';
        break;
      case AuctionStatus.ended:
        statusColor = Colors.grey;
        statusLabel = 'منتهي';
        break;
      case AuctionStatus.submitted:
        statusColor = Colors.orange;
        statusLabel = 'قيد المراجعة';
        break;
      default:
        statusColor = Colors.orange;
        statusLabel = 'مسودة';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // صورة المنتج أو أيقونة
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: auction.imageUrl != null && auction.imageUrl!.isNotEmpty
                    ? Image.network(auction.imageUrl!,
                    width: 44, height: 44, fit: BoxFit.cover)
                    : Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.gavel,
                      color: Color(0xFF1565C0)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(auction.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(
                      'السعر: ${auction.effectiveStartingPrice.toStringAsFixed(0)} DZD'
                          '${auction.adminAdjustedPrice != null ? ' (معدّل)' : ''}',
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(statusLabel,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),

          // يوم المعاينة وتاريخ المزاد
          if (auction.inspectionDay != null || auction.startTime != null) ...[
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            if (auction.inspectionDay != null)
              Row(
                children: [
                  const Icon(Icons.visibility,
                      size: 14, color: Colors.purple),
                  const SizedBox(width: 4),
                  Text('يوم المعاينة: ${_fmt(auction.inspectionDay)}',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.purple)),
                ],
              ),
            if (auction.startTime != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 14, color: Colors.green),
                  const SizedBox(width: 4),
                  Text('تاريخ المزاد: ${_fmt(auction.startTime)}',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.green)),
                ],
              ),
            ],
          ],

          // ملاحظة الأدمين على السعر
          if (auction.adminNote != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 14, color: Colors.orange),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('ملاحظة المسؤول: ${auction.adminNote}',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.orange)),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.arrow_forward_ios,
                  size: 14, color: Color(0xFF1565C0)),
              label: const Text('تتبع المزاد',
                  style:
                  TextStyle(color: Color(0xFF1565C0), fontSize: 13)),
              onPressed: () => Navigator.pushNamed(
                context,
                AppRoutes.trackAuction,
                arguments: auction,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime? d) {
    if (d == null) return 'غير محدد';
    return '${d.day}/${d.month}/${d.year}';
  }
}
