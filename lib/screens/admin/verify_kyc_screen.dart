import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';
import '../../data/services/firestore_service.dart';

class VerifyKycScreen extends StatefulWidget {
  const VerifyKycScreen({super.key});

  @override
  State<VerifyKycScreen> createState() => _VerifyKycScreenState();
}

class _VerifyKycScreenState extends State<VerifyKycScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _db = FirestoreService();
  late TabController _tabController;

  final List<Map<String, String>> _tabs = [
    {'label': 'بانتظار المراجعة', 'filter': 'pending'},
    {'label': 'معتمدون', 'filter': 'approved'},
    {'label': 'مرفوضون', 'filter': 'rejected'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Streams ────────────────────────────────────────────────────────────────

  Stream<List<UserModel>> _organizersStream(String kycStatus) {
    return _db.streamAllOrganizers().map(
          (list) => list.where((u) {
        if (kycStatus == 'pending') {
          return u.kycStatus == 'pending' || u.kycStatus == null;
        }
        return u.kycStatus == kycStatus;
      }).toList(),
    );
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _approve(UserModel user) async {
    final confirm = await _showConfirm(
      title: 'قبول طلب KYC',
      content: 'هل تريد قبول توثيق "${user.name}"؟',
      confirmText: 'قبول',
      confirmColor: Colors.green,
    );
    if (!confirm) return;
    try {
      await _db.approveKyc(user.id);
      _showSnack('✅ تم قبول طلب التوثيق');
    } catch (e) {
      _showSnack('❌ خطأ: $e', isError: true);
    }
  }

  Future<void> _reject(UserModel user) async {
    final reasonCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('رفض طلب KYC'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('المنظم: ${user.name}'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'سبب الرفض',
                border: OutlineInputBorder(),
                hintText: 'اكتب سبب الرفض هنا...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child:
            const Text('رفض', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _db.rejectKyc(user.id,
          reason: reasonCtrl.text.trim().isEmpty
              ? 'لم يُذكر سبب'
              : reasonCtrl.text.trim());
      _showSnack('🚫 تم رفض طلب التوثيق');
    } catch (e) {
      _showSnack('❌ خطأ: $e', isError: true);
    }
  }

  void _showOrganizerDetails(UserModel user) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name,
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.bold)),
                        Text(user.email,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close)),
                ],
              ),
              const Divider(height: 24),

              _KycStatusBadge(status: user.kycStatus?.name),
              const SizedBox(height: 16),

              _DetailRow(
                  icon: Icons.email,
                  label: 'البريد الإلكتروني',
                  value: user.email),
              _DetailRow(
                  icon: Icons.phone,
                  label: 'رقم الهاتف',
                  value: user.phone ?? 'غير محدد'),
              _DetailRow(
                  icon: Icons.location_on,
                  label: 'العنوان',
                  value: user.address ?? 'غير محدد'),
              _DetailRow(
                  icon: Icons.calendar_today,
                  label: 'تاريخ التسجيل',
                  value: user.createdAt != null
                      ? '${user.createdAt!.day}/${user.createdAt!.month}/${user.createdAt!.year}'
                      : 'غير محدد'),
              if (user.kycStatus == 'rejected' &&
                  user.kycRejectionReason != null)
                _DetailRow(
                    icon: Icons.info_outline,
                    label: 'سبب الرفض',
                    value: user.kycRejectionReason!),

              // KYC Documents section
              if (user.kycDocuments != null &&
                  user.kycDocuments!.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('وثائق KYC',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 8),
                ...user.kycDocuments!.entries.map(
                      (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.attach_file,
                            size: 16, color: Colors.blue),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(e.key,
                              style: const TextStyle(fontSize: 13)),
                        ),
                        TextButton(
                          onPressed: () {/* open document URL */},
                          child: const Text('عرض'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Actions
              if (user.kycStatus == 'pending' || user.kycStatus == null)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.close, color: Colors.red),
                        label: const Text('رفض',
                            style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red)),
                        onPressed: () {
                          Navigator.pop(context);
                          _reject(user);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: const Text('قبول',
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green),
                        onPressed: () {
                          Navigator.pop(context);
                          _approve(user);
                        },
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<bool> _showConfirm({
    required String title,
    required String content,
    required String confirmText,
    required Color confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmText,
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
    ));
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('التحقق من هوية المنظمين',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF1565C0),
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: _tabs
                .map((t) => Tab(text: t['label']!))
                .toList(),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: _tabs.map((t) {
            return _OrganizerListView(
              stream: _organizersStream(t['filter']!),
              filter: t['filter']!,
              onTap: _showOrganizerDetails,
              onApprove: _approve,
              onReject: _reject,
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// WIDGETS
// ══════════════════════════════════════════════════════════════════════════════

class _OrganizerListView extends StatelessWidget {
  final Stream<List<UserModel>> stream;
  final String filter;
  final void Function(UserModel) onTap;
  final void Function(UserModel) onApprove;
  final void Function(UserModel) onReject;

  const _OrganizerListView({
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
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('خطأ: ${snap.error}'));
        }
        final users = snap.data ?? [];
        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_outlined,
                    size: 64, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  filter == 'pending'
                      ? 'لا توجد طلبات بانتظار المراجعة'
                      : 'لا توجد سجلات',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: users.length,
          itemBuilder: (_, i) => _KycCard(
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

class _KycCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _KycCard({
    required this.user,
    required this.onTap,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final isPending =
        user.kycStatus == 'pending' || user.kycStatus == null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    child: Text(
                      user.name.isNotEmpty
                          ? user.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                        Text(user.email,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  _KycStatusBadge(status: user.kycStatus?.name),
                ],
              ),
              if (user.phone != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.phone,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(user.phone!,
                        style: const TextStyle(
                            fontSize: 13, color: Colors.grey)),
                  ],
                ),
              ],
              if (isPending) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.close,
                            size: 16, color: Colors.red),
                        label: const Text('رفض',
                            style: TextStyle(
                                color: Colors.red, fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            padding:
                            const EdgeInsets.symmetric(vertical: 6)),
                        onPressed: onReject,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check,
                            size: 16, color: Colors.white),
                        label: const Text('قبول',
                            style: TextStyle(
                                color: Colors.white, fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding:
                            const EdgeInsets.symmetric(vertical: 6)),
                        onPressed: onApprove,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _KycStatusBadge extends StatelessWidget {
  final String? status;
  const _KycStatusBadge({this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case 'approved':
        color = Colors.green;
        label = 'معتمد ✅';
        break;
      case 'rejected':
        color = Colors.red;
        label = 'مرفوض ❌';
        break;
      default:
        color = Colors.orange;
        label = 'بانتظار المراجعة';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600)),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1565C0)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
