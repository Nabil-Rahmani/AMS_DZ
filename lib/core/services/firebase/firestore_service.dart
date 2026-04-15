import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:auction_app2/shared/models/user_model.dart';
import 'package:auction_app2/shared/models/auction_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ══════════════════════════════════════════════════════════════════
  // USERS
  // ══════════════════════════════════════════════════════════════════

  Stream<List<UserModel>> streamAllUsers() {
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
        snap.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList());
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!, doc.id);
  }

  Future<void> createUser(UserModel user) async {
    await _firestore.collection('users').doc(user.id).set(user.toMap());
  }

  Future<void> toggleUserStatus(String uid, bool isActive) async {
    await _firestore.collection('users').doc(uid).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> changeUserRole(String uid, UserRole newRole) async {
    await _firestore.collection('users').doc(uid).update({
      'role': newRole.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _addNotification(
      userId: uid,
      type: 'role_changed',
      message: 'تم تغيير دورك في المنصة إلى: ${_roleLabel(newRole)}.',
    );
  }

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.admin: return 'مدير';
      case UserRole.organizer: return 'منظم';
      case UserRole.bidder: return 'مزايد';
    }
  }

  // ══════════════════════════════════════════════════════════════════
  // KYC
  // ══════════════════════════════════════════════════════════════════

  Stream<List<UserModel>> streamPendingKyc() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'organizer')
        .where('kycStatus', isEqualTo: KycStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
        snap.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList());
  }

  Stream<List<UserModel>> streamAllOrganizers() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'organizer')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
        snap.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList());
  }

  Future<void> approveKyc(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'kycStatus': KycStatus.approved.name,
      'isVerified': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _addNotification(
      userId: uid,
      type: 'kyc_approved',
      message: 'تم قبول طلب التحقق من هويتك. يمكنك الآن إنشاء مزادات.',
    );
  }

  Future<void> rejectKyc(String uid, {required String reason}) async {
    await _firestore.collection('users').doc(uid).update({
      'kycStatus': KycStatus.rejected.name,
      'isVerified': false,
      'kycRejectionReason': reason,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _addNotification(
      userId: uid,
      type: 'kyc_rejected',
      message: 'تم رفض طلب التحقق من هويتك. السبب: $reason',
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // AUCTIONS
  // ══════════════════════════════════════════════════════════════════

  Stream<List<AuctionModel>> streamAuctions({AuctionStatus? status}) {
    Query<Map<String, dynamic>> query = _firestore.collection('auctions');
    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }
    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
        snap.docs.map((d) => AuctionModel.fromMap(d.data(), d.id)).toList());
  }

  Future<String> createAuction(AuctionModel auction) async {
    final ref = await _firestore.collection('auctions').add(auction.toMap());
    return ref.id;
  }

  /// الأدمين يوافق على المزاد فقط (بدون تحديد وقت بعد)
  Future<void> approveAuction(String auctionId) async {
    await _firestore.collection('auctions').doc(auctionId).update({
      'status': AuctionStatus.approved.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// الأدمين يحدد جدول المزاد: يوم المعاينة + بداية + نهاية + يفعّله
  Future<void> setAuctionSchedule({
    required String auctionId,
    required String organizerId,
    required DateTime inspectionDay,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    await _firestore.collection('auctions').doc(auctionId).update({
      'inspectionDay': Timestamp.fromDate(inspectionDay),
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'status': AuctionStatus.approved.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    // إشعار للبائع
    await _addNotification(
      userId: organizerId,
      auctionId: auctionId,
      type: 'auction_scheduled',
      message:
      'تم تحديد موعد مزادك. يوم المعاينة: ${inspectionDay.day}/${inspectionDay.month}/${inspectionDay.year}، تاريخ المزاد: ${startTime.day}/${startTime.month}/${startTime.year}.',
    );
  }

  /// الأدمين يعدّل السعر الابتدائي مع ملاحظة
  Future<void> adjustAuctionPrice({
    required String auctionId,
    required String organizerId,
    required double newPrice,
    required String adminNote,
  }) async {
    await _firestore.collection('auctions').doc(auctionId).update({
      'adminAdjustedPrice': newPrice,
      'currentPrice': newPrice,
      'adminNote': adminNote,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    // إشعار للبائع
    await _addNotification(
      userId: organizerId,
      auctionId: auctionId,
      type: 'price_adjusted',
      message:
      'قام المسؤول بتعديل السعر الابتدائي لمزادك إلى ${newPrice.toStringAsFixed(2)} DZD. السبب: $adminNote',
    );
  }

  /// رفض مزاد
  Future<void> rejectAuction(String auctionId, {String? reason}) async {
    await _firestore.collection('auctions').doc(auctionId).update({
      'status': AuctionStatus.rejected.name,
      'rejectionReason': reason ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// تفعيل مزاد approved → active (بعد ما يحدد الوقت)
  Future<void> activateAuction(String auctionId) async {
    await _firestore.collection('auctions').doc(auctionId).update({
      'status': AuctionStatus.active.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// تحديد الفائز
  Future<void> declareWinner({
    required String auctionId,
    required String winnerId,
  }) async {
    await _firestore.collection('auctions').doc(auctionId).update({
      'winnerId': winnerId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _addNotification(
      userId: winnerId,
      auctionId: auctionId,
      type: 'winner_declared',
      message: 'مبروك! لقد فزت في المزاد.',
    );
  }

  Future<void> deleteAuction(String auctionId) async {
    await _firestore.collection('auctions').doc(auctionId).delete();
  }

  Future<Map<String, dynamic>?> getTopBid(String auctionId) async {
    final snap = await _firestore
        .collection('bids')
        .where('auctionId', isEqualTo: auctionId)
        .orderBy('amount', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return {'id': snap.docs.first.id, ...snap.docs.first.data()};
  }

  // ══════════════════════════════════════════════════════════════════
  // DASHBOARD STATS
  // ══════════════════════════════════════════════════════════════════

  Future<Map<String, int>> getDashboardStats() async {
    final results = await Future.wait([
      _firestore.collection('users').count().get(),
      _firestore
          .collection('users')
          .where('role', isEqualTo: 'organizer')
          .where('kycStatus', isEqualTo: KycStatus.pending.name)
          .count()
          .get(),
      _firestore
          .collection('auctions')
          .where('status', isEqualTo: AuctionStatus.active.name)
          .count()
          .get(),
      _firestore
          .collection('auctions')
          .where('status', isEqualTo: AuctionStatus.submitted.name)
          .count()
          .get(),
    ]);
    return {
      'totalUsers': results[0].count ?? 0,
      'pendingKyc': results[1].count ?? 0,
      'activeAuctions': results[2].count ?? 0,
      'pendingAuctions': results[3].count ?? 0,
    };
  }

  Future<Map<String, dynamic>> getReportsStats() async {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    final results = await Future.wait([
      _firestore.collection('users').where('createdAt', isGreaterThan: Timestamp.fromDate(thirtyDaysAgo)).count().get(),
      _firestore.collection('auctions').where('status', isEqualTo: 'ended').get(),
      _firestore.collection('auctions').count().get(),
    ]);

    final newUsers = (results[0] as AggregateQuerySnapshot).count ?? 0;
    final endedAuctionsDocs = (results[1] as QuerySnapshot).docs;
    final totalAuctions = (results[2] as AggregateQuerySnapshot).count ?? 0;

    double totalVolume = 0;
    for (var doc in endedAuctionsDocs) {
      final data = doc.data() as Map<String, dynamic>;
      totalVolume += (data['currentPrice'] ?? data['startingPrice'] ?? 0).toDouble();
    }

    return {
      'newUsersLast30Days': newUsers,
      'totalVolume': totalVolume,
      'totalAuctions': totalAuctions,
      'endedAuctionsCount': endedAuctionsDocs.length,
    };
  }

  // ══════════════════════════════════════════════════════════════════
  // NOTIFICATIONS
  // ══════════════════════════════════════════════════════════════════

  Future<void> _addNotification({
    required String userId,
    required String type,
    required String message,
    String? auctionId,
  }) async {
    await _firestore.collection('notifications').add({
      'userId': userId,
      if (auctionId != null) 'auctionId': auctionId,
      'type': type,
      'message': message,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
