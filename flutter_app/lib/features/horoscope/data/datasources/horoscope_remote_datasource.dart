import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_constants.dart';
import '../models/horoscope_model.dart';
abstract class HoroscopeRemoteDataSource {
  Future<HoroscopeModel> getHoroscope(String sign, String type);
}
class HoroscopeRemoteDataSourceImpl implements HoroscopeRemoteDataSource {
  final ApiClient _c; HoroscopeRemoteDataSourceImpl(this._c);
  @override
  Future<HoroscopeModel> getHoroscope(String sign, String type) =>
    _c.post(ApiConstants.horoscope, body: {'zodiac_sign': sign, 'horoscope_type': type}, fromJson: HoroscopeModel.fromJson);
}
