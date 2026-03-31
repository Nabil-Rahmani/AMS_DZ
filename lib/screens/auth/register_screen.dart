import 'package:flutter/material.dart';
import '../../../data/services/auth_service.dart';
import '../../routes/app_routes.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String _selectedRole = 'bidder';
  String _accountType = 'individual'; // 'individual' | 'company'

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final result = await _authService.register(
      email: _emailController.text,
      password: _passwordController.text,
      fullName: _fullNameController.text,
      phone: _phoneController.text,
      role: _selectedRole,
      accountType: _accountType,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success']) {
      _showSuccess('تم إنشاء الحساب بنجاح!');
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      switch (_selectedRole) {
        case 'organizer':
          Navigator.pushReplacementNamed(context, AppRoutes.organizerDashboard);
          break;
        default:
          Navigator.pushReplacementNamed(context, AppRoutes.bidderDashboard);
      }
    } else {
      _showError(result['error']);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, textDirection: TextDirection.rtl),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, textDirection: TextDirection.rtl),
      backgroundColor: Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1565C0),
          foregroundColor: Colors.white,
          title: const Text('إنشاء حساب جديد'),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── الاسم الكامل ──────────────────────
                      TextFormField(
                        controller: _fullNameController,
                        decoration: _inputDecoration(
                            label: 'الاسم الكامل / اسم الشركة',
                            icon: Icons.person_outline),
                        validator: (v) =>
                        v == null || v.isEmpty ? 'أدخل الاسم' : null,
                      ),
                      const SizedBox(height: 16),

                      // ── البريد الإلكتروني ─────────────────
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textDirection: TextDirection.ltr,
                        decoration: _inputDecoration(
                            label: 'البريد الإلكتروني',
                            icon: Icons.email_outlined),
                        validator: (v) {
                          if (v == null || v.isEmpty)
                            return 'أدخل البريد الإلكتروني';
                          if (!v.contains('@')) return 'صيغة غير صحيحة';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // ── رقم الهاتف ────────────────────────
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textDirection: TextDirection.ltr,
                        decoration: _inputDecoration(
                            label: 'رقم الهاتف', icon: Icons.phone_outlined),
                        validator: (v) =>
                        v == null || v.isEmpty ? 'أدخل رقم الهاتف' : null,
                      ),
                      const SizedBox(height: 16),

                      // ── نوع الحساب ────────────────────────
                      const Text('نوع الحساب',
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _AccountTypeCard(
                              icon: Icons.person,
                              label: 'شخص طبيعي',
                              selected: _accountType == 'individual',
                              onTap: () =>
                                  setState(() => _accountType = 'individual'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _AccountTypeCard(
                              icon: Icons.business,
                              label: 'شركة',
                              selected: _accountType == 'company',
                              onTap: () =>
                                  setState(() => _accountType = 'company'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── الدور ─────────────────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey.shade50,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedRole,
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(
                                value: 'bidder',
                                child: Row(children: [
                                  Icon(Icons.person,
                                      color: Color(0xFF1565C0)),
                                  SizedBox(width: 8),
                                  Text('مزايد'),
                                ]),
                              ),
                              DropdownMenuItem(
                                value: 'organizer',
                                child: Row(children: [
                                  Icon(Icons.business,
                                      color: Color(0xFF1565C0)),
                                  SizedBox(width: 8),
                                  Text('بائع / منظم مزادات'),
                                ]),
                              ),
                            ],
                            onChanged: (val) =>
                                setState(() => _selectedRole = val!),
                          ),
                        ),
                      ),

                      // ── ملاحظة للمنظم ─────────────────────
                      if (_selectedRole == 'organizer') ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: Color(0xFF1565C0), size: 16),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'بعد التسجيل ستحتاج لرفع وثائق KYC للمراجعة قبل نشر المزادات.',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF1565C0)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // ── كلمة المرور ───────────────────────
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textDirection: TextDirection.ltr,
                        decoration: _inputDecoration(
                            label: 'كلمة المرور',
                            icon: Icons.lock_outline)
                            .copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty)
                            return 'أدخل كلمة المرور';
                          if (v.length < 6)
                            return 'يجب أن تكون 6 أحرف على الأقل';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // ── تأكيد كلمة المرور ─────────────────
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirm,
                        textDirection: TextDirection.ltr,
                        decoration: _inputDecoration(
                            label: 'تأكيد كلمة المرور',
                            icon: Icons.lock_outline)
                            .copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            onPressed: () => setState(
                                    () => _obscureConfirm = !_obscureConfirm),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty)
                            return 'أكد كلمة المرور';
                          if (v != _passwordController.text)
                            return 'كلمتا المرور غير متطابقتين';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // ── زر إنشاء الحساب ───────────────────
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1565C0),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                              : const Text('إنشاء الحساب',
                              style: TextStyle(fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('لديك حساب بالفعل؟'),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('تسجيل الدخول',
                                style: TextStyle(
                                    color: Color(0xFF1565C0),
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
      {required String label, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF1565C0)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1565C0), width: 2),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }
}

class _AccountTypeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _AccountTypeCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF1565C0).withOpacity(0.08)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF1565C0) : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: selected
                    ? const Color(0xFF1565C0)
                    : Colors.grey.shade500,
                size: 28),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    color: selected
                        ? const Color(0xFF1565C0)
                        : Colors.grey.shade600,
                    fontWeight: selected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
