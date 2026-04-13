class KundliEntity {
  final String lagna, rasi, nakshatra, currentDasha;
  final List<PlanetEntity> planets;
  final String? aiInsight;
  const KundliEntity({required this.lagna, required this.rasi, required this.nakshatra, required this.currentDasha, required this.planets, this.aiInsight});
}
class PlanetEntity {
  final String name, symbol, rasi, degree, nakshatra, status;
  final int house; final bool isRetrograde;
  const PlanetEntity({required this.name, required this.symbol, required this.rasi, required this.degree, required this.nakshatra, required this.status, required this.house, required this.isRetrograde});
}
