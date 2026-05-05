// lib/features/auth/screens/terms_screen.dart
import 'package:flutter/material.dart';
import '../../../core/constants/ds_colors.dart';
import '../../../core/widgets/ds_widgets.dart';

class TermsScreen extends StatefulWidget {
  /// إذا كان true — يظهر زر "موافقة ومتابعة" (عند التسجيل)
  /// إذا كان false — شاشة عرض فقط
  final bool requireAcceptance;
  final VoidCallback? onAccepted;

  const TermsScreen({
    super.key,
    this.requireAcceptance = false,
    this.onAccepted,
  });

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  bool _accepted = false;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: DS.bg,
        appBar: DarkAppBar(
          title: 'الشروط والخصوصية',
          leading: widget.requireAcceptance
              ? null
              : IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
        ),
        body: Column(children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ──
                    Center(
                      child: Column(children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: DS.purpleGradient,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: DS.purpleShadow,
                          ),
                          child: const Icon(Icons.gavel_rounded,
                              color: Colors.white, size: 32),
                        ),
                        const SizedBox(height: 16),
                        Text('الشروط والخصوصية', style: DS.titleXL),
                        const SizedBox(height: 6),
                        Text(
                            'يرجى قراءة والموافقة على شروط الاستخدام وسياسة الخصوصية للمتابعة',
                            style: DS.bodySmall,
                            textAlign: TextAlign.center),
                      ]),
                    ),
                    const SizedBox(height: 28),

                    // ── شروط الاستخدام ──
                    const _SectionCard(
                      icon: Icons.article_rounded,
                      color: DS.purple,
                      title: '1. شروط الاستخدام',
                      items: [
                        'مرحباً بكم في AMS-DZ. باستخدامك لهذا التطبيق، فإنك توافق على الالتزام بالشروط التالية.',
                        'يجب أن تكون المعلومات المقدمة دقيقة وصحيحة.',
                        'يُمنع استخدام التطبيق لأغراض غير قانونية.',
                        'يتحمل المستخدم مسؤولية الحفاظ على سرية حسابه.',
                        'التطبيق منصة للمزادات العلنية ويخضع لقوانين التجارة المعمول بها في الجزائر.',
                        'يحق للإدارة إيقاف أي حساب يخالف هذه الشروط دون إشعار مسبق.',
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── سياسة الخصوصية ──
                    const _SectionCard(
                      icon: Icons.shield_rounded,
                      color: DS.info,
                      title: '2. سياسة الخصوصية',
                      items: [
                        'نحن نحترم خصوصيتك ونلتزم بحمايتها.',
                        'نجمع معلوماتك الأساسية لتقديم خدمة أفضل.',
                        'لا نبيع بياناتك الشخصية لأطراف ثالثة.',
                        'نستخدم تقنيات تشفير متطورة لحماية بياناتك.',
                        'يتم استخدام ملفات تعريف الارتباط لتحسين تجربة المستخدم.',
                        'يمكنك طلب حذف بياناتك في أي وقت عبر التواصل مع الدعم.',
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── قواعد المزايدة ──
                    const _SectionCard(
                      icon: Icons.gavel_rounded,
                      color: DS.warning,
                      title: '3. قواعد المزايدة',
                      items: [
                        'كل مزايدة تُقدَّم تعتبر عرضاً ملزماً قانونياً.',
                        'يجب دفع الضمان المطلوب للمشاركة في المزاد.',
                        'يسترد الضمان تلقائياً لغير الفائزين بعد انتهاء المزاد.',
                        'الفائز ملزم بإتمام الصفقة وفق الشروط المتفق عليها.',
                        'أي محاولة للتلاعب أو الغش تؤدي إلى إيقاف الحساب نهائياً.',
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── المسؤولية ──
                    const _SectionCard(
                      icon: Icons.balance_rounded,
                      color: DS.success,
                      title: '4. حدود المسؤولية',
                      items: [
                        'المنصة وسيط بين البائع والمشتري ولا تتحمل المسؤولية عن جودة المنتجات.',
                        'يتحمل البائع المسؤولية الكاملة عن صحة وصف المنتج.',
                        'في حالة النزاعات، يحق للإدارة التدخل للفصل في الخلافات.',
                      ],
                    ),
                    const SizedBox(height: 28),
                  ]),
            ),
          ),

          // ── Footer ──
          Container(
            padding: EdgeInsets.fromLTRB(
                20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
            decoration: const BoxDecoration(
              color: DS.bgCard,
              border: Border(top: BorderSide(color: DS.border)),
            ),
            child: widget.requireAcceptance
                ? Column(mainAxisSize: MainAxisSize.min, children: [
                    // Checkbox
                    GestureDetector(
                      onTap: () => setState(() => _accepted = !_accepted),
                      child: Row(children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: _accepted ? DS.purple : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: _accepted ? DS.purple : DS.border,
                                width: 1.5),
                          ),
                          child: _accepted
                              ? const Icon(Icons.check_rounded,
                                  color: Colors.white, size: 16)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text('أوافق على الشروط وسياسة الخصوصية',
                                style: DS.body)),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    GradientButton(
                      label: 'متابعة',
                      icon: Icons.arrow_back_ios_new_rounded,
                      onPressed: _accepted
                          ? () {
                              widget.onAccepted?.call();
                              Navigator.pop(context, true);
                            }
                          : null,
                    ),
                  ])
                : GradientButton(
                    label: 'حسناً، فهمت',
                    onPressed: () => Navigator.pop(context),
                  ),
          ),
        ]),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final List<String> items;

  const _SectionCard(
      {required this.icon,
      required this.color,
      required this.title,
      required this.items});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 20,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Text(title, style: DS.titleS.copyWith(fontSize: 15)),
        ]),
        const SizedBox(height: 14),
        const Divider(color: DS.border, height: 1),
        const SizedBox(height: 14),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 6,
                  height: 6,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(item, style: DS.body.copyWith(height: 1.5))),
              ]),
            )),
      ]),
    );
  }
}
