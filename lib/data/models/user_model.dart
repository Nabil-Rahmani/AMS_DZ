import 'package:cloud_firestore/cloud_firestore.dart';

// تعريف الـ enums (يمكن نقلهما لملف منفصل)
enum UserRole { admin, organizer, bidder }
enum KycStatus { pending, approved, rejected }

class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final bool isActive;
  final DateTime? createdAt; // nullable لأن قد لا يكون موجوداً عند الإنشاء

  // KYC
  final KycStatus? kycStatus;
  final bool isVerified;
  final String? kycRejectionReason;
  final Map<String, String>? kycDocuments;

  // معلومات إضافية
  final String? phone;
  final String? address;

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
  });

  // --- fromMap (للاستخدام مع البيانات العادية) ---
  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: _parseUserRole(map['role']),
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(map['createdAt']))
          : null,
      kycStatus: _parseKycStatus(map['kycStatus']),
      isVerified: map['isVerified'] ?? false,
      kycRejectionReason: map['kycRejectionReason'],
      kycDocuments: map['kycDocuments'] != null
          ? Map<String, String>.from(map['kycDocuments'])
          : null,
      phone: map['phone'],
      address: map['address'],
    );
  }

  // --- toMap (للتخزين في Firestore أو أي قاعدة بيانات) ---
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role.name,
      'isActive': isActive,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (kycStatus != null) 'kycStatus': kycStatus!.name,
      'isVerified': isVerified,
      if (kycRejectionReason != null) 'kycRejectionReason': kycRejectionReason,
      if (kycDocuments != null) 'kycDocuments': kycDocuments,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
    };
  }

  // --- fromFirestore (لقراءة البيانات من Firestore مباشرة) ---
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: _parseUserRole(data['role']),
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      kycStatus: _parseKycStatus(data['kycStatus']),
      isVerified: data['isVerified'] ?? false,
      kycRejectionReason: data['kycRejectionReason'],
      kycDocuments: data['kycDocuments'] != null
          ? Map<String, String>.from(data['kycDocuments'])
          : null,
      phone: data['phone'],
      address: data['address'],
    );
  }

  // --- copyWith (لتعديل نسخة مع الاحتفاظ بالباقي) ---
  UserModel copyWith({
    String? name,
    String? email,
    UserRole? role,
    bool? isActive,
    DateTime? createdAt,
    KycStatus? kycStatus,
    bool? isVerified,
    String? kycRejectionReason,
    Map<String, String>? kycDocuments,
    String? phone,
    String? address,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      kycStatus: kycStatus ?? this.kycStatus,
      isVerified: isVerified ?? this.isVerified,
      kycRejectionReason: kycRejectionReason ?? this.kycRejectionReason,
      kycDocuments: kycDocuments ?? this.kycDocuments,
      phone: phone ?? this.phone,
      address: address ?? this.address,
    );
  }
}

// دوال مساعدة لتحويل String إلى Enum
UserRole _parseUserRole(dynamic value) {
  if (value == null) return UserRole.bidder;
  if (value is UserRole) return value;
  final String roleStr = value.toString();
  switch (roleStr) {
    case 'admin':
      return UserRole.admin;
    case 'organizer':
      return UserRole.organizer;
    default:
      return UserRole.bidder;
  }
}

KycStatus? _parseKycStatus(dynamic value) {
  if (value == null) return null;
  if (value is KycStatus) return value;
  final String statusStr = value.toString();
  switch (statusStr) {
    case 'pending':
      return KycStatus.pending;
    case 'approved':
      return KycStatus.approved;
    case 'rejected':
      return KycStatus.rejected;
    default:
      return null;
  }
}