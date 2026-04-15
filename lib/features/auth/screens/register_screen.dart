import 'package:flutter/material.dart';
import 'package:auction_app2/core/services/auth/auth_service.dart';
import 'package:auction_app2/core/routes/app_routes.dart';
import '../../../core/constants/ds_colors.dart';
import '../../../core/widgets/ds_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _confCtrl  = TextEditingController();
  final _authService = AuthService();

  bool _loading = false;
  String _role = 'bidder';
  String _accountType = 'individual';

  late AnimationController _fadeCtrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose(); _phoneCtrl.dispose();
    _passCtrl.dispose(); _confCtrl.dispose(); _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Logic unchanged ────────────────────────────────────────────
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final result = await _authService.register(
      email: _emailCtrl.text, password: _passCtrl.text,
      fullName: _nameCtrl.text, phone: _phoneCtrl.text,
      role: _role, accountType: _accountType,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إنشاء الحساب بنجاح!')));
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      Navigator.pushReplacementNamed(context,
          _role == 'organizer' ? AppRoutes.organizerDashboard : AppRoutes.bidderDashboard);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['error'])));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DS.bg,
      appBar: DarkAppBar(
        leading: IconButton(
          icon: Container(width: 36, height: 36,
            decoration: BoxDecoration(shape: BoxShape.circle,
              color: DS.bgElevated, border: Border.all(color: DS.border)),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: DS.textPrimary)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FadeTransition(
        opacity: _fade,
        child: Stack(children: [
          const PurpleOrb(size: 220, alignment: Alignment.topRight, opacity: 0.6),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
              child: Form(
                key: _formKey,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('إنشاء حساب جديد', style: DS.titleXL),
                  const SizedBox(height: 6),
                  Row(children: [
                    Text('لديك حساب بالفعل؟ ', style: DS.body),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text('تسجيل الدخول',
                          style: DS.purple_text.copyWith(fontWeight: FontWeight.w700)),
                    ),
                  ]),
                  const SizedBox(height: 28),

                  // ── Role ────────────────────────────────────────
                  Text('نوع الحساب', style: DS.label),
                  const SizedBox(height: 10),
                  _ToggleRow(
                    options: [
                      _Option('bidder', 'مزايد', Icons.gavel_rounded),
                      _Option('organizer', 'بائع / منظم', Icons.store_rounded),
                    ],
                    selected: _role,
                    onChanged: (v) => setState(() => _role = v),
                  ),
                  const SizedBox(height: 20),

                  // ── Account type ─────────────────────────────────
                  Text('الشخصية القانونية', style: DS.label),
                  const SizedBox(height: 10),
                  _ToggleRow(
                    options: [
                      _Option('individual', 'شخص طبيعي', Icons.person_rounded),
                      _Option('company', 'شركة', Icons.business_rounded),
                    ],
                    selected: _accountType,
                    onChanged: (v) => setState(() => _accountType = v),
                  ),
                  const SizedBox(height: 24),

                  // ── Fields ────────────────────────────────────────
                  DarkTextField(controller: _nameCtrl, hint: 'الاسم الكامل',
                      icon: Icons.badge_outlined,
                      validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null),
                  const SizedBox(height: 14),
                  DarkTextField(controller: _emailCtrl, hint: 'البريد الإلكتروني',
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      textDir: TextDirection.ltr,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'مطلوب';
                        if (!v.contains('@')) return 'صيغة غير صحيحة';
                        return null;
                      }),
                  const SizedBox(height: 14),
                  DarkTextField(controller: _phoneCtrl, hint: 'رقم الهاتف',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null),
                  const SizedBox(height: 14),
                  DarkTextField(controller: _passCtrl, hint: 'كلمة المرور',
                      icon: Icons.lock_outline_rounded, obscure: true,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'مطلوب';
                        if (v.length < 6) return '6 أحرف على الأقل';
                        return null;
                      }),
                  const SizedBox(height: 14),
                  DarkTextField(controller: _confCtrl, hint: 'تأكيد كلمة المرور',
                      icon: Icons.lock_outline_rounded, obscure: true,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'مطلوب';
                        if (v != _passCtrl.text) return 'كلمتا المرور غير متطابقتين';
                        return null;
                      }),

                  if (_role == 'organizer') ...[
                    const SizedBox(height: 16),
                    DSBanner(
                      message: 'ستحتاج لرفع وثائق KYC بعد التسجيل للبدء في نشر المزادات.',
                      color: DS.purple, icon: Icons.info_outline_rounded,
                    ),
                  ],

                  const SizedBox(height: 32),
                  GradientButton(label: 'إنشاء الحساب', isLoading: _loading,
                      onPressed: _handleRegister, icon: Icons.person_add_rounded),
                  const SizedBox(height: 20),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Option { final String value, label; final IconData icon;
  const _Option(this.value, this.label, this.icon); }

class _ToggleRow extends StatelessWidget {
  final List<_Option> options;
  final String selected;
  final ValueChanged<String> onChanged;
  const _ToggleRow({required this.options, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(children: options.map((opt) {
      final sel = opt.value == selected;
      return Expanded(child: GestureDetector(
        onTap: () => onChanged(opt.value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: EdgeInsets.only(right: opt == options.last ? 0 : 12),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: sel ? DS.purpleDeep : DS.bgCard,
            border: Border.all(color: sel ? DS.purple : DS.border, width: sel ? 1.5 : 1),
            boxShadow: sel ? DS.purpleShadow : [],
          ),
          child: Column(children: [
            Icon(opt.icon, size: 20, color: sel ? DS.purple : DS.textMuted),
            const SizedBox(height: 6),
            Text(opt.label, style: TextStyle(
              fontSize: 12, fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
              color: sel ? DS.textPrimary : DS.textSecondary,
            )),
          ]),
        ),
      ));
    }).toList());
  }
}
