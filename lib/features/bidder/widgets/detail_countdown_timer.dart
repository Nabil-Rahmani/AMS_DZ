import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/widgets/ds_widgets.dart';

class DetailCountdownTimer extends StatefulWidget {
  final DateTime endTime;
  const DetailCountdownTimer({super.key, required this.endTime});

  @override
  State<DetailCountdownTimer> createState() => _DetailCountdownTimerState();
}

class _DetailCountdownTimerState extends State<DetailCountdownTimer> {
  late Duration _rem;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _update();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(_update);
    });
  }

  void _update() {
    _rem = widget.endTime.difference(DateTime.now());
    if (_rem.isNegative) {
      _rem = Duration.zero;
      _timer.cancel();
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = _rem.inHours.toString().padLeft(2, '0');
    final m = (_rem.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_rem.inSeconds % 60).toString().padLeft(2, '0');
    return DSCountdown(time: '$h:$m:$s', isUrgent: _rem.inMinutes < 10, large: true);
  }
}
