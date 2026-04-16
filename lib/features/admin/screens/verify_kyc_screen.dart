import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:auction_app2/shared/models/user_model.dart';
import 'package:auction_app2/core/services/firebase/firestore_service.dart';
import '../../../core/constants/ds_colors.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../widgets/kyc_card_components.dart';
import '../widgets/kyc_detail_row.dart';
import '../widgets/kyc_organizer_list.dart';

class VerifyKycScreen extends StatefulWidget {
  const VerifyKycScreen({super.key});
  @override
  State<VerifyKycScreen> createState() => _VerifyKycScreenState();
}

class _VerifyKycScreenState extends State<VerifyKycScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _db = FirestoreService();
  late TabController _tabController;

  final List<Map<String, dynamic>> _tabs = [
    {'label': 'بانتظار المراجعة', 'filter': KycStatus.pending},
    {'label': 'معتمدون', 'filter': KycStatus.approved},
    {'label': 'مرفوضون', 'filter': KycStatus.rejected},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Stream<List<UserModel>> _organizersStream(KycStatus filter) {
    return _db.streamAllOrganizers().map((list) => list.where((u) {
      if (filter == KycStatus.pending)
        return u.kycStatus == KycStatus.pending || u.kycStatus == null;
      return u.kycStatus == filter;
    }).toList());
  }

  Future<void> _approve(UserModel user) async {
    final confirm = await _showConfirm(
      title: 'قبول طلب KYC',
      content: 'هل تريد قبول توثيق "${user.name}"؟',
      confirmText: 'قبول',
      confirmColor: DS.success,
    );
    if (!confirm) return;
    try {
      await _db.approveKyc(user.id);
      _showSnack('✅ تم قبول طلب التوثيق');
    } catch (e) {
      _showSnack('❌ خطأ: $e', isError: true);
    }
  }

  Future<void> _reject(UserModel user) async {
    final reasonCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('رفض طلب KYC', style: DS.titleM),
              const SizedBox(height: 8),
              Text('المنظم: ${user.name}', style: DS.bodySmall),
              const SizedBox(height: 20),
              TextField(
                controller: reasonCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'سبب الرفض',
                  hintText: 'اكتب سبب الرفض هنا...',
                ),
              ),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('إلغاء'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: DS.error),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('رفض', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
    if (confirm != true) return;
    try {
      await _db.rejectKyc(
        user.id,
        reason: reasonCtrl.text.trim().isEmpty
            ? 'لم يُذكر سبب'
            : reasonCtrl.text.trim(),
      );
      _showSnack('🚫 تم رفض طلب التوثيق');
    } catch (e) {
      _showSnack('❌ خطأ: $e', isError: true);
    }
  }

  // ✅ التعديل هنا
  Future<void> _openDocument(String urlOrPath) async {
    try {
      String downloadUrl = urlOrPath;
      if (!urlOrPath.startsWith('http')) {
        downloadUrl = await FirebaseStorage.instance
            .ref(urlOrPath)
            .getDownloadURL();
      }
      final Uri uri = Uri.parse(downloadUrl);
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      _showSnack('❌ خطأ في فتح الوثيقة: $e', isError: true);
    }
  }

  void _showOrganizerDetails(UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => GlassCard(
          borderRadius: 32,
          padding: EdgeInsets.fromLTRB(
            24, 16, 24,
            MediaQuery.of(context).viewInsets.bottom + 36,
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: DS.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(children: [
                  DSAvatar(name: user.name, radius: 32, color: DS.purple),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name, style: DS.titleM),
                        const SizedBox(height: 4),
                        Text(user.email, style: DS.bodySmall),
                      ],
                    ),
                  ),
                  KycBadge(status: user.kycStatus),
                ]),
                const SizedBox(height: 24),
                const DSDivider(),
                const SizedBox(height: 20),
                KycDetailRow(
                  icon: Icons.phone_rounded,
                  label: 'رقم الهاتف',
                  value: user.phone ?? 'غير محدد',
                ),
                KycDetailRow(
                  icon: Icons.business_rounded,
                  label: 'نوع الحساب',
                  value: user.accountType == 'company' ? 'شركة' : 'شخص طبيعي',
                ),
                KycDetailRow(
                  icon: Icons.location_on_rounded,
                  label: 'العنوان',
                  value: user.address ?? 'غير محدد',
                ),
                KycDetailRow(
                  icon: Icons.calendar_today_rounded,
                  label: 'تاريخ التسجيل',
                  value: user.createdAt != null
                      ? '${user.createdAt!.day}/${user.createdAt!.month}/${user.createdAt!.year}'
                      : 'غير محدد',
                ),
                if (user.kycStatus == KycStatus.rejected &&
                    user.kycRejectionReason != null)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: DS.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: DS.error.withValues(alpha: 0.2)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.info_outline_rounded,
                          color: DS.error, size: 16),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          user.kycRejectionReason!,
                          style: DS.bodySmall.copyWith(color: DS.error),
                        ),
                      ),
                    ]),
                  ),
                if (user.kycDocuments != null &&
                    user.kycDocuments!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text('الوثائق المرفقة', style: DS.titleS),
                  const SizedBox(height: 12),
                  ...user.kycDocuments!.entries.map((e) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: DS.bgField,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: DS.border),
                    ),
                    child: Row(children: [
                      const Icon(Icons.description_outlined,
                          size: 18, color: DS.purple),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _docLabel(e.key),
                          style: DS.bodySmall.copyWith(
                              color: DS.textPrimary),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _openDocument(e.value),
                        child: Text('عرض',
                            style: DS.label.copyWith(color: DS.purple)),
                      ),
                    ]),
                  )),
                ],
                const SizedBox(height: 32),
                if (user.kycStatus == KycStatus.pending ||
                    user.kycStatus == null)
                  Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: DS.error),
                          foregroundColor: DS.error,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _reject(user);
                        },
                        child: const Text('رفض الطلب',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GradientButton(
                        label: 'اعتماد المنظم',
                        height: 52,
                        onPressed: () {
                          Navigator.pop(context);
                          _approve(user);
                        },
                      ),
                    ),
                  ]),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _docLabel(String key) {
    switch (key) {
      case 'national_id': return 'بطاقة التعريف الوطنية';
      case 'commercial_register': return 'السجل التجاري';
      case 'product_docs': return 'وثائق المنتج';
      case 'no_lien_certificate': return 'شهادة عدم الرهن';
      default: return key;
    }
  }

  Future<bool> _showConfirm({
    required String title,
    required String content,
    required String confirmText,
    required Color confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: DS.titleM),
              const SizedBox(height: 12),
              Text(content, style: DS.body, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('إلغاء'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: confirmColor),
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(confirmText,
                        style: const TextStyle(color: Colors.white)),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
    return result ?? false;
  }

  void _showSnack(String msg, {bool isError = false}) {
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
      child: Scaffold(
        backgroundColor: DS.bg,
        body: Column(children: [
          Container(
            height: 180,
            decoration: const BoxDecoration(gradient: DS.headerGradient),
            child: Stack(children: [
              const Positioned(
                top: -40, right: -40,
                child: PurpleOrb(size: 180, opacity: 0.2),
              ),
              SafeArea(
                bottom: false,
                child: Column(children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('التحقق من الهوية', style: DS.titleL),
                          Text('مراجعة وثائق المنظمين واعتمادهم',
                              style: DS.bodySmall),
                        ],
                      ),
                    ]),
                  ),
                  const Spacer(),
                  TabBar(
                    controller: _tabController,
                    indicatorColor: DS.purple,
                    indicatorWeight: 4,
                    labelColor: DS.textPrimary,
                    unselectedLabelColor: DS.textMuted,
                    labelStyle: DS.label.copyWith(
                        fontSize: 13, fontWeight: FontWeight.bold),
                    unselectedLabelStyle: DS.label.copyWith(fontSize: 13),
                    dividerColor: Colors.transparent,
                    tabs: _tabs
                        .map((t) => Tab(text: t['label'] as String))
                        .toList(),
                  ),
                ]),
              ),
            ]),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _tabs
                  .map((t) => KycOrganizerList(
                stream: _organizersStream(t['filter'] as KycStatus),
                filter: t['filter'] as KycStatus,
                onTap: _showOrganizerDetails,
                onApprove: _approve,
                onReject: _reject,
              ))
                  .toList(),
            ),
          ),
        ]),
      ),
    );
  }
}