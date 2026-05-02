import 'package:flutter/material.dart';
import 'package:auction_app2/core/services/auth/auth_service.dart';
import 'package:auction_app2/core/routes/app_routes.dart';
import '../../../core/constants/ds_colors.dart';
import '../../../core/widgets/ds_widgets.dart';
import 'email_verification_screen.dart'; // ✅ رجعنا للقديم

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _authService = AuthService();
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final result = await _authService.signIn(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result['success'] == true) {
      _navigateByRole(result['data']['role'] as String? ?? 'bidder');
      return;
    }

    // ✅ إذا الإيميل غير مؤكد — وجّهه لشاشة التحقق
    if (result['emailNotVerified'] == true) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EmailVerificationScreen(
            email: result['email'] as String,
            password: result['password'] as String,
            role: 'bidder',
          ),
        ),
      );
      return;
    }

    _showSnack(result['error'] ?? 'حدث خطأ', isError: true);
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
        Navigator.pushReplacementNamed(context, AppRoutes.browseAuctions);
    }
  }

  Future<void> _handleForgotPassword() async {
    if (_emailCtrl.text.isEmpty) {
      _showSnack('أدخل بريدك الإلكتروني أولاً', isError: true);
      return;
    }
    setState(() => _loading = true);
    final result =
        await _authService.resetPassword(email: _emailCtrl.text.trim());
    if (!mounted) return;
    setState(() => _loading = false);
    _showSnack(
      result['success'] ? 'تم إرسال رابط الاستعادة ✅' : result['error'],
      isError: !result['success'],
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(
          isError
              ? Icons.error_outline_rounded
              : Icons.check_circle_outline_rounded,
          color: isError ? DS.error : DS.success,
          size: 18,
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(msg)),
      ]),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: DS.bg,
      resizeToAvoidBottomInset: true,
      body: Stack(children: [
        const PurpleOrb(size: 320, alignment: Alignment.topRight),
        Positioned(
          bottom: -80,
          left: -80,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: DS.goldDark.withValues(alpha: 0.08),
            ),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      const FadeSlideIn(
                        duration: Duration(milliseconds: 600),
                        child: AmsLogo(size: 42),
                      ),
                      const Spacer(flex: 2),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('مرحباً بعودتك', style: DS.displayLarge),
                            const SizedBox(height: 8),
                            Row(children: [
                              Text('ليس لديك حساب؟ ', style: DS.body),
                              GestureDetector(
                                onTap: () => Navigator.pushNamed(
                                    context, AppRoutes.register),
                                child: Text('إنشاء حساب',
                                    style: DS.purple_text
                                        .copyWith(fontWeight: FontWeight.w700)),
                              ),
                            ]),
                          ],
                        ),
                      ),
                      const Spacer(flex: 1),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 200),
                        child: Form(
                          key: _formKey,
                          child: Column(children: [
                            DarkTextField(
                              controller: _emailCtrl,
                              hint: 'البريد الإلكتروني',
                              icon: Icons.mail_outline_rounded,
                              keyboardType: TextInputType.emailAddress,
                              textDir: TextDirection.ltr,
                              validator: (v) {
                                if (v == null || v.isEmpty)
                                  return 'أدخل البريد الإلكتروني';
                                if (!v.contains('@')) return 'صيغة غير صحيحة';
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            DarkTextField(
                              controller: _passCtrl,
                              hint: 'كلمة المرور',
                              icon: Icons.lock_outline_rounded,
                              obscure: true,
                              validator: (v) {
                                if (v == null || v.isEmpty)
                                  return 'أدخل كلمة المرور';
                                if (v.length < 6) return 'كلمة المرور قصيرة';
                                return null;
                              },
                            ),
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed:
                                    _loading ? null : _handleForgotPassword,
                                child: Text(
                                  'نسيت كلمة المرور؟',
                                  style: DS.label.copyWith(
                                    color: DS.purple,
                                    letterSpacing: 0.3,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ]),
                        ),
                      ),
                      const Spacer(flex: 1),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 300),
                        child: GradientButton(
                          label: 'تسجيل الدخول',
                          isLoading: _loading,
                          onPressed: _handleLogin,
                          icon: Icons.login_rounded,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const DSDivider(label: 'أو'),
                      const SizedBox(height: 20),
                      const FadeSlideIn(
                        delay: Duration(milliseconds: 400),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _SocialBtn(
                                icon: Icons.apple_rounded,
                                color: DS.textPrimary),
                            SizedBox(width: 14),
                            _SocialBtn(
                                icon: Icons.facebook, color: Color(0xFF1877F2)),
                            SizedBox(width: 14),
                            _SocialBtn(
                                icon: Icons.g_mobiledata_rounded,
                                color: Color(0xFFDB4437)),
                          ],
                        ),
                      ),
                      const Spacer(flex: 2),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _SocialBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _SocialBtn({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => TapAnimated(
        onTap: () {},
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: DS.bgElevated,
            border: Border.all(color: DS.border),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
      );
}
