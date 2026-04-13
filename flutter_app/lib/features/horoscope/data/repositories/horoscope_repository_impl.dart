import '../../domain/repositories/horoscope_repository.dart';
import '../datasources/horoscope_remote_datasource.dart';
import '../models/horoscope_model.dart';
class HoroscopeRepositoryImpl implements HoroscopeRepository {
  final HoroscopeRemoteDataSource _ds; HoroscopeRepositoryImpl(this._ds);
  @override Future<HoroscopeModel> getHoroscope(String sign, String type) => _ds.getHoroscope(sign, type);
}
