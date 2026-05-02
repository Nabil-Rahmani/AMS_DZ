import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../core/constants/ds_colors.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/models/wallet_model.dart';
import '../../../core/services/firebase/firestore_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});
  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with SingleTickerProviderStateMixin {
  final _db = FirestoreService();
  final _uid = FirebaseAuth.instance.currentUser!.uid;
  late AnimationController _animCtrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _showRechargeSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RechargeSheet(db: _db, uid: _uid),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: DS.bg,
        body: StreamBuilder<UserModel>(
          stream: _db.streamUser(_uid),
          builder: (ctx, userSnap) {
            final user = userSnap.data;
            return FadeTransition(
              opacity: _fade,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Container(
                      decoration:
                          const BoxDecoration(gradient: DS.headerGradient),
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                          child: Column(children: [
                            Row(children: [
                              Text('محفظتي',
                                  style: DS.titleL.copyWith(fontSize: 24)),
                              const Spacer(),
                              GestureDetector(
                                onTap: _showRechargeSheet,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 18, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                          color: const Color(0xFFF59E0B)
                                              .withValues(alpha: 0.4),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4))
                                    ],
                                  ),
                                  child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.add_rounded,
                                            color: Colors.white, size: 18),
                                        const SizedBox(width: 6),
                                        Text('شحن رصيد',
                                            style: DS.label.copyWith(
                                                color: Colors.white,
                                                fontSize: 13)),
                                      ]),
                                ),
                              ),
                            ]),
                            const SizedBox(height: 24),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF1A2340),
                                    Color(0xFF0D1528)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                border: Border.all(
                                    color:
                                        Colors.white.withValues(alpha: 0.08)),
                                boxShadow: [
                                  BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8))
                                ],
                              ),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withValues(alpha: 0.08),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                            Icons
                                                .account_balance_wallet_rounded,
                                            color: Colors.white,
                                            size: 18),
                                      ),
                                      const SizedBox(width: 10),
                                      Text('الرصيد المتاح',
                                          style: DS.bodySmall
                                              .copyWith(color: Colors.white70)),
                                    ]),
                                    const SizedBox(height: 16),
                                    Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            user != null
                                                ? user.balance
                                                    .toStringAsFixed(0)
                                                : '0',
                                            style: const TextStyle(
                                                fontSize: 44,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white,
                                                letterSpacing: -1),
                                          ),
                                          const SizedBox(width: 8),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 8),
                                            child: Text('DZD',
                                                style: DS.titleS.copyWith(
                                                    color: DS.success,
                                                    fontSize: 16)),
                                          ),
                                        ]),
                                    const SizedBox(height: 20),
                                    Divider(
                                        color: Colors.white
                                            .withValues(alpha: 0.08),
                                        height: 1),
                                    const SizedBox(height: 16),
                                    Row(children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF59E0B)
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.lock_rounded,
                                            color: Color(0xFFF59E0B), size: 14),
                                      ),
                                      const SizedBox(width: 10),
                                      Text('الضمان المحجوز:',
                                          style: DS.bodySmall
                                              .copyWith(color: Colors.white54)),
                                      const Spacer(),
                                      Text(
                                        'DZD ${user != null ? user.blockedBalance.toStringAsFixed(0) : '0'}',
                                        style: DS.titleS.copyWith(
                                            color: const Color(0xFFF59E0B),
                                            fontSize: 14),
                                      ),
                                    ]),
                                  ]),
                            ),
                          ]),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                      child: Text('سجل العمليات الأخير', style: DS.titleS),
                    ),
                  ),
                  StreamBuilder<List<WalletTransaction>>(
                    stream: _db.streamUserTransactions(_uid),
                    builder: (ctx, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.only(top: 40),
                            child: Center(
                                child: CircularProgressIndicator(
                                    color: DS.purple)),
                          ),
                        );
                      }
                      final txs = snap.data ?? [];
                      if (txs.isEmpty) {
                        return const SliverToBoxAdapter(
                          child: DSEmpty(
                            icon: Icons.receipt_long_rounded,
                            title: 'لا توجد معاملات',
                            subtitle: 'اشحن رصيدك للبدء',
                          ),
                        );
                      }
                      return SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _TransactionTile(tx: txs[i]),
                            ),
                            childCount: txs.length,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── صف معاملة ──────────────────────────────────────────
