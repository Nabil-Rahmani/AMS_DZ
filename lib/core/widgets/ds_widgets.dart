library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/ds_colors.dart';

// ══════════════════════════════════════════════════════════════════════════════
// LOGO WIDGET ✅ الخيار الثاني — دائرة ذهبية + زمردي
// ══════════════════════════════════════════════════════════════════════════════
class AmsLogo extends StatelessWidget {
  final double size;
  final bool showText;
  const AmsLogo({super.key, this.size = 44, this.showText = true});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // ── الحلقة الذهبية الخارجية ──
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: DS.goldLight,
                    width: size * 0.06,
                  ),
                ),
              ),
              // ── الدائرة الزمردية الداخلية ──
              Container(
                width: size * 0.82,
                height: size * 0.82,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: DS.purpleGradient,
                  boxShadow: DS.purpleShadow,
                ),
                child: Center(
                  child: Icon(
                    Icons.gavel_rounded,
                    color: Colors.white,
                    size: size * 0.42,
                  ),
                ),
              ),
              // ── النقطة الذهبية ──
              Positioned(
                bottom: size * 0.04,
                right: size * 0.04,
                child: Container(
                  width: size * 0.18,
                  height: size * 0.18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: DS.goldLight,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showText) ...[
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'AMS',
                    style: TextStyle(
                      fontSize: size * 0.45,
                      fontWeight: FontWeight.w800,
                      color: DS.textPrimary,
                      letterSpacing: 1.5,
                      height: 1,
                    ),
                  ),
                  TextSpan(
                    text: '-DZ',
                    style: TextStyle(
                      fontSize: size * 0.45,
                      fontWeight: FontWeight.w800,
                      color: DS.goldLight,
                      letterSpacing: 1.5,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: size * 2.2,
              height: 1.5,
              decoration: BoxDecoration(
                gradient: DS.goldGradient,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'AUCTIONS',
              style: TextStyle(
                fontSize: size * 0.22,
                fontWeight: FontWeight.w700,
                color: DS.gold,
                letterSpacing: 3.5,
                height: 1.2,
              ),
            ),
          ]),
        ],
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ROBUST IMAGE WIDGET
// ══════════════════════════════════════════════════════════════════════════════
class DSImage extends StatelessWidget {
  final String? url;
  final List<String>? urls;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double radius;
  final Widget? fallback;
  final bool showShimmer;

  const DSImage({
    super.key,
    this.url,
    this.urls,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.radius = 0,
    this.fallback,
    this.showShimmer = true,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Determine effective URL
    String? effectiveUrl = url;
    if ((effectiveUrl == null || effectiveUrl.isEmpty) &&
        urls != null &&
        urls!.isNotEmpty) {
      effectiveUrl = urls!.first;
    }

    // 2. Placeholder widget
    final placeholder = fallback ??
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            gradient: DS.headerGradient,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Center(
            child: Icon(
              Icons.gavel_rounded,
              size: (height != null && height! < 100) ? 24 : 48,
              color: DS.gold.withValues(alpha: 0.5),
            ),
          ),
        );

    if (effectiveUrl == null || effectiveUrl.isEmpty) {
      return placeholder;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.network(
        effectiveUrl,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child.animate().fadeIn(duration: 400.ms);
          }
          if (!showShimmer) {
            return const Center(
                child:
                    CircularProgressIndicator(color: DS.purple, strokeWidth: 2));
          }
          return Container(
            width: width,
            height: height,
            color: DS.bgCard,
          )
              .animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 1200.ms, color: DS.purple.withValues(alpha: 0.1));
        },
        errorBuilder: (context, error, stackTrace) => placeholder,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// DARK APP BAR
// ══════════════════════════════════════════════════════════════════════════════
class DarkAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showLogo;
  final List<Widget>? actions;
  final Widget? leading;
  final bool hasGradient;
  final double height;

