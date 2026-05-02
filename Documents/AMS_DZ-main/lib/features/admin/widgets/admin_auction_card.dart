import 'package:flutter/material.dart';
import 'package:auction_app2/shared/models/auction_model.dart';
import '../../../core/constants/ds_colors.dart';
import '../../../core/widgets/ds_widgets.dart';

class AdminAuctionCard extends StatelessWidget {
  final AuctionModel auction;
  final VoidCallback onApprove, onReject, onSetSchedule,
      onAdjustPrice, onActivate, onDeclareWinner, onDelete;
  final VoidCallback onRefundDeposits; // ✅ جديد

  const AdminAuctionCard({
    super.key,
    required this.auction,
    required this.onApprove,
    required this.onReject,
    required this.onSetSchedule,
    required this.onAdjustPrice,
    required this.onActivate,
    required this.onDeclareWinner,
    required this.onRefundDeposits, // ✅ جديد
    required this.onDelete,
  });

  String _fmt(DateTime? d) {
    if (d == null) return 'غير محدد';
    return '${d.day}/${d.month}/${d.year}';
  }

  Color get _statusColor {
    switch (auction.status) {
      case AuctionStatus.submitted: return DS.warning;
      case AuctionStatus.approved:  return DS.info;
      case AuctionStatus.active:    return DS.success;
      case AuctionStatus.ended:     return DS.textMuted;
      case AuctionStatus.rejected:  return DS.error;
      default: return DS.textMuted;
    }
  }

