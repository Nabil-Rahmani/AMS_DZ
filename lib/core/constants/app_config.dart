class AppConfig {
  // ── أثناء التطوير ──
  static const backendUrl = 'http://172.20.10.10:3000';

  // ── بعد الـ deploy على Render ──
  // static const backendUrl = 'https://otp-backend-xxxx.onrender.com/api';

  // نفس INTERNAL_API_KEY في ملف .env نتاع الـ backend
  static const internalApiKey = 'abc123456789securekey';
}