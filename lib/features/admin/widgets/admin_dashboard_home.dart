import 'package:flutter/material.dart';
import 'package:auction_app2/core/services/firebase/firestore_service.dart';
import '../../../core/constants/ds_colors.dart';
import '../../../core/widgets/ds_widgets.dart';

class AdminDashboardHome extends StatelessWidget {
  final FirestoreService? db;
  final Function(int) onActionTap;

  const AdminDashboardHome({
    super.key,
    this.db,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        FadeSlideIn(
          child: GlassCard(
            padding: const EdgeInsets.all(28),
            borderRadius: 32,
            backgroundColor: DS.purple.withValues(alpha: 0.05),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: DS.purple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('النظام متصل', style: DS.label.copyWith(color: DS.purple, fontSize: 10)),
                  ),
                ]),
                const SizedBox(height: 12),
                Text('مرحباً، المدير 👋',
                    style: DS.displayLarge.copyWith(fontSize: 32)),
                const SizedBox(height: 6),
                Text('إليك ملخص شامل لنشاط المنصة اليوم والمهمات المعلقة.',
                    style: DS.body.copyWith(color: DS.textSecondary)),
              ])),
              const SizedBox(width: 20),
              Container(
                width: 70, height: 70,
                decoration: BoxDecoration(
                  gradient: DS.purpleGradient,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: DS.purpleShadow,
                ),
                child: const Icon(Icons.admin_panel_settings_rounded,
                    color: Colors.white, size: 32),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 28),

        FadeSlideIn(delay: const Duration(milliseconds: 100),
          child: const DSSection(title: 'إحصائيات المنصة')),
        const SizedBox(height: 14),

        FadeSlideIn(
          delay: const Duration(milliseconds: 180),
          child: FutureBuilder<Map<String, int>>(
            future: db?.getDashboardStats(),
            builder: (ctx, snap) {
              final stats = snap.data ?? {
                'totalUsers': 0, 'pendingKyc': 0,
                'activeAuctions': 0, 'pendingAuctions': 0,
              };
              final loading = snap.connectionState == ConnectionState.waiting;
              return GridView.count(
                crossAxisCount: MediaQuery.of(context).size.width >= 600 ? 4 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
                children: [
                  DSStatCard(
                    icon: Icons.people_rounded, label: 'المستخدمون',
                    value: stats['totalUsers'].toString(), color: DS.purple, loading: loading),
                  DSStatCard(
                    icon: Icons.assignment_ind_rounded, label: 'طلبات KYC',
                    value: stats['pendingKyc'].toString(), color: DS.warning, loading: loading),
                  DSStatCard(
                    icon: Icons.gavel_rounded, label: 'مزادات نشطة',
                    value: stats['activeAuctions'].toString(), color: DS.success, loading: loading),
                  DSStatCard(
                    icon: Icons.pending_actions_rounded, label: 'بانتظار موافقة',
                    value: stats['pendingAuctions'].toString(), color: DS.gold, loading: loading),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 28),

        FadeSlideIn(delay: const Duration(milliseconds: 260),
          child: const DSSection(title: 'إجراءات سريعة')),
        const SizedBox(height: 14),

        ...[
          (
            icon: Icons.manage_accounts_rounded,
            title: 'إدارة المستخدمين',
            subtitle: 'إضافة، تفعيل أو تعطيل المستخدمين',
            color: DS.purple,
            index: 1,
          ),
          (
            icon: Icons.gavel_rounded,
            title: 'إدارة المزادات',
            subtitle: 'الموافقة أو رفض وجدولة المزادات',
            color: DS.gold,
            index: 2,
          ),
          (
            icon: Icons.verified_user_rounded,
            title: 'التحقق من الهوية KYC',
            subtitle: 'مراجعة وثائق الهوية للمنظمين',
            color: DS.success,
            index: 3,
          ),
          (
            icon: Icons.bar_chart_rounded,
            title: 'التقارير',
            subtitle: 'عرض إحصائيات وأداء المنصة',
            color: DS.info,
            index: 4,
          ),
        ].asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return FadeSlideIn(
            delay: Duration(milliseconds: 300 + i * 70),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: QuickActionTile(
                icon: item.icon,
                title: item.title,
                subtitle: item.subtitle,
                color: item.color,
                onTap: () => onActionTap(item.index),
              ),
            ),
          );
        }),
      ]),
    );
  }
}

class QuickActionTile extends StatefulWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final VoidCallback? onTap;
  const QuickActionTile({
    super.key,
    required this.icon, required this.title,
    required this.subtitle, required this.color, this.onTap,
  });

  @override
  State<QuickActionTile> createState() => _QuickActionTileState();
}

class _QuickActionTileState extends State<QuickActionTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 90));
    _scale = Tween(begin: 1.0, end: 0.97).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onTap?.call(); },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: GlassCard(
          padding: const EdgeInsets.all(20),
          borderRadius: 24,
          backgroundColor: widget.color.withValues(alpha: 0.03),
          border: Border.all(color: widget.color.withValues(alpha: 0.2)),
          child: Row(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(widget.icon, color: widget.color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.title, style: DS.titleS.copyWith(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(widget.subtitle, style: DS.bodySmall.copyWith(color: DS.textMuted)),
            ])),
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.arrow_back_ios_rounded, size: 14, color: widget.color),
            ),
          ]),
        ),
      ),
    );
  }
}
