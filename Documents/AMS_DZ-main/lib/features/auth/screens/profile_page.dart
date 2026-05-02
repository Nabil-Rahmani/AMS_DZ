import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/ds_colors.dart';
import '../../../core/widgets/ds_widgets.dart';
import 'package:auction_app2/shared/models/user_model.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: DS.bgModal.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: DS.border),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: DS.errorSurface,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: DS.error.withValues(alpha: 0.2)),
                      ),
                      child: const Icon(Icons.logout_rounded,
                          color: DS.error, size: 28),
                    ),
                    const SizedBox(height: 20),
                    Text('تسجيل الخروج؟', style: DS.titleM),
                    const SizedBox(height: 8),
                    Text('هل أنت متأكد من رغبتك في تسجيل الخروج؟',
                        style: DS.body, textAlign: TextAlign.center),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('إلغاء'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: DS.error),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('خروج'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (ok == true) {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: DS.purple));
          }
          if (!snap.hasData || !snap.data!.exists) {
            return const Center(
                child: Text('لم يتم العثور على بيانات المستخدم',
                    style: TextStyle(color: Colors.white)));
          }

          final user = UserModel.fromFirestore(snap.data!);

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
                  child: Column(
                    children: [
                      // Avatar
                      FadeSlideIn(
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: DS.purpleGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: DS.purple.withValues(alpha: 0.3),
                                blurRadius: 30,
                                offset: const Offset(0, 15),
                              )
                            ],
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 4),
                          ),
                          child: Center(
                            child: Text(
                              user.name.isNotEmpty
                                  ? user.name[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                  fontSize: 42,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      FadeSlideIn(
                          delay: const Duration(milliseconds: 100),
                          child: Text(user.name,
                              style: DS.displayLarge.copyWith(fontSize: 28))),
                      const SizedBox(height: 4),
                      FadeSlideIn(
                          delay: const Duration(milliseconds: 150),
                          child: Text(user.email,
                              style:
                                  DS.body.copyWith(color: DS.textSecondary))),

                      const SizedBox(height: 12),
                      FadeSlideIn(
                          delay: const Duration(milliseconds: 200),
                          child: DarkBadge(
                            label: user.role == UserRole.organizer
                                ? 'منظم مبيعات'
                                : 'مزايد معتمد',
                            color: user.role == UserRole.organizer
                                ? DS.success
                                : DS.purple,
                          )),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const FadeSlideIn(
                        delay: Duration(milliseconds: 250),
                        child: DSSection(title: 'المعلومات الشخصية')),
                    const SizedBox(height: 14),
                    _buildInfoCard(
                      'رقم الهاتف',
                      user.phone ?? 'غير مسجل',
                      Icons.phone_iphone_rounded,
                      DS.purple,
                      delay: 300,
                    ),
                    _buildInfoCard(
                      'نوع الحساب',
                      user.accountType == 'company' ? 'شركة / مؤسسة' : 'فردي',
                      Icons.business_center_rounded,
                      DS.info,
                      delay: 350,
                    ),
                    if (user.role == UserRole.organizer)
                      _buildInfoCard(
                        'حالة التحقق (KYC)',
                        _kycLabel(user.kycStatus),
                        Icons.verified_user_rounded,
                        _kycColor(user.kycStatus),
                        delay: 400,
                      ),
                    const SizedBox(height: 40),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 500),
                      child: TapAnimated(
                        onTap: () => _logout(context),
                        child: GlassCard(
                          padding: const EdgeInsets.symmetric(
                              vertical: 20, horizontal: 24),
                          borderRadius: 24,
                          backgroundColor: DS.error.withValues(alpha: 0.05),
                          border: Border.all(
                              color: DS.error.withValues(alpha: 0.15)),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: DS.error.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.logout_rounded,
                                    color: DS.error, size: 22),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'تسجيل الخروج',
                                  style: DS.titleS.copyWith(
                                      color: DS.error,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                              const Icon(Icons.arrow_back_ios_new_rounded,
                                  color: DS.error, size: 14),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon, Color color,
      {int delay = 0}) {
    return FadeSlideIn(
      delay: Duration(milliseconds: delay),
      child: GlassCard(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        borderRadius: 20,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: DS.bodySmall.copyWith(color: DS.textSecondary)),
                  const SizedBox(height: 4),
                  Text(value, style: DS.titleS.copyWith(fontSize: 16)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _kycLabel(KycStatus? status) {
    switch (status) {
      case KycStatus.approved:
        return 'موثق';
      case KycStatus.pending:
        return 'قيد المراجعة';
      case KycStatus.rejected:
        return 'مرفوض';
      default:
        return 'لم يتم التقديم';
    }
  }

  Color _kycColor(KycStatus? status) {
    switch (status) {
      case KycStatus.approved:
        return DS.success;
      case KycStatus.pending:
        return DS.warning;
      case KycStatus.rejected:
        return DS.error;
      default:
        return DS.textMuted;
    }
  }
}
