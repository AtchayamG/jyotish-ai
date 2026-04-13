import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_constants.dart';
import '../models/match_model.dart';
abstract class MatchRemoteDataSource { Future<MatchModel> getMatch(Map<String, dynamic> body); }
class MatchRemoteDataSourceImpl implements MatchRemoteDataSource {
  final ApiClient _c; MatchRemoteDataSourceImpl(this._c);
  @override Future<MatchModel> getMatch(Map<String, dynamic> body) => _c.post(ApiConstants.match, body: body, fromJson: MatchModel.fromJson);
}
