// lib/core/api/api_constants.dart

class ApiConstants {
  ApiConstants._();

  static const String _renderUrl = "https://jyotish-ai-4xw2.onrender.com";
  static String get baseUrl => _renderUrl;

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String register      = "/api/v1/auth/register";
  static const String login         = "/api/v1/auth/login";
  static const String refresh       = "/api/v1/auth/refresh";
  static const String googleAuth    = "/api/v1/auth/google";
  static const String updateFCMToken = "/api/v1/auth/fcm-token";

  // ── Astrology ─────────────────────────────────────────────────────────────
  static const String kundli    = "/api/v1/astrology/kundli";
  static const String horoscope = "/api/v1/astrology/horoscope";
  static const String match     = "/api/v1/astrology/match";
  static const String muhurtham = "/api/v1/astrology/muhurtham";
  static const String aiChat    = "/api/v1/astrology/chat";

  static String horoscopeBySign(String sign) =>
      "/api/v1/astrology/horoscope/$sign";
}
