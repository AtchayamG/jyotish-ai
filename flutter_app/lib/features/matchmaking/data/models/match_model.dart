class MatchModel {
  final int totalScore; final double percentage; final String verdict;
  final List<KutaModel> kutaScores; final DoshaModel dosha; final String? aiAnalysis;
  const MatchModel({required this.totalScore, required this.percentage, required this.verdict, required this.kutaScores, required this.dosha, this.aiAnalysis});
  factory MatchModel.fromJson(Map<String, dynamic> j) => MatchModel(
    totalScore: j['total_score'] ?? 0, percentage: (j['percentage'] as num?)?.toDouble() ?? 0,
    verdict: j['verdict'] ?? '', aiAnalysis: j['ai_analysis'],
    kutaScores: (j['kuta_scores'] as List? ?? []).map((k) => KutaModel.fromJson(k)).toList(),
    dosha: DoshaModel.fromJson(j['dosha'] ?? {}),
  );
}
class KutaModel {
  final String name, description; final int maxScore, obtainedScore;
  const KutaModel({required this.name, required this.description, required this.maxScore, required this.obtainedScore});
  factory KutaModel.fromJson(Map<String, dynamic> j) => KutaModel(name: j['name'] ?? '', description: j['description'] ?? '', maxScore: j['max_score'] ?? 0, obtainedScore: j['obtained_score'] ?? 0);
}
class DoshaModel {
  final bool hasDosha; final String? doshaType, severity, remedy;
  const DoshaModel({required this.hasDosha, this.doshaType, this.severity, this.remedy});
  factory DoshaModel.fromJson(Map<String, dynamic> j) => DoshaModel(hasDosha: j['has_dosha'] ?? false, doshaType: j['dosha_type'], severity: j['severity'], remedy: j['remedy']);
}
