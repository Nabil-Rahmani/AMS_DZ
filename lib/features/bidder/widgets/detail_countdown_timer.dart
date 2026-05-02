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
  Duration _rem = Duration.zero; // ✅ بدل late
  Timer? _timer;                 // ✅ nullable بدل late

  @override
  void initState() {
    super.initState();
    _update();
    // ✅ لا نبدأ timer إذا انتهى الوقت
    if (_rem > Duration.zero) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(_update);
      });
    }
  }

  void _update() {
    final diff = widget.endTime.difference(DateTime.now());
    _rem = diff.isNegative ? Duration.zero : diff;
    if (_rem == Duration.zero) {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel(); // ✅ آمن
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