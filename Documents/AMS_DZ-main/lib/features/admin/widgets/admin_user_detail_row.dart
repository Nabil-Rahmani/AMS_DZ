import 'package:flutter/material.dart';
import '../../../core/constants/ds_colors.dart';

class AdminUserDetailRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color? valueColor;
  const AdminUserDetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: DS.purpleDeep,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: DS.purple),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: DS.label),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? DS.textPrimary,
          )),
        ])),
      ]),
    );
  }
}
