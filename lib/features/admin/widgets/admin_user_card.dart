import 'package:flutter/material.dart';
import 'package:auction_app2/shared/models/user_model.dart';
import '../../../core/constants/ds_colors.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../utils/admin_utils.dart';

class AdminUserCard extends StatefulWidget {
  final UserModel user;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  const AdminUserCard({
    super.key,
    required this.user,
    required this.onTap,
    required this.onToggle,
  });

  @override
  State<AdminUserCard> createState() => _AdminUserCardState();
}

class _AdminUserCardState extends State<AdminUserCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 90));
    _scale = Tween(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final roleColor = AdminUtils.getRoleColor(user.role);
    final roleLabel = AdminUtils.getRoleLabel(user.role);

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: GlassCard(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          borderRadius: 24,
          backgroundColor: user.isActive ? DS.bgCard.withValues(alpha: 0.4) : DS.error.withValues(alpha: 0.03),
          child: Row(children: [
            DSAvatar(name: user.name, radius: 26, color: roleColor),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(user.name, style: DS.titleS.copyWith(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(user.email, style: DS.bodySmall),
              const SizedBox(height: 10),
              Row(children: [
                DarkBadge(label: roleLabel, color: roleColor),
                const SizedBox(width: 8),
                StatusDot(isActive: user.isActive),
                const SizedBox(width: 6),
                Text(
                  user.isActive ? 'مفعّل' : 'معطّل',
                  style: DS.label.copyWith(
                    color: user.isActive ? DS.success : DS.error,
                    letterSpacing: 0,
                    fontSize: 10,
                  ),
                ),
              ]),
            ])),
            IconButton(
              icon: Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: user.isActive ? DS.error.withValues(alpha: 0.1) : DS.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: user.isActive
                      ? DS.error.withValues(alpha: 0.2)
                      : DS.success.withValues(alpha: 0.2)),
                ),
                child: Icon(
                  user.isActive ? Icons.block_rounded : Icons.check_circle_outline_rounded,
                  color: user.isActive ? DS.error : DS.success,
                  size: 20,
                ),
              ),
              onPressed: widget.onToggle,
            ),
          ]),
        ),
      ),
    );
  }
}

class StatusDot extends StatefulWidget {
  final bool isActive;
  const StatusDot({super.key, required this.isActive});

  @override
  State<StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<StatusDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _pulse = Tween(begin: 0.6, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    if (widget.isActive) {
      _ctrl.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(StatusDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _ctrl.repeat(reverse: true);
      } else {
        _ctrl.stop();
      }
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return Container(width: 7, height: 7,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: DS.error));
    }
    return FadeTransition(
      opacity: _pulse,
      child: Container(width: 7, height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: DS.success,
            boxShadow: [BoxShadow(color: DS.success.withValues(alpha: 0.6), blurRadius: 4)],
          )),
    );
  }
}