  const DarkAppBar({
    super.key,
    this.title,
    this.showLogo = false,
    this.actions,
    this.leading,
    this.hasGradient = true,
    this.height = kToolbarHeight,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration:
          hasGradient ? const BoxDecoration(gradient: DS.headerGradient) : null,
      child: AppBar(
        backgroundColor: Colors.transparent,
        leading: leading,
        title: showLogo
            ? const AmsLogo(size: 36)
            : (title != null ? Text(title!) : null),
        actions: actions,
        centerTitle: false,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// GRADIENT BUTTON
// ══════════════════════════════════════════════════════════════════════════════
class GradientButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double height;
  final bool isGold;
  final double? width;

  const GradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.height = 56,
    this.isGold = false,
    this.width,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  @override
  Widget build(BuildContext context) {
    final gradient = widget.isGold ? DS.goldGradient : DS.purpleGradient;
    final shadows = widget.isGold ? DS.goldShadow : DS.purpleShadow;

    return TapAnimated(
      onTap: widget.onPressed,
      child: Container(
        width: widget.width ?? double.infinity,
        height: widget.height,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: widget.isLoading ? [] : shadows,
        ),
        child: widget.isLoading
            ? const Center(
                child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5)))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                ],
                Text(widget.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    )),
              ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// DARK TEXT FIELD
// ══════════════════════════════════════════════════════════════════════════════
class DarkTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final TextDirection? textDir;
  final Widget? suffix;

  const DarkTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.textDir,
    this.suffix,
  });

  @override
  State<DarkTextField> createState() => _DarkTextFieldState();
}

class _DarkTextFieldState extends State<DarkTextField> {
  bool _focused = false;
  bool _obscure = true;
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscure;
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: _focused
            ? [
                BoxShadow(
                    color: DS.purpleGlow, blurRadius: 20, spreadRadius: 2)
              ]
            : [],
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focus,
        obscureText: widget.obscure ? _obscure : false,
        keyboardType: widget.keyboardType,
        textDirection: widget.textDir,
        style: const TextStyle(
          color: DS.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        validator: widget.validator,
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: const TextStyle(color: DS.textMuted, fontSize: 14),
          filled: true,
          fillColor: _focused ? const Color(0xFFD1FAE5) : DS.bgField,
          prefixIcon: Icon(widget.icon,
              size: 18, color: _focused ? DS.purple : DS.textMuted),
          suffixIcon: widget.obscure
              ? IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 18,
                    color: DS.textMuted,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                )
              : widget.suffix,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: DS.border, width: 1.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: DS.border, width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: DS.purple, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: DS.error, width: 1.0),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: DS.error, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    ).animate(target: _focused ? 1 : 0).scale(
          begin: const Offset(1, 1),
          end: const Offset(1.02, 1.02),
          curve: Curves.easeOutBack,
          duration: const Duration(milliseconds: 200),
        );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// DARK CARD
// ══════════════════════════════════════════════════════════════════════════════
class DarkCard extends StatefulWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final Color? color;
  final Border? border;
  final double radius;
  final List<BoxShadow>? shadow;
  final EdgeInsets? margin;

  const DarkCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.border,
    this.radius = 24,
    this.shadow,
    this.margin,
  });

  @override
  State<DarkCard> createState() => _DarkCardState();
}

class _DarkCardState extends State<DarkCard> {
  @override
  Widget build(BuildContext context) {
    return TapAnimated(
      onTap: widget.onTap,
      child: Container(
        margin: widget.margin,
        padding: widget.padding ?? const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: widget.color ?? DS.bgCard,
          borderRadius: BorderRadius.circular(widget.radius),
          border: widget.border ?? Border.all(color: DS.border),
          boxShadow: widget.shadow ?? DS.cardShadow,
        ),
        child: widget.child,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// STATUS BADGE
// ══════════════════════════════════════════════════════════════════════════════
class DarkBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool dot;
  final bool pulse;

  const DarkBadge({
    super.key,
    required this.label,
    required this.color,
    this.dot = false,
    this.pulse = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (dot) ...[
          _PulseDot(color: color, animate: pulse),
          const SizedBox(width: 5),
        ],
        Text(label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            )),
      ]),
    );
  }
}

