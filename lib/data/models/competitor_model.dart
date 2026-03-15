class CompetitorModel {
  final String id;
  final String name;
  final String url;
  final String? description;
  final String? logoUrl;
  final bool isVerified;
  final String source;
  final DateTime? createdAt;

  const CompetitorModel({
    required this.id,
    required this.name,
    required this.url,
    this.description,
    this.logoUrl,
    this.isVerified = false,
    this.source = 'manual',
    this.createdAt,
  });

  factory CompetitorModel.fromJson(Map<String, dynamic> json) {
    return CompetitorModel(
      id: json['id'] as String,
      name: json['name'] as String,
      url: json['url'] as String,
      description: json['description'] as String?,
      logoUrl: json['logo_url'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      source: json['source'] as String? ?? 'manual',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'description': description,
      'logo_url': logoUrl,
      'is_verified': isVerified,
      'source': source,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
