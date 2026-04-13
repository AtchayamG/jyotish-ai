class HoroscopeModel {
  final String zodiacSign, type, dateRange, prediction, luckyColor, luckyGemstone;
  final double overallScore, careerScore, loveScore, healthScore, financeScore;
  final int luckyNumber;
  final List<String> doToday, avoidToday;
  const HoroscopeModel({required this.zodiacSign, required this.type, required this.dateRange, required this.prediction, required this.luckyColor, required this.luckyGemstone, required this.overallScore, required this.careerScore, required this.loveScore, required this.healthScore, required this.financeScore, required this.luckyNumber, required this.doToday, required this.avoidToday});
  factory HoroscopeModel.fromJson(Map<String, dynamic> j) => HoroscopeModel(
    zodiacSign: j['zodiac_sign'] ?? '', type: j['type'] ?? '', dateRange: j['date_range'] ?? '',
    prediction: j['prediction'] ?? '', luckyColor: j['lucky_color'] ?? '', luckyGemstone: j['lucky_gemstone'] ?? '',
    overallScore: (j['overall_score'] as num?)?.toDouble() ?? 7.0,
    careerScore: (j['scores']?['career'] as num?)?.toDouble() ?? 7.0,
    loveScore: (j['scores']?['love'] as num?)?.toDouble() ?? 7.0,
    healthScore: (j['scores']?['health'] as num?)?.toDouble() ?? 7.0,
    financeScore: (j['scores']?['finance'] as num?)?.toDouble() ?? 7.0,
    luckyNumber: j['lucky_number'] ?? 7,
    doToday: List<String>.from(j['do_today'] ?? []),
    avoidToday: List<String>.from(j['avoid_today'] ?? []),
  );
}
