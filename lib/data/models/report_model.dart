class ReportModel {
  final String id;
  final String runId;
  final int score;
  final String summary;
  final Map<String, dynamic> details;
  final List<RecommendationModel> recommendations;
  final Map<String, CompetitorScoreModel> competitorScores;
  final DateTime createdAt;

  const ReportModel({
    required this.id,
    required this.runId,
    required this.score,
    required this.summary,
    this.details = const {},
    this.recommendations = const [],
    this.competitorScores = const {},
    required this.createdAt,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    final recsJson = json['recommendations'] as List<dynamic>? ?? [];
    final scoresJson =
        json['competitor_scores'] as Map<String, dynamic>? ?? {};

    return ReportModel(
      id: json['id'] as String,
      runId: json['run_id'] as String,
      score: json['score'] as int,
      summary: json['summary'] as String,
      details: json['details'] as Map<String, dynamic>? ?? {},
      recommendations: recsJson
          .map((e) =>
              RecommendationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      competitorScores: scoresJson.map(
        (key, value) => MapEntry(
          key,
          CompetitorScoreModel.fromJson(value as Map<String, dynamic>),
        ),
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'run_id': runId,
      'score': score,
      'summary': summary,
      'details': details,
      'recommendations': recommendations.map((r) => r.toJson()).toList(),
      'competitor_scores':
          competitorScores.map((k, v) => MapEntry(k, v.toJson())),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class RecommendationModel {
  final String title;
  final String description;
  final String priority;
  final String area;

  const RecommendationModel({
    required this.title,
    required this.description,
    this.priority = 'medium',
    required this.area,
  });

  factory RecommendationModel.fromJson(Map<String, dynamic> json) {
    return RecommendationModel(
      title: json['title'] as String,
      description: json['description'] as String,
      priority: json['priority'] as String? ?? 'medium',
      area: json['area'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'priority': priority,
      'area': area,
    };
  }
}

class CompetitorScoreModel {
  final String name;
  final int overallScore;
  final Map<String, int> areaScores;

  const CompetitorScoreModel({
    required this.name,
    required this.overallScore,
    this.areaScores = const {},
  });

  factory CompetitorScoreModel.fromJson(Map<String, dynamic> json) {
    return CompetitorScoreModel(
      name: json['name'] as String,
      overallScore: json['overall_score'] as int,
      areaScores: (json['area_scores'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value as int),
          ) ??
          {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'overall_score': overallScore,
      'area_scores': areaScores,
    };
  }
}
