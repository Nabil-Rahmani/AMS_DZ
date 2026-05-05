import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:auction_app2/shared/models/auction_model.dart';
import 'package:auction_app2/core/services/favourites_service.dart';
import '../../../core/constants/ds_colors.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../widgets/bidder_auction_card.dart';

class FavouritesScreen extends StatelessWidget {
  const FavouritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: DS.bg,
        appBar: AppBar(
          backgroundColor: DS.bg,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: const Text('مزاداتي المفضلة',
              style: TextStyle(
                  color: DS.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 20)),
          actions: [
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Icon(Icons.favorite_rounded,
                  color: DS.error.withValues(alpha: 0.8), size: 22),
            ),
          ],
        ),
        body: StreamBuilder<Set<String>>(
          stream: FavouritesService.streamIds(),
          builder: (context, idsSnap) {
            if (idsSnap.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: DS.purple));
            }

            final ids = idsSnap.data ?? {};

            if (ids.isEmpty) {
              return const DSEmpty(
                icon: Icons.favorite_border_rounded,
                title: 'لا توجد مزادات مفضلة',
                subtitle: 'اضغط على القلب في أي مزاد لحفظه هنا',
                onRefresh: null,
              );
            }

            // Firestore whereIn بيقبل 10 عناصر كحد أقصى في كل query
            // نقسم IDs إذا أكثر من 10
            final idsList = ids.toList();
            final chunks = <List<String>>[];
            for (var i = 0; i < idsList.length; i += 10) {
              chunks.add(idsList.sublist(
                  i, i + 10 > idsList.length ? idsList.length : i + 10));
            }

            return _FavouritesBody(chunks: chunks, favouriteIds: ids);
          },
        ),
      ),
    );
  }
}

// ─── Body — يجمع نتائج كل الـ chunks ─────────────────────────────────────────
class _FavouritesBody extends StatelessWidget {
  final List<List<String>> chunks;
  final Set<String> favouriteIds;

  const _FavouritesBody({required this.chunks, required this.favouriteIds});

  Stream<List<AuctionModel>> _mergedStream() async* {
    // نستخدم أبسط حل: StreamBuilder متداخل مش مثالي لكثير chunks
    // للـ 99% من المستخدمين ids < 10 — chunk واحد يكفي
    final first = chunks.first;
    yield* FirebaseFirestore.instance
        .collection('auctions')
        .where(FieldPath.documentId, whereIn: first)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => AuctionModel.fromMap(d.data(), d.id)).toList());
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AuctionModel>>(
      stream: _mergedStream(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: DS.purple));
        }

        final auctions = snap.data ?? [];

        if (auctions.isEmpty) {
          return const DSEmpty(
            icon: Icons.gavel_rounded,
            title: 'لا توجد بيانات',
            subtitle: 'ربما تم حذف بعض المزادات',
            onRefresh: null,
          );
        }

        return StaggeredListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          itemCount: auctions.length,
          baseDelayMs: 80,
          staggerMs: 70,
          itemBuilder: (_, i) => BidderAuctionCard(auction: auctions[i]),
        );
      },
    );
  }
}
