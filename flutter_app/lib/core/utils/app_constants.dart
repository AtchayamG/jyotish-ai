// lib/core/utils/app_constants.dart
// Single source of truth for all constant values used across the app.

abstract class AppConstants {
  // ── App Info ──────────────────────────────────────────────────────────────
  static const String appName = 'Jyotish AI';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Ancient Wisdom. Modern Clarity.';

  // ── API ───────────────────────────────────────────────────────────────────
  // Change this to your Render deployment URL in production
  static const String baseUrlDev = 'http://localhost:8000/api/v1';
  static const String baseUrlProd =
      'https://jyotish-ai-backend.onrender.com/api/v1';

  // ── Storage Keys ──────────────────────────────────────────────────────────
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String themeModeKey = 'theme_mode';
  static const String birthDetailsKey = 'birth_details';
  static const String onboardingDoneKey = 'onboarding_done';

  // ── Route Names ───────────────────────────────────────────────────────────
  static const String routeSplash = '/';
  static const String routeOnboarding = '/onboarding';
  static const String routeLogin = '/login';
  static const String routeRegister = '/register';
  static const String routeHome = '/home';
  static const String routeKundli = '/kundli';
  static const String routeHoroscope = '/horoscope';
  static const String routeMatchmaking = '/matchmaking';
  static const String routeConsultation = '/consultation';
  static const String routeAiChat = '/ai-chat';
  static const String routeProfile = '/profile';
  static const String routeSettings = '/settings';
  static const String routeMuhurtham = '/muhurtham';

  // ── Astrology ─────────────────────────────────────────────────────────────
  static const List<String> zodiacSigns = [
    'Mesha',
    'Vrishabha',
    'Mithuna',
    'Karka',
    'Simha',
    'Kanya',
    'Tula',
    'Vrischika',
    'Dhanu',
    'Makara',
    'Kumbha',
    'Meena',
  ];

  static const List<String> zodiacSymbols = [
    '♈',
    '♉',
    '♊',
    '♋',
    '♌',
    '♍',
    '♎',
    '♏',
    '♐',
    '♑',
    '♒',
    '♓',
  ];

  static const List<String> planets = [
    'Sun ☉',
    'Moon ☽',
    'Mars ♂',
    'Mercury ☿',
    'Venus ♀',
    'Jupiter ♃',
    'Saturn ♄',
    'Rahu ☊',
    'Ketu ☋',
  ];

  static const Map<String, String> planetSymbols = {
    'Sun': '☉',
    'Moon': '☽',
    'Mars': '♂',
    'Mercury': '☿',
    'Venus': '♀',
    'Jupiter': '♃',
    'Saturn': '♄',
    'Rahu': '☊',
    'Ketu': '☋',
  };

  // ── Timeouts ──────────────────────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 15);

  // ── Pagination ────────────────────────────────────────────────────────────
  static const int defaultPageSize = 20;

  // ── Animation Durations ───────────────────────────────────────────────────
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animNormal = Duration(milliseconds: 350);
  static const Duration animSlow = Duration(milliseconds: 600);
}
