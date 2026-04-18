import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:auction_app2/shared/models/user_model.dart';
import 'package:auction_app2/shared/models/auction_model.dart';
import 'package:auction_app2/shared/models/wallet_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _db = FirebaseFirestore.instance;

  // ══════════════════════════════════════════════════════════════════
  // USERS
  // ══════════════════════════════════════════════════════════════════
  Stream<UserModel> streamUser(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => UserModel.fromMap(doc.data()!, doc.id));
  }

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
      case UserRole.admin:     return 'مدير';
      case UserRole.organizer: return 'منظم';
      case UserRole.bidder:    return 'مزايد';
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

  Future<void> approveAuction(String auctionId) async {
    await _firestore.collection('auctions').doc(auctionId).update({
      'status': AuctionStatus.approved.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setAuctionSchedule({
    required String auctionId,
    required String organizerId,
    required DateTime inspectionDay,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    await _firestore.collection('auctions').doc(auctionId).update({
      'inspectionDay': Timestamp.fromDate(inspectionDay),
      'startTime':     Timestamp.fromDate(startTime),
      'endTime':       Timestamp.fromDate(endTime),
      'status':        AuctionStatus.approved.name,
      'updatedAt':     FieldValue.serverTimestamp(),
    });
    await _addNotification(
      userId: organizerId,
      auctionId: auctionId,
      type: 'auction_scheduled',
      message:
      'تم تحديد موعد مزادك. يوم المعاينة: ${inspectionDay.day}/${inspectionDay.month}/${inspectionDay.year}، تاريخ المزاد: ${startTime.day}/${startTime.month}/${startTime.year}.',
    );
  }

  Future<void> adjustAuctionPrice({
    required String auctionId,
    required String organizerId,
    required double newPrice,
    required String adminNote,
  }) async {
    await _firestore.collection('auctions').doc(auctionId).update({
      'adminAdjustedPrice': newPrice,
      'currentPrice':       newPrice,
      'adminNote':          adminNote,
      'updatedAt':          FieldValue.serverTimestamp(),
    });
    await _addNotification(
      userId: organizerId,
      auctionId: auctionId,
      type: 'price_adjusted',
      message:
      'قام المسؤول بتعديل السعر الابتدائي لمزادك إلى ${newPrice.toStringAsFixed(2)} DZD. السبب: $adminNote',
    );
  }

  Future<void> rejectAuction(String auctionId, {String? reason}) async {
    await _firestore.collection('auctions').doc(auctionId).update({
      'status':          AuctionStatus.rejected.name,
      'rejectionReason': reason ?? '',
      'updatedAt':       FieldValue.serverTimestamp(),
    });
  }

  Future<void> activateAuction(String auctionId) async {
    await _firestore.collection('auctions').doc(auctionId).update({
      'status':    AuctionStatus.active.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> declareWinner({
    required String auctionId,
    required String winnerId,
  }) async {
    await _firestore.collection('auctions').doc(auctionId).update({
      'winnerId':  winnerId,
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
      'totalUsers':      results[0].count ?? 0,
      'pendingKyc':      results[1].count ?? 0,
      'activeAuctions':  results[2].count ?? 0,
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
    final newUsers         = (results[0] as AggregateQuerySnapshot).count ?? 0;
    final endedAuctionsDocs = (results[1] as QuerySnapshot).docs;
    final totalAuctions    = (results[2] as AggregateQuerySnapshot).count ?? 0;
    double totalVolume = 0;
    for (var doc in endedAuctionsDocs) {
      final data = doc.data() as Map<String, dynamic>;
      totalVolume += (data['currentPrice'] ?? data['startingPrice'] ?? 0).toDouble();
    }
    return {
      'newUsersLast30Days': newUsers,
      'totalVolume':        totalVolume,
      'totalAuctions':      totalAuctions,
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
      'type':      type,
      'message':   message,
      'isRead':    false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ══════════════════════════════════════════════════════════════════
  // DEPOSIT (نظام الضمان)
  // ══════════════════════════════════════════════════════════════════

  Future<void> payDeposit({
    required String auctionId,
    required String userId,
    required double depositAmount,
  }) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final user = UserModel.fromMap(userDoc.data()!, userDoc.id);
    if (user.availableBalance < depositAmount) {
      throw Exception('الرصيد غير كافٍ. رصيدك المتاح: ${user.availableBalance.toStringAsFixed(0)} DZD');
    }
    final batch = _firestore.batch();
    batch.update(_firestore.collection('users').doc(userId), {
      'balance':        FieldValue.increment(-depositAmount),
      'blockedBalance': FieldValue.increment(depositAmount),
      'updatedAt':      FieldValue.serverTimestamp(),
    });
    batch.update(_firestore.collection('auctions').doc(auctionId), {
      'depositPaidBy': FieldValue.arrayUnion([userId]),
      'updatedAt':     FieldValue.serverTimestamp(),
    });
    await batch.commit();
    await _addNotification(
      userId: userId,
      auctionId: auctionId,
      type: 'deposit_paid',
      message: 'تم دفع ضمان ${depositAmount.toStringAsFixed(0)} DZD. أنت الآن مشارك رسمي في المزاد.',
    );
  }

  Future<void> refundDeposits({
    required String auctionId,
    required String winnerId,
    required double depositAmount,
  }) async {
    final auctionDoc = await _firestore.collection('auctions').doc(auctionId).get();
    final data = auctionDoc.data()!;
    final List<String> depositPaidBy = List<String>.from(data['depositPaidBy'] ?? []);
    final batch = _firestore.batch();
    for (final uid in depositPaidBy) {
      if (uid == winnerId) continue;
      batch.update(_firestore.collection('users').doc(uid), {
        'balance':        FieldValue.increment(depositAmount),
        'blockedBalance': FieldValue.increment(-depositAmount),
        'updatedAt':      FieldValue.serverTimestamp(),
      });
      await _addNotification(
        userId: uid,
        auctionId: auctionId,
        type: 'deposit_refunded',
        message: 'تم إرجاع ضمانك ${depositAmount.toStringAsFixed(0)} DZD بعد انتهاء المزاد.',
      );
    }
    await batch.commit();
  }

  Future<void> refundSingleDeposit({
    required String auctionId,
    required String userId,
    required double depositAmount,
  }) async {
    final batch = _firestore.batch();
    batch.update(_firestore.collection('users').doc(userId), {
      'balance':        FieldValue.increment(depositAmount),
      'blockedBalance': FieldValue.increment(-depositAmount),
      'updatedAt':      FieldValue.serverTimestamp(),
    });
    batch.update(_firestore.collection('auctions').doc(auctionId), {
      'depositPaidBy': FieldValue.arrayRemove([userId]),
      'updatedAt':     FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  // ══════════════════════════════════════════════════════════════════
  // WALLET
  // ══════════════════════════════════════════════════════════════════

  Future<void> rechargeWithCode(String userId, String code) async {
    final codeDoc = await _db.collection('recharge_codes').doc(code).get();
    if (!codeDoc.exists) throw Exception('الكود غير صالح');
    final data = codeDoc.data()!;
    if (data['used'] == true) throw Exception('الكود مستخدم مسبقاً');
    final amount = (data['amount'] as num).toDouble();
    final batch = _db.batch();
    batch.update(_db.collection('recharge_codes').doc(code), {
      'used':   true,
      'usedBy': userId,
      'usedAt': FieldValue.serverTimestamp(),
    });
    batch.update(_db.collection('users').doc(userId), {
      'balance': FieldValue.increment(amount),
    });
    batch.set(_db.collection('wallet_transactions').doc(), {
      'userId':       userId,
      'amount':       amount,
      'method':       'rechargeCode',
      'status':       'approved',
      'rechargeCode': code,
      'createdAt':    FieldValue.serverTimestamp(),
      'approvedAt':   FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> requestDeposit({
    required String userId,
    required double amount,
    required DepositMethod method,
    String? proofUrl,
  }) async {
    await _db.collection('wallet_transactions').add({
      'userId':    userId,
      'amount':    amount,
      'method':    method.name,
      'status':    'pending',
      'proofUrl':  proofUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> approveDeposit(String txId, String userId, double amount) async {
    final batch = _db.batch();
    batch.update(_db.collection('wallet_transactions').doc(txId), {
      'status':     'approved',
      'approvedAt': FieldValue.serverTimestamp(),
    });
    batch.update(_db.collection('users').doc(userId), {
      'balance': FieldValue.increment(amount),
    });
    await batch.commit();
  }

  Future<void> rejectDeposit(String txId) async {
    await _db.collection('wallet_transactions').doc(txId).update({
      'status': 'rejected',
    });
  }

  Future<void> blockDeposit(String userId, double depositAmount) async {
    final userRef = _db.collection('users').doc(userId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(userRef);
      final balance = (snap['balance'] as num).toDouble();
      if (balance < depositAmount) throw Exception('الرصيد غير كافٍ');
      tx.update(userRef, {
        'balance':        FieldValue.increment(-depositAmount),
        'blockedBalance': FieldValue.increment(depositAmount),
      });
    });
  }

  Future<void> releaseDeposit(String userId, double depositAmount) async {
    await _db.collection('users').doc(userId).update({
      'blockedBalance': FieldValue.increment(-depositAmount),
      'balance':        FieldValue.increment(depositAmount),
    });
  }

  Future<void> consumeDeposit(String userId, double depositAmount) async {
    await _db.collection('users').doc(userId).update({
      'blockedBalance': FieldValue.increment(-depositAmount),
    });
  }

  // ✅ بدون orderBy لتجنب مشكلة الـ index
  Stream<List<WalletTransaction>> streamUserTransactions(String userId) =>
      _db.collection('wallet_transactions')
          .where('userId', isEqualTo: userId)
          .snapshots()
          .map((s) {
        final docs = s.docs
            .map((d) => WalletTransaction.fromMap(d.id, d.data()))
            .toList();
        // ترتيب يدوي بدل orderBy
        docs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return docs;
      });

  // ✅ بدون orderBy لتجنب مشكلة الـ index
  Stream<List<WalletTransaction>> streamPendingDeposits() =>
      _db.collection('wallet_transactions')
          .where('status', isEqualTo: 'pending')
          .snapshots()
          .map((s) {
        final docs = s.docs
            .map((d) => WalletTransaction.fromMap(d.id, d.data()))
            .toList();
        // ترتيب يدوي بدل orderBy
        docs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return docs;
      });
  Future<void> requestDepositWithCard({
    required String userId,
    required double amount,
    required String cardName,
    required String cardNumber,
    required String cardExpiry,
  }) async {
    await _db.collection('wallet_transactions').add({
      'userId':     userId,
      'amount':     amount,
      'method':     'card',
      'status':     'pending',
      // ✅ نحفظ آخر 4 أرقام فقط للأمان
      'cardName':   cardName,
      'cardLast4':  cardNumber.substring(cardNumber.length - 4),
      'cardExpiry': cardExpiry,
      'createdAt':  FieldValue.serverTimestamp(),
    });
  }
}