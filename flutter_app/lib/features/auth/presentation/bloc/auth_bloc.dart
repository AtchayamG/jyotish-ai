// lib/features/auth/presentation/bloc/auth_bloc.dart
import "package:flutter_bloc/flutter_bloc.dart";
import "package:equatable/equatable.dart";
import "../../domain/entities/user_entity.dart";
import "../../domain/usecases/login_usecase.dart";
import "../../domain/usecases/register_usecase.dart";
import "../../data/datasources/auth_remote_datasource.dart";
import "../../../../core/storage/secure_storage.dart";

// Events
abstract class AuthEvent extends Equatable { const AuthEvent(); @override List<Object?> get props => []; }
class CheckAuthStatus   extends AuthEvent { const CheckAuthStatus(); }
class LoginRequested    extends AuthEvent {
  final String email, password;
  const LoginRequested(this.email, this.password);
  @override List<Object?> get props => [email];
}
class RegisterRequested extends AuthEvent {
  final String email, password, name;
  const RegisterRequested(this.email, this.password, this.name);
  @override List<Object?> get props => [email];
}
class LogoutRequested extends AuthEvent { const LogoutRequested(); }

// States
abstract class AuthState extends Equatable { const AuthState(); @override List<Object?> get props => []; }
class AuthInitial         extends AuthState { const AuthInitial(); }
class AuthLoading         extends AuthState { const AuthLoading(); }
class AuthAuthenticated   extends AuthState {
  final UserEntity user; const AuthAuthenticated(this.user);
  @override List<Object?> get props => [user.id];
}
class AuthUnauthenticated extends AuthState { const AuthUnauthenticated(); }
class AuthError           extends AuthState {
  final String message; const AuthError(this.message);
  @override List<Object?> get props => [message];
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase login;
  final RegisterUseCase register;
  final AuthRemoteDataSource remoteDs;
  final SecureStorage storage;

  AuthBloc({required this.login, required this.register,
    required this.remoteDs, required this.storage})
      : super(const AuthInitial()) {
    on<CheckAuthStatus>(_onCheck);
    on<LoginRequested>(_onLogin);
    on<RegisterRequested>(_onRegister);
    on<LogoutRequested>(_onLogout);
  }

  Future<void> _onCheck(CheckAuthStatus e, Emitter<AuthState> emit) async {
    try {
      if (await storage.isLoggedIn()) {
        final id = await storage.getUserId() ?? "";
        final email = await storage.getUserEmail() ?? "";
        final name = await storage.getUserName() ?? "";
        emit(AuthAuthenticated(UserEntity(id:id,email:email,fullName:name,isPremium:false,isAdmin:false)));
      } else { emit(const AuthUnauthenticated()); }
    } catch (_) { emit(const AuthUnauthenticated()); }
  }

  Future<void> _onLogin(LoginRequested e, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final r = await login(e.email, e.password);
      await storage.saveTokens(access: r.accessToken, refresh: r.refreshToken);
      await storage.saveUser(id: r.user.id, email: r.user.email, name: r.user.fullName);
      emit(AuthAuthenticated(r.user));
    } catch (err) { emit(AuthError(_clean(err.toString()))); }
  }

  Future<void> _onRegister(RegisterRequested e, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final r = await register(e.email, e.password, e.name);
      await storage.saveTokens(access: r.accessToken, refresh: r.refreshToken);
      await storage.saveUser(id: r.user.id, email: r.user.email, name: r.user.fullName);
      emit(AuthAuthenticated(r.user));
    } catch (err) { emit(AuthError(_clean(err.toString()))); }
  }

  Future<void> _onLogout(LogoutRequested e, Emitter<AuthState> emit) async {
    try { await storage.clearTokens(); } catch (_) {}
    emit(const AuthUnauthenticated());
  }

  String _clean(String r) {
    if (r.contains("AppError")) return r.replaceAll(RegExp(r"AppError\[.*?\]:\s*"),"");
    if (r.contains("Invalid email")) return "Invalid email or password";
    return r.length > 80 ? "${r.substring(0,80)}…" : r;
  }
}
