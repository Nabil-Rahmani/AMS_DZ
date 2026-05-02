import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:auction_app2/core/services/notification_service.dart';
import '../../../core/constants/ds_colors.dart';
import '../../../core/widgets/ds_widgets.dart';

class KycUploadScreen extends StatefulWidget {
  const KycUploadScreen({super.key});

  @override
  State<KycUploadScreen> createState() => _KycUploadScreenState();
}

class _KycUploadScreenState extends State<KycUploadScreen>
    with SingleTickerProviderStateMixin {
  final _picker = ImagePicker();
  bool _isLoading  = false;
  bool _loadingDoc = true;
  String _accountType = 'individual';

  late AnimationController _animCtrl;
  late Animation<double>   _fade;

  Map<String, _DocItem> _docs = {};

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 600),
    );
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
    _animCtrl.forward();
    _loadAccountType();
  }

  Future<void> _loadAccountType() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final doc = await FirebaseFirestore.instance
          .collection('users').doc(uid).get();
      final type = doc.data()?['accountType'] as String? ?? 'individual';
      setState(() {
        _accountType = type;
        _docs        = _buildDocs(type);
        _loadingDoc  = false;
      });
    } catch (_) {
      setState(() {
        _docs       = _buildDocs('individual');
        _loadingDoc = false;
      });
    }
  }

  Map<String, _DocItem> _buildDocs(String accountType) {
    final isCompany = accountType == 'company';
    return {
      'national_id': _DocItem(
        label:    'بطاقة التعريف الوطنية',
        icon:     Icons.badge_rounded,
        required: true,
      ),
      if (isCompany)
        'commercial_register': _DocItem(
          label:    'السجل التجاري',
          icon:     Icons.business_rounded,
          required: true,
        ),
      'product_docs': _DocItem(
        label:    'وثائق المنتج',
        icon:     Icons.description_rounded,
        required: true,
      ),
      'no_lien_certificate': _DocItem(
        label:    'شهادة عدم الرهن (سيارات/عقارات)',
        icon:     Icons.gavel_rounded,
        required: false,
      ),
    };
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(String docKey) async {
    final source = await _showSourceDialog();
    if (source == null) return;
    final picked = await _picker.pickImage(
      source:       source,
      imageQuality: 80,
      maxWidth:     1200,
    );
    if (picked == null) return;
    setState(() => _docs[docKey]!.file = File(picked.path));
  }

  Future<ImageSource?> _showSourceDialog() {
    return showModalBottomSheet<ImageSource>(
      context:          context,
      backgroundColor:  Colors.transparent,
      isScrollControlled: true,
      builder: (_) => GlassCard(
        borderRadius: 32,
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color:        DS.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text('إضافة وثيقة', style: DS.titleM),
            const SizedBox(height: 8),
            Text('اختر مصدر الصورة المناسب', style: DS.bodySmall),
            const SizedBox(height: 32),
            Row(children: [
              Expanded(child: _SourceButton(
                icon:  Icons.camera_alt_rounded,
                label: 'كاميرا',
                onTap: () => Navigator.pop(context, ImageSource.camera),
              )),
              const SizedBox(width: 16),
              Expanded(child: _SourceButton(
                icon:  Icons.photo_library_rounded,
                label: 'المعرض',
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              )),
            ]),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    for (final entry in _docs.entries) {
      if (entry.value.required && entry.value.file == null) {
        _showError('يرجى رفع: ${entry.value.label}');
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      final uid     = FirebaseAuth.instance.currentUser!.uid;
      final storage = FirebaseStorage.instance;
      final Map<String, String> uploadedUrls = {};

      for (final entry in _docs.entries) {
        if (entry.value.file == null) continue;
        final ref = storage.ref('kyc/$uid/${entry.key}.jpg');
        await ref.putFile(entry.value.file!);
        uploadedUrls[entry.key] = await ref.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'kycDocuments':    uploadedUrls,
        'kycStatus':       'pending',
        'kycSubmittedAt':  FieldValue.serverTimestamp(),
      });

      // ✅ إشعار الأدمين
      final userDoc = await FirebaseFirestore.instance
          .collection('users').doc(uid).get();
      final userName = userDoc.data()?['name'] as String? ?? 'منظم';

      final adminSnap = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .limit(1)
          .get();

      if (adminSnap.docs.isNotEmpty) {
        await NotificationService.onKycSubmitted(
          adminId:    adminSnap.docs.first.id,
          sellerName: userName,
          sellerId:   uid,
        );
      }

      if (mounted) {
        _showSuccess('✅ تم إرسال وثائقك للمراجعة');
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      _showError('حدث خطأ: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: DS.error, behavior: SnackBarBehavior.floating),
  );

  void _showSuccess(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: DS.success, behavior: SnackBarBehavior.floating),
  );

  int get _uploadedCount => _docs.values.where((d) => d.file != null).length;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: DS.bg,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 220,
              pinned:          true,
              backgroundColor: DS.bg,
              leading: IconButton(
                icon: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color:  DS.bg.withValues(alpha: 0.5),
                    shape:  BoxShape.circle,
                    border: Border.all(color: DS.border),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: DS.textPrimary),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(fit: StackFit.expand, children: [
                  Container(decoration: const BoxDecoration(gradient: DS.headerGradient)),
                  const Positioned(
                    top: -50, right: -50,
                    child: PurpleOrb(size: 300, alignment: Alignment.topRight, opacity: 0.4),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 70, 24, 20),
                      child: FadeTransition(
                        opacity: _fade,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment:  MainAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient:     DS.goldGradient,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow:    DS.goldShadow,
                              ),
                              child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 28),
                            ),
                            const SizedBox(height: 16),
                            Text('التحقق من الهوية', style: DS.displayLarge.copyWith(fontSize: 32)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ),

            SliverToBoxAdapter(
              child: _loadingDoc
                  ? const SizedBox(
                height: 300,
                child: Center(child: CircularProgressIndicator(color: DS.purple)),
              )
                  : FadeTransition(
                opacity: _fade,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color:        DS.purple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border:       Border.all(color: DS.purple.withValues(alpha: 0.2)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.person_rounded, size: 16, color: DS.purple),
                          const SizedBox(width: 8),
                          Text(
                            _accountType == 'company' ? 'حساب شركة' : 'شخص طبيعي',
                            style: DS.label.copyWith(color: DS.purple, fontWeight: FontWeight.w700),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 16),
                      GlassCard(
                        padding:      const EdgeInsets.all(20),
                        borderRadius: 24,
                        child: Column(children: [
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color:        DS.info.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.info_outline_rounded, size: 18, color: DS.info),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                'الوثائق المميزة بـ إلزامي مطلوبة. سنقوم بمراجعة طلبك خلال 24 ساعة.',
                                style: DS.bodySmall.copyWith(
                                  color:      DS.textPrimary,
                                  fontWeight: FontWeight.w500,
                                  height:     1.5,
                                ),
                              ),
                            ),
                          ]),
                          const SizedBox(height: 20),
                          Row(children: [
                            Text(
                              '$_uploadedCount/${_docs.length} وثائق مرفوعة',
                              style: DS.label.copyWith(color: DS.purple, fontWeight: FontWeight.w700),
                            ),
                            const Spacer(),
                            Text(
                              'التقدم: ${_docs.isEmpty ? 0 : ((_uploadedCount / _docs.length) * 100).toInt()}%',
                              style: DS.label.copyWith(color: DS.textSecondary),
                            ),
                          ]),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value:           _docs.isEmpty ? 0 : _uploadedCount / _docs.length,
                              backgroundColor: DS.bgElevated,
                              color:           DS.purple,
                              minHeight:       8,
                            ),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 24),
                      const DSSection(title: 'الوثائق المطلوبة'),
                      const SizedBox(height: 16),
                      ..._docs.entries.toList().asMap().entries.map((entry) {
                        final i = entry.key;
                        final e = entry.value;
                        return FadeSlideIn(
                          delay: Duration(milliseconds: 100 + i * 80),
                          child: _DocCard(
                            item:       e.value,
                            isRequired: e.value.required,
                            onTap:      () => _pickImage(e.key),
                            onRemove:   () => setState(() => _docs[e.key]!.file = null),
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 500),
                        child: GradientButton(
                          label:     _isLoading ? 'جاري الرفع...' : 'إرسال للمراجعة',
                          icon:      Icons.send_rounded,
                          isLoading: _isLoading,
                          onPressed: _submit,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocCard extends StatelessWidget {
  final _DocItem     item;
  final bool         isRequired;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _DocCard({
    required this.item,
    required this.isRequired,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final uploaded = item.file != null;

    return GlassCard(
      margin:          const EdgeInsets.only(bottom: 16),
      padding:         EdgeInsets.zero,
      borderRadius:    24,
      backgroundColor: uploaded
          ? DS.success.withValues(alpha: 0.05)
          : DS.bgCard.withValues(alpha: 0.4),
      border: Border.all(
        color: uploaded ? DS.success.withValues(alpha: 0.4) : DS.border,
        width: uploaded ? 1.5 : 1,
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                color:        uploaded ? DS.success.withValues(alpha: 0.15) : DS.purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(item.icon, color: uploaded ? DS.success : DS.purple, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Text(
                      item.label,
                      style: DS.titleS.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isRequired)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color:        DS.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('إلزامي',
                          style: TextStyle(color: DS.error, fontWeight: FontWeight.w800, fontSize: 10)),
                    ),
                ]),
                const SizedBox(height: 6),
                Row(children: [
                  Icon(
                    uploaded ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                    size:  14,
                    color: uploaded ? DS.success : DS.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    uploaded ? 'تم اختيار الملف' : 'يرجى رفع الوثيقة',
                    style: DS.label.copyWith(color: uploaded ? DS.success : DS.textMuted, fontSize: 12),
                  ),
                ]),
              ]),
            ),
            if (uploaded)
              GestureDetector(
                onTap: onRemove,
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color:        DS.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete_outline_rounded, color: DS.error, size: 20),
                ),
              ),
          ]),
        ),
        if (uploaded)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            child: Stack(children: [
              Image.file(item.file!, height: 180, width: double.infinity, fit: BoxFit.cover),
              Positioned.fill(child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, DS.bg.withValues(alpha: 0.8)],
                    begin:  Alignment.topCenter,
                    end:    Alignment.bottomCenter,
                  ),
                ),
              )),
              Positioned(
                bottom: 20, right: 20, left: 20,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color:        Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border:       Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.check_circle_rounded, size: 16, color: DS.success),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('تم اختيار الملف للمراجعة',
                              style: DS.label.copyWith(color: Colors.white, fontSize: 12)),
                        ),
                      ]),
                    ),
                  ),
                ),
              ),
            ]),
          )
        else
          InkWell(
            onTap: onTap,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            child: Container(
              height: 100, width: double.infinity,
              decoration: BoxDecoration(
                color:        DS.purple.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                border:       const Border(top: BorderSide(color: DS.border)),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: DS.purple.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add_photo_alternate_rounded, size: 24, color: DS.purple),
                ),
                const SizedBox(height: 8),
                Text('اضغط لرفع الوثيقة',
                    style: DS.bodySmall.copyWith(color: DS.purple, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
      ]),
    );
  }
}

class _SourceButton extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final VoidCallback onTap;
  const _SourceButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color:        DS.purpleDeep,
          borderRadius: BorderRadius.circular(16),
          border:       Border.all(color: DS.purple.withValues(alpha: 0.2)),
        ),
        child: Column(children: [
          Icon(icon, color: DS.purple, size: 28),
          const SizedBox(height: 6),
          Text(label, style: DS.bodySmall.copyWith(color: DS.purple, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

class _DocItem {
  final String   label;
  final IconData icon;
  final bool     required;
  File?          file;

  _DocItem({required this.label, required this.icon, required this.required});
}