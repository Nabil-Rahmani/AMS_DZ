import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:auction_app2/core/services/auth/auth_service.dart';
import 'package:auction_app2/core/services/otp_service.dart';
import 'package:auction_app2/core/routes/app_routes.dart';
import '../../../core/constants/ds_colors.dart';
import '../../../core/widgets/ds_widgets.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final String password;
  final String role;

  const EmailVerificationScreen({
    super.key,
    required this.email,
    required this.password,
    required this.role,
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with SingleTickerProviderStateMixin {
  final _otpService = OtpService();
  final _authService = AuthService();

  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _verifying = false;
  bool _resending = false;
  int _resendTimer = 0;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);
    _startResendTimer();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _countdownTimer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    setState(() => _resendTimer = 60);
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _resendTimer--);
      if (_resendTimer <= 0) t.cancel();
    });
  }

  String get _enteredOtp => _controllers.map((c) => c.text).join();

  Future<void> _verifyOtp() async {
    if (_enteredOtp.length < 6) {
      _showError('أدخل الكود كاملاً (6 أرقام)');
      return;
    }
    setState(() => _verifying = true);
    try {
      // ✅ 1. تحقق من الكود
      final result = await _otpService.verifyOtp(widget.email, _enteredOtp);
      if (!mounted) return;

      if (!result['success']) {
        _showError(result['error'] ?? 'الكود غير صحيح');
        for (final c in _controllers) {
          c.clear();
        }
        _focusNodes.first.requestFocus();
        return;
      }

      // ✅ 2. سجل دخول مؤقت لجلب الـ uid
      final tempCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: widget.email.trim(),
        password: widget.password.trim(),
      );
      final uid = tempCredential.user?.uid;

      if (uid == null) {
        _showError('حدث خطأ في جلب بيانات المستخدم');
        return;
      }

      // ✅ 3. حدّث isVerified أولاً قبل أي تحقق
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'isVerified': true});

      // ✅ 4. سجل خروج وأعد الدخول عبر AuthService
      await FirebaseAuth.instance.signOut();

      final signInResult = await _authService.signIn(
        email: widget.email,
        password: widget.password,
      );
      if (!mounted) return;

      if (!signInResult['success']) {
        _showError(signInResult['error'] ?? 'حدث خطأ في تسجيل الدخول');
        return;
      }

      // ✅ 5. اجلب الـ role وانتقل
      String role = widget.role;
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      role = doc.data()?['role'] as String? ?? widget.role;

      _showSuccess('تم التحقق بنجاح ✅');
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      _navigateByRole(role);
    } catch (e) {
      if (mounted) _showError('حدث خطأ: $e');
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resendOtp() async {
    if (_resendTimer > 0 || _resending) return;
    setState(() => _resending = true);
    try {
      final result = await _otpService.sendOtp(widget.email);
      if (!mounted) return;
      if (result['success']) {
        _showSuccess('تم إرسال كود جديد ✅');
        _startResendTimer();
        for (final c in _controllers) {
          c.clear();
        }
        _focusNodes.first.requestFocus();
      } else {
        _showError(result['error'] ?? 'فشل إرسال الكود');
      }
    } catch (e) {
      if (mounted) _showError('حدث خطأ: $e');
    } finally {
      if (mounted) setState(() => _resending = false);
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

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: DS.error,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: DS.success,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 46,
      height: 56,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: DS.titleL.copyWith(color: DS.textPrimary),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: DS.bgCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: DS.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: DS.purple, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: DS.border),
          ),
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (val) {
          if (val.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          }
          if (val.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
          if (_enteredOtp.length == 6) _verifyOtp();
          setState(() {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final emailName = widget.email.split('@').first;
    final emailDomain = '@${widget.email.split('@').last}';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: DS.bg,
        body: Stack(children: [
          const PurpleOrb(
              size: 300, alignment: Alignment.topRight, opacity: 0.4),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                // ── Back ──
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: DS.bgElevated,
                        shape: BoxShape.circle,
                        border: Border.all(color: DS.border),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 15, color: DS.textPrimary),
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                // ── Icon ──
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, __) => Transform.scale(
                    scale: 1.0 + (_pulse.value * 0.08),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: DS.purple
                            .withValues(alpha: 0.1 + _pulse.value * 0.05),
                        border: Border.all(
                          color: DS.purple
                              .withValues(alpha: 0.3 + _pulse.value * 0.2),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: DS.purple
                                .withValues(alpha: 0.15 + _pulse.value * 0.1),
                            blurRadius: 20 + _pulse.value * 10,
                          )
                        ],
                      ),
                      child: const Icon(Icons.mark_email_unread_rounded,
                          color: DS.purple, size: 44),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                FadeSlideIn(
                  child: Text('أدخل كود التحقق',
                      style: DS.titleXL, textAlign: TextAlign.center),
                ),
                const SizedBox(height: 12),

                // ── Email ──
                FadeSlideIn(
                  delay: const Duration(milliseconds: 100),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: DS.bgCard,
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: DS.purple.withValues(alpha: 0.3)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.mail_rounded,
                          color: DS.purple, size: 18),
                      const SizedBox(width: 10),
                      Text(emailName,
                          style: DS.titleS.copyWith(color: DS.purple)),
                      Text(emailDomain,
                          style: DS.body.copyWith(color: DS.textSecondary)),
                    ]),
                  ),
                ),

                const SizedBox(height: 12),

                FadeSlideIn(
                  delay: const Duration(milliseconds: 150),
                  child: Text(
                    'أرسلنا كود من 6 أرقام لبريدك.\nافتح إيميلك وأدخل الكود هنا.',
                    style:
                        DS.body.copyWith(color: DS.textSecondary, height: 1.6),
                    textAlign: TextAlign.center,
                  ),
                ),

                const Spacer(flex: 1),

                // ── OTP Boxes ──
                FadeSlideIn(
                  delay: const Duration(milliseconds: 200),
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, _buildOtpBox),
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                // ── زر التحقق ──
                FadeSlideIn(
                  delay: const Duration(milliseconds: 250),
                  child: GradientButton(
                    label: 'تحقق من الكود ✅',
                    icon: Icons.verified_rounded,
                    isLoading: _verifying,
                    onPressed: (_verifying || _enteredOtp.length < 6)
                        ? null
                        : _verifyOtp,
                  ),
                ),

                const SizedBox(height: 16),

                // ── إعادة الإرسال ──
                FadeSlideIn(
                  delay: const Duration(milliseconds: 300),
                  child: GestureDetector(
                    onTap: (_resendTimer > 0 || _resending) ? null : _resendOtp,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: (_resendTimer > 0 || _resending)
                            ? DS.bgElevated
                            : DS.bgCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: (_resendTimer > 0 || _resending)
                              ? DS.border
                              : DS.purple.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Center(
                        child: _resending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: DS.purple, strokeWidth: 2))
                            : _resendTimer > 0
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                        const Icon(Icons.timer_rounded,
                                            size: 16, color: DS.textMuted),
                                        const SizedBox(width: 8),
                                        Text('إعادة الإرسال بعد $_resendTimerث',
                                            style: DS.label
                                                .copyWith(color: DS.textMuted)),
                                      ])
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                        const Icon(Icons.send_rounded,
                                            size: 16, color: DS.purple),
                                        const SizedBox(width: 8),
                                        Text('إعادة إرسال الكود',
                                            style: DS.label
                                                .copyWith(color: DS.purple)),
                                      ]),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'تغيير البريد الإلكتروني',
                    style: DS.bodySmall.copyWith(
                        color: DS.textMuted,
                        decoration: TextDecoration.underline),
                  ),
                ),

                const Spacer(flex: 1),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
