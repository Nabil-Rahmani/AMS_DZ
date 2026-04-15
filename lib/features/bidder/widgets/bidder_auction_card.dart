import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:auction_app2/shared/models/auction_model.dart';
import '../../../core/constants/ds_colors.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../screens/auction_detail_screen.dart';

class BidderAuctionCard extends StatelessWidget {
  final AuctionModel auction;
  const BidderAuctionCard({super.key, required this.auction});

  @override
  Widget build(BuildContext context) {
    final isActive   = auction.status == AuctionStatus.active;
    final isUpcoming = auction.status == AuctionStatus.approved;
    final isEnded    = auction.status == AuctionStatus.ended;

    return TapAnimated(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
            builder: (_) => AuctionDetailScreen(auctionId: auction.id)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: DS.bgCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isActive ? DS.success.withValues(alpha: 0.2) : DS.border),
          boxShadow: DS.cardShadow,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Stack(children: [
              auction.imageUrl != null && auction.imageUrl!.isNotEmpty
                  ? Image.network(auction.imageUrl!, height: 180, width: double.infinity, fit: BoxFit.cover)
                  : Container(
                      height: 180,
                      decoration: const BoxDecoration(gradient: DS.headerGradient),
                      child: Center(child: Icon(Icons.gavel_rounded, size: 56,
                          color: DS.gold.withValues(alpha: 0.5))),
                    ),
              Positioned.fill(child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, DS.bgCard.withValues(alpha: 0.5)],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    stops: const [0.5, 1.0],
                  ),
                ),
              )),
              Positioned(top: 14, right: 14, child: _statusBadge(auction.status, isActive)),
              if (auction.category != null)
                Positioned(top: 14, left: 14, child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: DS.bg.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: DS.border.withValues(alpha: 0.4)),
                      ),
                      child: Text(auction.category!,
                          style: const TextStyle(fontSize: 11, color: DS.textSecondary, fontWeight: FontWeight.w600)),
                    ),
                  ),
                )),
            ]),
          ),

          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(auction.title, style: DS.titleS, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(auction.description, style: DS.body.copyWith(fontSize: 13),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 14),
              Row(children: [
                DSPriceTag(
                  label: 'السعر الابتدائي',
                  amount: '${auction.effectiveStartingPrice.toStringAsFixed(0)} DZD',
                  isGold: true,
                ),
                const Spacer(),
                if (isActive && auction.endDateTime != null)
                  LiveAuctionTimer(endTime: auction.endDateTime!),
                if (isEnded) const DarkBadge(label: 'منتهي', color: DS.textMuted),
                if (isUpcoming && auction.startTime != null)
                  Row(children: [
                    const Icon(Icons.calendar_today_rounded, size: 13, color: DS.purple),
                    const SizedBox(width: 4),
                    Text(_fmtDate(auction.startTime!),
                        style: DS.bodySmall.copyWith(color: DS.purple, fontWeight: FontWeight.w600)),
                  ]),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  Widget _statusBadge(AuctionStatus status, bool isActive) {
    switch (status) {
      case AuctionStatus.active:
        return const DarkBadge(label: '● LIVE', color: DS.success, dot: false, pulse: false);
      case AuctionStatus.approved:
        return const DarkBadge(label: 'قادم', color: DS.purple);
      case AuctionStatus.ended:
        return const DarkBadge(label: 'منتهي', color: DS.textMuted);
      default:
        return DarkBadge(label: status.label, color: DS.textMuted);
    }
  }
}

class LiveAuctionTimer extends StatefulWidget {
  final DateTime endTime;
  const LiveAuctionTimer({super.key, required this.endTime});
  @override
  State<LiveAuctionTimer> createState() => _LiveAuctionTimerState();
}

class _LiveAuctionTimerState extends State<LiveAuctionTimer> {
  late Duration _rem;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _update();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) { if (mounted) setState(_update); });
  }

  void _update() {
    _rem = widget.endTime.difference(DateTime.now());
    if (_rem.isNegative) { _rem = Duration.zero; _timer.cancel(); }
  }

  @override
  void dispose() { _timer.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final h = _rem.inHours.toString().padLeft(2, '0');
    final m = (_rem.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_rem.inSeconds % 60).toString().padLeft(2, '0');
    return DSCountdown(time: '$h:$m:$s', isUrgent: _rem.inMinutes < 10);
  }
}
