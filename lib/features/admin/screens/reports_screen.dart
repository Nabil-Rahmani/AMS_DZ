import 'package:flutter/material.dart';
import 'package:auction_app2/core/services/firebase/firestore_service.dart';
import '../../../core/constants/ds_colors.dart';
import '../../../core/widgets/ds_widgets.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final FirestoreService _db = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: DS.bg,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const FadeSlideIn(
                child: DSSection(title: 'التقارير والإحصائيات'),
              ),
              const SizedBox(height: 20),

              FutureBuilder<Map<String, dynamic>>(
                future: _db.getReportsStats(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(color: DS.purple),
                    ));
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('خطأ في تحميل البيانات: ${snapshot.error}', style: DS.body));
                  }

                  final stats = snapshot.data!;
                  return Column(
                    children: [
                      // Overview Row
                      GridView.count(
                        crossAxisCount: MediaQuery.of(context).size.width >= 600 ? 2 : 1,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 2.2,
                        children: [
                          _ReportCard(
                            title: 'إجمالي المبيعات',
                            value: '${stats['totalVolume'].toStringAsFixed(0)} DZD',
                            icon: Icons.payments_rounded,
                            color: DS.success,
                            subtitle: 'من ${stats['endedAuctionsCount']} مزاد مكتمل',
                          ),
                          _ReportCard(
                            title: 'مستخدمون جدد',
                            value: stats['newUsersLast30Days'].toString(),
                            icon: Icons.person_add_rounded,
                            color: DS.purple,
                            subtitle: 'خلال آخر 30 يوم',
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Detailed Stats
                      const DSSection(title: 'نشاط المزاد'),
                      const SizedBox(height: 12),
                      _ActivityItem(
                        label: 'إجمالي المزادات المنشأة',
                        value: stats['totalAuctions'].toString(),
                        percent: 1.0,
                        color: DS.info,
                      ),
                      _ActivityItem(
                        label: 'المزادات المكتملة',
                        value: stats['endedAuctionsCount'].toString(),
                        percent: stats['totalAuctions'] > 0 ? stats['endedAuctionsCount'] / stats['totalAuctions'] : 0,
                        color: DS.gold,
                      ),
                      
                      const SizedBox(height: 32),
                      const DSSection(title: 'النمو والإنتاجية'),
                      const SizedBox(height: 12),
                      GlassCard(
                        padding: const EdgeInsets.all(24),
                        borderRadius: 24,
                        backgroundColor: DS.bgCard,
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('معدل التحويل', style: DS.titleS),
                                    Text('المزادات التي انتهت بنجاح', style: DS.bodySmall),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: DS.success.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${stats['totalAuctions'] > 0 ? (stats['endedAuctionsCount'] / stats['totalAuctions'] * 100).toStringAsFixed(1) : 0}%',
                                    style: DS.label.copyWith(color: DS.success, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String title, value, subtitle;
  final IconData icon;
  final Color color;

  const _ReportCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      backgroundColor: color.withValues(alpha: 0.02),
      border: Border.all(color: color.withValues(alpha: 0.1)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: DS.label),
                const SizedBox(height: 4),
                Text(value, style: DS.titleL.copyWith(fontSize: 22)),
                const SizedBox(height: 2),
                Text(subtitle, style: DS.bodySmall.copyWith(fontSize: 10, color: DS.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final String label, value;
  final double percent;
  final Color color;

  const _ActivityItem({
    required this.label,
    required this.value,
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: DS.titleS.copyWith(fontSize: 14)),
              Text(value, style: DS.titleS.copyWith(color: color)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 8,
              backgroundColor: color.withValues(alpha: 0.1),
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
