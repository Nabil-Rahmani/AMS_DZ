import 'package:flutter/material.dart';
import 'package:auction_app2/shared/models/user_model.dart';
import '../../../core/constants/ds_colors.dart';
import '../../../core/widgets/ds_widgets.dart';
import 'kyc_card_components.dart';

class KycOrganizerList extends StatelessWidget {
  final Stream<List<UserModel>> stream;
  final KycStatus filter;
  final void Function(UserModel) onTap;
  final void Function(UserModel) onApprove;
  final void Function(UserModel) onReject;

  const KycOrganizerList({
    super.key,
    required this.stream,
    required this.filter,
    required this.onTap,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserModel>>(
      stream: stream,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: DS.purple));
        }
        if (snap.hasError) {
          return Center(child: Text('خطأ: ${snap.error}', style: DS.body));
        }
        final users = snap.data ?? [];
        if (users.isEmpty) {
          return DSEmpty(
              icon: Icons.assignment_outlined,
              title: filter == KycStatus.pending
                  ? 'لا توجد طلبات بانتظار المراجعة'
                  : 'لا توجد سجلات',
              subtitle: 'هذا القسم فارغ حالياً');
        }
        return StaggeredListView(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          staggerMs: 60,
          itemBuilder: (_, i) => KycCard(
            user: users[i],
            onTap: () => onTap(users[i]),
            onApprove: () => onApprove(users[i]),
            onReject: () => onReject(users[i]),
          ),
        );
      },
    );
  }
}
