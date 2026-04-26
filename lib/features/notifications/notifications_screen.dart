// lib/features/notifications/notifications_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/ds_colors.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/services/notification_service.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: DS.bg,
        body: Column(children: [
          Container(
            height: 140,
            decoration: const BoxDecoration(gradient: DS.headerGradient),
            child: SafeArea(bottom: false, child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: DS.purple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: DS.purple.withValues(alpha: 0.2)),
                  ),
                  child: const Icon(Icons.notifications_rounded, color: DS.purple, size: 22),
                ),
                const SizedBox(width: 14),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('الإشعارات', style: DS.titleL.copyWith(fontSize: 22)),
                  Text('كل التنبيهات والأخبار', style: DS.bodySmall),
                ]),
                const Spacer(),
                // زر قراءة الكل
                GestureDetector(
                  onTap: () => NotificationService.markAllAsRead(uid),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: DS.purple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: DS.purple.withValues(alpha: 0.2)),
                    ),
                    child: Text('قراءة الكل', style: DS.label.copyWith(color: DS.purple)),
                  ),
                ),
              ]),
            )),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: NotificationService.streamNotifications(uid),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting)
                  return const Center(child: CircularProgressIndicator(color: DS.purple));
                final notifs = snap.data ?? [];
                if (notifs.isEmpty)
                  return const DSEmpty(
                    icon: Icons.notifications_off_rounded,
                    title: 'لا توجد إشعارات',
                    subtitle: 'ستظهر هنا كل التنبيهات',
                  );
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _NotifTile(notif: notifs[i]),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final Map<String, dynamic> notif;
  const _NotifTile({required this.notif});

  static const _typeIcons = {
    'kycSubmitted':      Icons.person_add_rounded,
    'kycApproved':       Icons.verified_rounded,
    'kycRejected':       Icons.cancel_rounded,
    'auctionSubmitted':  Icons.pending_rounded,
    'auctionApproved':   Icons.check_circle_rounded,
    'auctionRejected':   Icons.cancel_rounded,
    'priceAdjusted':     Icons.edit_rounded,
    'newBid':            Icons.trending_up_rounded,
    'bidOutbid':         Icons.money_off_rounded,
    'auctionStarted':    Icons.play_circle_rounded,
    'auctionEnded':      Icons.flag_rounded,
    'winner':            Icons.emoji_events_rounded,
    'depositPaid':       Icons.lock_rounded,
    'depositRefunded':   Icons.lock_open_rounded,
    'newAuctionCategory':Icons.campaign_rounded,
    'reminderDay':       Icons.calendar_today_rounded,
    'reminderHour':      Icons.schedule_rounded,
    'reminderThirty':    Icons.timer_rounded,
  };

  static const _typeColors = {
    'kycApproved':       DS.success,
    'auctionApproved':   DS.success,
    'winner':            DS.gold,
    'newBid':            DS.purple,
    'bidOutbid':         Color(0xFFF59E0B),
    'kycRejected':       DS.error,
    'auctionRejected':   DS.error,
    'newAuctionCategory':DS.info,
  };

  @override
  Widget build(BuildContext context) {
    final type     = notif['type'] as String? ?? '';
    final isRead   = notif['isRead'] as bool? ?? true;
    final icon     = _typeIcons[type] ?? Icons.notifications_rounded;
    final color    = _typeColors[type] ?? DS.purple;
    final title    = notif['title'] as String? ?? '';
    final message  = notif['message'] as String? ?? '';
    final createdAt = notif['createdAt'];
    String timeStr = '';
    if (createdAt is Timestamp) {
      final dt = createdAt.toDate();
      timeStr = '${dt.day}/${dt.month}/${dt.year}';
    }

    return GestureDetector(
      onTap: () => NotificationService.markAsRead(notif['id']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isRead ? DS.bgCard : DS.purple.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isRead ? DS.border : DS.purple.withValues(alpha: 0.3),
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(title,
                  style: DS.label.copyWith(
                      fontWeight: isRead ? FontWeight.w600 : FontWeight.w800))),
              if (!isRead)
                Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(color: DS.purple, shape: BoxShape.circle),
                ),
            ]),
            const SizedBox(height: 3),
            Text(message, style: DS.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(timeStr, style: DS.bodySmall.copyWith(color: DS.textMuted, fontSize: 11)),
          ])),
        ]),
      ),
    );
  }
}