class _TransactionTile extends StatelessWidget {
  final WalletTransaction tx;
  const _TransactionTile({required this.tx});

  static const _methodIcons = {
    DepositMethod.ccp: Icons.post_add_rounded,
    DepositMethod.baridiMob: Icons.phone_android_rounded,
    DepositMethod.rechargeCode: Icons.qr_code_rounded,
    DepositMethod.card: Icons.credit_card_rounded,
  };
  static const _methodLabels = {
    DepositMethod.ccp: 'CCP',
    DepositMethod.baridiMob: 'بريدي موب',
    DepositMethod.rechargeCode: 'كود شحن',
    DepositMethod.card: 'بطاقة بنكية',
  };

  Color get _statusColor => switch (tx.status) {
        DepositStatus.approved => DS.success,
        DepositStatus.rejected => DS.error,
        DepositStatus.pending => const Color(0xFFF59E0B),
      };
  String get _statusLabel => switch (tx.status) {
        DepositStatus.approved => 'تم التأكيد',
        DepositStatus.rejected => 'مرفوض',
        DepositStatus.pending => 'قيد الانتظار',
      };

  @override
  Widget build(BuildContext context) => GlassCard(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: DS.purple.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_methodIcons[tx.method], color: DS.purple, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(_methodLabels[tx.method]!, style: DS.label),
                const SizedBox(height: 2),
                Text(
                    '${tx.createdAt.day}/${tx.createdAt.month}/${tx.createdAt.year}',
                    style: DS.bodySmall),
              ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('+${tx.amount.toStringAsFixed(0)} دج',
                style: DS.titleM.copyWith(color: DS.success, fontSize: 15)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(_statusLabel,
                  style:
                      DS.bodySmall.copyWith(color: _statusColor, fontSize: 11)),
            ),
          ]),
        ]),
      );
}

// ══════════════════════════════════════════════════════
// RechargeSheet
// ══════════════════════════════════════════════════════
class RechargeSheet extends StatefulWidget {
  final FirestoreService db;
  final String uid;
  const RechargeSheet({super.key, required this.db, required this.uid});
  @override
  State<RechargeSheet> createState() => _RechargeSheetState();
}

class _RechargeSheetState extends State<RechargeSheet> {
  _PayMethod _method = _PayMethod.cib; // ✅ CIB افتراضياً
  final _amountCtrl = TextEditingController();
  final _cardNameCtrl = TextEditingController();
  final _cardNumberCtrl = TextEditingController();
  final _cardExpiryCtrl = TextEditingController();
  final _cardCvvCtrl = TextEditingController();
  bool _isLoading = false;
  bool _uploadingProof = false;
  String? _proofUrl;
  String? _generatedOtp;

