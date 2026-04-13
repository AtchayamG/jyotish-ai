// lib/features/auth/domain/usecases/register_usecase.dart
import "../repositories/auth_repository.dart";
class RegisterUseCase {
  final AuthRepository _r;
  RegisterUseCase(this._r);
  Future<AuthResult> call(String email, String password, String name) => _r.register(email, password, name);
}
