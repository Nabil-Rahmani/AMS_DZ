import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:auction_app2/core/services/firebase/firestore_service.dart';
import 'package:auction_app2/core/services/notification_service.dart';
import 'package:auction_app2/core/services/firebase_messaging_service.dart';
import '../../../core/constants/ds_colors.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../widgets/admin_dashboard_home.dart';
import '../../notifications/notifications_screen.dart';
import 'manage_users_screen.dart';
import 'manage_auctions_screen.dart';
import 'verify_kyc_screen.dart';
import 'reports_screen.dart';
import 'admin_wallet_requests_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  final FirestoreService _db = FirestoreService();
  int _selectedIndex = 0;
  late AnimationController _animCtrl;

  final List<({IconData icon, String label, Color color})> _nav = [
    (icon: Icons.dashboard_rounded, label: 'الرئيسية', color: DS.purple),
    (icon: Icons.notifications_rounded, label: 'الإشعارات', color: DS.warning),
    (icon: Icons.people_rounded, label: 'المستخدمون', color: DS.info),
    (icon: Icons.gavel_rounded, label: 'المزادات', color: DS.gold),
    (icon: Icons.verified_user_rounded, label: 'KYC', color: DS.success),
    (icon: Icons.account_balance_rounded, label: 'الشحن', color: DS.primary),
    (icon: Icons.bar_chart_rounded, label: 'التقارير', color: DS.info),
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Widget _buildPage() {
    switch (_selectedIndex) {
      case 0:
        return AdminDashboardHome(
            db: _db, onActionTap: (i) => setState(() => _selectedIndex = i));
      case 1:
        return const NotificationsScreen();
      case 2:
        return const ManageUsersScreen();
      case 3:
        return const ManageAuctionsScreen();
      case 4:
        return const VerifyKycScreen();
      case 5:
        return const AdminWalletRequestsScreen();
      case 6:
        return const ReportsScreen();
      default:
        return AdminDashboardHome(
            db: _db, onActionTap: (i) => setState(() => _selectedIndex = i));
    }
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: DS.bgModal.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: DS.border),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: DS.errorSurface,
                    border: Border.all(color: DS.error.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.logout_rounded,
                      color: DS.error, size: 28),
                ),
                const SizedBox(height: 18),
                Text('تسجيل الخروج؟', style: DS.titleM),
                const SizedBox(height: 8),
                Text('هل أنت متأكد من الخروج؟',
                    style: DS.body, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                Row(children: [
                  Expanded(
                      child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('إلغاء'),
                  )),
                  const SizedBox(width: 12),
                  Expanded(
                      child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: DS.error),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('خروج'),
                  )),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
    if (ok != true) return;
    await FirebaseMessagingService.onLogout();
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isWide = MediaQuery.of(context).size.width >= 800;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: DS.bg,
        appBar: isWide
            ? null
            : DarkAppBar(
                showLogo: true,
                actions: [
                  IconButton(
                    icon: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.logout_rounded,
                          size: 18, color: Color(0xFFEF4444)),
                    ),
                    onPressed: _logout,
                  ),
                  const SizedBox(width: 8),
                ],
              ),
        body: isWide
            ? Row(children: [_buildSidebar(uid), Expanded(child: _buildPage())])
            : _buildPage(),
        bottomNavigationBar: isWide
            ? null
            : Container(
                decoration: const BoxDecoration(
                  color: DS.purple,
                  border: Border(top: BorderSide(color: DS.purple)),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    navigationBarTheme: NavigationBarThemeData(
                      backgroundColor: DS.purple,
                      surfaceTintColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      indicatorColor: Colors.white.withValues(alpha: 0.2),
                      elevation: 0,
                      labelTextStyle: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700);
                        }
                        return TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 11);
                      }),
                      iconTheme: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return const IconThemeData(color: Colors.white);
                        }
                        return IconThemeData(
                            color: Colors.white.withValues(alpha: 0.6));
                      }),
                    ),
                  ),
                  child: NavigationBar(
                    backgroundColor: DS.purple,
                    surfaceTintColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: (i) =>
                        setState(() => _selectedIndex = i),
                    indicatorColor: Colors.white.withValues(alpha: 0.2),
                    destinations: _nav.asMap().entries.map((e) {
                      if (e.key == 1) {
                        return NavigationDestination(
                          icon: StreamBuilder<int>(
                            stream: NotificationService.streamUnreadCount(uid),
                            builder: (_, snap) {
                              final count = snap.data ?? 0;
                              return Badge(
                                isLabelVisible: count > 0,
                                label: Text('$count'),
                                backgroundColor: DS.error,
                                child:
                                    Icon(e.value.icon, color: Colors.white60),
                              );
                            },
                          ),
                          selectedIcon: StreamBuilder<int>(
                            stream: NotificationService.streamUnreadCount(uid),
                            builder: (_, snap) {
                              final count = snap.data ?? 0;
                              return Badge(
                                isLabelVisible: count > 0,
                                label: Text('$count'),
                                backgroundColor: DS.error,
                                child: Icon(e.value.icon, color: Colors.white),
                              );
                            },
                          ),
                          label: e.value.label,
                        );
                      }
                      return NavigationDestination(
                        icon: Icon(e.value.icon, color: Colors.white60),
                        selectedIcon: Icon(e.value.icon, color: Colors.white),
                        label: e.value.label,
                      );
                    }).toList(),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSidebar(String uid) {
    return GlassCard(
      borderRadius: 0,
      padding: EdgeInsets.zero,
      sigmaX: 30,
      sigmaY: 30,
      backgroundColor: DS.bgCard.withValues(alpha: 0.5),
      border: const Border(left: BorderSide(color: DS.border)),
      child: SizedBox(
          width: 260,
          child: Column(children: [
            Container(
              height: 180,
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: DS.border))),
              child: Stack(children: [
                const Positioned(
                    top: -40,
                    left: -40,
                    child: PurpleOrb(size: 150, opacity: 0.2)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AmsLogo(size: 42),
                        const SizedBox(height: 18),
                        Text('لوحة التحكم', style: DS.titleM),
                        const SizedBox(height: 4),
                        Text('الإدارة العامة للنظام',
                            style: DS.bodySmall.copyWith(color: DS.textMuted)),
                      ]),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            Expanded(
                child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: _nav.asMap().entries.map((e) {
                final sel = e.key == _selectedIndex;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedIndex = e.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: sel ? DS.purpleGradient : null,
                        color: sel ? null : DS.purple.withValues(alpha: 0.03),
                        boxShadow: sel ? DS.purpleShadow : [],
                        border: Border.all(
                            color: sel
                                ? Colors.transparent
                                : DS.border.withValues(alpha: 0.3)),
                      ),
                      child: Row(children: [
                        e.key == 1
                            ? StreamBuilder<int>(
                                stream:
                                    NotificationService.streamUnreadCount(uid),
                                builder: (_, snap) {
                                  final count = snap.data ?? 0;
                                  return Badge(
                                    isLabelVisible: count > 0,
                                    label: Text('$count'),
                                    backgroundColor: DS.error,
                                    child: Icon(e.value.icon,
                                        size: 22,
                                        color: sel
                                            ? Colors.white
                                            : DS.textSecondary),
                                  );
                                },
                              )
                            : Icon(e.value.icon,
                                size: 22,
                                color: sel ? Colors.white : DS.textSecondary),
                        const SizedBox(width: 14),
                        Text(e.value.label,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight:
                                  sel ? FontWeight.w700 : FontWeight.w500,
                              color: sel ? Colors.white : DS.textPrimary,
                            )),
                        const Spacer(),
                        if (sel)
                          const Icon(Icons.chevron_left_rounded,
                              color: Colors.white, size: 18),
                      ]),
                    ),
                  ),
                );
              }).toList(),
            )),
            Padding(
              padding: const EdgeInsets.all(20),
              child: GestureDetector(
                onTap: _logout,
                child: GlassCard(
                  padding: const EdgeInsets.all(16),
                  borderRadius: 16,
                  backgroundColor: const Color(0xFFFEF2F2),
                  border: Border.all(color: const Color(0xFFFECACA)),
                  child: Row(children: [
                    const Icon(Icons.logout_rounded,
                        size: 20, color: Color(0xFFEF4444)),
                    const SizedBox(width: 12),
                    Text('تسجيل الخروج',
                        style: DS.body.copyWith(
                            color: const Color(0xFFEF4444),
                            fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
            ),
          ])),
    );
  }
}