  String get _statusLabel {
    switch (auction.status) {
      case AuctionStatus.submitted: return 'قيد المراجعة';
      case AuctionStatus.approved:  return 'مقبول';
      case AuctionStatus.active:    return 'نشط';
      case AuctionStatus.ended:     return 'منتهي';
      case AuctionStatus.rejected:  return 'مرفوض';
      default: return 'مسودة';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin:           const EdgeInsets.only(bottom: 16),
      padding:          EdgeInsets.zero,
      borderRadius:     DS.radiusCard,
      backgroundColor:  _statusColor.withValues(alpha: 0.02),
      border:           Border.all(color: DS.border),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: DS.bgElevated.withValues(alpha: 0.4),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(DS.radiusCard)),
            border: Border(bottom: BorderSide(color: _statusColor.withValues(alpha: 0.2))),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(auction.title, style: DS.titleS.copyWith(fontSize: 16)),
              const SizedBox(height: 6),
              Text(auction.description, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: DS.bodySmall.copyWith(height: 1.4)),
            ])),
            const SizedBox(width: 12),
            DarkBadge(label: _statusLabel, color: _statusColor,
                dot: auction.status == AuctionStatus.active, pulse: true),
          ]),
        ),

        Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _DetailChip(
                icon:  Icons.payments_rounded,
                label: '${auction.startingPrice.toStringAsFixed(0)} DZD',
                color: DS.purple,
              ),
              if (auction.adminAdjustedPrice != null) ...[
                const SizedBox(width: 8),
                const Icon(Icons.arrow_back_rounded, size: 14, color: DS.warning),
                const SizedBox(width: 4),
                _DetailChip(
                  icon:  Icons.edit_rounded,
                  label: '${auction.adminAdjustedPrice!.toStringAsFixed(0)} DZD',
                  color: DS.warning,
                ),
              ],
            ]),

            if (auction.inspectionDay != null || auction.startTime != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: DS.bgField.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(DS.radiusField),
                  border: Border.all(color: DS.border),
                ),
                child: IntrinsicHeight(
                  child: Row(children: [
                    if (auction.inspectionDay != null) ...[
                      const Icon(Icons.visibility_rounded, size: 14, color: DS.purple),
                      const SizedBox(width: 6),
                      Text('معاينة: ${_fmt(auction.inspectionDay)}',
                          style: DS.label.copyWith(color: DS.textPrimary, fontSize: 10, letterSpacing: 0)),
                    ],
                    if (auction.inspectionDay != null && auction.startTime != null)
                      const VerticalDivider(width: 24, thickness: 1, indent: 4, endIndent: 4, color: DS.border),
                    if (auction.startTime != null) ...[
                      const Icon(Icons.gavel_rounded, size: 14, color: DS.success),
                      const SizedBox(width: 6),
                      Text('مزاد: ${_fmt(auction.startTime)}',
                          style: DS.label.copyWith(color: DS.textPrimary, fontSize: 10, letterSpacing: 0)),
                    ],
                  ]),
                ),
              ),
            ],

            const SizedBox(height: 18),
            _buildActions(),
          ]),
        ),
      ]),
    );
  }

  Widget _buildActions() {
    if (auction.status == AuctionStatus.submitted) {
      return Row(children: [
        Expanded(child: OutlinedButton.icon(
          icon:  const Icon(Icons.close_rounded, size: 16, color: DS.error),
          label: const Text('رفض', style: TextStyle(color: DS.error, fontSize: 13)),
          style: OutlinedButton.styleFrom(
            side:    const BorderSide(color: DS.error),
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape:   RoundedRectangleBorder(borderRadius: BorderRadius.circular(DS.radiusButton)),
          ),
          onPressed: onReject,
        )),
        const SizedBox(width: 10),
        Expanded(child: ElevatedButton.icon(
          icon:  const Icon(Icons.check_rounded, size: 16, color: Colors.white),
          label: const Text('موافقة', style: TextStyle(fontSize: 13, color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: DS.success,
            foregroundColor: Colors.white,
            padding:         const EdgeInsets.symmetric(vertical: 10),
            shape:           RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: onApprove,
        )),
      ]);
    }

    if (auction.status == AuctionStatus.approved) {
      return Column(children: [
        Row(children: [
          Expanded(child: OutlinedButton.icon(
            icon:  const Icon(Icons.price_change_rounded, size: 15),
            label: const Text('تعديل السعر', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape:   RoundedRectangleBorder(borderRadius: BorderRadius.circular(DS.radiusButton)),
            ),
            onPressed: onAdjustPrice,
          )),
          const SizedBox(width: 8),
          Expanded(child: OutlinedButton.icon(
            icon:  const Icon(Icons.calendar_month_rounded, size: 15, color: DS.purple),
            label: const Text('تحديد الموعد', style: TextStyle(fontSize: 12, color: DS.purple)),
            style: OutlinedButton.styleFrom(
              side:    const BorderSide(color: DS.purple),
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape:   RoundedRectangleBorder(borderRadius: BorderRadius.circular(DS.radiusButton)),
            ),
            onPressed: onSetSchedule,
          )),
        ]),
        const SizedBox(height: 8),
        SizedBox(width: double.infinity, child: ElevatedButton.icon(
          icon:  const Icon(Icons.play_arrow_rounded, size: 16, color: Colors.white),
          label: const Text('تفعيل المزاد', style: TextStyle(fontSize: 13, color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: DS.success,
            foregroundColor: Colors.white,
            padding:         const EdgeInsets.symmetric(vertical: 10),
            shape:           RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: onActivate,
        )),
      ]);
    }

    // ✅ منتهي بدون فائز — تحديد الفائز أولاً
    if (auction.status == AuctionStatus.ended && auction.winnerId == null) {
      return SizedBox(width: double.infinity, child: Container(
        decoration: BoxDecoration(
          gradient:     DS.goldGradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow:    DS.goldShadow,
        ),
        child: ElevatedButton.icon(
          icon:  const Icon(Icons.emoji_events_rounded, size: 16, color: Colors.white),
          label: const Text('تحديد الفائز', style: TextStyle(fontSize: 13, color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor:     Colors.transparent,
            padding:         const EdgeInsets.symmetric(vertical: 10),
            shape:           RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: onDeclareWinner,
        ),
      ));
    }

    // ✅ منتهي مع فائز — زر إرجاع الضمانات
    if (auction.status == AuctionStatus.ended && auction.winnerId != null) {
      return Column(children: [
        GlassCard(
          padding:         const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          borderRadius:    14,
          backgroundColor: DS.gold.withValues(alpha: 0.1),
          border:          Border.all(color: DS.gold.withValues(alpha: 0.2)),
          child: Row(children: [
            const Icon(Icons.emoji_events_rounded, color: DS.goldLight, size: 18),
            const SizedBox(width: 10),
            Text('تم تحديد الفائز بنجاح ✅',
                style: DS.titleS.copyWith(color: DS.goldLight, fontSize: 13)),
          ]),
        ),
        const SizedBox(height: 10),
        // ✅ زر إرجاع الضمانات
        SizedBox(width: double.infinity, child: OutlinedButton.icon(
          icon:  const Icon(Icons.account_balance_wallet_rounded, size: 16, color: DS.purple),
          label: const Text('إرجاع الضمانات', style: TextStyle(color: DS.purple, fontSize: 13)),
          style: OutlinedButton.styleFrom(
            side:    const BorderSide(color: DS.purple),
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape:   RoundedRectangleBorder(borderRadius: BorderRadius.circular(DS.radiusButton)),
          ),
          onPressed: onRefundDeposits,
        )),
      ]);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: OutlinedButton.icon(
        icon:  const Icon(Icons.delete_forever_rounded, size: 16, color: DS.error),
        label: const Text('حذف المزاد', style: TextStyle(color: DS.error, fontSize: 13)),
        style: OutlinedButton.styleFrom(
          side:    const BorderSide(color: DS.error, width: 1.2),
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape:   RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onDelete,
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  const _DetailChip({required this.icon, required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}