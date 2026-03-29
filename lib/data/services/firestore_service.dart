import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/auction_model.dart';
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // ══════════════════════════════════════════════════════════════════
  // USERS
  // ══════════════════════════════════════════════════════════════════
  /// Stream كل المستخدمين real-time
  Stream<List<UserModel>> streamAllUsers() {
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
        snap.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList());
  }
  /// جلب مستخدم واحد
  Future<UserModel?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!, doc.id);
  }

  /// إنشاء مستخدم جديد في Firestore (بعد Firebase Auth)
  Future<void> createUser(UserModel user) async {
    await _firestore.collection('users').doc(user.id).set(user.toMap());
  }

  /// تفعيل / تعطيل مستخدم
  Future<void> toggleUserStatus(String uid, bool isActive) async {
    await _firestore.collection('users').doc(uid).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// تحديث بيانات مستخدم
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ══════════════════════════════════════════════════════════════════
  // KYC (Organizer Verification)
  // ══════════════════════════════════════════════════════════════════

  /// Stream المنظمين اللي لديهم طلب KYC pending
  Stream<List<UserModel>> streamPendingKyc() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'organizer')
        .where('kycStatus', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
        snap.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList());
  }

  /// Stream كل المنظمين (بغض النظر عن KYC)
  Stream<List<UserModel>> streamAllOrganizers() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'organizer')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
        snap.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList());
  }

  /// الموافقة على KYC
  Future<void> approveKyc(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'kycStatus': 'approved',
      'isVerified': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _addNotification(
      userId: uid,
      type: 'kyc_approved',
      message: 'تم قبول طلب التحقق من هويتك. يمكنك الآن إنشاء مزادات.',
    );
  }

  /// رفض KYC مع سبب
  Future<void> rejectKyc(String uid, {required String reason}) async {
    await _firestore.collection('users').doc(uid).update({
      'kycStatus': 'rejected',
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

  /// Stream المزادات مع فلتر اختياري بالحالة
  Stream<List<AuctionModel>> streamAuctions({AuctionStatus? status}) {
    Query<Map<String, dynamic>> query =
    _firestore.collection('auctions');
    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }
    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
        snap.docs.map((d) => AuctionModel.fromMap(d.data(), d.id)).toList());
  }

  /// إنشاء مزاد جديد
  Future<String> createAuction(AuctionModel auction) async {
    final ref = await _firestore.collection('auctions').add(auction.toMap());
    return ref.id;
  }

  /// الموافقة على مزاد submitted → approved
  Future<void> approveAuction(String auctionId) async {
    await _firestore.collection('auctions').doc(auctionId).update({
      'status': AuctionStatus.approved.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// رفض مزاد submitted → rejected
  Future<void> rejectAuction(String auctionId, {String? reason}) async {
    await _firestore.collection('auctions').doc(auctionId).update({
      'status': AuctionStatus.rejected.name,
      'rejectionReason': reason ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// تحديد الفائز لمزاد منتهي
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

  /// جلب أعلى مزايدة لمزاد معين
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
          .where('kycStatus', isEqualTo: 'pending')
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

  // ══════════════════════════════════════════════════════════════════
  // NOTIFICATIONS (private helper)
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
