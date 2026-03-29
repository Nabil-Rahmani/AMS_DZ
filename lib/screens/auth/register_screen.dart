import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();

  bool _loading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  String _selectedRole = 'bidder';
  String? _errorMessage;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passController.text.trim(),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
        'uid': credential.user!.uid,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': _selectedRole,
        'isKycApproved': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'email-already-in-use':
            _errorMessage = 'هذا البريد مستخدم مسبقاً.';
            break;
          case 'weak-password':
            _errorMessage = 'كلمة المرور ضعيفة جداً.';
            break;
          case 'invalid-email':
            _errorMessage = 'البريد الإلكتروني غير صالح.';
            break;
          default:
            _errorMessage = 'حدث خطأ: ${e.message}';
        }
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'كلمة المرور مطلوبة';
    if (value.length < 8) return 'يجب أن تكون 8 أحرف على الأقل';
    if (!value.contains(RegExp(r'[A-Z]'))) return 'يجب أن تحتوي على حرف كبير';
    if (!value.contains(RegExp(r'[0-9]'))) return 'يجب أن تحتوي على رقم';
    if (!value.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]')))
      return 'يجب أن تحتوي على رمز خاص';
    return null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1565C0),
          foregroundColor: Colors.white,
          title: const Text('إنشاء حساب جديد'),
          centerTitle: true,
        ),
        body: SafeArea(
            child: Center(
                child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                        // Logo
                        Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1565C0),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(Icons.gavel, color: Colors.white, size: 44),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'AMS-DZ',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1565C0),
                        ),
                      ),const SizedBox(height: 28),

                        // Error message
                        if (_errorMessage != null)
                  Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

                // Name
                TextFormField(
                  controller: _nameController,
                  validator: (v) =>
                  v == null || v.trim().isEmpty ? 'الاسم مطلوب' : null,
                  decoration: _inputDecoration('الاسم الكامل', Icons.person_outline),
                ),
                const SizedBox(height: 14),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'البريد مطلوب';
                    final r = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!r.hasMatch(v.trim())) return 'صيغة البريد غير صحيحة';
                    return null;
                  },
                  decoration: _inputDecoration('البريد الإلكتروني', Icons.email_outlined),
                ),
                const SizedBox(height: 14),

                // Role selector - Cards
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'نوع الحساب',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                    children: [
                Expanded(
                child: GestureDetector(
                onTap: () => setState(() => _selectedRole = 'bidder'),
        child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: _selectedRole == 'bidder'
                  ? const Color(0xFF1565C0)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFF1565C0), width: 2),
            ),
            child: Column(
                children: [
                Icon(Icons.person,
                color: _selectedRole == 'bidder'
                    ? Colors.white
                    : const Color(0xFF1565C0),
                size: 30),
            const SizedBox(height: 6),
            Text(
                'مزايد',
                style: TextStyle(
                    color: _selectedRole == 'bidder'
                        ? Colors.white: const Color(0xFF1565C0),
                  fontWeight: FontWeight.bold,
                ),
            ),
                ],
            ),
        ),
                ),
                ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedRole = 'organizer'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: _selectedRole == 'organizer'
                                  ? const Color(0xFF1565C0)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFF1565C0), width: 2),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.business_center,
                                    color: _selectedRole == 'organizer'
                                        ? Colors.white
                                        : const Color(0xFF1565C0),
                                    size: 30),
                                const SizedBox(height: 6),
                                Text(
                                  'منظم',
                                  style: TextStyle(
                                    color: _selectedRole == 'organizer'
                                        ? Colors.white
                                        : const Color(0xFF1565C0),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                ),
                const SizedBox(height: 14),

                // Password
                TextFormField(
                  controller: _passController,
                  obscureText: _obscurePass,
                  validator: _validatePassword,
                  decoration: _inputDecoration(
                    'كلمة المرور',
                    Icons.lock_outline,
                    suffix: IconButton(
                      icon: Icon(
                        _obscurePass ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Confirm password
                TextFormField(
                    controller: _confirmPassController,
                    obscureText: _obscureConfirm,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'تأكيد كلمة المرور مطلوب';
                      if (v != _passController.text)
                        return 'كلمتا المرور غير متطابقتين';
                      return null;
                    },
                    decoration: _inputDecoration(
                        'تأكيد كلمة المرور',
                        Icons.lock_outline,
                        suffix: IconButton(
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () =>setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                    ),
                ),
                          const SizedBox(height: 24),

                          // Register button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1565C0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _loading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text(
                                'إنشاء الحساب',
                                style:
                                TextStyle(fontSize: 16, color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Back to login
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('لديك حساب بالفعل؟'),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text(
                                  'تسجيل الدخول',
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

  InputDecoration _inputDecoration(String label, IconData icon,
      {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF1565C0)),
      suffixIcon: suffix,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1565C0), width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }
}