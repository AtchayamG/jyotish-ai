// lib/core/storage/secure_storage.dart
import "package:flutter_secure_storage/flutter_secure_storage.dart";
import "../api/token_interceptor.dart";

class SecureStorage implements TokenStorage {
  static FlutterSecureStorage? _storage;

  static FlutterSecureStorage get _s {
    _storage ??= const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
      webOptions: WebOptions(
        dbName: "jyotish_ai_secure",
        publicKey: "jyotish_ai_key",
      ),
    );
    return _storage!;
  }

  // ── Keys ──────────────────────────────────────────────────────────────────
  static const _kAccess    = "access_token";
  static const _kRefresh   = "refresh_token";
  static const _kUserId    = "user_id";
  static const _kEmail     = "user_email";
  static const _kName      = "user_name";
  static const _kIsAdmin   = "is_admin";
  static const _kUserTier  = "user_tier";
  // Birth details
  static const _kDob       = "birth_dob";
  static const _kTob       = "birth_tob";
  static const _kPlace     = "birth_place";
  static const _kLat       = "birth_lat";
  static const _kLng       = "birth_lng";
  static const _kTz        = "birth_tz";
  static const _kMoonSign  = "moon_sign";

  // ── Token interface ───────────────────────────────────────────────────────

  @override
  Future<String?> getAccessToken() async {
    try { return await _s.read(key: _kAccess); } catch (_) { return null; }
  }

  @override
  Future<String?> getRefreshToken() async {
    try { return await _s.read(key: _kRefresh); } catch (_) { return null; }
  }

  @override
  Future<void> saveTokens({required String access, required String refresh}) async {
    try {
      await _s.write(key: _kAccess, value: access);
      await _s.write(key: _kRefresh, value: refresh);
    } catch (_) {}
  }

  @override
  Future<void> clearTokens() async {
    try { await _s.deleteAll(); } catch (_) {}
  }

  // ── User identity ─────────────────────────────────────────────────────────

  Future<void> saveUser({
    required String id,
    required String email,
    required String name,
    bool isAdmin = false,
    String userTier = "free",
  }) async {
    try {
      await _s.write(key: _kUserId, value: id);
      await _s.write(key: _kEmail, value: email);
      await _s.write(key: _kName, value: name);
      await _s.write(key: _kIsAdmin, value: isAdmin.toString());
      await _s.write(key: _kUserTier, value: userTier);
    } catch (_) {}
  }

  Future<String?> getUserId() async {
    try { return await _s.read(key: _kUserId); } catch (_) { return null; }
  }

  Future<String?> getUserEmail() async {
    try { return await _s.read(key: _kEmail); } catch (_) { return null; }
  }

  Future<String?> getUserName() async {
    try { return await _s.read(key: _kName); } catch (_) { return null; }
  }

  Future<bool> getIsAdmin() async {
    try {
      final v = await _s.read(key: _kIsAdmin);
      return v == 'true';
    } catch (_) { return false; }
  }

  Future<String> getUserTier() async {
    try {
      return await _s.read(key: _kUserTier) ?? "free";
    } catch (_) { return "free"; }
  }

  Future<bool> isLoggedIn() async => (await getAccessToken()) != null;

  // ── Birth details ─────────────────────────────────────────────────────────

  Future<void> saveBirthDetails({
    String? dob,
    String? tob,
    String? place,
    double? lat,
    double? lng,
    double? timezone,
    String? moonSign,
  }) async {
    try {
      if (dob != null)      await _s.write(key: _kDob, value: dob);
      if (tob != null)      await _s.write(key: _kTob, value: tob);
      if (place != null)    await _s.write(key: _kPlace, value: place);
      if (lat != null)      await _s.write(key: _kLat, value: lat.toString());
      if (lng != null)      await _s.write(key: _kLng, value: lng.toString());
      if (timezone != null) await _s.write(key: _kTz, value: timezone.toString());
      if (moonSign != null) await _s.write(key: _kMoonSign, value: moonSign);
    } catch (_) {}
  }

  Future<String?> getBirthDob()  async {
    try { return await _s.read(key: _kDob); }   catch (_) { return null; }
  }
  Future<String?> getBirthTob()  async {
    try { return await _s.read(key: _kTob); }   catch (_) { return null; }
  }
  Future<String?> getBirthPlace() async {
    try { return await _s.read(key: _kPlace); } catch (_) { return null; }
  }
  Future<double?> getBirthLat() async {
    try {
      final v = await _s.read(key: _kLat);
      return v != null ? double.tryParse(v) : null;
    } catch (_) { return null; }
  }
  Future<double?> getBirthLng() async {
    try {
      final v = await _s.read(key: _kLng);
      return v != null ? double.tryParse(v) : null;
    } catch (_) { return null; }
  }
  Future<double?> getBirthTimezone() async {
    try {
      final v = await _s.read(key: _kTz);
      return v != null ? double.tryParse(v) : null;
    } catch (_) { return null; }
  }
  Future<String?> getMoonSign() async {
    try { return await _s.read(key: _kMoonSign); } catch (_) { return null; }
  }
}
