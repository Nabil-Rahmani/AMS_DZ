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
import 'package:auction_app2/core/services/notification_service.dart';

class SubmitAuctionScreen extends StatefulWidget {
  const SubmitAuctionScreen({super.key});
  @override
  State<SubmitAuctionScreen> createState() => _SubmitAuctionScreenState();
}

class _SubmitAuctionScreenState extends State<SubmitAuctionScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _picker = ImagePicker();

  String _category = 'عقارات';
  bool _declarationAccepted = false;
  bool _termsAccepted = false;
  bool _loading = false;

  // ✅ تتبع أي حقل مفتوح اقتراحاته
  String? _openSuggestionsKey;

  final List<File> _images = [];
  static const int _maxImages = 60;

  final List<String> _categories = [
    'عقارات',
    'مركبات',
    'إلكترونيات',
    'أثاث',
    'مجوهرات',
    'معدات صناعية',
    'عتاد فلاحي',
    'معدات طاقة',
    'معدات بناء وأشغال عمومية',
    'أخرى',
  ];

  final Map<String, TextEditingController> _detailControllers = {};
  final Map<String, FocusNode> _detailFocusNodes = {};

  static const Map<String, List<Map<String, String>>> _categoryFields = {
    'مركبات': [
      {
        'key': 'vehicleType',
        'label': 'نوع المركبة',
        'hint': 'سيارة / شاحنة / دراجة / حافلة / جرار / ...',
        'emoji': '🚗'
      },
      {
        'key': 'brand',
        'label': 'الماركة',
        'hint': 'مثال: Renault / Mercedes / Yamaha',
        'emoji': '🏷'
      },
      {
        'key': 'model',
        'label': 'الموديل',
        'hint': 'مثال: Symbol / Actros / R1',
        'emoji': '🚘'
      },
      {
        'key': 'year',
        'label': 'سنة الصنع',
        'hint': 'مثال: 2019',
        'emoji': '📅'
      },
      {
        'key': 'engine',
        'label': 'المحرك',
        'hint': 'مثال: 1.5L / 6 سلندر / 125cc',
        'emoji': '⚙️'
      },
      {
        'key': 'fuel',
        'label': 'الوقود',
        'hint': 'بنزين / ديزل / غاز / كهرباء / هجين',
        'emoji': '⛽'
      },
      {
        'key': 'mileage',
        'label': 'المسافة (كم)',
        'hint': 'مثال: 85000',
        'emoji': '📏'
      },
      {
        'key': 'transmission',
        'label': 'ناقل الحركة',
        'hint': 'أوتوماتيك / يدوي',
        'emoji': '🔄'
      },
      {
        'key': 'color',
        'label': 'اللون',
        'hint': 'مثال: رمادي معدني',
        'emoji': '🎨'
      },
      {
        'key': 'numPlate',
        'label': 'رقم اللوحة',
        'hint': 'اختياري',
        'emoji': '🔢'
      },
      {
        'key': 'technicalVisit',
        'label': 'الفحص التقني',
        'hint': 'صالح حتى / منتهي',
        'emoji': '🔍'
      },
      {
        'key': 'condition',
        'label': 'الحالة العامة',
        'hint': 'ممتازة / جيدة / تحتاج صيانة',
        'emoji': '✅'
      },
    ],
    'عقارات': [
      {
        'key': 'type',
        'label': 'النوع',
        'hint': 'شقة / فيلا / محل / أرض / مستودع / ...',
        'emoji': '🏢'
      },
      {
        'key': 'area',
        'label': 'المساحة (م²)',
        'hint': 'مثال: 150',
        'emoji': '📐'
      },
      {'key': 'rooms', 'label': 'عدد الغرف', 'hint': 'مثال: 3', 'emoji': '🛏'},
      {
        'key': 'bathrooms',
        'label': 'عدد الحمامات',
        'hint': 'مثال: 2',
        'emoji': '🚿'
      },
      {
        'key': 'floor',
        'label': 'الطابق',
        'hint': 'مثال: 2 / أرضي',
        'emoji': '🏗'
      },
      {
        'key': 'age',
        'label': 'عمر البناء (سنة)',
        'hint': 'مثال: 5',
        'emoji': '📅'
      },
      {
        'key': 'facing',
        'label': 'الواجهة',
        'hint': 'شمال / جنوب / شرق / غرب',
        'emoji': '🧭'
      },
      {
        'key': 'condition',
        'label': 'الحالة',
        'hint': 'جديد / مجدد / يحتاج ترميم',
        'emoji': '✅'
      },
    ],
    'إلكترونيات': [
      {
        'key': 'type',
        'label': 'النوع',
        'hint': 'لابتوب / هاتف / تلفاز / طابعة / ...',
        'emoji': '🖥'
      },
      {
        'key': 'brand',
        'label': 'الماركة',
        'hint': 'مثال: Samsung / Apple / HP',
        'emoji': '🏷'
      },
      {
        'key': 'model',
        'label': 'الموديل',
        'hint': 'مثال: Galaxy S23',
        'emoji': '📱'
      },
      {'key': 'ram', 'label': 'RAM (GB)', 'hint': 'مثال: 16', 'emoji': '🧠'},
      {
        'key': 'storage',
        'label': 'التخزين',
        'hint': 'مثال: 512GB SSD',
        'emoji': '💾'
      },
      {
        'key': 'processor',
        'label': 'المعالج',
        'hint': 'مثال: i7 Gen 12',
        'emoji': '⚡'
      },
      {
        'key': 'screen',
        'label': 'الشاشة',
        'hint': 'مثال: 15.6 بوصة 4K',
        'emoji': '🖥'
      },
      {
        'key': 'battery',
        'label': 'البطارية',
        'hint': 'مثال: 5000 mAh / حالة جيدة',
        'emoji': '🔋'
      },
      {
        'key': 'condition',
        'label': 'الحالة',
        'hint': 'جديد / مستعمل / يحتاج إصلاح',
        'emoji': '✅'
      },
    ],
    'أثاث': [
      {
        'key': 'type',
        'label': 'النوع',
        'hint': 'غرفة نوم / صالون / مطبخ / مكتب / ...',
        'emoji': '🪑'
      },
      {
        'key': 'material',
        'label': 'المادة',
        'hint': 'خشب طبيعي / MDF / معدن / قماش',
        'emoji': '🪵'
      },
      {
        'key': 'color',
        'label': 'اللون',
        'hint': 'مثال: بني غامق / رمادي',
        'emoji': '🎨'
      },
      {
        'key': 'dimensions',
        'label': 'الأبعاد',
        'hint': 'مثال: 200×90×75 سم',
        'emoji': '📐'
      },
      {
        'key': 'pieces',
        'label': 'عدد القطع',
        'hint': 'مثال: طقم 7 قطع',
        'emoji': '🔢'
      },
      {
        'key': 'condition',
        'label': 'الحالة',
        'hint': 'جديد / مستعمل / ممتاز',
        'emoji': '✅'
      },
    ],
    'مجوهرات': [
      {
        'key': 'type',
        'label': 'النوع',
        'hint': 'خاتم / قلادة / سوار / حلق / طقم / ...',
        'emoji': '💍'
      },
      {
        'key': 'material',
        'label': 'المادة',
        'hint': 'ذهب / فضة / بلاتين / ...',
        'emoji': '✨'
      },
      {
        'key': 'weight',
        'label': 'الوزن (غ)',
        'hint': 'مثال: 12',
        'emoji': '⚖️'
      },
      {
        'key': 'carat',
        'label': 'العيار',
        'hint': 'مثال: 18 / 21 / 24',
        'emoji': '💎'
      },
      {
        'key': 'stones',
        'label': 'الأحجار',
        'hint': 'ألماس / ياقوت / زمرد / بدون',
        'emoji': '💠'
      },
      {
        'key': 'origin',
        'label': 'المصدر',
        'hint': 'مثال: إيطالي / تركي / جزائري',
        'emoji': '🌍'
      },
      {
        'key': 'condition',
        'label': 'الحالة',
        'hint': 'جديد / مستعمل',
        'emoji': '✅'
      },
    ],
    'معدات صناعية': [
      {
        'key': 'type',
        'label': 'النوع',
        'hint': 'كمبريسور / مولد / مخرطة / رافعة / ...',
        'emoji': '🏭'
      },
      {
        'key': 'brand',
        'label': 'الماركة',
        'hint': 'مثال: Atlas Copco / Perkins',
        'emoji': '🏷'
      },
      {
        'key': 'model',
        'label': 'الموديل',
        'hint': 'مثال: GA 15',
        'emoji': '🔖'
      },
      {
        'key': 'power',
        'label': 'القدرة',
        'hint': 'مثال: 15KW / 20HP',
        'emoji': '⚡'
      },
      {
        'key': 'year',
        'label': 'سنة الصنع',
        'hint': 'مثال: 2018',
        'emoji': '📅'
      },
      {
        'key': 'hours',
        'label': 'ساعات العمل',
        'hint': 'مثال: 3500 ساعة',
        'emoji': '⏱'
      },
      {
        'key': 'voltage',
        'label': 'الجهد الكهربائي',
        'hint': 'مثال: 380V / 220V',
        'emoji': '🔌'
      },
      {
        'key': 'condition',
        'label': 'الحالة',
        'hint': 'جيدة / تحتاج صيانة / ممتازة',
        'emoji': '✅'
      },
    ],
    'عتاد فلاحي': [
      {
        'key': 'type',
        'label': 'النوع',
        'hint': 'جرار / حصادة / آلة بذر / مضخة / رشاش / ...',
        'emoji': '🚜'
      },
      {
        'key': 'brand',
        'label': 'الماركة',
        'hint': 'مثال: John Deere / New Holland / Deutz',
        'emoji': '🏷'
      },
      {
        'key': 'model',
        'label': 'الموديل',
        'hint': 'مثال: 5090R',
        'emoji': '🔖'
      },
      {
        'key': 'year',
        'label': 'سنة الصنع',
        'hint': 'مثال: 2015',
        'emoji': '📅'
      },
      {
        'key': 'power',
        'label': 'القدرة (حصان)',
        'hint': 'مثال: 90 CV',
        'emoji': '⚡'
      },
      {
        'key': 'hours',
        'label': 'ساعات العمل',
        'hint': 'مثال: 2000 ساعة',
        'emoji': '⏱'
      },
      {'key': 'fuel', 'label': 'الوقود', 'hint': 'ديزل / بنزين', 'emoji': '⛽'},
      {
        'key': 'transmission',
        'label': 'ناقل الحركة',
        'hint': 'يدوي / أوتوماتيك',
        'emoji': '🔄'
      },
      {
        'key': 'attachments',
        'label': 'الملحقات',
        'hint': 'محراث / ملقط / مقطورة / ...',
        'emoji': '🔧'
      },
      {
        'key': 'condition',
        'label': 'الحالة',
        'hint': 'ممتازة / جيدة / تحتاج صيانة',
        'emoji': '✅'
      },
    ],
    'معدات طاقة': [
      {
        'key': 'type',
        'label': 'النوع',
        'hint': 'ألواح شمسية / مولد / بطاريات / عاكس / ...',
        'emoji': '⚡'
      },
      {
        'key': 'brand',
        'label': 'الماركة',
        'hint': 'مثال: Huawei / Victron / Fronius',
        'emoji': '🏷'
      },
      {
        'key': 'model',
        'label': 'الموديل',
        'hint': 'مثال: SUN2000-10KTL',
        'emoji': '🔖'
      },
      {
        'key': 'power',
        'label': 'القدرة (KW/Wc)',
        'hint': 'مثال: 10KW / 400Wc',
        'emoji': '🔋'
      },
      {
        'key': 'quantity',
        'label': 'الكمية',
        'hint': 'مثال: 24 لوح / 8 بطاريات',
        'emoji': '🔢'
      },
      {
        'key': 'year',
        'label': 'سنة الصنع',
        'hint': 'مثال: 2022',
        'emoji': '📅'
      },
      {
        'key': 'voltage',
        'label': 'الجهد',
        'hint': 'مثال: 24V / 48V / 220V',
        'emoji': '🔌'
      },
      {
        'key': 'energySource',
        'label': 'مصدر الطاقة',
        'hint': 'شمسي / رياح / ديزل / هجين',
        'emoji': '☀️'
      },
      {
        'key': 'warranty',
        'label': 'الضمان',
        'hint': 'مثال: 10 سنوات / منتهي',
        'emoji': '🛡'
      },
      {
        'key': 'condition',
        'label': 'الحالة',
        'hint': 'جديد / مستعمل / ممتاز',
        'emoji': '✅'
      },
    ],
    'معدات بناء وأشغال عمومية': [
      {
        'key': 'type',
        'label': 'النوع',
        'hint': 'حفارة / بلدوزر / رافعة / خلاطة / ...',
        'emoji': '🏗'
      },
      {
        'key': 'brand',
        'label': 'الماركة',
        'hint': 'مثال: Caterpillar / Komatsu / JCB',
        'emoji': '🏷'
      },
      {
        'key': 'model',
        'label': 'الموديل',
        'hint': 'مثال: CAT 320 / JCB 3CX',
        'emoji': '🔖'
      },
      {
        'key': 'year',
        'label': 'سنة الصنع',
        'hint': 'مثال: 2017',
        'emoji': '📅'
      },
      {
        'key': 'power',
        'label': 'القدرة (CV/KW)',
        'hint': 'مثال: 120CV / 90KW',
        'emoji': '⚡'
      },
      {
        'key': 'hours',
        'label': 'ساعات العمل',
        'hint': 'مثال: 5000 ساعة',
        'emoji': '⏱'
      },
      {
        'key': 'weight',
        'label': 'الوزن (طن)',
        'hint': 'مثال: 20 طن',
        'emoji': '⚖️'
      },
      {
        'key': 'reach',
        'label': 'الامتداد / العمق',
        'hint': 'مثال: 6م عمق / 15م ارتفاع',
        'emoji': '📏'
      },
      {'key': 'fuel', 'label': 'الوقود', 'hint': 'ديزل / كهرباء', 'emoji': '⛽'},
      {
        'key': 'attachments',
        'label': 'الملحقات',
        'hint': 'دلو / مطرقة / مجرفة / ...',
        'emoji': '🔧'
      },
      {
        'key': 'condition',
        'label': 'الحالة',
        'hint': 'جيدة / ممتازة / تحتاج صيانة',
        'emoji': '✅'
      },
    ],
  };

  static const Map<String, List<String>> _fieldSuggestions = {
    'transmission': ['يدوي', 'أوتوماتيك', 'نصف أوتوماتيك'],
    'fuel': ['ديزل', 'بنزين', 'غاز', 'كهرباء', 'هجين'],
    'condition': ['ممتازة', 'جيدة', 'تحتاج صيانة', 'جديد', 'مستعمل', 'مجدد'],
    'facing': ['شمال', 'جنوب', 'شرق', 'غرب', 'شمال شرق', 'شمال غرب'],
    'energySource': ['شمسي', 'رياح', 'ديزل', 'هجين'],
    'vehicleType': ['سيارة', 'شاحنة', 'دراجة نارية', 'حافلة', 'جرار', 'عربة'],
    'type': ['شقة', 'فيلا', 'محل تجاري', 'أرض', 'مستودع', 'مكتب'],
    'material': ['خشب طبيعي', 'MDF', 'معدن', 'قماش', 'جلد'],
    'stones': ['ألماس', 'ياقوت', 'زمرد', 'زفير', 'بدون أحجار'],
    'technicalVisit': ['صالح', 'منتهي', 'جديد'],
  };

  late AnimationController _animCtrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
    _animCtrl.forward();
    _initDetailControllers();
  }

  void _initDetailControllers() {
    _detailControllers.clear();
    _detailFocusNodes.clear();
    final fields = _categoryFields[_category] ?? [];
    for (final f in fields) {
      final key = f['key']!;
      _detailControllers[key] = TextEditingController();
      _detailFocusNodes[key] = _buildFocusNode(key);
    }
  }

  FocusNode _buildFocusNode(String key) {
    final fn = FocusNode();
    fn.addListener(() {
      if (!mounted) return;
      if (fn.hasFocus) {
        // ✅ فتح الاقتراحات فقط إذا عنده اقتراحات
        if (_fieldSuggestions.containsKey(key)) {
          setState(() => _openSuggestionsKey = key);
        }
      } else {
        if (_openSuggestionsKey == key) {
          setState(() => _openSuggestionsKey = null);
        }
      }
    });
    return fn;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    for (final c in _detailControllers.values) {
      c.dispose();
    }
    for (final f in _detailFocusNodes.values) {
      f.dispose();
    }
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (_images.length >= _maxImages) {
      _showError('الحد الأقصى $_maxImages صورة');
      return;
    }
    final source = await _showSourceDialog();
    if (source == null) return;
    if (source == ImageSource.gallery) {
      final picked =
          await _picker.pickMultiImage(imageQuality: 80, maxWidth: 1200);
      if (picked.isEmpty) return;
      final remaining = _maxImages - _images.length;
      setState(() =>
          _images.addAll(picked.take(remaining).map((e) => File(e.path))));
    } else {
      final picked = await _picker.pickImage(
          source: ImageSource.camera, imageQuality: 80, maxWidth: 1200);
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
            decoration: const BoxDecoration(
              color: DS.bgCard,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(top: BorderSide(color: DS.border)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: DS.border,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Text('إضافة صور', style: DS.titleS),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                    child: ImageSourceButton(
                        icon: Icons.camera_alt_rounded,
                        label: 'كاميرا',
                        onTap: () =>
                            Navigator.pop(context, ImageSource.camera))),
                const SizedBox(width: 12),
                Expanded(
                    child: ImageSourceButton(
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

  Map<String, dynamic> _buildDetails() {
    final Map<String, dynamic> details = {};
    _detailControllers.forEach((key, ctrl) {
      final val = ctrl.text.trim();
      if (val.isNotEmpty) details[key] = val;
    });
    return details;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_declarationAccepted) {
      _showError('يجب قبول التصريح القانوني');
      return;
    }
    if (!_termsAccepted) {
      _showError('يجب قبول الشروط والأحكام');
      return;
    }
    if (_images.isEmpty) {
      _showError('يرجى إضافة صورة واحدة على الأقل');
      return;
    }

    setState(() => _loading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final organizerName = userDoc.data()?['name'] ?? 'Unknown';
      final docRef = FirebaseFirestore.instance.collection('auctions').doc();
      final imageUrls = await _uploadImages(docRef.id);
      final details = _buildDetails();

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
        'inspectionDay': null,
        'startTime': null,
        'endTime': null,
        if (details.isNotEmpty) 'details': details,
      });

      try {
        final adminSnap = await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'admin')
            .limit(1)
            .get();
        if (adminSnap.docs.isNotEmpty) {
          await NotificationService.onAuctionSubmitted(
            adminId: adminSnap.docs.first.id,
            auctionTitle: _titleController.text.trim(),
            auctionId: docRef.id,
          );
        }
        await NotificationService.notifyInterestedUsers(
          category: _category,
          auctionTitle: _titleController.text.trim(),
          auctionId: docRef.id,
          organizerId: uid,
        );
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('✅ تم إرسال طلب المزاد للمراجعة'),
              backgroundColor: DS.success),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _showError('حدث خطأ: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(msg),
            backgroundColor: DS.error,
            behavior: SnackBarBehavior.floating),
      );

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: DS.bg,
        appBar: DarkAppBar(
          title: 'تقديم طلب مزاد',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Form(
          key: _formKey,
          child: FadeTransition(
            opacity: _fade,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const FadeSlideIn(
                  delay: Duration(milliseconds: 50),
                  child: DSBanner(
                    message:
                        'سيقوم المسؤول بتحديد يوم المعاينة وتاريخ المزاد بعد المراجعة.',
                    color: DS.info,
                    icon: Icons.info_outline_rounded,
                  ),
                ),
                const SizedBox(height: 20),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 150),
                  child: FormSection(
                    title: 'صور المنتج (حتى $_maxImages صورة)',
                    icon: Icons.photo_camera_rounded,
                    child: _buildPhotoGrid(),
                  ),
                ),
                const SizedBox(height: 16),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 250),
                  child: FormSection(
                    title: 'معلومات المنتج',
                    icon: Icons.inventory_2_rounded,
                    child: _buildProductInfo(),
                  ),
                ),
                const SizedBox(height: 16),
                if (_categoryFields.containsKey(_category)) ...[
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 300),
                    child: FormSection(
                      title: 'تفاصيل $_category',
                      icon: _getCategoryIcon(_category),
                      child: _buildDetailsSection(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                FadeSlideIn(
                  delay: const Duration(milliseconds: 350),
                  child: FormSection(
                    title: 'التصريح القانوني',
                    icon: Icons.gavel_rounded,
                    iconColor: DS.warning,
                    child: _buildLegal(),
                  ),
                ),
                const SizedBox(height: 32),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 450),
                  child: GradientButton(
                    label: _loading ? 'جاري الإرسال...' : 'إرسال للمراجعة',
                    icon: Icons.send_rounded,
                    isGold: true,
                    isLoading: _loading,
                    onPressed: _submit,
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ اقتراحات تظهر عند الضغط مثل dropdown بأنيميشن
  Widget _buildDetailsSection() {
    final fields = _categoryFields[_category] ?? [];
    return Column(
      children: fields.map((f) {
        final key = f['key']!;
        final ctrl = _detailControllers[key]!;
        final fn = _detailFocusNodes[key]!;
        final suggestions = _fieldSuggestions[key];
        final isOpen = _openSuggestionsKey == key;
        final hasSugg = suggestions != null;

        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── الحقل ──
              TextFormField(
                controller: ctrl,
                focusNode: fn,
                style: const TextStyle(
                  color: DS.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: f['hint'],
                  labelText: '${f['emoji']} ${f['label']}',
                  labelStyle:
                      const TextStyle(color: DS.textMuted, fontSize: 13),
                  hintStyle: const TextStyle(color: DS.textHint, fontSize: 13),
                  filled: true,
                  fillColor:
                      isOpen ? DS.purple.withValues(alpha: 0.05) : DS.bgField,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: DS.border)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: DS.border)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: DS.purple, width: 1.5)),
                  // ✅ سهم V يدل على وجود اقتراحات
                  suffixIcon: hasSugg
                      ? AnimatedRotation(
                          turns: isOpen ? 0.5 : 0,
                          duration: const Duration(milliseconds: 250),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: isOpen ? DS.purple : DS.textMuted,
                            size: 24,
                          ),
                        )
                      : null,
                ),
              ),

              // ✅ الاقتراحات تظهر/تختفي بأنيميشن
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 250),
                crossFadeState: isOpen && hasSugg
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                firstChild: Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: DS.bgCard,
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: DS.purple.withValues(alpha: 0.25)),
                    boxShadow: [
                      BoxShadow(
                        color: DS.purple.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (suggestions ?? []).map((s) {
                      final isSelected = ctrl.text == s;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            ctrl.text = s;
                            _openSuggestionsKey = null;
                          });
                          fn.unfocus();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? DS.purple
                                : DS.purple.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? DS.purple
                                  : DS.purple.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Text(
                            s,
                            style: TextStyle(
                              color: isSelected ? Colors.white : DS.purple,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                secondChild: const SizedBox.shrink(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'مركبات':
        return Icons.directions_car_rounded;
      case 'عقارات':
        return Icons.home_rounded;
      case 'إلكترونيات':
        return Icons.devices_rounded;
      case 'أثاث':
        return Icons.chair_rounded;
      case 'مجوهرات':
        return Icons.diamond_rounded;
      case 'معدات صناعية':
        return Icons.precision_manufacturing_rounded;
      case 'عتاد فلاحي':
        return Icons.agriculture_rounded;
      case 'معدات طاقة':
        return Icons.bolt_rounded;
      case 'معدات بناء وأشغال عمومية':
        return Icons.construction_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  Widget _buildPhotoGrid() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('${_images.length}/$_maxImages صورة',
            style: const TextStyle(
                color: DS.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const Spacer(),
        if (_images.isNotEmpty)
          TextButton.icon(
            icon: const Icon(Icons.delete_sweep_rounded, size: 16),
            label: const Text('حذف الكل',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            onPressed: () => setState(() => _images.clear()),
            style: TextButton.styleFrom(foregroundColor: DS.error),
          ),
      ]),
      const SizedBox(height: 12),
      if (_images.isNotEmpty) ...[
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10),
          itemCount: _images.length,
          itemBuilder: (_, i) => Stack(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(_images[i],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity),
            ),
            Positioned(
              top: 6,
              left: 6,
              child: GestureDetector(
                onTap: () => setState(() => _images.removeAt(i)),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                      color: DS.error, shape: BoxShape.circle),
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 14),
                ),
              ),
            ),
            if (i == 0)
              Positioned(
                bottom: 8,
                right: 8,
                child: GlassCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  borderRadius: 8,
                  backgroundColor: DS.gold.withValues(alpha: 0.8),
                  child: const Text('رئيسية',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800)),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 12),
      ],
      if (_images.length < _maxImages)
        InkWell(
          onTap: _pickImages,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: DS.purpleDeep.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: DS.purple.withValues(alpha: 0.1),
                    shape: BoxShape.circle),
                child: const Icon(Icons.add_photo_alternate_rounded,
                    size: 24, color: DS.purple),
              ),
              const SizedBox(height: 8),
              Text('إضافة صور (${_maxImages - _images.length} متبقية)',
                  style: const TextStyle(
                      color: DS.purple,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
    ]);
  }

  Widget _buildProductInfo() {
    return Column(children: [
      DarkTextField(
        controller: _titleController,
        hint: 'عنوان المزاد',
        icon: Icons.title_rounded,
        validator: (v) =>
            v == null || v.trim().isEmpty ? 'هذا الحقل مطلوب' : null,
      ),
      const SizedBox(height: 16),
      DarkTextField(
        controller: _descController,
        hint: 'الوصف التفصيلي للمنتج...',
        icon: Icons.description_rounded,
        keyboardType: TextInputType.multiline,
        validator: (v) =>
            v == null || v.trim().isEmpty ? 'هذا الحقل مطلوب' : null,
      ),
      const SizedBox(height: 16),
      DarkTextField(
        controller: _priceController,
        hint: 'السعر الابتدائي (DZD)',
        icon: Icons.payments_rounded,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: (v) =>
            v == null || v.trim().isEmpty ? 'هذا الحقل مطلوب' : null,
      ),
      const SizedBox(height: 16),
      DarkTextField(
        controller: _locationController,
        hint: 'الموقع / المدينة',
        icon: Icons.location_on_rounded,
        validator: (v) =>
            v == null || v.trim().isEmpty ? 'هذا الحقل مطلوب' : null,
      ),
      const SizedBox(height: 20),
      Align(
        alignment: Alignment.centerRight,
        child: Text('الفئة', style: DS.label.copyWith(letterSpacing: 0)),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: _categories.map((c) {
          final sel = c == _category;
          return GestureDetector(
            onTap: () {
              setState(() {
                _category = c;
                _openSuggestionsKey = null;
                for (final ctrl in _detailControllers.values) {
                  ctrl.dispose();
                }
                for (final fn in _detailFocusNodes.values) {
                  fn.dispose();
                }
                _detailControllers.clear();
                _detailFocusNodes.clear();
                final fields = _categoryFields[c] ?? [];
                for (final f in fields) {
                  final key = f['key']!;
                  _detailControllers[key] = TextEditingController();
                  _detailFocusNodes[key] = _buildFocusNode(key);
                }
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: sel ? DS.purpleGradient : null,
                color: sel ? null : DS.bgElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: sel ? Colors.transparent : DS.border),
                boxShadow: sel ? DS.purpleShadow : [],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(_getCategoryIcon(c),
                    size: 14, color: sel ? Colors.white : DS.textSecondary),
                const SizedBox(width: 6),
                Text(c,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
                      color: sel ? Colors.white : DS.textSecondary,
                    )),
              ]),
            ),
          );
        }).toList(),
      ),
    ]);
  }

  Widget _buildLegal() {
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DS.warning.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DS.warning.withValues(alpha: 0.2)),
        ),
        child: const Text(
          'أؤكد أن هذا المنتج خاضع للملكية التامة وغير مرهون، وأتحمل كامل المسؤولية القانونية عن البيانات المذكورة وتفاصيل المزاد.',
          style: TextStyle(
              height: 1.6,
              fontSize: 13,
              color: DS.textPrimary,
              fontWeight: FontWeight.w500),
        ),
      ),
      const SizedBox(height: 16),
      AnimatedCheckbox(
        value: _declarationAccepted,
        onChanged: (v) => setState(() => _declarationAccepted = v!),
        label: 'أقر وأصرّح بصحة ما ورد أعلاه',
      ),
      const SizedBox(height: 12),
      AnimatedCheckbox(
        value: _termsAccepted,
        onChanged: (v) => setState(() => _termsAccepted = v!),
        label: 'أوافق على شروط وأحكام المنصة',
      ),
    ]);
  }
}
