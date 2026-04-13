import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_constants.dart';
import '../models/kundli_model.dart';

abstract class KundliRemoteDataSource {
  Future<KundliModel> getKundli(Map<String, dynamic> birthDetails);
}

class KundliRemoteDataSourceImpl implements KundliRemoteDataSource {
  final ApiClient _c; KundliRemoteDataSourceImpl(this._c);
  @override
  Future<KundliModel> getKundli(Map<String, dynamic> bd) =>
    _c.post(ApiConstants.kundli, body: bd, fromJson: KundliModel.fromJson);
}
