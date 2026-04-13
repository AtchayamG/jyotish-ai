// lib/features/auth/domain/usecases/login_usecase.dart
import "../repositories/auth_repository.dart";
class LoginUseCase {
  final AuthRepository _r;
  LoginUseCase(this._r);
  Future<AuthResult> call(String email, String password) => _r.login(email, password);
}
