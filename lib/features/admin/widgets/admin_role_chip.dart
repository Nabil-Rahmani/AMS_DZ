import 'package:flutter/material.dart';
import '../../../core/constants/ds_colors.dart';

class AdminRoleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;
  const AdminRoleChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.color = DS.purple,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : DS.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : DS.border),
          boxShadow: selected ? [
            BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8)
          ] : [],
        ),
        child: Text(label, style: TextStyle(
          color: selected ? Colors.white : DS.textSecondary,
          fontSize: 13,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        )),
      ),
    );
  }
}
