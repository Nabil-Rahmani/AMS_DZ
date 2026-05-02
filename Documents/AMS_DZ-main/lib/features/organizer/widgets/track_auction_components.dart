import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/ds_colors.dart';
import '../../../core/widgets/ds_widgets.dart';

class DetailCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const DetailCard({super.key, required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      backgroundColor: DS.bgCard.withValues(alpha: 0.3),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: DS.purple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: DS.purple),
          ),
          const SizedBox(width: 14),
          Text(title, style: DS.titleS.copyWith(fontSize: 16)),
        ]),
        const SizedBox(height: 18),
        const DSDivider(),
        const SizedBox(height: 10),
        ...children,
      ]),
    );
  }
}

class DetailRow extends StatelessWidget {
  final String label, value;
  final bool highlight;
  const DetailRow({super.key, required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: DS.divider))),
      child: Row(children: [
        Expanded(flex: 2, child: Text(label,
            style: const TextStyle(fontSize: 12, color: DS.textSecondary))),
        Expanded(flex: 3, child: Text(value, style: TextStyle(
          fontSize: 13,
          fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
          color: highlight ? DS.purple : DS.textPrimary,
        ))),
      ]),
    );
  }
}

class LiveTimer extends StatefulWidget {
  final DateTime endTime;
  const LiveTimer({super.key, required this.endTime});
  @override
  State<LiveTimer> createState() => _LiveTimerState();
}

class _LiveTimerState extends State<LiveTimer> {
  late Duration _rem;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _update();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) { if (mounted) setState(_update); });
  }

  void _update() {
    _rem = widget.endTime.difference(DateTime.now());
    if (_rem.isNegative) { _rem = Duration.zero; _timer.cancel(); }
  }

  @override
  void dispose() { _timer.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final h = _rem.inHours.toString().padLeft(2, '0');
    final m = (_rem.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_rem.inSeconds % 60).toString().padLeft(2, '0');
    return DSCountdown(time: '$h:$m:$s', isUrgent: _rem.inMinutes < 10);
  }
}
