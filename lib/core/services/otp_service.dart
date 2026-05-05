import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class OtpService {
  static const _serviceId  = 'service_0zropdq';
  static const _templateId = 'template_6ev5s3m';
  static const _publicKey  = 'brauT1LxFwcxTeLzE';

  final _firestore = FirebaseFirestore.instance;

  // ─── توليد كود 6 أرقام ───────────────────────────────────────
  String _generateOtp() {
    final rand = Random.secure();
    return List.generate(6, (_) => rand.nextInt(10)).join();
  }

  // ─── إرسال OTP عبر EmailJS + حفظه في Firestore ──────────────
  Future<Map<String, dynamic>> sendOtp(String email) async {
    try {
      final otp    = _generateOtp();
      final expiry = DateTime.now().add(const Duration(minutes: 10));

      // ✅ حفظ في Firestore — مسموح بدون auth (المستخدم غير مسجل بعد)
      await _firestore.collection('otp_codes').doc(email).set({
        'otp':       otp,
        'expiresAt': Timestamp.fromDate(expiry),
        'verified':  false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // ✅ إرسال عبر EmailJS
      final response = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'service_id':  _serviceId,
          'template_id': _templateId,
          'user_id':     _publicKey,
          'template_params': {
            'email':    email,
            'otp_code': otp,
          },
        }),
      );

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        return {'success': false, 'error': 'فشل إرسال الكود: ${response.body}'};
      }
    } catch (e) {
      return {'success': false, 'error': 'حدث خطأ: $e'};
    }
  }

  // ─── التحقق من OTP ───────────────────────────────────────────
  Future<Map<String, dynamic>> verifyOtp(String email, String enteredOtp) async {
    try {
      final doc = await _firestore.collection('otp_codes').doc(email).get();

      if (!doc.exists) {
        return {'success': false, 'error': 'لم يتم إرسال كود لهذا البريد'};
      }

      final data      = doc.data()!;
      final savedOtp  = data['otp']        as String;
      final expiresAt = (data['expiresAt'] as Timestamp).toDate();
      final verified  = data['verified']   as bool? ?? false;

      if (verified) {
        return {'success': false, 'error': 'تم استخدام هذا الكود مسبقاً'};
      }

      if (DateTime.now().isAfter(expiresAt)) {
        return {'success': false, 'error': 'انتهت صلاحية الكود، اطلب كوداً جديداً'};
      }

      if (enteredOtp.trim() != savedOtp) {
        return {'success': false, 'error': 'الكود غير صحيح'};
      }

      // ✅ الكود صحيح — احذفه من Firestore
      await _firestore.collection('otp_codes').doc(email).delete();

      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': 'حدث خطأ: $e'};
    }
  }
}