import 'package:flutter/material.dart';
import '../../data/services/auth_service.dart';
import '../../routes/app_routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ─── تسجيل الدخول ───────────────────────────────────────────
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await _authService.signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success']) {
      final role = result['data']['role'] as String? ?? 'bidder';
      _navigateByRole(role);
    } else {
      _showError(result['error']);
    }
  }

  void _navigateByRole(String role) {
    switch (role) {
      case 'admin':
        Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
        break;
      case 'organizer':
        Navigator.pushReplacementNamed(context, AppRoutes.organizerDashboard);
        break;
      default:
        Navigator.pushReplacementNamed(context, AppRoutes.bidderDashboard);
    }
  }

  // ─── نسيت كلمة المرور ───────────────────────────────────────
  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showError('أدخل بريدك الإلكتروني أولاً ثم اضغط "نسيت كلمة المرور"');
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showError('صيغة البريد الإلكتروني غير صحيحة');
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authService.resetPassword(email: email);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success']) {
      _showSuccess('تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني');
    } else {
      _showError(result['error']);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textDirection: TextDirection.rtl),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textDirection: TextDirection.rtl),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // ── لوغو / عنوان ──────────────────────────
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.gavel, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'AMS-DZ',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                  const Text(
                    'نظام إدارة المزادات',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 32),

                  // ── بطاقة الفورم ──────────────────────────
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'تسجيل الدخول',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),

                            // البريد الإلكتروني
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textDirection: TextDirection.ltr,
                              decoration: _inputDecoration(
                                label: 'البريد الإلكتروني',
                                icon: Icons.email_outlined,
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'أدخل البريد الإلكتروني';
                                if (!v.contains('@')) return 'صيغة غير صحيحة';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // كلمة المرور
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textDirection: TextDirection.ltr,
                              decoration: _inputDecoration(
                                label: 'كلمة المرور',
                                icon: Icons.lock_outline,
                              ).copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                  onPressed: () => setState(
                                          () => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'أدخل كلمة المرور';
                                if (v.length < 6) return 'كلمة المرور قصيرة جداً';
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),

                            // نسيت كلمة المرور
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: _isLoading ? null : _handleForgotPassword,
                                child: const Text('نسيت كلمة المرور؟'),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // زر تسجيل الدخول
                            SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1565C0),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                    : const Text(
                                  'تسجيل الدخول',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // رابط إنشاء حساب
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('ليس لديك حساب؟'),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, AppRoutes.register),
                        child: const Text(
                          'إنشاء حساب',
                          style: TextStyle(
                            color: Color(0xFF1565C0),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String label, required IconData icon}) {
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
