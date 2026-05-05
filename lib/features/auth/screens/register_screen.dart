import 'package:flutter/material.dart';
import 'package:auction_app2/core/services/auth/auth_service.dart';
import 'package:auction_app2/core/services/otp_service.dart';
import '../../../core/constants/ds_colors.dart';
import '../../../core/widgets/ds_widgets.dart';
import 'terms_screen.dart';
import 'email_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confCtrl = TextEditingController();
  final _authService = AuthService();
  final _otpService = OtpService();

  bool _loading = false;
  bool _termsAccepted = false;
  String _role = 'bidder';
  String _accountType = 'individual';

  late AnimationController _fadeCtrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _showTerms() async {
    final accepted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TermsScreen(
          requireAcceptance: true,
          onAccepted: () => setState(() => _termsAccepted = true),
        ),
      ),
    );
    if (accepted == true) {
      setState(() => _termsAccepted = true);
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب الموافقة على الشروط والخصوصية أولاً'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text.trim();

    final result = await _authService.register(
      email: email,
      password: password,
      fullName: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      role: _role,
      accountType: _accountType,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      final otpResult = await _otpService.sendOtp(email);
      if (!mounted) return;
      setState(() => _loading = false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => EmailVerificationScreen(
            email: email,
            password: password,
            role: _role,
          ),
        ),
      );

      if (!otpResult['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'تم إنشاء الحساب لكن فشل إرسال الكود: ${otpResult['error']}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? 'حدث خطأ أثناء التسجيل')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DS.bg,
      appBar: DarkAppBar(
        leading: IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: DS.bgElevated,
              border: Border.all(color: DS.border),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 15,
              color: DS.textPrimary,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FadeTransition(
        opacity: _fade,
        child: Stack(children: [
          const PurpleOrb(
              size: 220, alignment: Alignment.topRight, opacity: 0.6),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('إنشاء حساب جديد', style: DS.titleXL),
                    const SizedBox(height: 6),
                    Row(children: [
                      Text('لديك حساب بالفعل؟ ', style: DS.body),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Text('تسجيل الدخول',
                            style: DS.purple_text
                                .copyWith(fontWeight: FontWeight.w700)),
                      ),
                    ]),
                    const SizedBox(height: 28),

                    // ── نوع الحساب ──
                    Text('نوع الحساب', style: DS.label),
                    const SizedBox(height: 10),
                    _ToggleRow(
                      options: const [
                        _Option('bidder', 'مزايد', Icons.gavel_rounded),
                        _Option('organizer', 'بائع', Icons.store_rounded),
                      ],
                      selected: _role,
                      onChanged: (v) => setState(() => _role = v),
                    ),
                    const SizedBox(height: 20),

                    // ── الشخصية القانونية — تظهر فقط للبائع ──
                    if (_role == 'organizer') ...[
                      Text('الشخصية القانونية', style: DS.label),
                      const SizedBox(height: 10),
                      _ToggleRow(
                        options: const [
                          _Option(
                              'individual', 'شخص طبيعي', Icons.person_rounded),
                          _Option('company', 'شركة', Icons.business_rounded),
                        ],
                        selected: _accountType,
                        onChanged: (v) => setState(() => _accountType = v),
                      ),
                      const SizedBox(height: 24),
                    ] else
                      const SizedBox(height: 4),

                    // ── الحقول ──
                    DarkTextField(
                      controller: _nameCtrl,
                      hint: 'الاسم الكامل',
                      icon: Icons.badge_outlined,
                      validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 14),
                    DarkTextField(
                      controller: _emailCtrl,
                      hint: 'البريد الإلكتروني',
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      textDir: TextDirection.ltr,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'مطلوب';
                        if (!v.contains('@')) return 'صيغة غير صحيحة';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    DarkTextField(
                      controller: _phoneCtrl,
                      hint: 'رقم الهاتف',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 14),
                    DarkTextField(
                      controller: _passCtrl,
                      hint: 'كلمة المرور',
                      icon: Icons.lock_outline_rounded,
                      obscure: true,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'مطلوب';
                        if (v.length < 6) return '6 أحرف على الأقل';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    DarkTextField(
                      controller: _confCtrl,
                      hint: 'تأكيد كلمة المرور',
                      icon: Icons.lock_outline_rounded,
                      obscure: true,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'مطلوب';
                        if (v != _passCtrl.text) {
                          return 'كلمتا المرور غير متطابقتين';
                        }
                        return null;
                      },
                    ),

                    // ── banner KYC للبائع ──
                    if (_role == 'organizer') ...[
                      const SizedBox(height: 16),
                      const DSBanner(
                        message:
                            'ستحتاج لرفع وثائق KYC بعد التسجيل للبدء في نشر المزادات.',
                        color: DS.purple,
                        icon: Icons.info_outline_rounded,
                      ),
                    ],

                    const SizedBox(height: 24),

                    // ── الشروط ──
                    GestureDetector(
                      onTap: _showTerms,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _termsAccepted
                              ? DS.success.withValues(alpha: 0.05)
                              : DS.bgCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _termsAccepted
                                ? DS.success.withValues(alpha: 0.4)
                                : DS.border,
                            width: _termsAccepted ? 1.5 : 1,
                          ),
                        ),
                        child: Row(children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: _termsAccepted
                                  ? DS.success
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: _termsAccepted ? DS.success : DS.border,
                                width: 1.5,
                              ),
                            ),
                            child: _termsAccepted
                                ? const Icon(Icons.check_rounded,
                                    color: Colors.white, size: 16)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: DS.body,
                                children: [
                                  const TextSpan(text: 'أوافق على '),
                                  TextSpan(
                                    text: 'الشروط والخصوصية',
                                    style: DS.purple_text.copyWith(
                                      fontWeight: FontWeight.w700,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: _termsAccepted ? DS.success : DS.textMuted,
                          ),
                        ]),
                      ),
                    ),

                    const SizedBox(height: 24),
                    GradientButton(
                      label: 'إنشاء الحساب',
                      isLoading: _loading,
                      onPressed: _handleRegister,
                      icon: Icons.person_add_rounded,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Option {
  final String value, label;
  final IconData icon;
  const _Option(this.value, this.label, this.icon);
}

class _ToggleRow extends StatelessWidget {
  final List<_Option> options;
  final String selected;
  final ValueChanged<String> onChanged;
  const _ToggleRow({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: options.map((opt) {
        final sel = opt.value == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(opt.value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: EdgeInsets.only(right: opt == options.last ? 0 : 12),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: sel ? DS.purpleDeep : DS.bgCard,
                border: Border.all(
                  color: sel ? DS.purple : DS.border,
                  width: sel ? 1.5 : 1,
                ),
                boxShadow: sel ? DS.purpleShadow : [],
              ),
              child: Column(children: [
                Icon(opt.icon, size: 20, color: sel ? DS.purple : DS.textMuted),
                const SizedBox(height: 6),
                Text(opt.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                      color: sel ? DS.textPrimary : DS.textSecondary,
                    )),
              ]),
            ),
          ),
        );
      }).toList(),
    );
  }
}
