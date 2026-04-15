import 'package:flutter/material.dart';
import 'package:auction_app2/shared/models/auction_model.dart';
import '../../../core/constants/ds_colors.dart';
import '../../../core/widgets/ds_widgets.dart';
import 'admin_auction_card.dart';

class AdminAuctionList extends StatelessWidget {
  final Stream<List<AuctionModel>> stream;
  final void Function(AuctionModel) onApprove, onReject, onSetSchedule,
      onAdjustPrice, onActivate, onDeclareWinner, onDelete;

  const AdminAuctionList({
    super.key,
    required this.stream,
    required this.onApprove,
    required this.onReject,
    required this.onSetSchedule,
    required this.onAdjustPrice,
    required this.onActivate,
    required this.onDeclareWinner,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AuctionModel>>(
      stream: stream,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: DS.purple));
        }
        if (snap.hasError) {
          return Center(child: Text('خطأ: ${snap.error}', style: DS.body));
        }
        final list = snap.data ?? [];
        if (list.isEmpty) {
          return const DSEmpty(
              icon: Icons.inbox_rounded,
              title: 'لا توجد مزادات',
              subtitle: 'لا توجد مزادات في هذه الفئة');
        }
        return StaggeredListView(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          staggerMs: 55,
          itemBuilder: (_, i) => AdminAuctionCard(
            auction: list[i],
            onApprove: () => onApprove(list[i]),
            onReject: () => onReject(list[i]),
            onSetSchedule: () => onSetSchedule(list[i]),
            onAdjustPrice: () => onAdjustPrice(list[i]),
            onActivate: () => onActivate(list[i]),
            onDeclareWinner: () => onDeclareWinner(list[i]),
            onDelete: () => onDelete(list[i]),
          ),
        );
      },
    );
  }
}
