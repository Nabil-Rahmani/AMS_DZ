 import 'package:cloud_firestore/cloud_firestore.dart';
enum DepositMethod { ccp, baridiMob, rechargeCode, card }
 enum DepositStatus { pending, approved, rejected }

class WalletTransaction {
  final String id;
  final String userId;
  final double amount;
  final DepositMethod method;
  final DepositStatus status;
  final String? proofUrl;      // صورة وصل CCP
  final String? rechargeCode;  // كود الشحن
  final DateTime createdAt;
  final DateTime? approvedAt;

  const WalletTransaction({required this.id, required this.userId, required this.amount, required this.method, required this.status, this.proofUrl, this.rechargeCode, required this.createdAt, this.approvedAt});


Map<String, dynamic> toMap() => {
  'userId': userId,
  'amount': amount,
  'method': method.name,
  'status': status.name,
  'proofUrl': proofUrl,
  'rechargeCode': rechargeCode,
  'createdAt': createdAt,
  'approvedAt': approvedAt,
};

factory WalletTransaction.fromMap(String id, Map<String, dynamic> m) =>
WalletTransaction(
id: id,
userId: m['userId'],
amount: (m['amount'] as num).toDouble(),
method: DepositMethod.values.byName(m['method']),
status: DepositStatus.values.byName(m['status']),
proofUrl: m['proofUrl'],
rechargeCode: m['rechargeCode'],
createdAt: (m['createdAt'] as Timestamp).toDate(),
approvedAt: m['approvedAt'] != null ? (m['approvedAt'] as Timestamp).toDate() : null,
);
}