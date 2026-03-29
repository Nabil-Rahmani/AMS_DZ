import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/services/firestore_service.dart';

class SubmitAuctionScreen extends StatefulWidget {
  const SubmitAuctionScreen({super.key});

  @override
  State<SubmitAuctionScreen> createState() => _SubmitAuctionScreenState();
}

class _SubmitAuctionScreenState extends State<SubmitAuctionScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();

  // Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _startingPriceController = TextEditingController();
  final _minBidIncrementController = TextEditingController();
  final _locationController = TextEditingController();

  // State
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedCategory = 'عقارات';
  bool _isSubmitting = false;
  bool _isSavingDraft = false;

  final List<String> _categories = [
    'عقارات',
    'سيارات',
    'إلكترونيات',
    'تحف وفنون',
    'مجوهرات',
    'معدات',
    'أخرى',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _startingPriceController.dispose();
    _minBidIncrementController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // ─── Pick Date ────────────────────────────────────────────────
  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart
        ? (_startDate ?? now)
        : (_endDate ?? (_startDate ?? now).add(const Duration(days: 1)));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF1565C0),
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (pickedTime == null) return;

    final finalDt = DateTime(
      picked.year,
      picked.month,
      picked.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      if (isStart) {
        _startDate = finalDt;
        if (_endDate != null && _endDate!.isBefore(finalDt)) {
          _endDate = null;
        }
      } else {
        _endDate = finalDt;
      }
    });
  }

  // ─── Validate & Submit ────────────────────────────────────────
  Future<void> _submit({bool asDraft = false}) async {
    if (!asDraft && !_formKey.currentState!.validate()) return;

    if (!asDraft) {
      if (_startDate == null) {
        _showError('يرجى تحديد تاريخ البداية');
        return;
      }
      if (_endDate == null) {
        _showError('يرجى تحديد تاريخ النهاية');
        return;
      }
      if (_endDate!.isBefore(_startDate!)) {
        _showError('تاريخ النهاية يجب أن يكون بعد تاريخ البداية');
        return;
      }
    }

    setState(() {
      if (asDraft) {
        _isSavingDraft = true;
      } else {
        _isSubmitting = true;
      }
    });

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final now = Timestamp.now();

      final auctionData = {
        'organizerId': uid,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,
        'startingPrice': double.tryParse(_startingPriceController.text) ?? 0,
        'currentPrice': double.tryParse(_startingPriceController.text) ?? 0,
        'minBidIncrement':
        double.tryParse(_minBidIncrementController.text) ?? 100,
        'location': _locationController.text.trim(),
        'startDate':
        _startDate != null ? Timestamp.fromDate(_startDate!) : null,
        'endDate': _endDate != null ? Timestamp.fromDate(_endDate!) : null,
        'status': asDraft ? 'draft' : 'submitted',
        'createdAt': now,
        'updatedAt': now,
        'winnerId': null,
        'winnerBidId': null,
        'imageUrls': [],
      };

      await FirebaseFirestore.instance.collection('auctions').add(auctionData);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(asDraft
              ? 'تم حفظ المسودة بنجاح ✓'
              : 'تم إرسال المزاد للمراجعة بنجاح ✓'),
          backgroundColor:
          asDraft ? Colors.blueGrey : const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      _showError('حدث خطأ: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isSavingDraft = false;
        });
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFC62828),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─── UI Helpers ───────────────────────────────────────────────
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(title,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1565C0))),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator ??
                (v) {
              if (v == null || v.trim().isEmpty) return 'هذا الحقل مطلوب';
              return null;
            },
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFF1565C0), size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
            const BorderSide(color: Color(0xFF1565C0), width: 1.8),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildDateTile({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    final hasValue = value != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: hasValue
                ? const Color(0xFF1565C0)
                : Colors.grey.shade400,
            width: hasValue ? 1.8 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: hasValue
                    ? const Color(0xFF1565C0)
                    : Colors.grey.shade500,
                size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade600)),
                  const SizedBox(height: 2),
                  Text(
                    hasValue
                        ? '${value!.day}/${value.month}/${value.year}  ${value.hour}:${value.minute.toString().padLeft(2, '0')}'
                        : 'اضغط لتحديد التاريخ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: hasValue
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: hasValue
                          ? Colors.black87
                          : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'إنشاء مزاد جديد',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87),
        ),
        leading: const BackButton(color: Colors.black87),
        actions: [
          TextButton.icon(
            onPressed: _isSavingDraft ? null : () => _submit(asDraft: true),
            icon: _isSavingDraft
                ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save_outlined,
                size: 18, color: Colors.blueGrey),
            label: const Text('مسودة',
                style: TextStyle(color: Colors.blueGrey)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── المعلومات الأساسية ──
              _sectionTitle('📋  المعلومات الأساسية'),
              _buildTextField(
                controller: _titleController,
                label: 'عنوان المزاد',
                icon: Icons.title_rounded,
                hint: 'مثال: شقة 3 غرف في الجزائر العاصمة',
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'العنوان مطلوب';
                  if (v.trim().length < 5) return 'العنوان قصير جداً';
                  return null;
                },
              ),
              _buildTextField(
                controller: _descriptionController,
                label: 'الوصف',
                icon: Icons.description_rounded,
                hint: 'اكتب وصفاً تفصيلياً للعنصر المعروض...',
                maxLines: 4,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'الوصف مطلوب';
                  if (v.trim().length < 20)
                    return 'الوصف يجب أن يكون 20 حرفاً على الأقل';
                  return null;
                },
              ),

              // Category Dropdown
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'الفئة',
                    prefixIcon: const Icon(Icons.category_rounded,
                        color: Color(0xFF1565C0), size: 20),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: Color(0xFF1565C0), width: 1.8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: _categories
                      .map((c) =>
                      DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _selectedCategory = v ?? _selectedCategory),
                ),
              ),

              _buildTextField(
                controller: _locationController,
                label: 'الموقع',
                icon: Icons.location_on_rounded,
                hint: 'مثال: الجزائر العاصمة، وهران...',
              ),

              const SizedBox(height: 4),

              // ── السعر ──
              _sectionTitle('💰  التسعير'),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _startingPriceController,
                      label: 'السعر الابتدائي (DZD)',
                      icon: Icons.price_change_rounded,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'مطلوب';
                        if (double.tryParse(v) == null || double.parse(v) <= 0)
                          return 'سعر غير صالح';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _minBidIncrementController,
                      label: 'الحد الأدنى للزيادة',
                      icon: Icons.trending_up_rounded,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'مطلوب';
                        if (double.tryParse(v) == null || double.parse(v) <= 0)
                          return 'قيمة غير صالحة';
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              // ── التواريخ ──
              _sectionTitle('📅  مدة المزاد'),
              _buildDateTile(
                label: 'تاريخ البداية',
                value: _startDate,
                icon: Icons.play_arrow_rounded,
                onTap: () => _pickDate(isStart: true),
              ),
              const SizedBox(height: 12),
              _buildDateTile(
                label: 'تاريخ النهاية',
                value: _endDate,
                icon: Icons.stop_rounded,
                onTap: () => _pickDate(isStart: false),
              ),

              const SizedBox(height: 28),

              // ── Submit Button ──
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : () => _submit(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  icon: _isSubmitting
                      ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_rounded, color: Colors.white),
                  label: Text(
                    _isSubmitting ? 'جاري الإرسال...' : 'إرسال للمراجعة',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Info note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: Color(0xFF1565C0), size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'بعد الإرسال، سيراجع المسؤول طلبك ويوافق عليه قبل نشر المزاد.',
                        style: TextStyle(
                            fontSize: 12, color: Color(0xFF1565C0)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
