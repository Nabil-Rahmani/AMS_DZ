import 'package:flutter/material.dart';
import '../../../core/constants/ds_colors.dart';
import '../../../core/widgets/ds_widgets.dart';

class FormSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? iconColor;
  final Widget child;
  const FormSection({super.key, required this.title, required this.icon, required this.child, this.iconColor});

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? DS.purple;
    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Text(title, style: DS.titleS.copyWith(fontSize: 16)),
        ]),
        const SizedBox(height: 18),
        const DSDivider(),
        const SizedBox(height: 18),
        child,
      ]),
    );
  }
}

class AnimatedCheckbox extends StatefulWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final String label;
  const AnimatedCheckbox({super.key, required this.value, required this.onChanged, required this.label});

  @override
  State<AnimatedCheckbox> createState() => _AnimatedCheckboxState();
}

class _AnimatedCheckboxState extends State<AnimatedCheckbox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _scale = Tween(begin: 1.0, end: 0.95).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onChanged(!widget.value); },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: widget.value ? DS.purpleDeep : DS.bgElevated,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: widget.value ? DS.purple : DS.border,
                width: widget.value ? 1.5 : 1),
          ),
          child: Row(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22, height: 22,
              decoration: BoxDecoration(
                gradient: widget.value ? DS.purpleGradient : null,
                color: widget.value ? null : DS.bgCard,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                    color: widget.value ? Colors.transparent : DS.border),
                boxShadow: widget.value ? [
                  BoxShadow(color: DS.purple.withValues(alpha: 0.4),
                      blurRadius: 8, offset: const Offset(0, 3))
                ] : [],
              ),
              child: widget.value
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(widget.label, style: TextStyle(
              fontSize: 13,
              fontWeight: widget.value ? FontWeight.w600 : FontWeight.w500,
              color: widget.value ? DS.purple : DS.textPrimary,
            ))),
          ]),
        ),
      ),
    );
  }
}

class ImageSourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const ImageSourceButton({super.key, required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: DS.purpleDeep,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DS.purple.withValues(alpha: 0.2)),
        ),
        child: Column(children: [
          Icon(icon, color: DS.purple, size: 28),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(
              color: DS.purple, fontWeight: FontWeight.w600, fontSize: 13)),
        ]),
      ),
    );
  }
}
