import 'competitor_model.dart';

class JobModel {
  final String id;
  final String name;
  final String productUrl;
  final String? productDescription;
  final String? productCategory;
  final String status;
  final String schedule;
  final List<CompetitorModel> competitors;
  final List<String> analysisAreas;
  final Map<String, dynamic>? config;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? lastRunId;
  final DateTime? lastRunAt;

  const JobModel({
    required this.id,
    required this.name,
    required this.productUrl,
    this.productDescription,
    this.productCategory,
    this.status = 'draft',
    this.schedule = 'manual',
    this.competitors = const [],
    this.analysisAreas = const [],
    this.config,
    required this.createdAt,
    required this.updatedAt,
    this.lastRunId,
    this.lastRunAt,
  });

  factory JobModel.fromJson(Map<String, dynamic> json) {
    return JobModel(
      id: json['id'] as String,
      name: json['name'] as String,
      productUrl: json['product_url'] as String,
      productDescription: json['product_description'] as String?,
      productCategory: json['product_category'] as String?,
      status: json['status'] as String? ?? 'draft',
      schedule: json['schedule'] as String? ?? 'manual',
      competitors: (json['competitors'] as List<dynamic>?)
              ?.map(
                  (e) => CompetitorModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      analysisAreas: (json['analysis_areas'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      config: json['config'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      lastRunId: json['last_run_id'] as String?,
      lastRunAt: json['last_run_at'] != null
          ? DateTime.parse(json['last_run_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'product_url': productUrl,
      'product_description': productDescription,
      'product_category': productCategory,
      'status': status,
      'schedule': schedule,
      'competitors': competitors.map((c) => c.toJson()).toList(),
      'analysis_areas': analysisAreas,
      'config': config,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_run_id': lastRunId,
      'last_run_at': lastRunAt?.toIso8601String(),
    };
  }

  JobModel copyWith({
    String? id,
    String? name,
    String? productUrl,
    String? productDescription,
    String? productCategory,
    String? status,
    String? schedule,
    List<CompetitorModel>? competitors,
    List<String>? analysisAreas,
    Map<String, dynamic>? config,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? lastRunId,
    DateTime? lastRunAt,
  }) {
    return JobModel(
      id: id ?? this.id,
      name: name ?? this.name,
      productUrl: productUrl ?? this.productUrl,
      productDescription: productDescription ?? this.productDescription,
      productCategory: productCategory ?? this.productCategory,
      status: status ?? this.status,
      schedule: schedule ?? this.schedule,
      competitors: competitors ?? this.competitors,
      analysisAreas: analysisAreas ?? this.analysisAreas,
      config: config ?? this.config,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastRunId: lastRunId ?? this.lastRunId,
      lastRunAt: lastRunAt ?? this.lastRunAt,
    );
  }
}
