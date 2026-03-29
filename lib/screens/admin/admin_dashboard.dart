import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/services/firestore_service.dart';
import 'manage_users_screen.dart';
import 'manage_auctions_screen.dart';
import 'verify_kyc_screen.dart';
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirestoreService _db = FirestoreService();
  int _selectedIndex = 0;

  final List<_NavItem> _navItems = [
    _NavItem(icon: Icons.dashboard, label: 'لوحة التحكم'),
    _NavItem(icon: Icons.people, label: 'المستخدمون'),
    _NavItem(icon: Icons.gavel, label: 'المزادات'),
    _NavItem(icon: Icons.verified_user, label: 'التحقق KYC'),
  ];

  // ── Build current page ─────────────────────────────────────────────────────

  Widget _buildPage() {
    switch (_selectedIndex) {
      case 0:
        return _DashboardHome(db: _db);
      case 1:
        return const ManageUsersScreen();
      case 2:
        return const ManageAuctionsScreen();
      case 3:
        return const VerifyKycScreen();
      default:
        return const _DashboardHome(db: null);
    }
  }

  String get _pageTitle => _navItems[_selectedIndex].label;

  // ── Logout ─────────────────────────────────────────────────────────────────

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('خروج',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_pageTitle,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF1565C0),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              tooltip: 'تسجيل الخروج',
              onPressed: _logout,
            ),
          ],
        ),

        // Drawer للشاشات الصغيرة
        drawer: isWide ? null : _buildDrawer(),

        body: isWide
            ? Row(
          children: [
            _buildSidebar(),
            const VerticalDivider(width: 1),
            Expanded(child: _buildPage()),
          ],
        )
            : _buildPage(),

        // Bottom nav للموبايل
        bottomNavigationBar: isWide
            ? null
            : NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (i) =>
              setState(() => _selectedIndex = i),
          backgroundColor: Colors.white,
          indicatorColor:
          const Color(0xFF1565C0).withOpacity(0.15),
          destinations: _navItems
              .map((item) => NavigationDestination(
            icon: Icon(item.icon),
            label: item.label,
          ))
              .toList(),
        ),
      ),
    );
  }

  // ── Sidebar (tablet/desktop) ───────────────────────────────────────────────

  Widget _buildSidebar() {
    return Container(
      width: 220,
      color: const Color(0xFF0D47A1),
      child: Column(
        children: [
          // Logo area
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
            color: const Color(0xFF1565C0),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.gavel, color: Colors.white, size: 32),
                SizedBox(height: 8),
                Text('AMS-DZ',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                Text('لوحة المدير',
                    style:
                    TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Nav items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _navItems.length,
              itemBuilder: (_, i) {
                final selected = _selectedIndex == i;
                return _SidebarTile(
                  item: _navItems[i],
                  selected: selected,
                  onTap: () => setState(() => _selectedIndex = i),
                );
              },
            ),
          ),

          // Logout
          Padding(
            padding: const EdgeInsets.all(12),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.white60),
              title: const Text('تسجيل الخروج',
                  style: TextStyle(color: Colors.white60)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              onTap: _logout,
            ),
          ),
        ],
      ),
    );
  }

  // ── Drawer (mobile) ────────────────────────────────────────────────────────

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: const Color(0xFF0D47A1),
        child: Column(
          children: [
            DrawerHeader(
              decoration:
              const BoxDecoration(color: Color(0xFF1565C0)),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.gavel, color: Colors.white, size: 36),
                  SizedBox(height: 8),
                  Text('AMS-DZ',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  Text('لوحة المدير',
                      style: TextStyle(
                          color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: _navItems.length,
                itemBuilder: (_, i) => _SidebarTile(
                  item: _navItems[i],
                  selected: _selectedIndex == i,
                  onTap: () {
                    setState(() => _selectedIndex = i);
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
            ListTile(
              leading:
              const Icon(Icons.logout, color: Colors.white60),
              title: const Text('تسجيل الخروج',
                  style: TextStyle(color: Colors.white60)),
              onTap: () {
                Navigator.pop(context);
                _logout();
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Dashboard Home (الصفحة الرئيسية مع الإحصائيات)
// ══════════════════════════════════════════════════════════════════════════════

class _DashboardHome extends StatelessWidget {
  final FirestoreService? db;
  const _DashboardHome({this.db});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('مرحباً بك، المدير 👋',
              style:
              TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('إليك ملخص النشاط الحالي',
              style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          const SizedBox(height: 20),

          // Stats cards
          FutureBuilder<Map<String, int>>(
            future: db?.getDashboardStats(),
            builder: (ctx, snap) {
              final stats = snap.data ??
                  {
                    'totalUsers': 0,
                    'pendingKyc': 0,
                    'activeAuctions': 0,
                    'pendingAuctions': 0,
                  };
              return GridView.count(
                crossAxisCount:
                MediaQuery.of(context).size.width >= 600 ? 4 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: [
                  _StatCard(
                    icon: Icons.people,
                    label: 'المستخدمون',
                    value: stats['totalUsers'].toString(),
                    color: const Color(0xFF1565C0),
                    loading: snap.connectionState ==
                        ConnectionState.waiting,
                  ),
                  _StatCard(
                    icon: Icons.assignment_ind,
                    label: 'طلبات KYC',
                    value: stats['pendingKyc'].toString(),
                    color: Colors.orange,
                    loading: snap.connectionState ==
                        ConnectionState.waiting,
                  ),
                  _StatCard(
                    icon: Icons.gavel,
                    label: 'مزادات نشطة',
                    value: stats['activeAuctions'].toString(),
                    color: Colors.green,
                    loading: snap.connectionState ==
                        ConnectionState.waiting,
                  ),
                  _StatCard(
                    icon: Icons.pending_actions,
                    label: 'بانتظار الموافقة',
                    value: stats['pendingAuctions'].toString(),
                    color: Colors.purple,
                    loading: snap.connectionState ==
                        ConnectionState.waiting,
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          // Quick actions
          const Text('إجراءات سريعة',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _QuickActions(
            onUsersTab: () {
              final state = context
                  .findAncestorStateOfType<_AdminDashboardState>();
              state?.setState(() => state._selectedIndex = 1);
            },
            onAuctionsTab: () {
              final state = context
                  .findAncestorStateOfType<_AdminDashboardState>();
              state?.setState(() => state._selectedIndex = 2);
            },
            onKycTab: () {
              final state = context
                  .findAncestorStateOfType<_AdminDashboardState>();
              state?.setState(() => state._selectedIndex = 3);
            },
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// WIDGETS
// ══════════════════════════════════════════════════════════════════════════════

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class _SidebarTile extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: selected
            ? Colors.white.withOpacity(0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(item.icon,
            color: selected ? Colors.white : Colors.white60),
        title: Text(
          item.label,
          style: TextStyle(
              color: selected ? Colors.white : Colors.white60,
              fontWeight: selected
                  ? FontWeight.bold
                  : FontWeight.normal),
        ),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        onTap: onTap,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool loading;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              loading
                  ? Container(
                width: 40,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
              )
                  : Text(value,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color)),
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final VoidCallback onUsersTab;
  final VoidCallback onAuctionsTab;
  final VoidCallback onKycTab;

  const _QuickActions({
    required this.onUsersTab,
    required this.onAuctionsTab,
    required this.onKycTab,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ActionTile(
          icon: Icons.person_add,
          title: 'إدارة المستخدمين',
          subtitle: 'إضافة، تفعيل أو تعطيل المستخدمين',
          color: const Color(0xFF1565C0),
          onTap: onUsersTab,
        ),
        const SizedBox(height: 10),
        _ActionTile(
          icon: Icons.gavel,
          title: 'إدارة المزادات',
          subtitle: 'الموافقة أو رفض المزادات المقدمة',
          color: Colors.green,
          onTap: onAuctionsTab,
        ),
        const SizedBox(height: 10),
        _ActionTile(
          icon: Icons.verified_user,
          title: 'التحقق من الهوية (KYC)',
          subtitle: 'مراجعة طلبات توثيق المنظمين',
          color: Colors.orange,
          onTap: onKycTab,
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 1.5,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                    Text(subtitle,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 14, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
