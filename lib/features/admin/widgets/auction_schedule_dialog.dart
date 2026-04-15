import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:auction_app2/shared/models/auction_model.dart';
import '../../../core/constants/ds_colors.dart';
import '../../../core/widgets/ds_widgets.dart';

class AuctionScheduleDialog extends StatefulWidget {
  final AuctionModel auction;
  final void Function(DateTime, DateTime, DateTime) onSave;
  const AuctionScheduleDialog({super.key, required this.auction, required this.onSave});

  @override
  State<AuctionScheduleDialog> createState() => _AuctionScheduleDialogState();
}

class _AuctionScheduleDialogState extends State<AuctionScheduleDialog> {
  DateTime? _inspectionDay, _startTime, _endTime;

  Future<DateTime?> _pickDateTime(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return null;
    if (!context.mounted) return null;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  String _fmt(DateTime? d) {
    if (d == null) return 'اضغط للاختيار';
    return '${d.day}/${d.month}/${d.year}  ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: DS.bgModal.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: DS.border),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('جدول: ${widget.auction.title}',
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: DS.titleM),
              const SizedBox(height: 20),
              DateTile(
                icon: Icons.visibility_rounded,
                label: 'يوم المعاينة',
                value: _fmt(_inspectionDay),
                color: DS.purple,
                onTap: () async {
                  final d = await _pickDateTime(context);
                  if (d != null) setState(() => _inspectionDay = d);
                },
              ),
              const SizedBox(height: 10),
              DateTile(
                icon: Icons.play_arrow_rounded,
                label: 'بداية المزاد',
                value: _fmt(_startTime),
                color: DS.success,
                onTap: () async {
                  final d = await _pickDateTime(context);
                  if (d != null) setState(() => _startTime = d);
                },
              ),
              const SizedBox(height: 10),
              DateTile(
                icon: Icons.stop_rounded,
                label: 'نهاية المزاد',
                value: _fmt(_endTime),
                color: DS.error,
                onTap: () async {
                  final d = await _pickDateTime(context);
                  if (d != null) setState(() => _endTime = d);
                },
              ),
              const SizedBox(height: 32),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                )),
                const SizedBox(width: 12),
                Expanded(child: GradientButton(
                  label: 'حفظ الجدول',
                  height: 48,
                  onPressed: () {
                    if (_inspectionDay == null || _startTime == null || _endTime == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('يرجى تحديد كافة المواعيد')),
                      );
                      return;
                    }
                    widget.onSave(_inspectionDay!, _startTime!, _endTime!);
                    Navigator.pop(context);
                  },
                )),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

class DateTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  final VoidCallback onTap;
  const DateTile({super.key, required this.icon, required this.label, required this.value, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: DS.bgElevated.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DS.border),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: DS.label.copyWith(fontSize: 10)),
            const SizedBox(height: 2),
            Text(value, style: DS.bodySmall.copyWith(fontWeight: FontWeight.w700, color: DS.textPrimary)),
          ])),
          const Icon(Icons.edit_calendar_rounded, size: 16, color: DS.textMuted),
        ]),
      ),
    );
  }
}
