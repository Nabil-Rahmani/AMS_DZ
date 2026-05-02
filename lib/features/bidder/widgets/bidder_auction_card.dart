import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:auction_app2/shared/models/auction_model.dart';
import 'package:auction_app2/core/services/favourites_service.dart';
import 'package:auction_app2/core/services/notification_service.dart';
import 'package:auction_app2/core/services/firebase/firestore_service.dart';
import '../../../core/constants/ds_colors.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../screens/auction_detail_screen.dart';

class BidderAuctionCard extends StatelessWidget {
  final AuctionModel auction;
  const BidderAuctionCard({super.key, required this.auction});

  @override
  Widget build(BuildContext context) {
    final isActive   = auction.status == AuctionStatus.active;
    final isUpcoming = auction.status == AuctionStatus.approved;
    final isEnded    = auction.status == AuctionStatus.ended;

    return TapAnimated(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
            builder: (_) => AuctionDetailScreen(auctionId: auction.id)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color:        DS.bgCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isActive ? DS.success.withValues(alpha: 0.2) : DS.border),
          boxShadow:    DS.cardShadow,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Stack(children: [
              auction.imageUrl != null && auction.imageUrl!.isNotEmpty
                  ? Image.network(auction.imageUrl!, height: 180, width: double.infinity, fit: BoxFit.cover)
                  : Container(
                height: 180,
                decoration: const BoxDecoration(gradient: DS.headerGradient),
                child: Center(child: Icon(Icons.gavel_rounded, size: 56,
                    color: DS.gold.withValues(alpha: 0.5))),
              ),
              Positioned.fill(child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, DS.bgCard.withValues(alpha: 0.5)],
                    begin:  Alignment.topCenter,
                    end:    Alignment.bottomCenter,
                    stops:  const [0.5, 1.0],
                  ),
                ),
              )),
              Positioned(top: 14, right: 14, child: _statusBadge(auction.status, isActive)),
              Positioned(top: 10, left: 10,  child: _FavouriteButton(auctionId: auction.id)),
              if (auction.category != null)
                Positioned(bottom: 12, left: 14, child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color:        DS.bg.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(20),
                        border:       Border.all(color: DS.border.withValues(alpha: 0.4)),
                      ),
                      child: Text(auction.category!,
                          style: const TextStyle(fontSize: 11, color: DS.textSecondary, fontWeight: FontWeight.w600)),
                    ),
                  ),
                )),
            ]),
          ),

          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(auction.title, style: DS.titleS, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(auction.description, style: DS.body.copyWith(fontSize: 13),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 14),

              Row(children: [
                DSPriceTag(
                  label:  'السعر الابتدائي',
                  amount: '${auction.effectiveStartingPrice.toStringAsFixed(0)} DZD',
                  isGold: true,
                ),
                const Spacer(),

                // ✅ مزاد نشط — ينتهي بعد
                if (isActive && auction.endDateTime != null)
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('ينتهي بعد',
                        style: DS.bodySmall.copyWith(color: DS.textMuted, fontSize: 10)),
                    const SizedBox(height: 2),
                    LiveAuctionTimer(
                      endTime:   auction.endDateTime!,
                      auctionId: auction.id,
                    ),
                  ]),

                // ✅ مزاد منتهي
                if (isEnded)
                  const DarkBadge(label: 'منتهي', color: DS.textMuted),

                // ✅ مزاد قادم — يبدأ بعد
                if (isUpcoming && auction.startTime != null)
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('يبدأ بعد',
                        style: DS.bodySmall.copyWith(
                          color:      DS.purple,
                          fontSize:   10,
                          fontWeight: FontWeight.w600,
                        )),
                    const SizedBox(height: 2),
                    UpcomingAuctionTimer(
                      startTime:    auction.startTime!,
                      auctionId:    auction.id,
                      auctionTitle: auction.title,
                    ),
                  ]),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _statusBadge(AuctionStatus status, bool isActive) {
    switch (status) {
      case AuctionStatus.active:
        return const DarkBadge(label: '● LIVE', color: DS.success, dot: false, pulse: false);
      case AuctionStatus.approved:
        return const DarkBadge(label: 'قادم', color: DS.purple);
      case AuctionStatus.ended:
        return const DarkBadge(label: 'منتهي', color: DS.textMuted);
      default:
        return DarkBadge(label: status.label, color: DS.textMuted);
    }
  }
}

// ── زر المفضلة ───────────────────────────────────────
class _FavouriteButton extends StatefulWidget {
  final String auctionId;
  const _FavouriteButton({required this.auctionId});
  @override
  State<_FavouriteButton> createState() => _FavouriteButtonState();
}

