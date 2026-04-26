import 'package:auction_app2/shared/models/user_model.dart';
import 'package:auction_app2/core/services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // ─── تسجيل الدخول ───────────────────────────────────────────
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email:    email.trim(),
        password: password.trim(),
      );
      final uid  = credential.user!.uid;
      final user = credential.user!;

      await user.reload();

      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) {
        return {'success': false, 'error': 'لم يتم العثور على بيانات المستخدم'};
      }

      // ✅ تحقق من isVerified في Firestore
      final isVerified = doc.data()?['isVerified'] as bool? ?? false;
      if (!isVerified) {
        await _auth.signOut();
        return {
          'success':          false,
          'emailNotVerified': true,
          'error':            'يجب تأكيد بريدك الإلكتروني أولاً',
        };
      }

      await NotificationService.saveFcmToken(uid);
      return {'success': true, 'user': user, 'data': doc.data()};

    } on FirebaseAuthException catch (e) {
      return {'success': false, 'error': _getErrorMessage(e.code)};
    } catch (e) {
      return {'success': false, 'error': 'حدث خطأ غير متوقع: $e'};
    }
  }

  // ─── إنشاء حساب ─────────────────────────────────────────────
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
    String accountType = 'individual',
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email:    email.trim(),
        password: password.trim(),
      );
      final uid = credential.user!.uid;

      await _firestore.collection('users').doc(uid).set({
        'uid':         uid,
        'name':        fullName.trim(),
        'email':       email.trim(),
        'phone':       phone.trim(),
        'role':        role,
        'accountType': accountType,
        'isActive':    true,
        'isVerified':  false,
        if (role == 'organizer') 'kycStatus': KycStatus.pending.name,
        'createdAt':   FieldValue.serverTimestamp(),
      });

      await credential.user!.updateDisplayName(fullName.trim());

      // ✅ لا signOut هنا — نبقى مسجلين حتى نكمل التحقق

      // إشعار للأدمين عند organizer جديد
      if (role == 'organizer') {
        try {
          final adminSnap = await _firestore
              .collection('users')
              .where('role', isEqualTo: 'admin')
              .limit(1)
              .get();
          if (adminSnap.docs.isNotEmpty) {
            await NotificationService.onKycSubmitted(
              adminId:    adminSnap.docs.first.id,
              sellerName: fullName.trim(),
              sellerId:   uid,
            );
          }
        } catch (_) {}
      }

      return {'success': true, 'user': credential.user};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'error': _getErrorMessage(e.code)};
    } catch (e) {
      return {'success': false, 'error': 'حدث خطأ غير متوقع: $e'};
    }
  }

  // ─── إعادة إرسال إيميل التحقق ───────────────────────────────
  Future<Map<String, dynamic>> resendVerificationEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email:    email.trim(),
        password: password.trim(),
      );
      if (credential.user!.emailVerified) {
        await _auth.signOut();
        return {'success': false, 'error': 'البريد الإلكتروني مؤكد بالفعل'};
      }
      await credential.user!.sendEmailVerification();
      await _auth.signOut();
      return {'success': true};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'error': _getErrorMessage(e.code)};
    } catch (e) {
      return {'success': false, 'error': 'حدث خطأ: $e'};
    }
  }

  // ─── التحقق من حالة الإيميل ─────────────────────────────────
  Future<bool> checkEmailVerified({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email:    email.trim(),
        password: password.trim(),
      );
      final user = credential.user;
      if (user == null) return false;

      await user.reload();
      final refreshed = _auth.currentUser;

      print('=== EMAIL VERIFICATION DEBUG ===');
      print('email: ${refreshed?.email}');
      print('emailVerified: ${refreshed?.emailVerified}');
      print('uid: ${refreshed?.uid}');
      print('================================');

      final verified = refreshed?.emailVerified ?? false;
      if (!verified) await _auth.signOut();
      return verified;
    } catch (_) {
      return false;
    }
  }

  // ─── جلب UserModel ──────────────────────────────────────────
  Future<UserModel?> getUserModel(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      return null;
    }
  }

  // ─── نسيت كلمة المرور ───────────────────────────────────────
  Future<Map<String, dynamic>> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return {'success': true};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'error': _getErrorMessage(e.code)};
    } catch (e) {
      return {'success': false, 'error': 'حدث خطأ غير متوقع: $e'};
    }
  }

  // ─── تسجيل الخروج ───────────────────────────────────────────
  Future<void> signOut() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      try { await NotificationService.clearFcmToken(uid); } catch (_) {}
    }
    await _auth.signOut();
  }

  // ─── رسائل الخطأ ────────────────────────────────────────────
  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':         return 'البريد الإلكتروني غير مسجل';
      case 'wrong-password':         return 'كلمة المرور غير صحيحة';
      case 'invalid-credential':     return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
      case 'email-already-in-use':   return 'البريد الإلكتروني مستخدم مسبقاً';
      case 'weak-password':          return 'كلمة المرور ضعيفة، يجب أن تكون 6 أحرف على الأقل';
      case 'invalid-email':          return 'صيغة البريد الإلكتروني غير صحيحة';
      case 'too-many-requests':      return 'تم تجاوز عدد المحاولات، حاول لاحقاً';
      case 'network-request-failed': return 'تحقق من اتصالك بالإنترنت';
      case 'user-disabled':          return 'تم تعطيل هذا الحساب';
      default:                       return 'حدث خطأ: $code';
    }
  }
}