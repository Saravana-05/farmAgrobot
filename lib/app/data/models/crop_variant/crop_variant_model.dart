class CropVariant {
  final String id;
  final String cropId;
  final String cropName;
  final String cropVariant;
  final String unit;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CropVariant({
    required this.id,
    required this.cropId,
    required this.cropName,
    required this.cropVariant,
    required this.unit,
    this.createdAt,
    this.updatedAt,
  });

  /// Create a copy of this CropVariant with the given fields replaced with new values
  CropVariant copyWith({
    String? id,
    String? cropId,
    String? cropName,
    String? cropVariant,
    String? unit,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CropVariant(
      id: id ?? this.id,
      cropId: cropId ?? this.cropId,
      cropName: cropName ?? this.cropName,
      cropVariant: cropVariant ?? this.cropVariant,
      unit: unit ?? this.unit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert CropVariant instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'crop_id': cropId,
      'crop_name': cropName,
      'crop_variant': cropVariant,
      'unit': unit,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create CropVariant instance from JSON
  factory CropVariant.fromJson(Map<String, dynamic> json) {
    return CropVariant(
      id: json['id']?.toString() ?? '',
      cropId: json['crop']?.toString() ?? json['crop_id']?.toString() ?? '',
      cropName: json['crop_name'] ?? '',
      cropVariant: json['crop_variant'] ?? '',
      unit: json['unit'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  @override
  String toString() {
    return 'CropVariant{id: $id, cropId: $cropId, cropName: $cropName, cropVariant: $cropVariant, unit: $unit}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CropVariant &&
        other.id == id &&
        other.cropId == cropId &&
        other.cropName == cropName &&
        other.cropVariant == cropVariant &&
        other.unit == unit;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        cropId.hashCode ^
        cropName.hashCode ^
        cropVariant.hashCode ^
        unit.hashCode;
  }
}