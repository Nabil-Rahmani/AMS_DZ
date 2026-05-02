import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:auction_app2/core/services/notification_service.dart';
import '../../../core/constants/ds_colors.dart';
import '../../auth/screens/profile_page.dart';
import '../../notifications/notifications_screen.dart';
import 'organizer_dashboard_home.dart';

class OrganizerDashboard extends StatefulWidget {
  const OrganizerDashboard({super.key});
  @override
  State<OrganizerDashboard> createState() => _OrganizerDashboardState();
}

class _OrganizerDashboardState extends State<OrganizerDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const OrganizerDashboardHome(),
    const NotificationsScreen(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: DS.bg,
        body: IndexedStack(index: _selectedIndex, children: _pages),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            // ✅ أخضر زيتوني = DS.purple (0xFF0D9488)
            color: DS.purple,
            border: Border(
              top: BorderSide(color: Color(0xFF0F766E), width: 1),
            ),
          ),
          child: NavigationBar(
            // ✅ أخضر زيتوني بدون شفافية
            backgroundColor: DS.purple,
            elevation: 0,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (i) => setState(() => _selectedIndex = i),
            // ✅ مؤشر الاختيار أبيض شفاف
            indicatorColor: Colors.white.withValues(alpha: 0.15),
            indicatorShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              NavigationDestination(
                icon: Icon(
                  Icons.dashboard_outlined,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
                // ✅ أيقونة محددة بيضاء
                selectedIcon: const Icon(
                  Icons.dashboard_rounded,
                  color: Colors.white,
                ),
                label: 'الرئيسية',
              ),
              // ✅ تبويب الإشعارات مع Badge
              NavigationDestination(
                icon: StreamBuilder<int>(
                  stream: NotificationService.streamUnreadCount(uid),
                  builder: (_, snap) {
                    final count = snap.data ?? 0;
                    return Badge(
                      isLabelVisible: count > 0,
                      label: Text('$count'),
                      backgroundColor: DS.error,
                      child: Icon(
                        Icons.notifications_outlined,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
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
                      child: const Icon(
                        Icons.notifications_rounded,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
                label: 'الإشعارات',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.person_outline_rounded,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
                selectedIcon: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                ),
                label: 'حسابي',
              ),
            ],
          ),
        ),
      ),
    );
  }
}