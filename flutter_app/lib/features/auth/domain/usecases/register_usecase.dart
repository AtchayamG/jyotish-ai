// lib/features/auth/domain/usecases/register_usecase.dart
import "../repositories/auth_repository.dart";

class RegisterUseCase {
  final AuthRepository _r;
  RegisterUseCase(this._r);

  Future<AuthResult> call(
    String email,
    String password,
    String name, {
    String? dateOfBirth,
    String? timeOfBirth,
    String? placeOfBirth,
    double? latitude,
    double? longitude,
    double? timezone,
  }) =>
      _r.register(
        email,
        password,
        name,
        dateOfBirth: dateOfBirth,
        timeOfBirth: timeOfBirth,
        placeOfBirth: placeOfBirth,
        latitude: latitude,
        longitude: longitude,
        timezone: timezone,
      );
}
