// lib/features/bidder/screens/bidder_id_upload_screen.dart
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/ds_colors.dart';
import '../../../core/widgets/ds_widgets.dart';

class BidderIdUploadScreen extends StatefulWidget {
  /// إذا كان true — يظهر كخطوة إلزامية قبل المزايدة
  final bool isRequired;
  final VoidCallback? onVerified;

  const BidderIdUploadScreen({
    super.key,
    this.isRequired = false,
    this.onVerified,
  });

  @override
  State<BidderIdUploadScreen> createState() => _BidderIdUploadScreenState();
}

class _BidderIdUploadScreenState extends State<BidderIdUploadScreen>
    with SingleTickerProviderStateMixin {
  final _picker = ImagePicker();
  late AnimationController _animCtrl;
  late Animation<double> _fade;

  File? _frontImage;
  File? _backImage;
  bool _isLoading = false;

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

  Future<void> _pickImage(bool isFront) async {
    final source = await _showSourceDialog();
    if (source == null) return;
    final picked = await _picker.pickImage(
        source: source, imageQuality: 85, maxWidth: 1200);
    if (picked == null) return;
    setState(() {
      if (isFront) {
        _frontImage = File(picked.path);
      } else {
        _backImage = File(picked.path);
      }
    });
  }

  Future<ImageSource?> _showSourceDialog() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: const BoxDecoration(
                color: DS.bgCard,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(top: BorderSide(color: DS.border))),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: DS.border,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              Text('اختر مصدر الصورة', style: DS.titleS),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                    child: _SourceBtn(
                        icon: Icons.camera_alt_rounded,
                        label: 'كاميرا',
                        onTap: () =>
                            Navigator.pop(context, ImageSource.camera))),
                const SizedBox(width: 12),
                Expanded(
                    child: _SourceBtn(
                        icon: Icons.photo_library_rounded,
                        label: 'المعرض',
                        onTap: () =>
                            Navigator.pop(context, ImageSource.gallery))),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_frontImage == null) {
      _showError('يرجى رفع الوجه الأمامي لبطاقة الهوية');
      return;
    }
    if (_backImage == null) {
      _showError('يرجى رفع الوجه الخلفي لبطاقة الهوية');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final storage = FirebaseStorage.instance;

      // رفع الوجه الأمامي
      final frontRef = storage.ref('bidder_ids/$uid/front.jpg');
      await frontRef.putFile(_frontImage!);
      final frontUrl = await frontRef.getDownloadURL();

      // رفع الوجه الخلفي
      final backRef = storage.ref('bidder_ids/$uid/back.jpg');
      await backRef.putFile(_backImage!);
      final backUrl = await backRef.getDownloadURL();

      // حفظ في Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'idCardFront': frontUrl,
        'idCardBack': backUrl,
        'idCardSubmittedAt': FieldValue.serverTimestamp(),
        'idCardVerified': false, // الأدمين يوافق لاحقاً
      });

      if (mounted) {
        _showSuccess('✅ تم إرسال بطاقة هويتك للمراجعة');
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          widget.onVerified?.call();
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      _showError('حدث خطأ: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(msg),
            backgroundColor: DS.error,
            behavior: SnackBarBehavior.floating),
      );

  void _showSuccess(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(msg),
            backgroundColor: DS.success,
            behavior: SnackBarBehavior.floating),
      );

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: DS.bg,
        body: CustomScrollView(
          slivers: [
            // ── Header ──
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: DS.bg,
              leading: widget.isRequired
                  ? null
                  : IconButton(
                      icon: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                            color: DS.bg.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                            border: Border.all(color: DS.border)),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            size: 16, color: DS.textPrimary),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(fit: StackFit.expand, children: [
                  Container(
                      decoration:
                          const BoxDecoration(gradient: DS.headerGradient)),
                  const Positioned(
                      top: -50,
                      right: -50,
                      child: PurpleOrb(size: 280, opacity: 0.3)),
                  SafeArea(
                      child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
                    child: FadeTransition(
                      opacity: _fade,
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                  color: DS.purple.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: DS.purple.withValues(alpha: 0.3))),
                              child: const Icon(Icons.badge_rounded,
                                  color: DS.purple, size: 28),
                            ),
                            const SizedBox(height: 14),
                            Text('توثيق الحساب', style: DS.titleXL),
                            Text('صورة بطاقة الهوية', style: DS.bodySmall),
                          ]),
                    ),
                  )),
                ]),
              ),
            ),

            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fade,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Banner ──
                        const DSBanner(
                          message:
                              'لتتمكن من المزايدة، يرجى التقاط صورة واضحة لبطاقة هويتك (الوجه الأمامي والخلفي) للتأكد من هويتك كإجراء أمني.',
                          color: DS.purple,
                          icon: Icons.info_outline_rounded,
                        ),
                        const SizedBox(height: 24),

                        const DSSection(title: 'صور بطاقة الهوية الوطنية'),
                        const SizedBox(height: 16),

                        // ── الوجه الأمامي ──
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 100),
                          child: _IdCardUploadTile(
                            label: 'الوجه الأمامي',
                            subtitle: 'الجهة التي تحتوي على الصورة',
                            icon: Icons.person_rounded,
                            image: _frontImage,
                            onTap: () => _pickImage(true),
                            onRemove: () => setState(() => _frontImage = null),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── الوجه الخلفي ──
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 200),
                          child: _IdCardUploadTile(
                            label: 'الوجه الخلفي',
                            subtitle: 'الجهة التي تحتوي على الباركود',
                            icon: Icons.credit_card_rounded,
                            image: _backImage,
                            onTap: () => _pickImage(false),
                            onRemove: () => setState(() => _backImage = null),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // ── تعليمات ──
                        GlassCard(
                          padding: const EdgeInsets.all(16),
                          borderRadius: 16,
                          backgroundColor: DS.warning.withValues(alpha: 0.05),
                          border: Border.all(
                              color: DS.warning.withValues(alpha: 0.2)),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  const Icon(Icons.tips_and_updates_rounded,
                                      color: DS.warning, size: 16),
                                  const SizedBox(width: 8),
                                  Text('نصائح للحصول على صورة واضحة',
                                      style:
                                          DS.label.copyWith(color: DS.warning)),
                                ]),
                                const SizedBox(height: 12),
                                ...[
                                  'تأكد من وضوح جميع البيانات والأرقام',
                                  'تجنب الإضاءة القوية أو الانعكاس',
                                  'ضع البطاقة على خلفية داكنة',
                                  'التقط الصورة بشكل مستقيم دون إمالة',
                                ].map((tip) => Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Row(children: [
                                        Container(
                                            width: 5,
                                            height: 5,
                                            decoration: const BoxDecoration(
                                                color: DS.warning,
                                                shape: BoxShape.circle)),
                                        const SizedBox(width: 8),
                                        Expanded(
                                            child:
                                                Text(tip, style: DS.bodySmall)),
                                      ]),
                                    )),
                              ]),
                        ),
                        const SizedBox(height: 28),

                        FadeSlideIn(
                          delay: const Duration(milliseconds: 300),
                          child: GradientButton(
                            label:
                                _isLoading ? 'جاري الرفع...' : 'إرسال للتحقق',
                            icon: Icons.send_rounded,
                            isLoading: _isLoading,
                            onPressed: _submit,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── بطاقة رفع صورة ──────────────────────────────────────
class _IdCardUploadTile extends StatelessWidget {
  final String label, subtitle;
  final IconData icon;
  final File? image;
  final VoidCallback onTap, onRemove;

  const _IdCardUploadTile({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.image,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final uploaded = image != null;
    return GlassCard(
      padding: EdgeInsets.zero,
      borderRadius: 20,
      backgroundColor: uploaded
          ? DS.success.withValues(alpha: 0.04)
          : DS.bgCard.withValues(alpha: 0.4),
      border: Border.all(
          color: uploaded ? DS.success.withValues(alpha: 0.4) : DS.border,
          width: uploaded ? 1.5 : 1),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: uploaded
                    ? DS.success.withValues(alpha: 0.12)
                    : DS.purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon,
                  color: uploaded ? DS.success : DS.purple, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(label, style: DS.titleS.copyWith(fontSize: 14)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: DS.bodySmall
                          .copyWith(color: DS.textMuted, fontSize: 12)),
                ])),
            if (uploaded)
              GestureDetector(
                onTap: onRemove,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                      color: DS.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.delete_outline_rounded,
                      color: DS.error, size: 18),
                ),
              ),
          ]),
        ),
        if (uploaded)
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(20)),
            child: Stack(children: [
              Image.file(image!,
                  height: 160, width: double.infinity, fit: BoxFit.cover),
              Positioned.fill(
                  child: Container(
                      decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                Colors.transparent,
                DS.bg.withValues(alpha: 0.7)
              ], begin: Alignment.topCenter, end: Alignment.bottomCenter)))),
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1))),
                        child: Row(children: [
                          const Icon(Icons.check_circle_rounded,
                              size: 14, color: DS.success),
                          const SizedBox(width: 8),
                          Text('تم اختيار الصورة',
                              style: DS.label
                                  .copyWith(color: Colors.white, fontSize: 11))
                        ]),
                      ),
                    )),
              ),
            ]),
          )
        else
          InkWell(
            onTap: onTap,
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(20)),
            child: Container(
              height: 90,
              width: double.infinity,
              decoration: BoxDecoration(
                  color: DS.purple.withValues(alpha: 0.04),
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(20)),
                  border: const Border(top: BorderSide(color: DS.border))),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: DS.purple.withValues(alpha: 0.1),
                            shape: BoxShape.circle),
                        child: const Icon(Icons.add_photo_alternate_rounded,
                            size: 22, color: DS.purple)),
                    const SizedBox(height: 6),
                    Text('اضغط لإضافة الصورة',
                        style: DS.bodySmall.copyWith(
                            color: DS.purple, fontWeight: FontWeight.w600)),
                  ]),
            ),
          ),
      ]),
    );
  }
}

class _SourceBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SourceBtn(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
              color: DS.purpleDeep,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: DS.purple.withValues(alpha: 0.2))),
          child: Column(children: [
            Icon(icon, color: DS.purple, size: 26),
            const SizedBox(height: 6),
            Text(label,
                style: DS.bodySmall
                    .copyWith(color: DS.purple, fontWeight: FontWeight.w600)),
          ]),
        ),
      );
}