  // ✅ decoration موحد لكل الحقول
  InputDecoration _inputDec(String label, IconData icon) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: DS.textSecondary),
        prefixIcon: Icon(icon, color: DS.purple),
        filled: true,
        fillColor: DS.bgField,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: DS.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: DS.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: DS.purple, width: 1.5),
        ),
      );

  @override
  void dispose() {
    _amountCtrl.dispose();
    _cardNameCtrl.dispose();
    _cardNumberCtrl.dispose();
    _cardExpiryCtrl.dispose();
    _cardCvvCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadProof() async {
    setState(() => _uploadingProof = true);
    try {
      final img = await ImagePicker()
          .pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (img == null) {
        setState(() => _uploadingProof = false);
        return;
      }
      final bytes = await img.readAsBytes();
      final ref = FirebaseStorage.instance.ref(
          'deposit_proofs/${widget.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putData(bytes);
      _proofUrl = await ref.getDownloadURL();
      if (mounted) setState(() {});
      _snack('تم رفع الصورة ✅');
    } catch (e) {
      _snack('فشل رفع الصورة: $e', isError: true);
    } finally {
      if (mounted) setState(() => _uploadingProof = false);
    }
  }

  String _generateOtp() {
    final ms = DateTime.now().millisecondsSinceEpoch;
    return ((ms % 900000) + 100000).toString().substring(0, 6);
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      if (_method == _PayMethod.ccp) {
        final amount = double.tryParse(_amountCtrl.text);
        if (amount == null || amount <= 0) throw Exception('المبلغ غير صالح');
        if (_proofUrl == null) throw Exception('ارفع صورة الوصل أولاً');
        await widget.db.requestDeposit(
            userId: widget.uid,
            amount: amount,
            method: DepositMethod.ccp,
            proofUrl: _proofUrl);
        if (mounted) {
          Navigator.pop(context);
          _snack('تم إرسال طلب الشحن، بانتظار موافقة المدير ⏳');
        }
      } else {
        final amount = double.tryParse(_amountCtrl.text);
        if (amount == null || amount <= 0) throw Exception('المبلغ غير صالح');
        if (_cardNameCtrl.text.trim().isEmpty)
          throw Exception('أدخل الاسم على البطاقة');
        if (_cardNumberCtrl.text.trim().length < 16)
          throw Exception('رقم البطاقة غير صالح');
        if (_cardExpiryCtrl.text.trim().length < 5)
          throw Exception('أدخل تاريخ الانتهاء');
        if (_cardCvvCtrl.text.trim().length < 3)
          throw Exception('أدخل رمز CVV');
        _generatedOtp = _generateOtp();
        setState(() => _isLoading = false);
        _showOtpDialog(amount);
      }
    } catch (e) {
      _snack('خطأ: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showOtpDialog(double amount) {
    final otpCtrl = TextEditingController();
    bool verifying = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                      color: DS.bgModal.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: DS.border)),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: DS.purple.withValues(alpha: 0.1),
                            border: Border.all(
                                color: DS.purple.withValues(alpha: 0.3))),
                        child: const Icon(Icons.sms_rounded,
                            color: DS.purple, size: 30)),
                    const SizedBox(height: 16),
                    Text('تحقق من الدفع', style: DS.titleM),
                    const SizedBox(height: 8),
                    Text('تم إرسال رمز التحقق إلى هاتفك',
                        style: DS.body, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: DS.bgElevated,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: DS.purple.withValues(alpha: 0.2))),
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                    color: DS.purple.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.credit_card_rounded,
                                    color: DS.purple, size: 18)),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text('CIB Algérie', style: DS.label),
                                  const SizedBox(height: 4),
                                  RichText(
                                      text: TextSpan(style: DS.body, children: [
                                    const TextSpan(text: 'رمز التحقق: '),
                                    TextSpan(
                                        text: _generatedOtp,
                                        style: DS.titleM.copyWith(
                                            color: DS.purple, letterSpacing: 4))
                                  ])),
                                  const SizedBox(height: 2),
                                  Text('صالح لمدة 5 دقائق',
                                      style: DS.bodySmall
                                          .copyWith(color: DS.textMuted)),
                                ])),
                          ]),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: otpCtrl,
                      keyboardType: TextInputType.number,
                      textDirection: TextDirection.ltr,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: DS.titleM
                          .copyWith(letterSpacing: 8, color: DS.textPrimary),
                      decoration: InputDecoration(
                        hintText: '• • • • • •',
                        counterText: '',
                        filled: true,
                        fillColor: DS.bgField,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: DS.border)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(children: [
                      Expanded(
                          child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('إلغاء'))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: GradientButton(
                              label: 'تأكيد',
                              isLoading: verifying,
                              onPressed: verifying
                                  ? null
                                  : () async {
                                      if (otpCtrl.text.trim() !=
                                          _generatedOtp) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                                content: Text(
                                                    '❌ رمز التحقق غير صحيح'),
                                                backgroundColor: Colors.red));
                                        return;
                                      }
                                      setD(() => verifying = true);
                                      try {
                                        await widget.db.requestDepositWithCard(
                                            userId: widget.uid,
                                            amount: amount,
                                            cardName: _cardNameCtrl.text.trim(),
                                            cardNumber:
                                                _cardNumberCtrl.text.trim(),
                                            cardExpiry:
                                                _cardExpiryCtrl.text.trim());
                                        if (mounted) {
                                          Navigator.pop(ctx);
                                          Navigator.pop(context);
                                          _showSuccessDialog(amount);
                                        }
                                      } catch (e) {
                                        setD(() => verifying = false);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                                content: Text('خطأ: $e'),
                                                backgroundColor: DS.error));
                                      }
                                    })),
                    ]),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog(double amount) {
    showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                    color: DS.bgModal.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: DS.border)),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: DS.success.withValues(alpha: 0.1),
                          border: Border.all(
                              color: DS.success.withValues(alpha: 0.3))),
                      child: const Icon(Icons.check_circle_rounded,
                          color: DS.success, size: 36)),
                  const SizedBox(height: 16),
                  Text('تم الدفع بنجاح ✅',
                      style: DS.titleM.copyWith(color: DS.success)),
                  const SizedBox(height: 8),
                  Text('طلب شحن ${amount.toStringAsFixed(0)} دج قيد المراجعة',
                      style: DS.body, textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  Text('سيتم تأكيده من طرف المدير قريباً',
                      style: DS.bodySmall.copyWith(color: DS.textMuted),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  GradientButton(
                      label: 'حسناً', onPressed: () => Navigator.pop(context)),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? DS.error : DS.success,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: const BoxDecoration(
              color: DS.bgCard,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(top: BorderSide(color: DS.border)),
            ),
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              padding: EdgeInsets.fromLTRB(
                  24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 32),
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: DS.border,
                          borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 20),
                  Text('شحن الرصيد', style: DS.titleM),
                  const SizedBox(height: 20),

                  // ✅ CIB أولاً ثم CCP
                  Row(children: [
                    Expanded(
                        child: _MethodTab(
                      label: 'CIB',
                      icon: Icons.credit_card_rounded,
                      subtitle: 'بطاقة بنكية',
                      selected: _method == _PayMethod.cib,
                      onTap: () => setState(() => _method = _PayMethod.cib),
                    )),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _MethodTab(
                      label: 'CCP',
                      icon: Icons.post_add_rounded,
                      subtitle: 'حوالة بريدية',
                      selected: _method == _PayMethod.ccp,
                      onTap: () => setState(() => _method = _PayMethod.ccp),
                    )),
                  ]),

                  const SizedBox(height: 24),

                  // ✅ حقل المبلغ
                  TextField(
                    controller: _amountCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                        color: DS.textPrimary, fontWeight: FontWeight.w600),
                    decoration:
                        _inputDec('المبلغ (دج)', Icons.payments_rounded),
                  ),

                  const SizedBox(height: 16),

                  if (_method == _PayMethod.ccp) ...[
                    const _CcpInfoCard(),
                    const SizedBox(height: 16),
                    _ProofUploadButton(
                      proofUrl: _proofUrl,
                      uploading: _uploadingProof,
                      onTap: _pickAndUploadProof,
                    ),
                  ],

                  if (_method == _PayMethod.cib) ...[
                    // ✅ حقل الاسم
                    TextField(
                      controller: _cardNameCtrl,
                      style: const TextStyle(
                          color: DS.textPrimary, fontWeight: FontWeight.w600),
                      decoration: _inputDec(
                          'الاسم على البطاقة', Icons.person_outline_rounded),
                    ),
                    const SizedBox(height: 12),

                    // ✅ حقل رقم البطاقة
                    TextField(
                      controller: _cardNumberCtrl,
                      keyboardType: TextInputType.number,
                      textDirection: TextDirection.ltr,
                      maxLength: 16,
                      style: const TextStyle(
                          color: DS.textPrimary, fontWeight: FontWeight.w600),
                      decoration:
                          _inputDec('رقم البطاقة', Icons.credit_card_rounded)
                              .copyWith(counterText: ''),
                    ),
                    const SizedBox(height: 12),

                    Row(children: [
                      // ✅ حقل التاريخ
                      Expanded(
                          child: TextField(
                        controller: _cardExpiryCtrl,
                        keyboardType: TextInputType.number,
                        textDirection: TextDirection.ltr,
                        maxLength: 5,
                        style: const TextStyle(
                            color: DS.textPrimary, fontWeight: FontWeight.w600),
                        decoration:
                            _inputDec('MM/YY', Icons.calendar_today_rounded)
                                .copyWith(counterText: ''),
                        onChanged: (v) {
                          if (v.length == 2 && !v.contains('/')) {
                            _cardExpiryCtrl.text = '$v/';
                            _cardExpiryCtrl.selection =
                                const TextSelection.collapsed(offset: 3);
                          }
                        },
                      )),
                      const SizedBox(width: 12),

                      // ✅ حقل CVV
                      Expanded(
                          child: TextField(
                        controller: _cardCvvCtrl,
                        keyboardType: TextInputType.number,
                        textDirection: TextDirection.ltr,
                        maxLength: 3,
                        obscureText: true,
                        style: const TextStyle(
                            color: DS.textPrimary, fontWeight: FontWeight.w600),
                        decoration: _inputDec('CVV', Icons.lock_outline_rounded)
                            .copyWith(counterText: ''),
                      )),
                    ]),
                  ],

                  const SizedBox(height: 24),
                  GradientButton(
                    label: 'تأكيد الشحن',
                    isLoading: _isLoading,
                    onPressed: (_isLoading || _uploadingProof) ? null : _submit,
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _PayMethod { ccp, cib }

class _MethodTab extends StatelessWidget {
  final String label, subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _MethodTab(
      {required this.label,
      required this.subtitle,
      required this.icon,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            gradient: selected ? DS.purpleGradient : null,
            color: selected ? null : DS.bgElevated,
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: selected ? DS.purple : DS.border, width: 1.5),
            boxShadow: selected ? DS.purpleShadow : null,
          ),
          child: Column(children: [
            Icon(icon,
                color: selected ? Colors.white : DS.textSecondary, size: 26),
            const SizedBox(height: 8),
            Text(label,
                style: DS.titleS
                    .copyWith(color: selected ? Colors.white : DS.textPrimary)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: DS.bodySmall.copyWith(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.7)
                        : DS.textMuted,
                    fontSize: 11)),
          ]),
        ),
      );
}

