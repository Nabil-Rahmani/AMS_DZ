import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/ds_colors.dart';
import '../../../core/widgets/ds_widgets.dart';
import 'package:auction_app2/core/routes/app_routes.dart';

class InterestsScreen extends StatefulWidget {
  const InterestsScreen({super.key});
  @override
  State<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends State<InterestsScreen> {
  final Set<String> _selected = {};
  bool _loading = false;

  final List<Map<String, dynamic>> _interests = [
    {
      'label': 'عقارات',
      'icon': Icons.home_rounded,
      'color': const Color(0xFF0D9488)
    },
    {
      'label': 'سيارات',
      'icon': Icons.directions_car_rounded,
      'color': const Color(0xFF3B82F6)
    },
    {
      'label': 'إلكترونيات',
      'icon': Icons.devices_rounded,
      'color': const Color(0xFF8B5CF6)
    },
    {
      'label': 'أثاث',
      'icon': Icons.chair_rounded,
      'color': const Color(0xFFF59E0B)
    },
    {
      'label': 'مجوهرات',
      'icon': Icons.diamond_rounded,
      'color': const Color(0xFFEC4899)
    },
    {
      'label': 'معدات صناعية',
      'icon': Icons.precision_manufacturing_rounded,
      'color': const Color(0xFF6B7280)
    },
    {
      'label': 'فن وتحف',
      'icon': Icons.palette_rounded,
      'color': const Color(0xFFEF4444)
    },
    {
      'label': 'ملابس وأزياء',
      'icon': Icons.checkroom_rounded,
      'color': const Color(0xFF10B981)
    },
    {
      'label': 'كتب ومخطوطات',
      'icon': Icons.menu_book_rounded,
      'color': const Color(0xFFD97706)
    },
    {
      'label': 'أخرى',
      'icon': Icons.category_rounded,
      'color': const Color(0xFF9CA3AF)
    },
  ];

  Future<void> _save() async {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('اختر اهتماماً واحداً على الأقل'),
          backgroundColor: DS.error,
        ),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'interests': _selected.toList(),
        'interestsSetAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        // ✅ إصلاح — استخدم AppRoutes.browseAuctions بدل '/bidder'
        Navigator.pushReplacementNamed(context, AppRoutes.browseAuctions);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: DS.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: DS.bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              const SizedBox(height: 20),

              // ── Header ──
              FadeSlideIn(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: DS.purpleGradient,
                    shape: BoxShape.circle,
                    boxShadow: DS.purpleShadow,
                  ),
                  child: const Icon(Icons.interests_rounded,
                      color: Colors.white, size: 38),
                ),
              ),
              const SizedBox(height: 24),

              FadeSlideIn(
                delay: const Duration(milliseconds: 100),
                child: Text('ما الذي يهمك؟', style: DS.titleXL),
              ),
              const SizedBox(height: 8),

              FadeSlideIn(
                delay: const Duration(milliseconds: 150),
                child: Text(
                  'اختر الفئات التي تهمك لنعرض لك المزادات المناسبة',
                  style: DS.body.copyWith(color: DS.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),

              // ── Grid ──
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.6,
                  ),
                  itemCount: _interests.length,
                  itemBuilder: (_, i) {
                    final item = _interests[i];
                    final label = item['label'] as String;
                    final icon = item['icon'] as IconData;
                    final color = item['color'] as Color;
                    final selected = _selected.contains(label);

                    return FadeSlideIn(
                      delay: Duration(milliseconds: 100 + (i * 50)),
                      child: GestureDetector(
                        onTap: () => setState(() {
                          selected
                              ? _selected.remove(label)
                              : _selected.add(label);
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          decoration: BoxDecoration(
                            color: selected
                                ? color.withValues(alpha: 0.1)
                                : DS.bgCard,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: selected ? color : DS.border,
                              width: selected ? 2 : 1,
                            ),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.2),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    )
                                  ]
                                : DS.cardShadow,
                          ),
                          child: Stack(children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(icon,
                                      color: selected ? color : DS.textMuted,
                                      size: 28),
                                  const SizedBox(height: 8),
                                  Text(label,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: selected
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        color:
                                            selected ? color : DS.textSecondary,
                                      )),
                                ],
                              ),
                            ),
                            if (selected)
                              Positioned(
                                top: 10,
                                left: 10,
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check_rounded,
                                      color: Colors.white, size: 13),
                                ),
                              ),
                          ]),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // ── Counter + Button ──
              FadeSlideIn(
                delay: const Duration(milliseconds: 600),
                child: Column(children: [
                  if (_selected.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'تم اختيار ${_selected.length} فئة',
                        style: DS.label.copyWith(color: DS.purple),
                      ),
                    ),
                  GradientButton(
                    label: _loading ? 'جاري الحفظ...' : 'متابعة',
                    icon: Icons.arrow_back_rounded,
                    height: 56,
                    isLoading: _loading,
                    onPressed: _save,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    // ✅ إصلاح — استخدم AppRoutes.browseAuctions بدل '/bidder'
                    onPressed: () => Navigator.pushReplacementNamed(
                      context,
                      AppRoutes.browseAuctions,
                    ),
                    child: Text('تخطي',
                        style: DS.body.copyWith(color: DS.textMuted)),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
