import 'dart:ui';
import 'package:flutter/material.dart';
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
        vsync: this, duration: const Duration(milliseconds: 600));
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
      child: FadeTransition(
        opacity: _fade,
        child: Scaffold(
          backgroundColor: DS.bg,
          body: StreamBuilder<UserModel>(
            stream: _db.streamUser(_uid),
            builder: (ctx, userSnap) {
              final user = userSnap.data;
              return Column(children: [
                Container(
                  height: 220,
                  decoration: const BoxDecoration(gradient: DS.headerGradient),
                  child: Stack(children: [
                    const Positioned(
                        top: -60, left: -40,
                        child: PurpleOrb(size: 240, opacity: 0.25)),
                    SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: DS.purple.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: DS.purple.withValues(alpha: 0.2)),
                                ),
                                child: const Icon(Icons.account_balance_wallet_rounded,
                                    color: DS.purple, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Text('محفظتي', style: DS.titleL.copyWith(fontSize: 22)),
                              const Spacer(),
                              GestureDetector(
                                onTap: _showRechargeSheet,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    gradient: DS.purpleGradient,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: DS.purpleShadow,
                                  ),
                                  child: Row(children: [
                                    const Icon(Icons.add_rounded,
                                        color: Colors.white, size: 18),
                                    const SizedBox(width: 6),
                                    Text('شحن',
                                        style: DS.label.copyWith(color: Colors.white)),
                                  ]),
                                ),
                              ),
                            ]),
                            const SizedBox(height: 24),
                            Row(children: [
                              Expanded(child: _BalanceCard(
                                label: 'الرصيد المتاح',
                                amount: user?.balance ?? 0,
                                icon: Icons.wallet_rounded,
                                color: DS.success,
                              )),
                              const SizedBox(width: 12),
                              Expanded(child: _BalanceCard(
                                label: 'المجمد',
                                amount: user?.blockedBalance ?? 0,
                                icon: Icons.lock_rounded,
                                color: DS.purple,
                              )),
                            ]),
                          ],
                        ),
                      ),
                    ),
                  ]),
                ),
                Expanded(
                  child: StreamBuilder<List<WalletTransaction>>(
                    stream: _db.streamUserTransactions(_uid),
                    builder: (ctx, snap) {
                      if (snap.connectionState == ConnectionState.waiting)
                        return const Center(
                            child: CircularProgressIndicator(color: DS.purple));
                      final txs = snap.data ?? [];
                      if (txs.isEmpty)
                        return const DSEmpty(
                          icon: Icons.receipt_long_rounded,
                          title: 'لا توجد معاملات',
                          subtitle: 'اشحن رصيدك للبدء',
                        );
                      return ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: txs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _TransactionTile(tx: txs[i]),
                      );
                    },
                  ),
                ),
              ]);
            },
          ),
        ),
      ),
    );
  }
}

// ── بطاقة الرصيد ──────────────────────────────────────
class _BalanceCard extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color color;
  const _BalanceCard(
      {required this.label,
        required this.amount,
        required this.icon,
        required this.color});

  @override
  Widget build(BuildContext context) => GlassCard(
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(label, style: DS.bodySmall),
      ]),
      const SizedBox(height: 8),
      Text('${amount.toStringAsFixed(0)} دج',
          style: DS.titleM.copyWith(color: color, fontSize: 20)),
    ]),
  );
}

// ── صف معاملة ──────────────────────────────────────────
class _TransactionTile extends StatelessWidget {
  final WalletTransaction tx;
  const _TransactionTile({required this.tx});

  static const _methodIcons = {
    DepositMethod.ccp:          Icons.post_add_rounded,
    DepositMethod.baridiMob:    Icons.phone_android_rounded,
    DepositMethod.rechargeCode: Icons.qr_code_rounded,
    DepositMethod.card:         Icons.credit_card_rounded,
  };

  static const _methodLabels = {
    DepositMethod.ccp:          'CCP',
    DepositMethod.baridiMob:    'بريدي موب',
    DepositMethod.rechargeCode: 'كود شحن',
    DepositMethod.card:         'بطاقة بنكية',
  };

