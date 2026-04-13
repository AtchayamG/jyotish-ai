import '../../data/models/match_model.dart';
abstract class MatchRepository { Future<MatchModel> getMatch(Map<String, dynamic> p1, Map<String, dynamic> p2); }