class _PulseDot extends StatefulWidget {
  final Color color;
  final bool animate;
  const _PulseDot({required this.color, this.animate = false});
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _anim = Tween(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    if (widget.animate) _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color
              .withValues(alpha: widget.animate ? _anim.value : 1.0),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SECTION HEADER
// ══════════════════════════════════════════════════════════════════════════════
class DSSection extends StatelessWidget {
  final String title;
  final String? trailing;
  final VoidCallback? onTrailing;

  const DSSection(
      {super.key, required this.title, this.trailing, this.onTrailing});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: Text(title, style: DS.titleS)),
      if (trailing != null)
        GestureDetector(
          onTap: onTrailing,
          child: Text(trailing!, style: DS.purple_text),
        ),
    ]);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// EMPTY STATE
// ══════════════════════════════════════════════════════════════════════════════
class DSEmpty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  final VoidCallback? onRefresh;

  const DSEmpty({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(
      duration: const Duration(milliseconds: 600),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: DS.purple.withValues(alpha: 0.05),
                  border: Border.all(
                      color: DS.purple.withValues(alpha: 0.1), width: 2),
                ),
                child: Icon(icon,
                    size: 44, color: DS.purple.withValues(alpha: 0.4)),
              ),
              const SizedBox(height: 32),
              Text(title,
                  style: DS.titleM.copyWith(fontSize: 20),
                  textAlign: TextAlign.center),
              if (subtitle != null) ...[
                const SizedBox(height: 12),
                Text(subtitle!,
                    style: DS.body.copyWith(color: DS.textSecondary),
                    textAlign: TextAlign.center),
              ],
              const SizedBox(height: 32),
              if (action != null)
                action!
              else if (onRefresh != null)
                ElevatedButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('تحديث القائمة'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    backgroundColor: DS.purple,
                    foregroundColor: Colors.white,
                  ),
                )
              else
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.explore_outlined, size: 18),
                  label: const Text('استكشاف المزادات'),
                ),
            ],
          ).animate().scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1, 1),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutBack,
              ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// AVATAR INITIALS
// ══════════════════════════════════════════════════════════════════════════════
class DSAvatar extends StatelessWidget {
  final String name;
  final double radius;
  final Color? color;

  const DSAvatar({super.key, required this.name, this.radius = 24, this.color});

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty
        ? name.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join()
        : '?';
    final c = color ?? DS.purple;
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [c, Color.lerp(c, DS.bg, 0.4)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: c.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Center(
          child: Text(initials,
              style: TextStyle(
                fontSize: radius * 0.55,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ))),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// STAT CARD
// ══════════════════════════════════════════════════════════════════════════════
class DSStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool loading;

  const DSStatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return DarkCard(
      padding: const EdgeInsets.all(16),
      border: Border.all(color: color.withValues(alpha: 0.2)),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 12),
            loading
                ? Container(
                    height: 22,
                    width: 48,
                    decoration: BoxDecoration(
                        color: DS.bgElevated,
                        borderRadius: BorderRadius.circular(6)))
                : Text(value,
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: color)),
            const SizedBox(height: 2),
            Text(label, style: DS.label),
          ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// INFO BANNER
// ══════════════════════════════════════════════════════════════════════════════
class DSBanner extends StatelessWidget {
  final String message;
  final Color color;
  final IconData icon;
  final Widget? action;

  const DSBanner({
    super.key,
    required this.message,
    required this.color,
    required this.icon,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 10),
          Expanded(
              child: Text(message,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    height: 1.4,
                  ))),
        ]),
        if (action != null) ...[const SizedBox(height: 12), action!],
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// BACKGROUND ORB
// ══════════════════════════════════════════════════════════════════════════════
class PurpleOrb extends StatelessWidget {
  final double size;
  final Alignment alignment;
  final double opacity;

