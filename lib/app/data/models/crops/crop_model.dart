class Crop {
  final String id;
  final String cropName;
  final String? cropImage; // Image file path from API
  final String? imageUrl; // Full URL for displaying image
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Crop({
    required this.id,
    required this.cropName,
    this.cropImage,
    this.imageUrl,
    this.createdAt,
    this.updatedAt,
  });

  /// Create Crop from JSON
  factory Crop.fromJson(Map<String, dynamic> json) {
    return Crop(
      id: json['id']?.toString() ?? '',
      cropName: json['crop_name'] ?? '',
      cropImage: json['crop_image'],
      imageUrl: json['image_url'] ?? json['crop_image'], // fallback to crop_image if image_url not present
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  /// Convert Crop to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'crop_name': cropName,
      'crop_image': cropImage,
      'image_url': imageUrl,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create a copy of Crop with updated fields
  Crop copyWith({
    String? id,
    String? cropName,
    String? cropImage,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Crop(
      id: id ?? this.id,
      cropName: cropName ?? this.cropName,
      cropImage: cropImage ?? this.cropImage,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if crop has image
  bool get hasImage => cropImage != null && cropImage!.isNotEmpty;

  /// Get display name with proper formatting
  String get displayName => cropName.trim();

  /// Get formatted creation date
  String get formattedCreatedAt {
    if (createdAt == null) return 'N/A';
    return '${createdAt!.day}/${createdAt!.month}/${createdAt!.year}';
  }

  /// Get formatted update date
  String get formattedUpdatedAt {
    if (updatedAt == null) return 'N/A';
    return '${updatedAt!.day}/${updatedAt!.month}/${updatedAt!.year}';
  }

  @override
  String toString() {
    return 'Crop(id: $id, cropName: $cropName, hasImage: $hasImage, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Crop && 
           other.id == id && 
           other.cropName == cropName;
  }

  @override
  int get hashCode {
    return id.hashCode ^ cropName.hashCode;
  }
}