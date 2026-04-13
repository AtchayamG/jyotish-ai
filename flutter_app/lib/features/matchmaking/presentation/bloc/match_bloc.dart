import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/match_model.dart';
import '../../domain/usecases/get_match_usecase.dart';
abstract class MatchEvent extends Equatable { const MatchEvent(); @override List<Object?> get props => []; }
class FetchMatch extends MatchEvent { final Map<String, dynamic> p1, p2; const FetchMatch(this.p1, this.p2); @override List<Object?> get props => [p1, p2]; }
abstract class MatchState extends Equatable { const MatchState(); @override List<Object?> get props => []; }
class MatchInitial extends MatchState { const MatchInitial(); }
class MatchLoading extends MatchState { const MatchLoading(); }
class MatchLoaded  extends MatchState { final MatchModel data; const MatchLoaded(this.data); @override List<Object?> get props => [data]; }
class MatchError   extends MatchState { final String msg; const MatchError(this.msg); @override List<Object?> get props => [msg]; }
class MatchBloc extends Bloc<MatchEvent, MatchState> {
  final GetMatchUseCase _uc;
  MatchBloc(this._uc) : super(const MatchInitial()) {
    on<FetchMatch>((e, emit) async { emit(const MatchLoading()); try { emit(MatchLoaded(await _uc(e.p1, e.p2))); } catch (err) { emit(MatchError(err.toString())); } });
  }
}
