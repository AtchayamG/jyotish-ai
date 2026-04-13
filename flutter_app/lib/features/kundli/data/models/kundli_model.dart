class KundliModel {
  final ChartSummaryModel summary;
  final List<PlanetModel> planets;
  final String currentDasha;
  final List<DashaModel> dashas;
  final String? aiInsight;
  const KundliModel({required this.summary, required this.planets, required this.currentDasha, required this.dashas, this.aiInsight});

  factory KundliModel.fromJson(Map<String, dynamic> j) => KundliModel(
    summary: ChartSummaryModel.fromJson(j['summary']),
    planets: (j['planets'] as List).map((p) => PlanetModel.fromJson(p)).toList(),
    currentDasha: j['current_dasha'] ?? '',
    dashas: (j['dashas'] as List? ?? []).map((d) => DashaModel.fromJson(d)).toList(),
    aiInsight: j['ai_insight'],
  );
}

class ChartSummaryModel {
  final String lagna, lagnaLord, rasi, rasiLord, nakshatra, tithi, yoga, karana;
  final int pada;
  const ChartSummaryModel({required this.lagna, required this.lagnaLord, required this.rasi, required this.rasiLord, required this.nakshatra, required this.tithi, required this.yoga, required this.karana, required this.pada});
  factory ChartSummaryModel.fromJson(Map<String, dynamic> j) => ChartSummaryModel(
    lagna: j['lagna'] ?? '', lagnaLord: j['lagna_lord'] ?? '', rasi: j['rasi'] ?? '',
    rasiLord: j['rasi_lord'] ?? '', nakshatra: j['nakshatra'] ?? '', tithi: j['tithi'] ?? '',
    yoga: j['yoga'] ?? '', karana: j['karana'] ?? '', pada: j['pada'] ?? 1,
  );
}

class PlanetModel {
  final String name, symbol, rasi, degree, nakshatra, status;
  final int pada, house;
  final bool isRetrograde;
  const PlanetModel({required this.name, required this.symbol, required this.rasi, required this.degree, required this.nakshatra, required this.status, required this.pada, required this.house, required this.isRetrograde});
  factory PlanetModel.fromJson(Map<String, dynamic> j) => PlanetModel(
    name: j['name'] ?? '', symbol: j['symbol'] ?? '●', rasi: j['rasi'] ?? '',
    degree: j['degree'] ?? '', nakshatra: j['nakshatra'] ?? '', status: j['status'] ?? 'Neutral',
    pada: j['pada'] ?? 1, house: j['house'] ?? 1, isRetrograde: j['is_retrograde'] ?? false,
  );
}

class DashaModel {
  final String planet, startDate, endDate; final bool isCurrent;
  const DashaModel({required this.planet, required this.startDate, required this.endDate, required this.isCurrent});
  factory DashaModel.fromJson(Map<String, dynamic> j) => DashaModel(
    planet: j['planet'] ?? '', startDate: j['start_date'] ?? '', endDate: j['end_date'] ?? '', isCurrent: j['is_current'] ?? false,
  );
}
