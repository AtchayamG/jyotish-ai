// lib/features/auth/presentation/bloc/auth_bloc.dart
import "package:flutter_bloc/flutter_bloc.dart";
import "package:equatable/equatable.dart";
import "../../domain/entities/user_entity.dart";
import "../../domain/usecases/login_usecase.dart";
import "../../domain/usecases/register_usecase.dart";
import "../../data/datasources/auth_remote_datasource.dart";
import "../../../../core/storage/secure_storage.dart";

// ── Events ────────────────────────────────────────────────────────────────────

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class CheckAuthStatus extends AuthEvent { const CheckAuthStatus(); }

class LoginRequested extends AuthEvent {
  final String email, password;
  const LoginRequested(this.email, this.password);
  @override
  List<Object?> get props => [email];
}

class RegisterRequested extends AuthEvent {
  final String email, password, name;
  final String? dateOfBirth;
  final String? timeOfBirth;
  final String? placeOfBirth;
  final double? latitude;
  final double? longitude;
  final double? timezone;

  const RegisterRequested(
    this.email,
    this.password,
    this.name, {
    this.dateOfBirth,
    this.timeOfBirth,
    this.placeOfBirth,
    this.latitude,
    this.longitude,
    this.timezone,
  });

  @override
  List<Object?> get props => [email, dateOfBirth];
}

class LogoutRequested extends AuthEvent { const LogoutRequested(); }

/// Fired from ProfileCompletePage when a user (created via admin portal)
/// fills in their birth details for the first time.
class UpdateBirthDetailsRequested extends AuthEvent {
  final String dateOfBirth;
  final String timeOfBirth;
  final String placeOfBirth;
  final double latitude;
  final double longitude;
  final double timezone;

  const UpdateBirthDetailsRequested({
    required this.dateOfBirth,
    required this.timeOfBirth,
    required this.placeOfBirth,
    required this.latitude,
    required this.longitude,
    required this.timezone,
  });

  @override
  List<Object?> get props =>
      [dateOfBirth, timeOfBirth, placeOfBirth, latitude, longitude, timezone];
}

// ── States ────────────────────────────────────────────────────────────────────

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial         extends AuthState { const AuthInitial(); }
class AuthLoading         extends AuthState { const AuthLoading(); }
class AuthAuthenticated   extends AuthState {
  final UserEntity user;
  const AuthAuthenticated(this.user);
  @override List<Object?> get props => [user.id, user.dateOfBirth];
}
class AuthUnauthenticated extends AuthState { const AuthUnauthenticated(); }
class AuthError           extends AuthState {
  final String message;
  const AuthError(this.message);
  @override List<Object?> get props => [message];
}

