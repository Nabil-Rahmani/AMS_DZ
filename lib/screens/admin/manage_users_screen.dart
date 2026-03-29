import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/user_model.dart';
import '../../data/services/firestore_service.dart';
class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final FirestoreService _db = FirestoreService();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _roleFilter = 'all'; // all | admin | organizer | bidder

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Filtering ──────────────────────────────────────────────────────────────

  List<UserModel> _applyFilters(List<UserModel> users) {
    return users.where((u) {
      final matchesRole =
          _roleFilter == 'all' || u.role.name.toLowerCase() == _roleFilter;
      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          u.name.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q);
      return matchesRole && matchesSearch;
    }).toList();
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _toggleStatus(UserModel user) async {
    final action = user.isActive ? 'تعطيل' : 'تفعيل';
    final confirm = await _showConfirm(
      title: '$action المستخدم',
      content: 'هل أنت متأكد من $action "${user.name}"؟',
      confirmText: action,
      confirmColor: user.isActive ? Colors.red : Colors.green,
    );
    if (!confirm) return;
    try {
      await _db.toggleUserStatus(user.id, !user.isActive);
      _showSnack(user.isActive
          ? '🔴 تم تعطيل المستخدم'
          : '🟢 تم تفعيل المستخدم');
    } catch (e) {
      _showSnack('❌ خطأ: $e', isError: true);
    }
  }

  void _showUserDetails(UserModel user) {
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
                    backgroundColor: const Color(0xFF1565C0).withOpacity(0.1),
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1565C0)),
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
              _DetailRow(icon: Icons.person, label: 'الدور', value: _roleLabel(user.role as String)),
              _DetailRow(
                  icon: Icons.verified_user,
                  label: 'الحالة',
                  value: user.isActive ? 'مفعّل' : 'معطّل'),
              if (user.role == 'organizer')
                _DetailRow(
                    icon: Icons.assignment_turned_in,
                    label: 'حالة KYC',
                    value: _kycLabel(user.kycStatus?.name)),
              _DetailRow(
                  icon: Icons.calendar_today,
                  label: 'تاريخ التسجيل',
                  value: user.createdAt != null
                      ? _formatDate(user.createdAt!)
                      : 'غير محدد'),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(
                      user.isActive ? Icons.block : Icons.check_circle,
                      color: Colors.white),
                  label: Text(
                      user.isActive ? 'تعطيل المستخدم' : 'تفعيل المستخدم',
                      style: const TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor:
                      user.isActive ? Colors.red : Colors.green),
                  onPressed: () {
                    Navigator.pop(context);
                    _toggleStatus(user);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddUserDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String selectedRole = 'bidder';
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('إضافة مستخدم جديد'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                        labelText: 'الاسم الكامل',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder()),
                    validator: (v) =>
                    v == null || v.trim().isEmpty ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(
                        labelText: 'البريد الإلكتروني',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder()),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                    v == null || !v.contains('@') ? 'بريد غير صالح' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passCtrl,
                    decoration: const InputDecoration(
                        labelText: 'كلمة المرور',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder()),
                    obscureText: true,
                    validator: (v) =>
                    v == null || v.length < 6 ? '6 أحرف على الأقل' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(
                        labelText: 'الدور',
                        prefixIcon: Icon(Icons.work),
                        border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'bidder', child: Text('مزايد')),
                      DropdownMenuItem(
                          value: 'organizer', child: Text('منظم مزادات')),
                      DropdownMenuItem(value: 'admin', child: Text('مدير')),
                    ],
                    onChanged: (v) =>
                        setDialogState(() => selectedRole = v ?? 'bidder'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0)),
              onPressed: isLoading
                  ? null
                  : () async {
                if (!formKey.currentState!.validate()) return;
                setDialogState(() => isLoading = true);
                try {
                  final cred = await FirebaseAuth.instance
                      .createUserWithEmailAndPassword(
                    email: emailCtrl.text.trim(),
                    password: passCtrl.text.trim(),
                  );
                  final user = UserModel(
                    id: cred.user!.uid,
                    name: nameCtrl.text.trim(),
                    email: emailCtrl.text.trim(),
                    role: UserRole.values.firstWhere(
                      (e) => e.name == selectedRole,
                ),
                    isActive: true,
                    createdAt: DateTime.now(),
                  );
                  await _db.createUser(user);
                  if (mounted) Navigator.pop(ctx);
                  _showSnack('✅ تم إنشاء المستخدم بنجاح');
                } catch (e) {
                  setDialogState(() => isLoading = false);
                  _showSnack('❌ خطأ: $e', isError: true);
                }
              },
              child: isLoading
                  ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
                  : const Text('إضافة',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
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
            child:
            Text(confirmText, style: const TextStyle(color: Colors.white)),
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

  String _roleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'مدير النظام';
      case 'organizer':
        return 'منظم مزادات';
      case 'bidder':
        return 'مزايد';
      default:
        return role;
    }
  }

  String _kycLabel(String? status) {
    switch (status) {
      case 'pending':
        return 'بانتظار المراجعة';
      case 'approved':
        return 'معتمد ✅';
      case 'rejected':
        return 'مرفوض ❌';
      default:
        return 'لم يُقدَّم بعد';
    }
  }

  String _formatDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إدارة المستخدمين',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF1565C0),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_add, color: Colors.white),
              tooltip: 'إضافة مستخدم',
              onPressed: _showAddUserDialog,
            ),
          ],
        ),
        body: Column(
          children: [
            // ── Search + Filter bar ─────────────────────────────────
            Container(
              color: Colors.grey[100],
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Column(
                children: [
                  // Search field
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'بحث بالاسم أو البريد...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          })
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                  const SizedBox(height: 8),
                  // Role filter chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                            label: 'الكل',
                            selected: _roleFilter == 'all',
                            onTap: () => setState(() => _roleFilter = 'all')),
                        _FilterChip(
                            label: 'مزايد',
                            selected: _roleFilter == 'bidder',
                            onTap: () =>
                                setState(() => _roleFilter = 'bidder')),
                        _FilterChip(
                            label: 'منظم',
                            selected: _roleFilter == 'organizer',
                            onTap: () =>
                                setState(() => _roleFilter = 'organizer')),
                        _FilterChip(
                            label: 'مدير',
                            selected: _roleFilter == 'admin',
                            onTap: () =>
                                setState(() => _roleFilter = 'admin')),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── List ───────────────────────────────────────────────
            Expanded(
              child: StreamBuilder<List<UserModel>>(
                stream: _db.streamAllUsers(),
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(child: Text('خطأ: ${snap.error}'));
                  }
                  final filtered = _applyFilters(snap.data ?? []);
                  if (filtered.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline,
                              size: 64, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('لا توجد نتائج',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final user = filtered[i];
                      return _UserCard(
                        user: user,
                        onTap: () => _showUserDetails(user),
                        onToggle: () => _toggleStatus(user),
                        roleLabel: _roleLabel(user.role.name),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// WIDGETS
// ══════════════════════════════════════════════════════════════════════════════

class _UserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final String roleLabel;

  const _UserCard({
    required this.user,
    required this.onTap,
    required this.onToggle,
    required this.roleLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF1565C0).withOpacity(0.1),
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
          ),
        ),
        title: Text(user.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email,
                style:
                const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 3),
            Row(
              children: [
                _RoleBadge(role: user.role.name, label: roleLabel),
                const SizedBox(width: 6),
                _StatusDot(isActive: user.isActive),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(
            user.isActive ? Icons.block : Icons.check_circle_outline,
            color: user.isActive ? Colors.red : Colors.green,
          ),
          tooltip: user.isActive ? 'تعطيل' : 'تفعيل',
          onPressed: onToggle,
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  final String label;
  const _RoleBadge({required this.role, required this.label});

  Color get _color {
    switch (role) {
      case 'admin':
        return Colors.purple;
      case 'organizer':
        return Colors.blue;
      default:
        return Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, color: _color, fontWeight: FontWeight.w600)),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final bool isActive;
  const _StatusDot({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? Colors.green : Colors.red,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          isActive ? 'مفعّل' : 'معطّل',
          style: TextStyle(
              fontSize: 11,
              color: isActive ? Colors.green : Colors.red),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1565C0) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected
                  ? const Color(0xFF1565C0)
                  : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
              color: selected ? Colors.white : Colors.grey[700],
              fontSize: 13,
              fontWeight:
              selected ? FontWeight.w600 : FontWeight.normal),
        ),
      ),
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
