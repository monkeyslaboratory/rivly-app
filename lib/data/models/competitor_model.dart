class CompetitorModel {
  final String id;
  final String name;
  final String url;
  final String accessStatus;
  final String proxyCountry;
  final DateTime? createdAt;

  const CompetitorModel({
    required this.id,
    required this.name,
    required this.url,
    this.accessStatus = 'public',
    this.proxyCountry = '',
    this.createdAt,
  });

  factory CompetitorModel.fromJson(Map<String, dynamic> json) {
    return CompetitorModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      url: json['url'] as String? ?? '',
      accessStatus: json['access_status'] as String? ?? 'public',
      proxyCountry: json['proxy_country'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'url': url,
    };
  }
}