  const PurpleOrb({
    super.key,
    this.size = 340,
    this.alignment = Alignment.topRight,
    this.opacity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Transform.translate(
        offset: Offset(size * 0.35, -size * 0.35),
        child: Opacity(
          opacity: opacity,
          child: Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
                shape: BoxShape.circle, gradient: DS.orbGradient),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PRICE TAG
// ══════════════════════════════════════════════════════════════════════════════
class DSPriceTag extends StatelessWidget {
  final String label;
  final String amount;
  final bool isGold;
  final bool large;

  const DSPriceTag({
    super.key,
    required this.label,
    required this.amount,
    this.isGold = false,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isGold ? DS.goldLight : DS.purple;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: DS.label),
      const SizedBox(height: 3),
      Text(amount,
          style: TextStyle(
            fontSize: large ? 28 : 18,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: -0.5,
          )),
    ]);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// COUNTDOWN DISPLAY
// ══════════════════════════════════════════════════════════════════════════════
class DSCountdown extends StatelessWidget {
  final String time;
  final bool isUrgent;
  final bool large;

  const DSCountdown(
      {super.key,
      required this.time,
      this.isUrgent = false,
      this.large = false});

  @override
  Widget build(BuildContext context) {
    final color = isUrgent ? DS.error : DS.warning;
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: large ? 16 : 10, vertical: large ? 10 : 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.timer_rounded, size: large ? 18 : 14, color: color),
        const SizedBox(width: 5),
        Text(time,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: large ? 20 : 13,
              color: color,
              letterSpacing: 1.5,
              fontFeatures: const [FontFeature.tabularFigures()],
            )),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// DIVIDER WITH LABEL
// ══════════════════════════════════════════════════════════════════════════════
class DSDivider extends StatelessWidget {
  final String? label;
  const DSDivider({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    if (label == null) return const Divider(color: DS.divider, height: 1);
    return Row(children: [
      const Expanded(child: Divider(color: DS.divider)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Text(label!, style: DS.label),
      ),
      const Expanded(child: Divider(color: DS.divider)),
    ]);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// GLASS CARD
// ══════════════════════════════════════════════════════════════════════════════
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double borderRadius;
  final double sigmaX;
  final double sigmaY;
  final Color? backgroundColor;
  final Border? border;
  final EdgeInsets? margin;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 24,
    this.sigmaX = 18,
    this.sigmaY = 18,
    this.backgroundColor,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY),
          child: Container(
            padding: padding ?? const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: backgroundColor ?? DS.bgCard.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(borderRadius),
              border: border ??
                  Border.all(color: DS.border.withValues(alpha: 0.5), width: 1),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// FADE-SLIDE-IN
// ══════════════════════════════════════════════════════════════════════════════
class FadeSlideIn extends StatelessWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset beginOffset;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 500),
    this.beginOffset = const Offset(0, 0.08),
  });

  @override
  Widget build(BuildContext context) {
    return child
        .animate(delay: delay)
        .fadeIn(duration: duration, curve: Curves.easeOutCubic)
        .slide(
          begin: beginOffset,
          end: Offset.zero,
          duration: duration,
          curve: Curves.easeOutCubic,
        );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAP ANIMATED
// ══════════════════════════════════════════════════════════════════════════════
class TapAnimated extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  const TapAnimated({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.97,
  });

  @override
  State<TapAnimated> createState() => _TapAnimatedState();
}

class _TapAnimatedState extends State<TapAnimated> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: widget.child.animate(target: _isPressed ? 1 : 0).scaleXY(
            end: widget.scale,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOutCubic,
          ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// STAGGERED LIST VIEW
// ══════════════════════════════════════════════════════════════════════════════
class StaggeredListView extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final EdgeInsets? padding;
  final int baseDelayMs;
  final int staggerMs;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final ScrollController? controller;

  const StaggeredListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding,
    this.baseDelayMs = 100,
    this.staggerMs = 60,
    this.physics,
    this.shrinkWrap = false,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      padding: padding,
      itemCount: itemCount,
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemBuilder: (ctx, i) => FadeSlideIn(
        delay: Duration(milliseconds: baseDelayMs + (i * staggerMs)),
        child: itemBuilder(ctx, i),
      ),
    );
  }
}
