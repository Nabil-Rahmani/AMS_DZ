import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:auction_app2/shared/models/user_model.dart';
import 'package:auction_app2/core/services/firebase/firestore_service.dart';
import '../../../core/constants/ds_colors.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../widgets/admin_user_card.dart';
import '../widgets/admin_user_detail_row.dart';
import '../widgets/admin_role_chip.dart';
import '../utils/admin_utils.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});
  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _db = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _roleFilter = 'all';

  late AnimationController _animCtrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

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

  Future<void> _toggleStatus(UserModel user) async {
    final action = user.isActive ? 'تعطيل' : 'تفعيل';
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: DS.bgModal.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: DS.border)),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: user.isActive ? DS.errorSurface : DS.successSurface,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: user.isActive
                            ? DS.error.withValues(alpha: 0.3)
                            : DS.success.withValues(alpha: 0.3)),
                  ),
                  child: Icon(
                      user.isActive
                          ? Icons.block_rounded
                          : Icons.check_circle_rounded,
                      color: user.isActive ? DS.error : DS.success,
                      size: 28),
                ),
                const SizedBox(height: 16),
                Text('$action المستخدم', style: DS.titleM),
                const SizedBox(height: 8),
                Text('هل أنت متأكد من $action "${user.name}"؟',
                    style: DS.body, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                Row(children: [
                  Expanded(
                      child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('إلغاء'))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: user.isActive ? DS.error : DS.success),
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(action,
                        style: const TextStyle(color: Colors.white)),
                  )),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
    if (result != true) return;
    try {
      await _db.toggleUserStatus(user.id, !user.isActive);
      _showSnack(user.isActive ? 'تم تعطيل المستخدم' : 'تم تفعيل المستخدم');
    } catch (e) {
      _showSnack('خطأ: $e', isError: true);
    }
  }

  Future<void> _changeRole(UserModel user) async {
    UserRole selectedRole = user.role;
    final result = await showDialog<UserRole>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                    color: DS.bgModal.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: DS.border)),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('تغيير دور المستخدم', style: DS.titleM),
                  const SizedBox(height: 10),
                  Text(user.name, style: DS.bodySmall),
                  const SizedBox(height: 20),
                  ...UserRole.values.map((role) => RadioListTile<UserRole>(
                        title: Text(AdminUtils.getRoleLabel(role)),
                        value: role,
                        groupValue: selectedRole,
                        onChanged: (v) =>
                            setDialogState(() => selectedRole = v!),
                      )),
                  const SizedBox(height: 24),
                  Row(children: [
                    Expanded(
                        child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('إلغاء'))),
                    const SizedBox(width: 12),
                    Expanded(
                        child: GradientButton(
                            label: 'تغيير',
                            height: 48,
                            onPressed: () => Navigator.pop(ctx, selectedRole))),
                  ]),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
    if (result == null || result == user.role) return;
    try {
      await _db.changeUserRole(user.id, result);
      _showSnack('تم تغيير دور المستخدم بنجاح');
    } catch (e) {
      _showSnack('خطأ: $e', isError: true);
    }
  }

  void _showUserDetails(UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: const BoxDecoration(
              color: DS.bgCard,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(top: BorderSide(color: DS.border)),
            ),
            padding: EdgeInsets.fromLTRB(
                24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: DS.border,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Row(children: [
                DSAvatar(
                    name: user.name,
                    radius: 32,
                    color: AdminUtils.getRoleColor(user.role)),
                const SizedBox(width: 16),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(user.name, style: DS.titleM),
                      const SizedBox(height: 3),
                      Text(user.email, style: DS.body.copyWith(fontSize: 13)),
                    ])),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                        color: DS.bgElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: DS.border)),
                    child: const Icon(Icons.close_rounded,
                        size: 18, color: DS.textSecondary),
                  ),
                ),
              ]),
              const SizedBox(height: 20),
              const DSDivider(),
              const SizedBox(height: 16),
              AdminUserDetailRow(
                  icon: Icons.work_outline_rounded,
                  label: 'الدور',
                  value: AdminUtils.getRoleLabel(user.role)),
              AdminUserDetailRow(
                icon: user.isActive
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                label: 'الحالة',
                value: user.isActive ? 'مفعّل' : 'معطّل',
                valueColor: user.isActive ? DS.success : DS.error,
              ),
              if (user.role == UserRole.organizer)
                AdminUserDetailRow(
                    icon: Icons.verified_user_rounded,
                    label: 'حالة KYC',
                    value: AdminUtils.getKycLabel(user.kycStatus)),
              if (user.createdAt != null)
                AdminUserDetailRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'تاريخ التسجيل',
                    value:
                        '${user.createdAt!.day}/${user.createdAt!.month}/${user.createdAt!.year}'),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                    child: OutlinedButton.icon(
                  icon: const Icon(Icons.shield_outlined, size: 18),
                  label: const Text('تغيير الدور'),
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                  onPressed: () {
                    Navigator.pop(context);
                    _changeRole(user);
                  },
                )),
                const SizedBox(width: 12),
                Expanded(
                    child: GradientButton(
                  label: user.isActive ? 'تعطيل المستخدم' : 'تفعيل المستخدم',
                  icon: user.isActive
                      ? Icons.block_rounded
                      : Icons.check_circle_rounded,
                  onPressed: () {
                    Navigator.pop(context);
                    _toggleStatus(user);
                  },
                )),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  void _showAddUserDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    UserRole selectedRole = UserRole.bidder;
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                    color: DS.bgModal.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: DS.border)),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('إضافة مستخدم جديد', style: DS.titleM),
                    const SizedBox(height: 20),
                    TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                            labelText: 'الاسم الكامل',
                            prefixIcon: Icon(Icons.person_outline_rounded)),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'مطلوب' : null),
                    const SizedBox(height: 12),
                    TextFormField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        textDirection: TextDirection.ltr,
                        decoration: const InputDecoration(
                            labelText: 'البريد الإلكتروني',
                            prefixIcon: Icon(Icons.mail_outline_rounded)),
                        validator: (v) => v == null || !v.contains('@')
                            ? 'بريد غير صالح'
                            : null),
                    const SizedBox(height: 12),
                    TextFormField(
                        controller: passCtrl,
                        obscureText: true,
                        textDirection: TextDirection.ltr,
                        decoration: const InputDecoration(
                            labelText: 'كلمة المرور',
                            prefixIcon: Icon(Icons.lock_outline_rounded)),
                        validator: (v) => v == null || v.length < 6
                            ? '6 أحرف على الأقل'
                            : null),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<UserRole>(
                      initialValue: selectedRole,
                      decoration: const InputDecoration(
                          labelText: 'الدور',
                          prefixIcon: Icon(Icons.work_outline_rounded)),
                      items: UserRole.values
                          .map((r) => DropdownMenuItem(
                              value: r,
                              child: Text(AdminUtils.getRoleLabel(r))))
                          .toList(),
                      onChanged: (v) => setDialogState(
                          () => selectedRole = v ?? UserRole.bidder),
                    ),
                    const SizedBox(height: 24),
                    Row(children: [
                      Expanded(
                          child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('إلغاء'))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: GradientButton(
                        label: 'إضافة',
                        height: 48,
                        isLoading: isLoading,
                        onPressed: isLoading
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                setDialogState(() => isLoading = true);
                                try {
                                  final cred = await FirebaseAuth.instance
                                      .createUserWithEmailAndPassword(
                                          email: emailCtrl.text.trim(),
                                          password: passCtrl.text.trim());
                                  final user = UserModel(
                                      id: cred.user!.uid,
                                      name: nameCtrl.text.trim(),
                                      email: emailCtrl.text.trim(),
                                      role: selectedRole,
                                      isActive: true,
                                      createdAt: DateTime.now());
                                  await _db.createUser(user);
                                  if (mounted) Navigator.pop(ctx);
                                  _showSnack('تم إنشاء المستخدم بنجاح ✅');
                                } catch (e) {
                                  setDialogState(() => isLoading = false);
                                  _showSnack('خطأ: $e', isError: true);
                                }
                              },
                      )),
                    ]),
                  ])),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg), backgroundColor: isError ? DS.error : DS.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: FadeTransition(
        opacity: _fade,
        child: Scaffold(
          backgroundColor: DS.bg,
          body: Column(children: [
            // ── Header ──
            Container(
              height: 180,
              decoration: const BoxDecoration(gradient: DS.headerGradient),
              child: Stack(children: [
                const Positioned(
                    top: -50,
                    right: -50,
                    child: PurpleOrb(size: 220, opacity: 0.3)),
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                      color: DS.purple.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: DS.purple
                                              .withValues(alpha: 0.2))),
                                  child: const Icon(Icons.people_rounded,
                                      color: DS.purple, size: 24),
                                ),
                                const SizedBox(height: 14),
                                Text('إدارة المستخدمين',
                                    style: DS.titleL.copyWith(fontSize: 26)),
                                const SizedBox(height: 4),
                                Text('التحكم في صلاحيات وأدوار أعضاء المنصة',
                                    style: DS.bodySmall),
                              ]),
                          const Spacer(),
                          GestureDetector(
                            onTap: _showAddUserDialog,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                  gradient: DS.purpleGradient,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: DS.purpleShadow),
                              child: Row(children: [
                                const Icon(Icons.person_add_rounded,
                                    color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Text('إضافة',
                                    style: DS.label.copyWith(
                                        color: Colors.white, fontSize: 13)),
                              ]),
                            ),
                          ),
                        ]),
                  ),
                ),
              ]),
            ),

            // ── Search + Filters ──
            GlassCard(
              borderRadius: 0,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              backgroundColor: DS.bgCard.withValues(alpha: 0.4),
              border: const Border(bottom: BorderSide(color: DS.border)),
              child: Column(children: [
                TextField(
                  controller: _searchController,
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    hintText: 'بحث عن مستخدم بالاسم أو البريد...',
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: DS.purple, size: 20),
                    filled: true,
                    fillColor: DS.bgField.withValues(alpha: 0.5),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            })
                        : null,
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    AdminRoleChip(
                        label: 'الكل',
                        selected: _roleFilter == 'all',
                        onTap: () => setState(() => _roleFilter = 'all')),
                    const SizedBox(width: 8),
                    AdminRoleChip(
                        label: 'مزايد',
                        selected: _roleFilter == 'bidder',
                        onTap: () => setState(() => _roleFilter = 'bidder'),
                        color: DS.success),
                    const SizedBox(width: 8),
                    AdminRoleChip(
                        label: 'منظم',
                        selected: _roleFilter == 'organizer',
                        onTap: () => setState(() => _roleFilter = 'organizer'),
                        color: DS.purple),
                    const SizedBox(width: 8),
                    AdminRoleChip(
                        label: 'مدير',
                        selected: _roleFilter == 'admin',
                        onTap: () => setState(() => _roleFilter = 'admin'),
                        color: const Color(0xFF7C3AED)),
                  ]),
                ),
              ]),
            ),

            const Divider(height: 1),

            // ── List ──
            Expanded(
              child: StreamBuilder<List<UserModel>>(
                stream: _db.streamAllUsers(),
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(color: DS.purple));
                  }
                  if (snap.hasError) {
                    return Center(
                        child: Text('خطأ: ${snap.error}', style: DS.body));
                  }
                  final filtered = _applyFilters(snap.data ?? []);
                  if (filtered.isEmpty) {
                    return const DSEmpty(
                      icon: Icons.people_outline_rounded,
                      title: 'لا توجد نتائج',
                      subtitle: 'جرّب تغيير مرشح البحث',
                    );
                  }
                  return StaggeredListView(
                    // ✅ padding أسفل 90 — يكفي لإظهار آخر عنصر فوق الـ FAB
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                    itemCount: filtered.length,
                    staggerMs: 50,
                    itemBuilder: (ctx, i) => AdminUserCard(
                      user: filtered[i],
                      onTap: () => _showUserDetails(filtered[i]),
                      onToggle: () => _toggleStatus(filtered[i]),
                    ),
                  );
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
