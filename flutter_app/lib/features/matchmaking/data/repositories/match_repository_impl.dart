import '../../domain/repositories/match_repository.dart';
import '../datasources/match_remote_datasource.dart';
import '../models/match_model.dart';
class MatchRepositoryImpl implements MatchRepository {
  final MatchRemoteDataSource _ds; MatchRepositoryImpl(this._ds);
  @override Future<MatchModel> getMatch(Map<String, dynamic> p1, Map<String, dynamic> p2) => _ds.getMatch({'person1': p1, 'person2': p2});
}
