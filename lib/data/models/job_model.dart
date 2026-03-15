import 'competitor_model.dart';

class JobModel {
  final String id;
  final String name;
  final String productUrl;
  final String status;
  final String scheduleFrequency;
  final String deviceType;
  final List<CompetitorModel> competitors;
  final List<String> areas;
  final DateTime createdAt;
  final DateTime updatedAt;

  const JobModel({
    required this.id,
    required this.name,
    required this.productUrl,
    this.status = 'draft',
    this.scheduleFrequency = 'weekly',
    this.deviceType = 'desktop',
    this.competitors = const [],
    this.areas = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory JobModel.fromJson(Map<String, dynamic> json) {
    return JobModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      productUrl: json['product_url'] as String? ?? '',
      status: json['status'] as String? ?? 'draft',
      scheduleFrequency: json['schedule_frequency'] as String? ?? 'weekly',
      deviceType: json['device_type'] as String? ?? 'desktop',
      competitors: (json['competitors'] as List<dynamic>?)
              ?.map((e) => CompetitorModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      areas:
          (json['areas'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'product_url': productUrl,
        'status': status,
        'schedule_frequency': scheduleFrequency,
        'device_type': deviceType,
        'areas': areas,
      };

  JobModel copyWith({
    String? id,
    String? name,
    String? productUrl,
    String? status,
    String? scheduleFrequency,
    String? deviceType,
    List<CompetitorModel>? competitors,
    List<String>? areas,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return JobModel(
      id: id ?? this.id,
      name: name ?? this.name,
      productUrl: productUrl ?? this.productUrl,
      status: status ?? this.status,
      scheduleFrequency: scheduleFrequency ?? this.scheduleFrequency,
      deviceType: deviceType ?? this.deviceType,
      competitors: competitors ?? this.competitors,
      areas: areas ?? this.areas,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
