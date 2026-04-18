 import 'package:flutter/material.dart';
 import 'package:flutter/widgets.dart';
 import '../../../core/services/firebase/firestore_service.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../shared/models/wallet_model.dart';
import 'package:auction_app2/core/constants/ds_colors.dart';

class AdminWalletRequestsScreen extends StatelessWidget {
  const AdminWalletRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = FirestoreService();
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      backgroundColor: DS.bg,
      body: Column(children: [
        Container(height: 140, decoration: const BoxDecoration(gradient: DS.headerGradient),
            child: SafeArea(bottom: false, child: Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 0), child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: DS.purple.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: DS.purple.withValues(alpha: 0.2))), child: const Icon(Icons.account_balance_rounded, color: DS.purple, size: 22)),
              const SizedBox(width: 14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('طلبات الشحن', style: DS.titleL.copyWith(fontSize: 22)), Text('المعلقة بانتظار الموافقة', style: DS.bodySmall)]),
            ])))),
        Expanded(child: StreamBuilder<List<WalletTransaction>>(
          stream: db.streamPendingDeposits(),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: DS.purple));
            final list = snap.data ?? [];
            if (list.isEmpty) return const DSEmpty(icon: Icons.inbox_rounded, title: 'لا توجد طلبات معلقة', subtitle: 'كل الطلبات تمت معالجتها');
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _DepositRequestCard(tx: list[i], db: db),
            );
          },
        )),
      ]),
    ));
  }
}

class _DepositRequestCard extends StatelessWidget {
  final WalletTransaction tx; final FirestoreService db;
  const _DepositRequestCard({required this.tx, required this.db});

  void _snack(BuildContext ctx, String msg, {bool isError = false}) =>
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(msg), backgroundColor: isError ? DS.error : DS.success));

  @override
  Widget build(BuildContext context) {
    final methodLabels = {DepositMethod.ccp: 'CCP', DepositMethod.baridiMob: 'بريدي موب', DepositMethod.card: 'بطاقة بنكية'};
    return GlassCard(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: DS.purple.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.account_balance_wallet_rounded, color: DS.purple, size: 18)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('طلب شحن — ${methodLabels[tx.method] ?? tx.method.name}', style: DS.label),
          Text('المستخدم: ${tx.userId}', style: DS.bodySmall, overflow: TextOverflow.ellipsis),
        ])),
        Text('${tx.amount.toStringAsFixed(0)} دج', style: DS.titleM.copyWith(color: DS.success)),
      ]),
      if (tx.proofUrl != null) ...[
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => showDialog(context: context, builder: (_) => Dialog(child: Image.network(tx.proofUrl!))),
          child: Container(height: 120, width: double.infinity, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), image: DecorationImage(image: NetworkImage(tx.proofUrl!), fit: BoxFit.cover))),
        ),
      ],
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: OutlinedButton.icon(
          icon: const Icon(Icons.close_rounded, size: 18),
          label: const Text('رفض'),
          style: OutlinedButton.styleFrom(foregroundColor: DS.error, side: const BorderSide(color: DS.error), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          onPressed: () async { await db.rejectDeposit(tx.id); _snack(context, 'تم رفض الطلب'); },
        )),
        const SizedBox(width: 12),
        Expanded(child: GradientButton(
          label: 'موافقة',
          icon: Icons.check_rounded,
          onPressed: () async { await db.approveDeposit(tx.id, tx.userId, tx.amount); _snack(context, 'تمت الموافقة ✅'); },
        )),
      ]),
    ]));
  }
}