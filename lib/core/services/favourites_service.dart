import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// خدمة المفضلة — تحفظ في Firestore تحت:
/// users/{uid}/favourites/{auctionId}
class FavouritesService {
  // ─── مرجع الـ subcollection ───────────────────────────
  static CollectionReference<Map<String, dynamic>> _col() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('favourites');
  }

  // ─── إضافة / حذف (Toggle) ────────────────────────────
  static Future<void> toggle(String auctionId) async {
    final doc = _col().doc(auctionId);
    final snap = await doc.get();
    if (snap.exists) {
      await doc.delete();
    } else {
      await doc.set({'savedAt': FieldValue.serverTimestamp()});
    }
  }

  // ─── هل مزاد معين في المفضلة؟ ─────────────────────────
  static Future<bool> isFavourite(String auctionId) async {
    final snap = await _col().doc(auctionId).get();
    return snap.exists;
  }

  // ─── Stream — قائمة IDs المفضلة (للـ UI الفوري) ───────
  static Stream<Set<String>> streamIds() {
    return _col()
        .orderBy('savedAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => d.id).toSet());
  }

  // ─── جلب مرة واحدة (one-shot) ─────────────────────────
  static Future<Set<String>> fetchIds() async {
    final snap = await _col().get();
    return snap.docs.map((d) => d.id).toSet();
  }
}