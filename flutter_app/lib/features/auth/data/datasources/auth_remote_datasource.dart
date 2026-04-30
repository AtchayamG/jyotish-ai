// lib/features/auth/data/datasources/auth_remote_datasource.dart
import "../../../../core/api/api_client.dart";
import "../../../../core/api/api_constants.dart";
import "../models/auth_model.dart";

abstract class AuthRemoteDataSource {
  Future<AuthModel> login({required String email, required String password});
  Future<AuthModel> register({
    required String email,
    required String password,
    required String fullName,
    String? dateOfBirth,
    String? timeOfBirth,
    String? placeOfBirth,
    double? latitude,
    double? longitude,
    double? timezone,
  });
  Future<UserModel> updateProfile({
    String? dateOfBirth,
    String? timeOfBirth,
    String? placeOfBirth,
    double? latitude,
    double? longitude,
    double? timezone,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _c;
  AuthRemoteDataSourceImpl(this._c);

  @override
  Future<AuthModel> login({required String email, required String password}) =>
      _c.post(
        ApiConstants.login,
        body: {"email": email, "password": password},
        fromJson: AuthModel.fromJson,
      );

  @override
  Future<AuthModel> register({
    required String email,
    required String password,
    required String fullName,
    String? dateOfBirth,
    String? timeOfBirth,
    String? placeOfBirth,
    double? latitude,
    double? longitude,
    double? timezone,
  }) =>
      _c.post(
        ApiConstants.register,
        body: {
          "email": email,
          "password": password,
          "full_name": fullName,
          if (dateOfBirth != null) "date_of_birth": dateOfBirth,
          if (timeOfBirth != null) "time_of_birth": timeOfBirth,
          if (placeOfBirth != null) "place_of_birth": placeOfBirth,
          if (latitude != null) "birth_latitude": latitude,
          if (longitude != null) "birth_longitude": longitude,
          if (timezone != null) "birth_timezone": timezone,
        },
        fromJson: AuthModel.fromJson,
      );

  @override
  Future<UserModel> updateProfile({
    String? dateOfBirth,
    String? timeOfBirth,
    String? placeOfBirth,
    double? latitude,
    double? longitude,
    double? timezone,
  }) =>
      _c.put(
        ApiConstants.userProfile,
        body: {
          if (dateOfBirth != null) "date_of_birth": dateOfBirth,
          if (timeOfBirth != null) "time_of_birth": timeOfBirth,
          if (placeOfBirth != null) "place_of_birth": placeOfBirth,
          if (latitude != null) "birth_latitude": latitude,
          if (longitude != null) "birth_longitude": longitude,
          if (timezone != null) "birth_timezone": timezone,
        },
        fromJson: UserModel.fromJson,
      );
}
