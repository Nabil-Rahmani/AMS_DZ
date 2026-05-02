import 'package:flutter/material.dart';
import 'package:auction_app2/shared/models/user_model.dart';
import '../../../core/constants/ds_colors.dart';
import '../../../core/widgets/ds_widgets.dart';

class KycCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const KycCard({
    super.key,
    required this.user,
    required this.onTap,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = user.kycStatus == KycStatus.pending || user.kycStatus == null;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 14),
      borderRadius: 24,
      padding: const EdgeInsets.all(16),
      border: Border.all(color: DS.border),
      backgroundColor: DS.bgCard.withValues(alpha: 0.4),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DSAvatar(name: user.name, radius: 24, color: DS.purple),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name, style: DS.titleS.copyWith(fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(user.email, style: DS.bodySmall),
                    ],
                  ),
                ),
                KycBadge(status: user.kycStatus),
              ],
            ),
            const SizedBox(height: 16),
            const DSDivider(),
            const SizedBox(height: 12),
            Row(
              children: [
                MiniInfo(icon: Icons.business_rounded, label: user.accountType == 'company' ? 'شركة' : 'شخص طبيعي'),
                if (user.phone != null) ...[
                  const SizedBox(width: 16),
                  MiniInfo(icon: Icons.phone_rounded, label: user.phone!),
                ],
              ],
            ),
            if (isPending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: DS.error),
                        foregroundColor: DS.error,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: onReject,
                      child: const Text('رفض', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GradientButton(
                      label: 'قبول',
                      height: 44,
                      onPressed: onApprove,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class KycBadge extends StatelessWidget {
  final KycStatus? status;
  const KycBadge({super.key, this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case KycStatus.approved:
        color = DS.success;
        label = 'معتمد ✅';
        break;
      case KycStatus.rejected:
        color = DS.error;
        label = 'مرفوض ❌';
        break;
      default:
        color = DS.warning;
        label = 'قيد المراجعة';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}

class MiniInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  const MiniInfo({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: DS.textMuted),
      const SizedBox(width: 6),
      Text(label, style: DS.bodySmall.copyWith(fontSize: 11)),
    ]);
  }
}
