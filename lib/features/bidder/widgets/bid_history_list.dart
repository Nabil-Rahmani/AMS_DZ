import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:auction_app2/shared/models/bid_model.dart';
import '../../../core/constants/ds_colors.dart';
import '../../../core/widgets/ds_widgets.dart';

class BidHistoryList extends StatelessWidget {
  final Stream<List<BidModel>> bidsStream;

  const BidHistoryList({super.key, required this.bidsStream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BidModel>>(
      stream: bidsStream,
      builder: (ctx, s) {
        if (s.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: DS.purple),
          );
        }
        final bids = s.data ?? [];
        if (bids.isEmpty) {
          return const DarkCard(
            child: DSEmpty(
              icon: Icons.history_rounded,
              title: 'لا توجد مزايدات بعد',
              subtitle: 'كن الأول!',
            ),
          );
        }

        final uid = FirebaseAuth.instance.currentUser?.uid;
        return DarkCard(
          padding: EdgeInsets.zero,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: bids.length,
            separatorBuilder: (_, __) =>
                const Divider(color: DS.divider, height: 1),
            itemBuilder: (_, i) {
              final bid = bids[i];
              final isTop = i == 0;
              final isMe = bid.bidderId == uid;
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: isTop ? DS.goldGradient : null,
                    color: isTop ? null : DS.bgElevated,
                    border: isTop ? null : Border.all(color: DS.border),
                  ),
                  child: Center(
                    child: Text(
                      isTop ? '🥇' : '${i + 1}',
                      style: TextStyle(
                        fontSize: isTop ? 17 : 13,
                        fontWeight: FontWeight.w800,
                        color: isTop ? Colors.white : DS.textMuted,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  isMe ? 'أنت' : 'مزايد ${bid.bidderId.substring(0, 6)}...',
                  style: TextStyle(
                    fontWeight: isTop ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                    color: isMe ? DS.purple : DS.textPrimary,
                  ),
                ),
                subtitle: bid.timestamp != null
                    ? Text(
                        '${bid.timestamp!.day}/${bid.timestamp!.month}',
                        style: DS.bodySmall,
                      )
                    : null,
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${bid.amount.toStringAsFixed(0)} DZD',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: isTop ? DS.goldLight : DS.textPrimary,
                      ),
                    ),
                    if (isTop)
                      Text(
                        'الأعلى',
                        style: DS.bodySmall.copyWith(
                          color: DS.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
