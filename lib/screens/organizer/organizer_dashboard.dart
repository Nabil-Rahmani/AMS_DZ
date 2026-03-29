import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/auction_model.dart';
import '../../routes/app_routes.dart';

class OrganizerDashboard extends StatefulWidget {
  const OrganizerDashboard({super.key});

  @override
  State<OrganizerDashboard> createState() => _OrganizerDashboardState();
}

class _OrganizerDashboardState extends State<OrganizerDashboard> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  String _kycStatus = 'pending';
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
      setState(() {
        _kycStatus = userDoc.data()?['kycStatus'] ?? 'pending';
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
      if (data['status'] == 'active') active++;
      revenue += (data['currentPrice'] ?? data['startingPrice'] ?? 0).toDouble();
    }

    setState(() {
      _totalAuctions = auctionsSnap.docs.length;
      _activeAuctions = active;
      _totalRevenue = revenue;
    });
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid;
    final kycApproved = _kycStatus == 'approved';

    return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1565C0),
          title: const Text('Organizer Dashboard',
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
                    // KYC Banner
                    _buildKycBanner(kycApproved),
                const SizedBox(height: 16),

                // Stats Row
                Row(
                  children: [
                    _buildStatCard('Total Auctions', _totalAuctions.toString(),
                        Icons.gavel, Colors.blue),
                    const SizedBox(width: 12),
                    _buildStatCard('Active', _activeAuctions.toString(),
                        Icons.play_circle, Colors.green),
                    const SizedBox(width: 12),
                    _buildStatCard('Revenue',
                        '\$${_totalRevenue.toStringAsFixed(0)}',
                        Icons.attach_money, Colors.orange),
                  ],
                ),
                const SizedBox(height: 20),

                // Auctions List
                const Text('My Auctions',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold,
                        color: Color(0xFF1565C0))),
                const SizedBox(height: 10),

                if (uid != null)
            StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('auctions')
            .where('organizerId', isEqualTo: uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {if (snapshot.connectionState == ConnectionState.waiting) {
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
                Text('No auctions yet',
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
        label: const Text('New Auction',
            style: TextStyle(color: Colors.white)),
      )
          : null,
    );
  }

  Widget _buildKycBanner(bool approved) {
    if (approved) {
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
            Text('KYC Verified — You can post auctions',
                style: TextStyle(
                    color: Colors.green.shade700, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _kycStatus == 'rejected'
                  ? 'KYC Rejected — Contact support'
                  : 'KYC Pending — Awaiting admin approval',
              style: TextStyle(
                  color: Colors.orange.shade700, fontWeight: FontWeight.w600),
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
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Column(
                children: [
                Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(value,style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color)),
                  Text(title,
                      style:
                      TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      textAlign: TextAlign.center),
                ],
            ),
        ),
    );
  }

  Widget _buildAuctionCard(AuctionModel auction) {
    Color statusColor;
    switch (auction.status) {
      case AuctionStatus.active:
        statusColor = Colors.green;
        break;
      case AuctionStatus.approved:
        statusColor = Colors.blue;
        break;
      case AuctionStatus.rejected:
        statusColor = Colors.red;
        break;
      case AuctionStatus.ended:
        statusColor = Colors.grey;
        break;
      default:
        statusColor = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.gavel, color: Color(0xFF1565C0)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(auction.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(
                    'Starting: \$${auction.startingPrice.toStringAsFixed(0)}',
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
          ),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              auction.status.name.toUpperCase(),
              style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios,
                size: 16, color: Color(0xFF1565C0)),
            onPressed: () => Navigator.pushNamed(
                context, AppRoutes.trackAuction),
          ),
        ],
      ),
    );
  }
}