import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole  { admin, organizer, bidder }
enum KycStatus { pending, approved, rejected }

class UserModel {
  final String    id;
  final String    name;
  final String    email;
  final UserRole  role;
  final bool      isActive;
  final DateTime? createdAt;

  // KYC
  final KycStatus? kycStatus;
  final bool       isVerified;
  final String?    kycRejectionReason;
  final Map<String, String>? kycDocuments;

  // معلومات إضافية
  final String? phone;
  final String? address;
  final String? accountType;

  // الرصيد
  final double balance;
  final double blockedBalance;

  // الضمان
  final double?       depositAmount;
  final List<String>? depositPaidBy;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
    this.createdAt,
    this.kycStatus,
    this.isVerified = false,
    this.kycRejectionReason,
    this.kycDocuments,
    this.phone,
    this.address,
    this.accountType,
    this.balance        = 0.0,
    this.blockedBalance = 0.0,
    this.depositAmount,
    this.depositPaidBy,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id:       id,
      name:     map['name']     ?? '',
      email:    map['email']    ?? '',
      role:     _parseUserRole(map['role']),
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(map['createdAt'].toString()))
          : null,
      kycStatus:          _parseKycStatus(map['kycStatus']),
      isVerified:         map['isVerified']         ?? false,
      kycRejectionReason: map['kycRejectionReason'],
      kycDocuments: map['kycDocuments'] != null
          ? Map<String, String>.from(map['kycDocuments'])
          : null,
      phone:          map['phone'],
      address:        map['address'],
      accountType:    map['accountType'],
      balance:        (map['balance']        ?? 0.0).toDouble(),
      blockedBalance: (map['blockedBalance'] ?? 0.0).toDouble(),
      depositAmount: map['depositAmount'] != null
          ? (map['depositAmount']).toDouble()
          : null,
      depositPaidBy: map['depositPaidBy'] != null
          ? List<String>.from(map['depositPaidBy'])
          : null,
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'name':     name,
      'email':    email,
      'role':     role.name,
      'isActive': isActive,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (kycStatus != null) 'kycStatus': kycStatus!.name,
      'isVerified': isVerified,
      if (kycRejectionReason != null) 'kycRejectionReason': kycRejectionReason,
      if (kycDocuments != null)       'kycDocuments':       kycDocuments,
      if (phone != null)              'phone':              phone,
      if (address != null)            'address':            address,
      if (accountType != null)        'accountType':        accountType,
      'balance':        balance,
      'blockedBalance': blockedBalance,
      if (depositAmount != null) 'depositAmount': depositAmount,
      if (depositPaidBy != null) 'depositPaidBy': depositPaidBy,
    };
  }

  UserModel copyWith({
    String?    name,
    String?    email,
    UserRole?  role,
    bool?      isActive,
    DateTime?  createdAt,
    KycStatus? kycStatus,
    bool?      isVerified,
    String?    kycRejectionReason,
    Map<String, String>? kycDocuments,
    String? phone,
    String? address,
    String? accountType,
    double? balance,
    double? blockedBalance,
  }) {
    return UserModel(
      id:                 id,
      name:               name               ?? this.name,
      email:              email              ?? this.email,
      role:               role               ?? this.role,
      isActive:           isActive           ?? this.isActive,
      createdAt:          createdAt          ?? this.createdAt,
      kycStatus:          kycStatus          ?? this.kycStatus,
      isVerified:         isVerified         ?? this.isVerified,
      kycRejectionReason: kycRejectionReason ?? this.kycRejectionReason,
      kycDocuments:       kycDocuments       ?? this.kycDocuments,
      phone:              phone              ?? this.phone,
      address:            address            ?? this.address,
      accountType:        accountType        ?? this.accountType,
      balance:            balance            ?? this.balance,
      blockedBalance:     blockedBalance     ?? this.blockedBalance,
    );
  }

  // ── Computed ──
  double get availableBalance => balance - blockedBalance;
  bool   get isAdmin          => role == UserRole.admin;
  bool   get isOrganizer      => role == UserRole.organizer;
  bool   get isBidder         => role == UserRole.bidder;
  bool   get kycApproved      => kycStatus == KycStatus.approved;
  bool   get kycPending       => kycStatus == KycStatus.pending;
  bool   get kycRejected      => kycStatus == KycStatus.rejected;
}

UserRole _parseUserRole(dynamic value) {
  if (value == null) return UserRole.bidder;
  switch (value.toString()) {
    case 'admin':     return UserRole.admin;
    case 'organizer': return UserRole.organizer;
    default:          return UserRole.bidder;
  }
}

KycStatus? _parseKycStatus(dynamic value) {
  if (value == null) return null;
  switch (value.toString()) {
    case 'pending':  return KycStatus.pending;
    case 'approved': return KycStatus.approved;
    case 'rejected': return KycStatus.rejected;
    default:         return null;
  }
}