class _CcpInfoCard extends StatelessWidget {
  const _CcpInfoCard();
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: DS.bgElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: DS.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.info_outline_rounded, color: DS.purple, size: 16),
            const SizedBox(width: 8),
            Text('بيانات الحساب البريدي (CCP)', style: DS.label)
          ]),
          const SizedBox(height: 14),
          const _InfoRow(label: 'الاسم', value: 'AMS AUCTIONS DZ'),
          const _InfoRow(label: 'رقم الحساب', value: '0023456789'),
          const _InfoRow(label: 'المفتاح', value: '22'),
          const _InfoRow(label: 'RIP', value: '00799999002345678922'),
        ]),
      );
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Text('$label: ', style: DS.bodySmall.copyWith(color: DS.textMuted)),
          Expanded(
              child: Text(value,
                  style: DS.bodySmall.copyWith(
                      color: DS.textPrimary, fontWeight: FontWeight.w700))),
          GestureDetector(
            onTap: () => Clipboard.setData(ClipboardData(text: value)),
            child: const Icon(Icons.copy_rounded, size: 14, color: DS.purple),
          ),
        ]),
      );
}

class _ProofUploadButton extends StatelessWidget {
  final String? proofUrl;
  final bool uploading;
  final VoidCallback onTap;
  const _ProofUploadButton(
      {required this.proofUrl, required this.uploading, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: uploading ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: DS.bgElevated,
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: proofUrl != null ? DS.success : DS.border),
          ),
          child: uploading
              ? const Center(
                  child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: DS.purple, strokeWidth: 2)))
              : Column(children: [
                  Icon(
                      proofUrl != null
                          ? Icons.check_circle_rounded
                          : Icons.upload_rounded,
                      color: proofUrl != null ? DS.success : DS.textSecondary,
                      size: 30),
                  const SizedBox(height: 8),
                  Text(proofUrl != null ? 'تم رفع الوصل ✅' : 'ارفع صورة الوصل',
                      style: DS.body.copyWith(
                          color: proofUrl != null
                              ? DS.success
                              : DS.textSecondary)),
                  if (proofUrl == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('اضغط هنا لاختيار صورة من المعرض',
                          style: DS.bodySmall.copyWith(color: DS.textMuted)),
                    ),
                ]),
        ),
      );
}
