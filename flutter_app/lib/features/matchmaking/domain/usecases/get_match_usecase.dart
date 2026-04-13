import '../../data/models/match_model.dart';
import '../repositories/match_repository.dart';
class GetMatchUseCase { final MatchRepository _r; GetMatchUseCase(this._r); Future<MatchModel> call(Map<String, dynamic> p1, Map<String, dynamic> p2) => _r.getMatch(p1, p2); }
