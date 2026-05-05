import 'package:flutter/material.dart';
import '../../../core/constants/ds_colors.dart';

class AuctionFilterSheet extends StatefulWidget {
  final String initialCategory;
  final List<String> categories;
  final Function(String) onApply;

  const AuctionFilterSheet({
    super.key,
    required this.initialCategory,
    required this.categories,
    required this.onApply,
  });

  @override
  State<AuctionFilterSheet> createState() => _AuctionFilterSheetState();
}

class _AuctionFilterSheetState extends State<AuctionFilterSheet> {
  late String _tempCategory;

  @override
  void initState() {
    super.initState();
    _tempCategory = widget.initialCategory;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: const BoxDecoration(
          color: DS.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: DS.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 24),
            const Text('تصفية حسب الفئة', 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: DS.textPrimary)),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: widget.categories.map((c) {
                final isSel = c == _tempCategory;
                return GestureDetector(
                  onTap: () => setState(() => _tempCategory = c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSel ? DS.purple : DS.bgField,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isSel ? DS.purple : DS.border),
                      boxShadow: isSel ? DS.purpleShadow : [],
                    ),
                    child: Text(c, style: TextStyle(
                      color: isSel ? Colors.white : DS.textSecondary,
                      fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 14,
                    )),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                widget.onApply(_tempCategory);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: DS.purple,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('تطبيق الفلتر', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
