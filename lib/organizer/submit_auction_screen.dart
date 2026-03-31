import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/auction_model.dart';

class SubmitAuctionScreen extends StatefulWidget {
  const SubmitAuctionScreen({super.key});

  @override
  State<SubmitAuctionScreen> createState() => _SubmitAuctionScreenState();
}

class _SubmitAuctionScreenState extends State<SubmitAuctionScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();

  String _category = 'عقارات';
  bool _declarationAccepted = false;
  bool _termsAccepted = false;
  bool _loading = false;

  final List<String> _categories = [
    'عقارات', 'سيارات', 'إلكترونيات', 'أثاث', 'معدات صناعية', 'أخرى'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_declarationAccepted) {
      _showError('يجب قبول التصريح القانوني للمتابعة');
      return;
    }
    if (!_termsAccepted) {
      _showError('يجب قبول الشروط والأحكام للمتابعة');
      return;
    }

    setState(() => _loading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final organizerName = userDoc.data()?['name'] ?? 'Unknown';

      // البائع يرسل المعلومات والسعر فقط
      // الأدمين هو اللي يحدد يوم المعاينة + تاريخ المزاد
      await FirebaseFirestore.instance.collection('auctions').add({
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
        'createdAt': FieldValue.serverTimestamp(),
        'sellerDeclarationAccepted': true,
        'declarationAcceptedAt': FieldValue.serverTimestamp(),
        'termsAccepted': true,
        // التواريخ null — الأدمين هو اللي يحددها
        'inspectionDay': null,
        'startTime': null,
        'endTime': null,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم إرسال طلب المزاد للمراجعة'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _showError('حدث خطأ: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('تقديم طلب مزاد'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── ملاحظة للبائع ────────────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
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
                      'بعد مراجعة الطلب، سيقوم المسؤول بتحديد يوم المعاينة وتاريخ المزاد.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF1565C0)),
                    ),
                  ),
                ],
              ),
            ),

            // ── معلومات المزاد ───────────────────────────────
            _buildSection(
              title: 'معلومات المنتج',
              children: [
                _buildField(_titleController, 'عنوان المزاد', Icons.title),
                const SizedBox(height: 12),
                _buildField(_descController, 'الوصف التفصيلي', Icons.description,
                    maxLines: 4),
                const SizedBox(height: 12),
                _buildField(
                  _priceController,
                  'السعر الابتدائي (DZD)',
                  Icons.attach_money,
                  isNumber: true,
                ),
                const SizedBox(height: 12),
                _buildField(_locationController, 'الموقع / المدينة',
                    Icons.location_on),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _category,
                  decoration: _inputDecoration('الفئة', Icons.category),
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _category = v!),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── التصريح القانوني ─────────────────────────────
            _buildSection(
              title: '⚖️ التصريح القانوني',
              titleColor: Colors.orange[800]!,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: const Text(
                    'أؤكد أن هذا المنتج:\n'
                        '• غير خاضع لأي حجز قضائي أو إداري\n'
                        '• غير مرهون أو مثقل بأي دين\n'
                        '• لا توجد عليه ضرائب أو رسوم متأخرة\n'
                        '• أنا مالكه الشرعي وأحق ببيعه\n\n'
                        'أتحمل المسؤولية القانونية الكاملة في حالة مخالفة أي من هذه البنود.',
                    style: TextStyle(height: 1.6, fontSize: 13),
                  ),
                ),
                CheckboxListTile(
                  value: _declarationAccepted,
                  onChanged: (v) => setState(() => _declarationAccepted = v!),
                  title: const Text('أقر وأصرّح بصحة ما ورد أعلاه',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  activeColor: const Color(0xFF1565C0),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                CheckboxListTile(
                  value: _termsAccepted,
                  onChanged: (v) => setState(() => _termsAccepted = v!),
                  title: const Text('أوافق على شروط وأحكام المنصة'),
                  activeColor: const Color(0xFF1565C0),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── زر الإرسال ───────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _loading ? null : _submit,
                icon: _loading
                    ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send),
                label: Text(_loading ? 'جاري الإرسال...' : 'إرسال للمراجعة'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
    Color? titleColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: titleColor ?? const Color(0xFF1565C0))),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  TextFormField _buildField(
      TextEditingController controller,
      String label,
      IconData icon, {
        int maxLines = 1,
        bool isNumber = false,
      }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: _inputDecoration(label, icon),
      validator: (v) =>
      v == null || v.trim().isEmpty ? 'هذا الحقل مطلوب' : null,
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: const Color(0xFFF5F6FA),
    );
  }
}
