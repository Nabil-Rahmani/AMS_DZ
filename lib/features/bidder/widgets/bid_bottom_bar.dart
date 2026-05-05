import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/constants/ds_colors.dart';
import '../../../core/widgets/ds_widgets.dart';

class BidBottomBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isPlacing;
  final String? bidError;
  final VoidCallback onBidPressed;
  final Function(String) onChanged;

  const BidBottomBar({
    super.key,
    required this.controller,
    required this.isPlacing,
    required this.bidError,
    required this.onBidPressed,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            decoration: BoxDecoration(
              color: DS.bgCard.withValues(alpha: 0.75),
              border: const Border(top: BorderSide(color: DS.divider)),
              boxShadow: [
                BoxShadow(
                  color: DS.purple.withValues(alpha: 0.08),
                  blurRadius: 30,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(children: [
                Expanded(
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: DS.bgField.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: bidError != null
                              ? DS.error.withValues(alpha: 0.5)
                              : DS.border),
                    ),
                    child: TextField(
                      controller: controller,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(
                          color: DS.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700),
                      decoration: const InputDecoration(
                        hintText: 'المبلغ (DZD)',
                        hintStyle: TextStyle(color: DS.textHint, fontSize: 14),
                        prefixIcon: Icon(Icons.payments_rounded,
                            color: DS.gold, size: 20),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onChanged: onChanged,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GradientButton(
                  label: 'مزايدة',
                  isGold: true,
                  height: 52,
                  width: 110,
                  isLoading: isPlacing,
                  icon: Icons.gavel_rounded,
                  onPressed: onBidPressed,
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
