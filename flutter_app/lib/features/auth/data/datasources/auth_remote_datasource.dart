// lib/features/auth/data/datasources/auth_remote_datasource.dart
import "../../../../core/api/api_client.dart";
import "../../../../core/api/api_constants.dart";
import "../models/auth_model.dart";

abstract class AuthRemoteDataSource {
  Future<AuthModel> login({required String email, required String password});
  Future<AuthModel> register({required String email, required String password, required String fullName});
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _c;
  AuthRemoteDataSourceImpl(this._c);

  @override
  Future<AuthModel> login({required String email, required String password}) =>
      _c.post(ApiConstants.login,
          body: {"email": email, "password": password},
          fromJson: AuthModel.fromJson);

  @override
  Future<AuthModel> register({required String email, required String password, required String fullName}) =>
      _c.post(ApiConstants.register,
          body: {"email": email, "password": password, "full_name": fullName},
          fromJson: AuthModel.fromJson);
}
