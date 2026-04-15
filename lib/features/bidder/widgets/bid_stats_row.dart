import 'package:flutter/material.dart';
import '../../../core/constants/ds_colors.dart';

class BidStatsRow extends StatelessWidget {
  final int totalBids;
  final int wonAuctions;
  final int totalParticipated;

  const BidStatsRow({
    super.key,
    required this.totalBids,
    required this.wonAuctions,
    required this.totalParticipated,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DS.bgCard,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(children: [
        Expanded(child: _MiniStat(label: 'إجمالي المزايدات', value: totalBids.toString(), color: DS.purple)),
        const SizedBox(width: 12),
        Expanded(child: _MiniStat(label: 'مزادات مُكتسبة', value: wonAuctions.toString(), color: DS.goldDark)),
        const SizedBox(width: 12),
        Expanded(child: _MiniStat(label: 'مزادات شاركت', value: totalParticipated.toString(), color: DS.success)),
      ]),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MiniStat({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 11, color: DS.textSecondary), textAlign: TextAlign.center),
    ]);
  }
}
