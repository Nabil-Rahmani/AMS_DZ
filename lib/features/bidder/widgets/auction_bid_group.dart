import 'package:flutter/material.dart';
import 'package:auction_app2/shared/models/auction_model.dart';
import 'package:auction_app2/shared/models/bid_model.dart';
import '../../../core/constants/ds_colors.dart';
import '../../../core/widgets/ds_widgets.dart';

class AuctionBidGroup extends StatelessWidget {
  final AuctionModel? auction;
  final List<BidModel> bids;
  final bool isWinner;
  final VoidCallback? onTap;

  const AuctionBidGroup({
    super.key,
    required this.auction,
    required this.bids,
    required this.isWinner,
    this.onTap,
  });

  String _fmt(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final highestBid = bids.map((b) => b.amount).reduce((a, b) => a > b ? a : b);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: DS.bgCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isWinner ? DS.goldDark : DS.border, width: isWinner ? 2 : 1),
          boxShadow: [BoxShadow(color: isWinner ? DS.goldDark.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isWinner ? DS.goldLight : DS.bgElevated,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(auction?.title ?? 'مزاد غير معروف', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: DS.textPrimary)),
                if (auction?.category != null) ...[
                  const SizedBox(height: 2),
                  Text(auction!.category!, style: const TextStyle(fontSize: 12, color: DS.textSecondary)),
                ],
              ])),
              const SizedBox(width: 12),
              if (isWinner)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(gradient: DS.goldGradient, borderRadius: BorderRadius.circular(20)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.emoji_events_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text('فائز 🏆', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                  ]),
                )
              else if (auction != null)
                _buildDarkBadge(auction!.status),
            ]),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: _SmallTile(label: 'أعلى مزايدة منك', value: '${highestBid.toStringAsFixed(0)} DZD', highlight: true)),
                const SizedBox(width: 12),
                if (auction != null) Expanded(child: _SmallTile(label: 'السعر الحالي', value: '${(auction!.currentPrice ?? 0).toStringAsFixed(0)} DZD')),
              ]),
              const SizedBox(height: 14),
              Text('مزايداتك (${bids.length})', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: DS.textPrimary)),
              const SizedBox(height: 8),
              ...bids.take(3).map((bid) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: DS.bgElevated, borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: DS.purple, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text('${bid.amount.toStringAsFixed(0)} DZD', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: DS.textPrimary)),
                  const Spacer(),
                  if (bid.timestamp != null) Text(_fmt(bid.timestamp!), style: const TextStyle(fontSize: 11, color: DS.textSecondary)),
                ]),
              )),
              if (bids.length > 3) Text('+ ${bids.length - 3} مزايدات أخرى', style: const TextStyle(fontSize: 12, color: DS.purple, fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildDarkBadge(AuctionStatus status) {
    switch (status) {
      case AuctionStatus.active: return const DarkBadge(label: 'مباشر', color: DS.success, dot: true);
      case AuctionStatus.ended: return DarkBadge(label: 'منتهي', color: DS.textMuted);
      case AuctionStatus.approved: return const DarkBadge(label: 'قادم', color: DS.info);
      default: return DarkBadge(label: status.name, color: DS.textMuted);
    }
  }
}

class _SmallTile extends StatelessWidget {
  final String label, value;
  final bool highlight;
  const _SmallTile({required this.label, required this.value, this.highlight = false});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlight ? DS.purpleDeep : DS.bgElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 11, color: DS.textSecondary)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: highlight ? DS.purple : DS.textPrimary)),
      ]),
    );
  }
}