class _FavouriteButtonState extends State<_FavouriteButton>
    with SingleTickerProviderStateMixin {
  bool _isFav = false;
  late AnimationController _ctrl;
  late Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _scale = Tween(begin: 1.0, end: 1.3).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _load();
  }

  Future<void> _load() async {
    final fav = await FavouritesService.isFavourite(widget.auctionId);
    if (mounted) setState(() => _isFav = fav);
  }

  Future<void> _toggle() async {
    await FavouritesService.toggle(widget.auctionId);
    setState(() => _isFav = !_isFav);
    _ctrl.forward(from: 0);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color:  _isFav ? DS.error.withValues(alpha: 0.15) : Colors.black38,
            shape:  BoxShape.circle,
            border: Border.all(
              color: _isFav ? DS.error.withValues(alpha: 0.3) : Colors.white24,
            ),
          ),
          child: Icon(
            _isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: _isFav ? DS.error : Colors.white,
            size:  18,
          ),
        ),
      ),
    );
  }
}

// ── Timer المزاد النشط ────────────────────────────────
class LiveAuctionTimer extends StatefulWidget {
  final DateTime endTime;
  final String   auctionId;
  const LiveAuctionTimer({super.key, required this.endTime, required this.auctionId});
  @override
  State<LiveAuctionTimer> createState() => _LiveAuctionTimerState();
}

class _LiveAuctionTimerState extends State<LiveAuctionTimer> {
  Duration _rem   = Duration.zero;
  Timer?   _timer;
  bool     _ended = false;

  @override
  void initState() {
    super.initState();
    _update();
    if (_rem > Duration.zero) {
      _timer = Timer.periodic(
        const Duration(seconds: 1),
            (_) { if (mounted) setState(_update); },
      );
    }
  }

  void _update() {
    final diff = widget.endTime.difference(DateTime.now());
    _rem = diff.isNegative ? Duration.zero : diff;
    if (_rem == Duration.zero && !_ended) {
      _ended = true;
      _timer?.cancel();
      _timer = null;
      // ✅ غير status لـ ended تلقائياً
      FirestoreService().checkAndEndAuction(widget.auctionId, widget.endTime);
    }
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final h = _rem.inHours.toString().padLeft(2, '0');
    final m = (_rem.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_rem.inSeconds % 60).toString().padLeft(2, '0');
    return DSCountdown(time: '$h:$m:$s', isUrgent: _rem.inMinutes < 10);
  }
}

// ── Timer المزاد القادم ───────────────────────────────
class UpcomingAuctionTimer extends StatefulWidget {
  final DateTime startTime;
  final String   auctionId;
  final String   auctionTitle;

  const UpcomingAuctionTimer({
    super.key,
    required this.startTime,
    required this.auctionId,
    required this.auctionTitle,
  });

  @override
  State<UpcomingAuctionTimer> createState() => _UpcomingAuctionTimerState();
}

class _UpcomingAuctionTimerState extends State<UpcomingAuctionTimer> {
  Duration _rem       = Duration.zero;
  Timer?   _timer;
  bool     _notifSent = false;
  bool     _started   = false;

  @override
  void initState() {
    super.initState();
    _update();
    if (_rem > Duration.zero) {
      _timer = Timer.periodic(
        const Duration(seconds: 1),
            (_) { if (mounted) setState(_update); },
      );
    } else {
      // ✅ إذا الوقت انتهى من البداية — فعّل مباشرة
      _triggerStart();
    }
  }

  void _update() {
    final diff = widget.startTime.difference(DateTime.now());
    _rem = diff.isNegative ? Duration.zero : diff;

    // ✅ إشعار 30 دقيقة قبل البداية
    if (!_notifSent && _rem.inMinutes <= 30 && _rem.inMinutes > 29) {
      _notifSent = true;
      _sendReminderNotification();
    }

    // ✅ كي يصل الوقت للصفر — فعّل المزاد
    if (_rem == Duration.zero && !_started) {
      _started = true;
      _timer?.cancel();
      _timer = null;
      _triggerStart();
    }
  }

  void _triggerStart() {
    // ✅ غير status لـ active تلقائياً
    FirestoreService().checkAndStartAuction(widget.auctionId, widget.startTime);
  }

  Future<void> _sendReminderNotification() async {
    try {
      await NotificationService.scheduleAuctionReminders(
        auctionId:    widget.auctionId,
        auctionTitle: widget.auctionTitle,
        startTime:    widget.startTime,
      );
    } catch (_) {}
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final d = _rem.inDays;
    final h = (_rem.inHours % 24).toString().padLeft(2, '0');
    final m = (_rem.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_rem.inSeconds % 60).toString().padLeft(2, '0');

    final timeText = d > 0 ? '$d يوم $h:$m:$s' : '$h:$m:$s';
    final isUrgent = _rem.inMinutes <= 30;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isUrgent
            ? DS.error.withValues(alpha: 0.1)
            : DS.purple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUrgent
              ? DS.error.withValues(alpha: 0.3)
              : DS.purple.withValues(alpha: 0.3),
        ),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(
          isUrgent ? Icons.notifications_active_rounded : Icons.schedule_rounded,
          size:  13,
          color: isUrgent ? DS.error : DS.purple,
        ),
        const SizedBox(width: 4),
        Text(
          timeText,
          style: TextStyle(
            fontSize:   12,
            color:      isUrgent ? DS.error : DS.purple,
            fontWeight: FontWeight.w700,
          ),
        ),
      ]),
    );
  }
}