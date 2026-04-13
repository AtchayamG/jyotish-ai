import '../../domain/entities/kundli_entity.dart';
import '../../domain/repositories/kundli_repository.dart';
import '../datasources/kundli_remote_datasource.dart';

class KundliRepositoryImpl implements KundliRepository {
  final KundliRemoteDataSource _ds; KundliRepositoryImpl(this._ds);
  @override
  Future<KundliEntity> getKundli({required int year, required int month, required int day, required int hour, required int minute, required double latitude, required double longitude, required String name}) async {
    final m = await _ds.getKundli({'name': name, 'year': year, 'month': month, 'day': day, 'hour': hour, 'minute': minute, 'latitude': latitude, 'longitude': longitude, 'timezone': 5.5, 'ayanamsa': 'lahiri'});
    return KundliEntity(
      lagna: m.summary.lagna, rasi: m.summary.rasi, nakshatra: m.summary.nakshatra,
      currentDasha: m.currentDasha, aiInsight: m.aiInsight,
      planets: m.planets.map((p) => PlanetEntity(name: p.name, symbol: p.symbol, rasi: p.rasi, degree: p.degree, nakshatra: p.nakshatra, status: p.status, house: p.house, isRetrograde: p.isRetrograde)).toList(),
    );
  }
}
