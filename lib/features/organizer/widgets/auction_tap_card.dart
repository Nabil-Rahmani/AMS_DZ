import 'package:flutter/material.dart';
import '../../../shared/models/auction_model.dart';
import '../../../core/constants/ds_colors.dart';
import '../../../core/widgets/ds_widgets.dart';

class AuctionTapCard extends StatefulWidget {
  final AuctionModel auction;
  final Color statusColor;
  final String statusLabel;
  final VoidCallback onTap;
  final String Function(DateTime?) dateFormatter;

  const AuctionTapCard({
    super.key,
    required this.auction,
    required this.statusColor,
    required this.statusLabel,
    required this.onTap,
    required this.dateFormatter,
  });

  @override
  State<AuctionTapCard> createState() => _AuctionTapCardState();
}

class _AuctionTapCardState extends State<AuctionTapCard> {
  @override
  Widget build(BuildContext context) {
    final auction = widget.auction;
    return TapAnimated(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: DS.bgCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: DS.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 4,
                color: widget.statusColor,
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Hero(
                      tag: 'auction_img_${auction.id}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child:
                            auction.imageUrl != null &&
                                auction.imageUrl!.isNotEmpty
                            ? Image.network(
                                auction.imageUrl!,
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  gradient: DS.purpleGradient,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.gavel_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            auction.title,
                            style: DS.titleS.copyWith(fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                auction.effectiveStartingPrice.toStringAsFixed(
                                  0,
                                ),
                                style: const TextStyle(
                                  color: DS.goldLight,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'DZD',
                                style: DS.label.copyWith(fontSize: 10),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    DarkBadge(
                      label: widget.statusLabel,
                      color: widget.statusColor,
                      dot: auction.status == AuctionStatus.active,
                      pulse: true,
                    ),
                  ],
                ),
              ),

              if (auction.inspectionDay != null || auction.startTime != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    borderRadius: 16,
                    backgroundColor: DS.bgElevated.withValues(alpha: 0.4),
                    child: Row(
                      children: [
                        if (auction.inspectionDay != null) ...[
                          const Icon(
                            Icons.visibility_rounded,
                            size: 14,
                            color: DS.purple,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'المعاينة: ${widget.dateFormatter(auction.inspectionDay)}',
                            style: DS.bodySmall.copyWith(
                              color: DS.purple,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                        ],
                        if (auction.startTime != null) ...[
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 14,
                            color: DS.success,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'البداية: ${widget.dateFormatter(auction.startTime)}',
                            style: DS.bodySmall.copyWith(
                              color: DS.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

              if (auction.adminNote != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: DSBanner(
                    message: auction.adminNote!,
                    color: DS.warning,
                    icon: Icons.info_rounded,
                  ),
                ),

              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: widget.onTap,
                      icon: const Icon(Icons.analytics_rounded, size: 18),
                      label: const Text(
                        'تتبع وإحصائيات',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: DS.purple,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
