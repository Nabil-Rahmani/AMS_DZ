import 'package:flutter/material.dart';
import 'package:auction_app2/shared/models/user_model.dart';
import '../../../core/constants/ds_colors.dart';

class AdminUtils {
  static String getRoleLabel(UserRole role) {
    switch (role) {
      case UserRole.admin:     return 'مدير النظام';
      case UserRole.organizer: return 'منظم مزادات';
      case UserRole.bidder:    return 'مزايد';
    }
  }

  static String getKycLabel(KycStatus? status) {
    switch (status) {
      case KycStatus.pending:  return 'بانتظار المراجعة';
      case KycStatus.approved: return 'معتمد ✅';
      case KycStatus.rejected: return 'مرفوض ❌';
      default: return 'لم يُقدَّم بعد';
    }
  }

  static Color getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:     return const Color(0xFF7C3AED);
      case UserRole.organizer: return DS.purple;
      case UserRole.bidder:    return DS.success;
    }
  }
}
