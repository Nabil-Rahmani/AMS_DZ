import 'package:flutter/material.dart';
import '../../../core/services/firebase/firestore_service.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../shared/models/wallet_model.dart';
import 'package:auction_app2/core/constants/ds_colors.dart';

class AdminWalletRequestsScreen extends StatelessWidget {
  const AdminWalletRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = FirestoreService();
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: DS.bg,
        body: Column(children: [
          Container(
            height: 140,
            decoration: const BoxDecoration(gradient: DS.headerGradient),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: DS.purple.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: DS.purple.withValues(alpha: 0.2)),
                        ),
                        child: const Icon(Icons.account_balance_rounded,
                            color: DS.purple, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('طلبات الشحن',
                                style: DS.titleL.copyWith(fontSize: 22)),
                            Text('المعلقة بانتظار الموافقة',
                                style: DS.bodySmall),
                          ]),
                    ]),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<WalletTransaction>>(
              stream: db.streamPendingDeposits(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: DS.purple));
                }
                final list = snap.data ?? [];
                if (list.isEmpty) {
                  return const DSEmpty(
                    icon: Icons.inbox_rounded,
                    title: 'لا توجد طلبات معلقة',
                    subtitle: 'كل الطلبات تمت معالجتها',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) =>
                      _DepositRequestCard(tx: list[i], db: db),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

class _DepositRequestCard extends StatefulWidget {
  final WalletTransaction tx;
  final FirestoreService db;
  const _DepositRequestCard({required this.tx, required this.db});

  @override
  State<_DepositRequestCard> createState() => _DepositRequestCardState();
}

class _DepositRequestCardState extends State<_DepositRequestCard> {
  bool _loading = false;

  static const _methodLabels = {
    DepositMethod.ccp: 'CCP',
    DepositMethod.baridiMob: 'بريدي موب',
    DepositMethod.card: 'بطاقة بنكية',
    DepositMethod.rechargeCode: 'كود شحن',
  };

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? DS.error : DS.success,
    ));
  }

  Future<void> _reject() async {
    setState(() => _loading = true);
    try {
      // ✅ نمرر tx.userId و tx.amount باش يوصل إشعار للمستخدم
      await widget.db
          .rejectDeposit(widget.tx.id, widget.tx.userId, widget.tx.amount);
      _snack('تم رفض الطلب');
    } catch (e) {
      _snack('خطأ: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _approve() async {
    setState(() => _loading = true);
    try {
      await widget.db
          .approveDeposit(widget.tx.id, widget.tx.userId, widget.tx.amount);
      _snack('تمت الموافقة ✅');
    } catch (e) {
      _snack('خطأ: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header ──
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: DS.purple.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.account_balance_wallet_rounded,
                color: DS.purple, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(
                  'طلب شحن — ${_methodLabels[widget.tx.method] ?? widget.tx.method.name}',
                  style: DS.label,
                ),
                Text(
                  'المستخدم: ${widget.tx.userId}',
                  style: DS.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ])),
          Text(
            '${widget.tx.amount.toStringAsFixed(0)} دج',
            style: DS.titleM.copyWith(color: DS.success),
          ),
        ]),

        // ── صورة الوصل ──
        if (widget.tx.proofUrl != null) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => showDialog(
              context: context,
              builder: (_) => Dialog(child: Image.network(widget.tx.proofUrl!)),
            ),
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: NetworkImage(widget.tx.proofUrl!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],

        const SizedBox(height: 16),

        // ── Buttons ──
        Row(children: [
          Expanded(
              child: OutlinedButton.icon(
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('رفض'),
            style: OutlinedButton.styleFrom(
              foregroundColor: DS.error,
              side: const BorderSide(color: DS.error),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _loading ? null : _reject, // ✅ بلا async gap
          )),
          const SizedBox(width: 12),
          Expanded(
              child: GradientButton(
            label: 'موافقة',
            icon: Icons.check_rounded,
            isLoading: _loading,
            onPressed: _loading ? null : _approve, // ✅ بلا async gap
          )),
        ]),
      ]),
    );
  }
}