// ── BLoC ──────────────────────────────────────────────────────────────────────

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase login;
  final RegisterUseCase register;
  final AuthRemoteDataSource remoteDs;
  final SecureStorage storage;

  AuthBloc({
    required this.login,
    required this.register,
    required this.remoteDs,
    required this.storage,
  }) : super(const AuthInitial()) {
    on<CheckAuthStatus>(_onCheck);
    on<LoginRequested>(_onLogin);
    on<RegisterRequested>(_onRegister);
    on<LogoutRequested>(_onLogout);
    on<UpdateBirthDetailsRequested>(_onUpdateBirthDetails);
  }

  Future<void> _onCheck(CheckAuthStatus e, Emitter<AuthState> emit) async {
    try {
      if (await storage.isLoggedIn()) {
        final id       = await storage.getUserId()      ?? "";
        final email    = await storage.getUserEmail()   ?? "";
        final name     = await storage.getUserName()    ?? "";
        final isAdmin  = await storage.getIsAdmin();
        final dob      = await storage.getBirthDob();
        final tob      = await storage.getBirthTob();
        final place    = await storage.getBirthPlace();
        final lat      = await storage.getBirthLat();
        final lng      = await storage.getBirthLng();
        final tz       = await storage.getBirthTimezone();
        final moonSign = await storage.getMoonSign();
        emit(AuthAuthenticated(UserEntity(
          id: id, email: email, fullName: name,
          isPremium: false, isAdmin: isAdmin,
          dateOfBirth: dob, timeOfBirth: tob, placeOfBirth: place,
          birthLatitude: lat, birthLongitude: lng, birthTimezone: tz,
          moonSign: moonSign,
        )));
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (_) {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onLogin(LoginRequested e, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final r = await login(e.email, e.password);
      await storage.saveTokens(access: r.accessToken, refresh: r.refreshToken);
      await storage.saveUser(
          id: r.user.id, email: r.user.email, name: r.user.fullName,
          isAdmin: r.user.isAdmin);
      await storage.saveBirthDetails(
        dob:      r.user.dateOfBirth,
        tob:      r.user.timeOfBirth,
        place:    r.user.placeOfBirth,
        lat:      r.user.birthLatitude,
        lng:      r.user.birthLongitude,
        timezone: r.user.birthTimezone,
        moonSign: r.user.moonSign,
      );
      emit(AuthAuthenticated(r.user));
    } catch (err) {
      emit(AuthError(_clean(err.toString())));
    }
  }

  Future<void> _onRegister(RegisterRequested e, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final r = await register(
        e.email, e.password, e.name,
        dateOfBirth: e.dateOfBirth,
        timeOfBirth: e.timeOfBirth,
        placeOfBirth: e.placeOfBirth,
        latitude:    e.latitude,
        longitude:   e.longitude,
        timezone:    e.timezone,
      );
      await storage.saveTokens(access: r.accessToken, refresh: r.refreshToken);
      await storage.saveUser(
          id: r.user.id, email: r.user.email, name: r.user.fullName,
          isAdmin: r.user.isAdmin);
      await storage.saveBirthDetails(
        dob:      r.user.dateOfBirth,
        tob:      r.user.timeOfBirth,
        place:    r.user.placeOfBirth,
        lat:      r.user.birthLatitude,
        lng:      r.user.birthLongitude,
        timezone: r.user.birthTimezone,
        moonSign: r.user.moonSign,
      );
      emit(AuthAuthenticated(r.user));
    } catch (err) {
      emit(AuthError(_clean(err.toString())));
    }
  }

  Future<void> _onUpdateBirthDetails(
      UpdateBirthDetailsRequested e, Emitter<AuthState> emit) async {
    final current = state;
    if (current is! AuthAuthenticated) return;
    emit(const AuthLoading());
    try {
      final updated = await remoteDs.updateProfile(
        dateOfBirth:  e.dateOfBirth,
        timeOfBirth:  e.timeOfBirth,
        placeOfBirth: e.placeOfBirth,
        latitude:     e.latitude,
        longitude:    e.longitude,
        timezone:     e.timezone,
      );
      await storage.saveBirthDetails(
        dob:      updated.dateOfBirth,
        tob:      updated.timeOfBirth,
        place:    updated.placeOfBirth,
        lat:      updated.birthLatitude,
        lng:      updated.birthLongitude,
        timezone: updated.birthTimezone,
        moonSign: updated.moonSign,
      );
      emit(AuthAuthenticated(UserEntity(
        id:             updated.id,
        email:          updated.email,
        fullName:       updated.fullName,
        isPremium:      updated.isPremium,
        isAdmin:        updated.isAdmin,
        dateOfBirth:    updated.dateOfBirth,
        timeOfBirth:    updated.timeOfBirth,
        placeOfBirth:   updated.placeOfBirth,
        birthLatitude:  updated.birthLatitude,
        birthLongitude: updated.birthLongitude,
        birthTimezone:  updated.birthTimezone,
        moonSign:       updated.moonSign,
      )));
    } catch (err) {
      // Restore previous state on failure
      emit(current);
      emit(AuthError(_clean(err.toString())));
    }
  }

  Future<void> _onLogout(LogoutRequested e, Emitter<AuthState> emit) async {
    try { await storage.clearTokens(); } catch (_) {}
    emit(const AuthUnauthenticated());
  }

  String _clean(String r) {
    if (r.contains("AppError"))      return r.replaceAll(RegExp(r"AppError\[.*?\]:\s*"), "");
    if (r.contains("Invalid email")) return "Invalid email or password";
    if (r.contains("409"))           return "Email already registered. Please sign in.";
    return r.length > 80 ? "${r.substring(0, 80)}…" : r;
  }
}