  Color get _statusColor => switch (tx.status) {
    DepositStatus.approved => DS.success,
    DepositStatus.rejected => DS.error,
    DepositStatus.pending  => const Color(0xFFF59E0B),
  };

  String get _statusLabel => switch (tx.status) {
    DepositStatus.approved => 'تم التأكيد',
    DepositStatus.rejected => 'مرفوض',
    DepositStatus.pending  => 'قيد الانتظار',
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_methodLabels[tx.method]!, style: DS.label),
          const SizedBox(height: 2),
          Text(
              '${tx.createdAt.day}/${tx.createdAt.month}/${tx.createdAt.year}',
              style: DS.bodySmall),
        ]),
      ),
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
              style: DS.bodySmall
                  .copyWith(color: _statusColor, fontSize: 11)),
        ),
      ]),
    ]),
  );
}

// ══════════════════════════════════════════════════════
// RechargeSheet — CCP و CIB فقط
// ══════════════════════════════════════════════════════
class RechargeSheet extends StatefulWidget {
  final FirestoreService db;
  final String uid;
  const RechargeSheet({super.key, required this.db, required this.uid});
  @override
  State<RechargeSheet> createState() => _RechargeSheetState();
}

class _RechargeSheetState extends State<RechargeSheet> {
  // فقط طريقتين
  _PayMethod _method = _PayMethod.ccp;

  final _amountCtrl     = TextEditingController();
  final _cardNameCtrl   = TextEditingController();
  final _cardNumberCtrl = TextEditingController();
  final _cardExpiryCtrl = TextEditingController();
  final _cardCvvCtrl    = TextEditingController();

