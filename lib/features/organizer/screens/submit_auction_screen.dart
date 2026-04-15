import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:auction_app2/shared/models/auction_model.dart';
import '../../../core/constants/ds_colors.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../widgets/submit_auction_components.dart';

class SubmitAuctionScreen extends StatefulWidget {
  const SubmitAuctionScreen({super.key});
  @override
  State<SubmitAuctionScreen> createState() => _SubmitAuctionScreenState();
}

class _SubmitAuctionScreenState extends State<SubmitAuctionScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController    = TextEditingController();
  final _descController     = TextEditingController();
  final _priceController    = TextEditingController();
  final _locationController = TextEditingController();
  final _picker             = ImagePicker();

  String _category = 'عقارات';
  bool _declarationAccepted = false;
  bool _termsAccepted = false;
  bool _loading = false;

  final List<File> _images = [];
  static const int _maxImages = 6;

  final List<String> _categories = ['عقارات', 'سيارات', 'إلكترونيات', 'أثاث', 'معدات صناعية', 'أخرى'];

  late AnimationController _animCtrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _titleController.dispose(); _descController.dispose();
    _priceController.dispose(); _locationController.dispose();
    _animCtrl.dispose(); super.dispose();
  }

  Future<void> _pickImages() async {
    if (_images.length >= _maxImages) { _showError('الحد الأقصى $_maxImages صور'); return; }
    final source = await _showSourceDialog();
    if (source == null) return;
    if (source == ImageSource.gallery) {
      final picked = await _picker.pickMultiImage(imageQuality: 80, maxWidth: 1200);
      if (picked.isEmpty) return;
      final remaining = _maxImages - _images.length;
      setState(() => _images.addAll(picked.take(remaining).map((e) => File(e.path))));
    } else {
      final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80, maxWidth: 1200);
      if (picked == null) return;
      setState(() => _images.add(File(picked.path)));
    }
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
            decoration: const BoxDecoration(color: DS.bgCard, borderRadius: BorderRadius.vertical(top: Radius.circular(28)), border: Border(top: BorderSide(color: DS.border))),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: DS.border, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Text('إضافة صور', style: DS.titleS),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: ImageSourceButton(icon: Icons.camera_alt_rounded, label: 'كاميرا', onTap: () => Navigator.pop(context, ImageSource.camera))),
                const SizedBox(width: 12),
                Expanded(child: ImageSourceButton(icon: Icons.photo_library_rounded, label: 'المعرض', onTap: () => Navigator.pop(context, ImageSource.gallery))),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  Future<List<String>> _uploadImages(String auctionId) async {
    final storage = FirebaseStorage.instance;
    final List<String> urls = [];
    for (int i = 0; i < _images.length; i++) {
      final ref = storage.ref('auctions/$auctionId/image_$i.jpg');
      await ref.putFile(_images[i]);
      urls.add(await ref.getDownloadURL());
    }
    return urls;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_declarationAccepted) { _showError('يجب قبول التصريح القانوني'); return; }
    if (!_termsAccepted)       { _showError('يجب قبول الشروط والأحكام'); return; }
    if (_images.isEmpty)       { _showError('يرجى إضافة صورة واحدة على الأقل'); return; }
    setState(() => _loading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final organizerName = userDoc.data()?['name'] ?? 'Unknown';
      final docRef = FirebaseFirestore.instance.collection('auctions').doc();
      final imageUrls = await _uploadImages(docRef.id);
      await docRef.set({
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'startingPrice': double.parse(_priceController.text.trim()),
        'currentPrice': double.parse(_priceController.text.trim()),
        'category': _category,
        'location': _locationController.text.trim(),
        'organizerId': uid,
        'organizerName': organizerName,
        'status': AuctionStatus.submitted.name,
        'itemCount': 1,
        'imageUrl': imageUrls.isNotEmpty ? imageUrls.first : null,
        'imageUrls': imageUrls,
        'createdAt': FieldValue.serverTimestamp(),
        'sellerDeclarationAccepted': true,
        'declarationAcceptedAt': FieldValue.serverTimestamp(),
        'termsAccepted': true,
        'inspectionDay': null, 'startTime': null, 'endTime': null,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ تم إرسال طلب المزاد للمراجعة'), backgroundColor: DS.success));
        Navigator.pop(context);
      }
    } catch (e) { _showError('حدث خطأ: $e'); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: DS.error, behavior: SnackBarBehavior.floating));

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: DS.bg,
        appBar: DarkAppBar(title: 'تقديم طلب مزاد', leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => Navigator.pop(context))),
        body: Form(
          key: _formKey,
          child: FadeTransition(
            opacity: _fade,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                FadeSlideIn(delay: const Duration(milliseconds: 50), child: DSBanner(message: 'سيقوم المسؤول بتحديد يوم المعاينة وتاريخ المزاد بعد المراجعة.', color: DS.info, icon: Icons.info_outline_rounded)),
                const SizedBox(height: 20),
                FadeSlideIn(delay: const Duration(milliseconds: 150), child: FormSection(title: 'صور المنتج', icon: Icons.photo_camera_rounded, child: _buildPhotoGrid())),
                const SizedBox(height: 16),
                FadeSlideIn(delay: const Duration(milliseconds: 250), child: FormSection(title: 'معلومات المنتج', icon: Icons.inventory_2_rounded, child: _buildProductInfo())),
                const SizedBox(height: 16),
                FadeSlideIn(delay: const Duration(milliseconds: 350), child: FormSection(title: 'التصريح القانوني', icon: Icons.gavel_rounded, iconColor: DS.warning, child: _buildLegal())),
                const SizedBox(height: 32),
                FadeSlideIn(delay: const Duration(milliseconds: 450), child: GradientButton(label: _loading ? 'جاري الإرسال...' : 'إرسال للمراجعة', icon: Icons.send_rounded, isGold: true, isLoading: _loading, onPressed: _submit)),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoGrid() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('${_images.length}/$_maxImages صور', style: const TextStyle(color: DS.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
        const Spacer(),
        if (_images.isNotEmpty) TextButton.icon(icon: const Icon(Icons.delete_sweep_rounded, size: 16), label: const Text('حذف الكل', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)), onPressed: () => setState(() => _images.clear()), style: TextButton.styleFrom(foregroundColor: DS.error)),
      ]),
      const SizedBox(height: 12),
      if (_images.isNotEmpty) ...[
        GridView.builder(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10),
          itemCount: _images.length,
          itemBuilder: (_, i) => Stack(children: [
            ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(_images[i], fit: BoxFit.cover, width: double.infinity, height: double.infinity)),
            Positioned(top: 6, left: 6, child: GestureDetector(onTap: () => setState(() => _images.removeAt(i)), child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: DS.error, shape: BoxShape.circle), child: const Icon(Icons.close_rounded, color: Colors.white, size: 14)))),
            if (i == 0) Positioned(bottom: 8, right: 8, child: GlassCard(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), borderRadius: 8, backgroundColor: DS.gold.withValues(alpha: 0.8), child: const Text('رئيسية', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)))),
          ]),
        ),
        const SizedBox(height: 12),
      ],
      if (_images.length < _maxImages) InkWell(onTap: _pickImages, borderRadius: BorderRadius.circular(16), child: Container(height: 100, width: double.infinity, decoration: BoxDecoration(color: DS.purpleDeep.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(16)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: DS.purple.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.add_photo_alternate_rounded, size: 24, color: DS.purple)), const SizedBox(height: 8), const Text('إضافة صور للمنتج', style: TextStyle(color: DS.purple, fontSize: 13, fontWeight: FontWeight.w700))]))),
    ]);
  }

  Widget _buildProductInfo() {
    return Column(children: [
      DarkTextField(controller: _titleController, hint: 'عنوان المزاد (مثال: سيارة مرسيدس 2024)', icon: Icons.title_rounded, validator: (v) => v == null || v.trim().isEmpty ? 'هذا الحقل مطلوب' : null),
      const SizedBox(height: 16),
      DarkTextField(controller: _descController, hint: 'الوصف التفصيلي للمنتج...', icon: Icons.description_rounded, keyboardType: TextInputType.multiline, validator: (v) => v == null || v.trim().isEmpty ? 'هذا الحقل مطلوب' : null),
      const SizedBox(height: 16),
      DarkTextField(controller: _priceController, hint: 'السعر الابتدائي (DZD)', icon: Icons.payments_rounded, keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: (v) => v == null || v.trim().isEmpty ? 'هذا الحقل مطلوب' : null),
      const SizedBox(height: 16),
      DarkTextField(controller: _locationController, hint: 'الموقع / المدينة', icon: Icons.location_on_rounded, validator: (v) => v == null || v.trim().isEmpty ? 'هذا الحقل مطلوب' : null),
      const SizedBox(height: 20),
      Align(alignment: Alignment.centerRight, child: Text('الفئة', style: DS.label.copyWith(letterSpacing: 0))),
      const SizedBox(height: 12),
      Wrap(spacing: 10, runSpacing: 10, children: _categories.map((c) {
        final sel = c == _category;
        return GestureDetector(onTap: () => setState(() => _category = c), child: AnimatedContainer(duration: const Duration(milliseconds: 250), padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10), decoration: BoxDecoration(gradient: sel ? DS.purpleGradient : null, color: sel ? null : DS.bgElevated, borderRadius: BorderRadius.circular(14), border: Border.all(color: sel ? Colors.transparent : DS.border), boxShadow: sel ? DS.purpleShadow : []), child: Text(c, style: TextStyle(fontSize: 13, fontWeight: sel ? FontWeight.w800 : FontWeight.w600, color: sel ? Colors.white : DS.textSecondary))));
      }).toList()),
    ]);
  }

  Widget _buildLegal() {
    return Column(children: [
      Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: DS.warning.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: DS.warning.withValues(alpha: 0.2))), child: const Text('أؤكد أن هذا المنتج خاضع للملكية التامة وغير مرهون، وأتحمل كامل المسؤولية القانونية عن البيانات المذكورة وتفاصيل المزاد.', style: TextStyle(height: 1.6, fontSize: 13, color: DS.textPrimary, fontWeight: FontWeight.w500))),
      const SizedBox(height: 16),
      AnimatedCheckbox(value: _declarationAccepted, onChanged: (v) => setState(() => _declarationAccepted = v!), label: 'أقر وأصرّح بصحة ما ورد أعلاه'),
      const SizedBox(height: 12),
      AnimatedCheckbox(value: _termsAccepted, onChanged: (v) => setState(() => _termsAccepted = v!), label: 'أوافق على شروط وأحكام المنصة'),
    ]);
  }
}
