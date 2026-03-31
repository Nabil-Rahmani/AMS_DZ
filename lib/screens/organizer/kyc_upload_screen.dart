import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class KycUploadScreen extends StatefulWidget {
  const KycUploadScreen({super.key});

  @override
  State<KycUploadScreen> createState() => _KycUploadScreenState();
}

class _KycUploadScreenState extends State<KycUploadScreen> {
  final _picker = ImagePicker();
  bool _isLoading = false;

  final Map<String, _DocItem> _docs = {
    'national_id': _DocItem(
      label: 'بطاقة التعريف الوطنية',
      icon: Icons.badge,
      required: true,
    ),
    'commercial_register': _DocItem(
      label: 'السجل التجاري (للشركات)',
      icon: Icons.business,
      required: false,
    ),
    'product_docs': _DocItem(
      label: 'وثائق المنتج',
      icon: Icons.description,
      required: true,
    ),
    'no_lien_certificate': _DocItem(
      label: 'شهادة عدم الرهن (للسيارات/العقارات)',
      icon: Icons.gavel,
      required: false,
    ),
  };

  Future<void> _pickImage(String docKey) async {
    final source = await _showSourceDialog();
    if (source == null) return;

    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (picked == null) return;
    setState(() => _docs[docKey]!.file = File(picked.path));
  }

  Future<ImageSource?> _showSourceDialog() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF1565C0)),
              title: const Text('التقاط صورة'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF1565C0)),
              title: const Text('اختيار من المعرض'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
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
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final storage = FirebaseStorage.instance;
      final Map<String, String> uploadedUrls = {};

      for (final entry in _docs.entries) {
        if (entry.value.file == null) continue;
        final ref = storage.ref('kyc/$uid/${entry.key}.jpg');
        await ref.putFile(entry.value.file!);
        uploadedUrls[entry.key] = await ref.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'kycDocuments': uploadedUrls,
        'kycStatus': 'pending',
        'kycSubmittedAt': FieldValue.serverTimestamp(),
      });

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
      SnackBar(content: Text(msg), backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating));

  void _showSuccess(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating));

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1565C0),
          foregroundColor: Colors.white,
          title: const Text('رفع وثائق التحقق (KYC)'),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFF1565C0)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'الوثائق المميزة بـ (*) إلزامية. سيتم مراجعتها خلال 24-48 ساعة.',
                        style: TextStyle(fontSize: 13, color: Color(0xFF1565C0)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ..._docs.entries.map((e) => _DocCard(
                item: e.value,
                onTap: () => _pickImage(e.key),
                onRemove: () => setState(() => _docs[e.key]!.file = null),
              )),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _submit,
                  icon: _isLoading
                      ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.upload_file),
                  label: Text(_isLoading ? 'جاري الرفع...' : 'إرسال للمراجعة'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocCard extends StatelessWidget {
  final _DocItem item;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _DocCard({required this.item, required this.onTap, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.file != null ? Colors.green : Colors.grey.shade300,
          width: item.file != null ? 2 : 1,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.icon, color: const Color(0xFF1565C0)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(child: Text(item.label,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14))),
                        if (item.required)
                          const Text('*', style: TextStyle(
                              color: Colors.red, fontWeight: FontWeight.bold)),
                      ]),
                      const SizedBox(height: 2),
                      Text(
                        item.file != null ? '✅ تم الرفع' : 'لم يتم الرفع بعد',
                        style: TextStyle(fontSize: 12,
                            color: item.file != null ? Colors.green : Colors.grey),
                      ),
                    ],
                  ),
                ),
                if (item.file != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: onRemove,
                  ),
              ],
            ),
          ),
          if (item.file != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
              child: Image.file(item.file!, height: 160,
                  width: double.infinity, fit: BoxFit.cover),
            )
          else
            InkWell(
              onTap: onTap,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
              child: Container(
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(14)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined,
                        size: 32, color: Colors.grey.shade400),
                    const SizedBox(height: 4),
                    Text('اضغط لرفع الصورة',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DocItem {
  final String label;
  final IconData icon;
  final bool required;
  File? file;

  _DocItem({required this.label, required this.icon,
    required this.required, this.file});
}
