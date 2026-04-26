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
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: DS.border.withValues(alpha: 0.5))),
          ),
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: NavigationBar(
                backgroundColor: DS.bgCard.withValues(alpha: 0.8),
                elevation: 0,
                selectedIndex: _selectedIndex,
                onDestinationSelected: (i) => setState(() => _selectedIndex = i),
                indicatorColor: DS.purple.withValues(alpha: 0.1),
                destinations: [
                  const NavigationDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard_rounded, color: DS.purple),
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
                          child: const Icon(Icons.notifications_outlined),
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
                          child: const Icon(Icons.notifications_rounded, color: DS.purple),
                        );
                      },
                    ),
                    label: 'الإشعارات',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.person_outline_rounded),
                    selectedIcon: Icon(Icons.person_rounded, color: DS.purple),
                    label: 'حسابي',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
