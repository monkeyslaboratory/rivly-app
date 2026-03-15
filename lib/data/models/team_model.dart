class TeamModel {
  final String id;
  final String name;
  final String plan;
  final DateTime createdAt;

  const TeamModel({
    required this.id,
    required this.name,
    this.plan = 'free',
    required this.createdAt,
  });

  factory TeamModel.fromJson(Map<String, dynamic> json) {
    return TeamModel(
      id: json['id'] as String,
      name: json['name'] as String,
      plan: json['plan'] as String? ?? 'free',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'plan': plan,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