  bool    _isLoading      = false;
  bool    _uploadingProof = false;
  String? _proofUrl;
  String? _generatedOtp;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _cardNameCtrl.dispose();
    _cardNumberCtrl.dispose();
    _cardExpiryCtrl.dispose();
    _cardCvvCtrl.dispose();
    super.dispose();
  }

  // ── رفع صورة الوصل (CCP) ──
  Future<void> _pickAndUploadProof() async {
    setState(() => _uploadingProof = true);
    try {
      final img = await ImagePicker()
          .pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (img == null) { setState(() => _uploadingProof = false); return; }
      final bytes = await img.readAsBytes();
      final ref = FirebaseStorage.instance.ref(
        'deposit_proofs/${widget.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
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
        // ── CCP: مبلغ + وصل ──
        final amount = double.tryParse(_amountCtrl.text);
        if (amount == null || amount <= 0) throw Exception('المبلغ غير صالح');
        if (_proofUrl == null) throw Exception('ارفع صورة الوصل أولاً');
        await widget.db.requestDeposit(
          userId:   widget.uid,
          amount:   amount,
          method:   DepositMethod.ccp,
          proofUrl: _proofUrl,
        );
        if (mounted) {
          Navigator.pop(context);
          _snack('تم إرسال طلب الشحن، بانتظار موافقة المدير ⏳');
        }
      } else {
        // ── CIB (بطاقة بنكية): مبلغ + بيانات البطاقة + OTP ──
        final amount = double.tryParse(_amountCtrl.text);
        if (amount == null || amount <= 0) throw Exception('المبلغ غير صالح');
        if (_cardNameCtrl.text.trim().isEmpty)       throw Exception('أدخل الاسم على البطاقة');
        if (_cardNumberCtrl.text.trim().length < 16) throw Exception('رقم البطاقة غير صالح');
        if (_cardExpiryCtrl.text.trim().length < 5)  throw Exception('أدخل تاريخ الانتهاء');
        if (_cardCvvCtrl.text.trim().length < 3)     throw Exception('أدخل رمز CVV');
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

  // ── OTP Dialog للـ CIB ──
  void _showOtpDialog(double amount) {
    final otpInputCtrl = TextEditingController();
    bool verifying = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Directionality(
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
                    border: Border.all(color: DS.border),
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: DS.purple.withValues(alpha: 0.1),
                        border: Border.all(color: DS.purple.withValues(alpha: 0.3)),
                      ),
                      child: const Icon(Icons.sms_rounded, color: DS.purple, size: 30),
                    ),
                    const SizedBox(height: 16),
                    Text('تحقق من الدفع', style: DS.titleM),
                    const SizedBox(height: 8),
                    Text('تم إرسال رمز التحقق إلى هاتفك',
                        style: DS.body, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    // SMS وهمي
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: DS.bgElevated,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: DS.purple.withValues(alpha: 0.2)),
                      ),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: DS.purple.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.credit_card_rounded,
                              color: DS.purple, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('CIB Algérie', style: DS.label),
                            const SizedBox(height: 4),
                            RichText(
                              text: TextSpan(
                                style: DS.body,
                                children: [
                                  const TextSpan(text: 'رمز التحقق: '),
                                  TextSpan(
                                    text: _generatedOtp,
                                    style: DS.titleM.copyWith(
                                        color: DS.purple, letterSpacing: 4),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text('صالح لمدة 5 دقائق',
                                style: DS.bodySmall.copyWith(color: DS.textMuted)),
                          ]),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: otpInputCtrl,
                      keyboardType: TextInputType.number,
                      textDirection: TextDirection.ltr,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: DS.titleM.copyWith(letterSpacing: 8),
                      decoration: InputDecoration(
                        hintText: '• • • • • •',
                        counterText: '',
                        filled: true,
                        fillColor: DS.bgField,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: DS.border),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(children: [
                      Expanded(child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('إلغاء'),
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: GradientButton(
                        label: 'تأكيد',
                        isLoading: verifying,
                        onPressed: verifying ? null : () async {
                          if (otpInputCtrl.text.trim() != _generatedOtp) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('❌ رمز التحقق غير صحيح'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          setDialogState(() => verifying = true);
                          try {
                            await widget.db.requestDepositWithCard(
                              userId:     widget.uid,
                              amount:     amount,
                              cardName:   _cardNameCtrl.text.trim(),
                              cardNumber: _cardNumberCtrl.text.trim(),
                              cardExpiry: _cardExpiryCtrl.text.trim(),
                            );
                            if (mounted) {
                              Navigator.pop(ctx);
                              Navigator.pop(context);
                              _showSuccessDialog(amount);
                            }
                          } catch (e) {
                            setDialogState(() => verifying = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('خطأ: $e'),
                                  backgroundColor: DS.error),
                            );
                          }
                        },
                      )),
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
                  border: Border.all(color: DS.border),
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: DS.success.withValues(alpha: 0.1),
                      border: Border.all(color: DS.success.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.check_circle_rounded,
                        color: DS.success, size: 36),
                  ),
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
                    label: 'حسناً',
                    onPressed: () => Navigator.pop(context),
                  ),
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
        backgroundColor: isError ? DS.error : DS.success));
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
            padding: EdgeInsets.fromLTRB(
                24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 32),
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                // Handle
                Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                        color: DS.border,
                        borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 20),
                Text('شحن الرصيد', style: DS.titleM),
                const SizedBox(height: 20),

                // ── اختيار الطريقة: CCP أو CIB ──
                Row(children: [
                  Expanded(child: _MethodTab(
                    label: 'CCP',
                    icon: Icons.post_add_rounded,
                    subtitle: 'حوالة بريدية',
                    selected: _method == _PayMethod.ccp,
                    onTap: () => setState(() => _method = _PayMethod.ccp),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _MethodTab(
                    label: 'CIB',
                    icon: Icons.credit_card_rounded,
                    subtitle: 'بطاقة بنكية',
                    selected: _method == _PayMethod.cib,
                    onTap: () => setState(() => _method = _PayMethod.cib),
                  )),
                ]),
                const SizedBox(height: 24),

                // ── حقل المبلغ (مشترك) ──
                TextField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'المبلغ (دج)',
                    prefixIcon: Icon(Icons.payments_rounded),
                  ),
                ),
                const SizedBox(height: 16),

                // ── حقول CCP: معلومات الحساب + رفع الوصل ──
                if (_method == _PayMethod.ccp) ...[
                  _CcpInfoCard(),
                  const SizedBox(height: 16),
                  _ProofUploadButton(
                    proofUrl: _proofUrl,
                    uploading: _uploadingProof,
                    onTap: _pickAndUploadProof,
                  ),
                ],

                // ── حقول CIB: بيانات البطاقة ──
                if (_method == _PayMethod.cib) ...[
                  TextField(
                    controller: _cardNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'الاسم على البطاقة',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _cardNumberCtrl,
                    keyboardType: TextInputType.number,
                    textDirection: TextDirection.ltr,
                    maxLength: 16,
                    decoration: const InputDecoration(
                      labelText: 'رقم البطاقة',
                      prefixIcon: Icon(Icons.credit_card_rounded),
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: TextField(
                      controller: _cardExpiryCtrl,
                      keyboardType: TextInputType.number,
                      textDirection: TextDirection.ltr,
                      maxLength: 5,
                      decoration: const InputDecoration(
                        labelText: 'MM/YY',
                        prefixIcon: Icon(Icons.calendar_today_rounded),
                        counterText: '',
                      ),
                      onChanged: (v) {
                        if (v.length == 2 && !v.contains('/')) {
                          _cardExpiryCtrl.text = '$v/';
                          _cardExpiryCtrl.selection =
                              TextSelection.collapsed(offset: 3);
                        }
                      },
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(
                      controller: _cardCvvCtrl,
                      keyboardType: TextInputType.number,
                      textDirection: TextDirection.ltr,
                      maxLength: 3,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'CVV',
                        prefixIcon: Icon(Icons.lock_outline_rounded),
                        counterText: '',
                      ),
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
    );
  }
}

// ── Enum الطريقتين فقط ──
enum _PayMethod { ccp, cib }

// ── Tab الطريقة ──
class _MethodTab extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _MethodTab({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

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
        border: Border.all(
            color: selected ? DS.purple : DS.border, width: 1.5),
        boxShadow: selected ? DS.purpleShadow : null,
      ),
      child: Column(children: [
        Icon(icon, color: selected ? Colors.white : DS.textSecondary, size: 26),
        const SizedBox(height: 8),
        Text(label,
            style: DS.titleS.copyWith(
                color: selected ? Colors.white : DS.textPrimary)),
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

// ── معلومات حساب CCP ──
class _CcpInfoCard extends StatelessWidget {
  const _CcpInfoCard();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: DS.bgElevated,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: DS.border),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.info_outline_rounded, color: DS.purple, size: 16),
        const SizedBox(width: 8),
        Text('بيانات الحساب البريدي (CCP)', style: DS.label),
      ]),
      const SizedBox(height: 14),
      _InfoRow(label: 'الاسم', value: 'AMS AUCTIONS DZ'),
      _InfoRow(label: 'رقم الحساب', value: '0023456789'),
      _InfoRow(label: 'المفتاح', value: '22'),
      _InfoRow(label: 'RIP', value: '00799999002345678922'),
    ]),
  );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Text('$label: ', style: DS.bodySmall.copyWith(color: DS.textMuted)),
      Expanded(
        child: Text(value,
            style: DS.bodySmall.copyWith(
                color: DS.textPrimary, fontWeight: FontWeight.w700)),
      ),
      GestureDetector(
        onTap: () {
          // TODO: copy to clipboard
        },
        child: const Icon(Icons.copy_rounded, size: 14, color: DS.purple),
      ),
    ]),
  );
}

// ── زر رفع الوصل ──
class _ProofUploadButton extends StatelessWidget {
  final String? proofUrl;
  final bool uploading;
  final VoidCallback onTap;
  const _ProofUploadButton(
      {required this.proofUrl,
        required this.uploading,
        required this.onTap});

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
        border: Border.all(
            color: proofUrl != null ? DS.success : DS.border),
      ),
      child: uploading
          ? const Center(
          child: SizedBox(
              width: 24, height: 24,
              child: CircularProgressIndicator(
                  color: DS.purple, strokeWidth: 2)))
          : Column(children: [
        Icon(
          proofUrl != null
              ? Icons.check_circle_rounded
              : Icons.upload_rounded,
          color: proofUrl != null ? DS.success : DS.textSecondary,
          size: 30,
        ),
        const SizedBox(height: 8),
        Text(
          proofUrl != null ? 'تم رفع الوصل ✅' : 'ارفع صورة الوصل',
          style: DS.body.copyWith(
              color: proofUrl != null
                  ? DS.success
                  : DS.textSecondary),
        ),
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