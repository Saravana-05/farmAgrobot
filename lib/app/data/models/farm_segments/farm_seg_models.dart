class FarmSegment {
  final String id;
  final String farmName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const FarmSegment({
    required this.id,
    required this.farmName,
    this.createdAt,
    this.updatedAt,
  });

  // Create FarmSegment from JSON
  factory FarmSegment.fromJson(Map<String, dynamic> json) {
    return FarmSegment(
      id: json['id']?.toString() ?? '',
      farmName: json['farm_name'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  // Convert FarmSegment to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farm_name': farmName,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Create a copy of FarmSegment with updated fields
  FarmSegment copyWith({
    String? id,
    String? farmName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FarmSegment(
      id: id ?? this.id,
      farmName: farmName ?? this.farmName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get display name with proper formatting
  String get displayName => farmName.trim();

  @override
  String toString() {
    return 'FarmSegment(id: $id, farmName: $farmName, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FarmSegment &&
        other.id == id &&
        other.farmName == farmName &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        farmName.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}