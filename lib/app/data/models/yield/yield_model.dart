class YieldModel {
  final String id;
  final String cropId;
  final String cropName;
  final DateTime harvestDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<YieldVariant> yieldVariants;
  final List<YieldFarmSegment> yieldFarmSegments;
  final List<BillImage> billImages;

  YieldModel({
    required this.id,
    required this.cropId,
    required this.cropName,
    required this.harvestDate,
    this.createdAt,
    this.updatedAt,
    this.yieldVariants = const [],
    this.yieldFarmSegments = const [],
    this.billImages = const [],
  });

  factory YieldModel.fromJson(Map<String, dynamic> json) {
    return YieldModel(
      id: json['id']?.toString() ?? '',
      cropId: json['crop']?.toString() ?? '',
      cropName: json['crop_name'] ?? '',
      harvestDate: json['harvest_date'] != null
          ? DateTime.parse(json['harvest_date'])
          : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      yieldVariants: json['yield_variants'] != null
          ? (json['yield_variants'] as List)
              .map((variant) => YieldVariant.fromJson(variant))
              .toList()
          : [],
      yieldFarmSegments: json['yield_farm_segments'] != null
          ? (json['yield_farm_segments'] as List)
              .map((segment) => YieldFarmSegment.fromJson(segment))
              .toList()
          : [],
      billImages: json['bill_images'] != null
          ? (json['bill_images'] as List)
              .map((image) => BillImage.fromJson(image))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'crop': cropId,
      'crop_name': cropName,
      'harvest_date': harvestDate.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'yield_variants': yieldVariants.map((v) => v.toJson()).toList(),
      'yield_farm_segments': yieldFarmSegments.map((s) => s.toJson()).toList(),
      'bill_images': billImages.map((b) => b.toJson()).toList(),
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'crop': cropId,
      'harvest_date': harvestDate.toIso8601String(),
      'variants': yieldVariants.map((v) => v.toCreateJson()).toList(),
      'farm_segments': yieldFarmSegments.map((s) => s.farmSegmentId).toList(),
    };
  }

  // Convenience getters
  int get billCount => billImages.length;
  bool get hasBills => billImages.isNotEmpty;
  List<String> get billUrls => billImages.map((img) => img.imageUrl).toList();
  String? get firstBillUrl =>
      billImages.isNotEmpty ? billImages.first.imageUrl : null;

  // Calculate total quantity across all variants
  double get totalQuantity {
    return yieldVariants.fold(0.0, (sum, variant) => sum + variant.quantity);
  }

  String get displayName {
    if (yieldVariants.isNotEmpty) {
      return '$cropName - ${yieldVariants.first.cropVariantName}';
    }
    return cropName;
  }

  YieldModel copyWith({
    String? id,
    String? cropId,
    String? cropName,
    DateTime? harvestDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<YieldVariant>? yieldVariants,
    List<YieldFarmSegment>? yieldFarmSegments,
    List<BillImage>? billImages,
  }) {
    return YieldModel(
      id: id ?? this.id,
      cropId: cropId ?? this.cropId,
      cropName: cropName ?? this.cropName,
      harvestDate: harvestDate ?? this.harvestDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      yieldVariants: yieldVariants ?? this.yieldVariants,
      yieldFarmSegments: yieldFarmSegments ?? this.yieldFarmSegments,
      billImages: billImages ?? this.billImages,
    );
  }

  @override
  String toString() {
    return 'YieldModel(id: $id, cropName: $cropName, harvestDate: $harvestDate, billCount: $billCount)';
  }

  List<String> get farmSegmentNames {
    return yieldFarmSegments.map((s) => s.farmSegmentName).toList();
  }
}

class YieldVariant {
  final String? id;
  final String yieldRecordId;
  final String cropVariantId;
  final String cropVariantName;
  final double quantity;
  final String unit;
  final DateTime? createdAt;

  YieldVariant({
    this.id,
    required this.yieldRecordId,
    required this.cropVariantId,
    required this.cropVariantName,
    required this.quantity,
    required this.unit,
    this.createdAt,
  });

  factory YieldVariant.fromJson(Map<String, dynamic> json) {
    return YieldVariant(
      id: json['id']?.toString(),
      yieldRecordId: json['yield_record']?.toString() ?? '',
      cropVariantId: json['crop_variant']?.toString() ??
          json['crop_variant_id']?.toString() ??
          '',
      cropVariantName: json['crop_variant_name'] ??
          json['crop_variant']?['crop_variant'] ??
          '',
      quantity: double.tryParse(json['quantity']?.toString() ?? '0') ?? 0.0,
      unit: json['unit']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'yield_record': yieldRecordId,
      'crop_variant': cropVariantId,
      'crop_variant_name': cropVariantName,
      'quantity': quantity,
      'unit': unit,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'crop_variant_id': cropVariantId,
      'quantity': quantity,
      'unit': unit,
    };
  }

  YieldVariant copyWith({
    String? id,
    String? yieldRecordId,
    String? cropVariantId,
    String? cropVariantName,
    double? quantity,
    String? unit,
    DateTime? createdAt,
  }) {
    return YieldVariant(
      id: id ?? this.id,
      yieldRecordId: yieldRecordId ?? this.yieldRecordId,
      cropVariantId: cropVariantId ?? this.cropVariantId,
      cropVariantName: cropVariantName ?? this.cropVariantName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'YieldVariant(cropVariantName: $cropVariantName, quantity: $quantity, unit: $unit)';
  }
}

class YieldFarmSegment {
  final String? id;
  final String yieldRecordId;
  final String farmSegmentId;
  final String farmSegmentName;
  final DateTime? createdAt;

  YieldFarmSegment({
    this.id,
    required this.yieldRecordId,
    required this.farmSegmentId,
    required this.farmSegmentName,
    this.createdAt,
  });

  factory YieldFarmSegment.fromJson(Map<String, dynamic> json) {
    return YieldFarmSegment(
      id: json['id']?.toString(),
      yieldRecordId: json['yield_record']?.toString() ?? '',
      farmSegmentId: json['farm_segment']?.toString() ??
          json['farm_segment_id']?.toString() ??
          '',
      farmSegmentName:
          json['farm_segment_name'] ?? json['farm_segment']?['farm_name'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'yield_record': yieldRecordId,
      'farm_segment': farmSegmentId,
      'farm_segment_name': farmSegmentName,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  YieldFarmSegment copyWith({
    String? id,
    String? yieldRecordId,
    String? farmSegmentId,
    String? farmSegmentName,
    DateTime? createdAt,
  }) {
    return YieldFarmSegment(
      id: id ?? this.id,
      yieldRecordId: yieldRecordId ?? this.yieldRecordId,
      farmSegmentId: farmSegmentId ?? this.farmSegmentId,
      farmSegmentName: farmSegmentName ?? this.farmSegmentName,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'YieldFarmSegment(farmSegmentName: $farmSegmentName)';
  }
}

class BillImage {
  final String id;
  final String yieldRecordId;
  final String imageUrl;
  final String? originalFilename;
  final int? fileSize;
  final DateTime? uploadedAt;

  BillImage({
    required this.id,
    required this.yieldRecordId,
    required this.imageUrl,
    this.originalFilename,
    this.fileSize,
    this.uploadedAt,
  });

  factory BillImage.fromJson(Map<String, dynamic> json) {
    print('BillImage.fromJson input: $json'); // Debug log

    return BillImage(
      id: json['id']?.toString() ?? '',
      // Handle missing yield_record field - use empty string for now
      yieldRecordId: json['yield_record']?.toString() ??
          json['yield_record_id']?.toString() ??
          '',
      // FIXED: Check 'url' field first (from backend), then other variations
      imageUrl: json['url']?.toString() ??
          json['image']?.toString() ??
          json['image_url']?.toString() ??
          '',
      originalFilename: json['original_filename']?.toString(),
      fileSize: json['file_size'] != null
          ? int.tryParse(json['file_size'].toString())
          : null,
      uploadedAt: json['uploaded_at'] != null
          ? DateTime.parse(json['uploaded_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'yield_record': yieldRecordId,
      'image': imageUrl,
      'original_filename': originalFilename,
      'file_size': fileSize,
      'uploaded_at': uploadedAt?.toIso8601String(),
    };
  }

  // Convenience getter for filename
  String get filename => originalFilename ?? imageUrl.split('/').last;

  // Convenience getter for file size in MB
  String get fileSizeFormatted {
    if (fileSize == null) return 'Unknown';
    if (fileSize! < 1024) return '${fileSize}B';
    if (fileSize! < 1024 * 1024)
      return '${(fileSize! / 1024).toStringAsFixed(1)}KB';
    return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  BillImage copyWith({
    String? id,
    String? yieldRecordId,
    String? imageUrl,
    String? originalFilename,
    int? fileSize,
    DateTime? uploadedAt,
  }) {
    return BillImage(
      id: id ?? this.id,
      yieldRecordId: yieldRecordId ?? this.yieldRecordId,
      imageUrl: imageUrl ?? this.imageUrl,
      originalFilename: originalFilename ?? this.originalFilename,
      fileSize: fileSize ?? this.fileSize,
      uploadedAt: uploadedAt ?? this.uploadedAt,
    );
  }

  @override
  String toString() {
    return 'BillImage(id: $id, filename: $filename, fileSize: $fileSizeFormatted)';
  }
}

// Summary models for statistics
class YieldSummary {
  final int totalYields;
  final int totalBills;
  final List<MonthlySummary> monthlySummary;
  final List<CropSummary> cropSummary;
  final List<VariantSummary> variantSummary;

  YieldSummary({
    required this.totalYields,
    required this.totalBills,
    required this.monthlySummary,
    required this.cropSummary,
    required this.variantSummary,
  });

  factory YieldSummary.fromJson(Map<String, dynamic> json) {
    return YieldSummary(
      totalYields: json['total_yields'] ?? 0,
      totalBills: json['total_bills'] ?? 0,
      monthlySummary: json['monthly_summary'] != null
          ? (json['monthly_summary'] as List)
              .map((item) => MonthlySummary.fromJson(item))
              .toList()
          : [],
      cropSummary: json['crop_summary'] != null
          ? (json['crop_summary'] as List)
              .map((item) => CropSummary.fromJson(item))
              .toList()
          : [],
      variantSummary: json['variant_summary'] != null
          ? (json['variant_summary'] as List)
              .map((item) => VariantSummary.fromJson(item))
              .toList()
          : [],
    );
  }
}

class MonthlySummary {
  final DateTime month;
  final int yieldCount;
  final int billCount;

  MonthlySummary({
    required this.month,
    required this.yieldCount,
    required this.billCount,
  });

  factory MonthlySummary.fromJson(Map<String, dynamic> json) {
    return MonthlySummary(
      month: DateTime.parse(json['month']),
      yieldCount: json['yield_count'] ?? 0,
      billCount: json['bill_count'] ?? 0,
    );
  }
}

class CropSummary {
  final String cropName;
  final int yieldCount;
  final int billCount;

  CropSummary({
    required this.cropName,
    required this.yieldCount,
    required this.billCount,
  });

  factory CropSummary.fromJson(Map<String, dynamic> json) {
    return CropSummary(
      cropName: json['crop__crop_name'] ?? '',
      yieldCount: json['yield_count'] ?? 0,
      billCount: json['bill_count'] ?? 0,
    );
  }
}

class VariantSummary {
  final String cropVariantName;
  final String cropName;
  final double totalQuantity;
  final double avgQuantity;
  final int yieldCount;

  VariantSummary({
    required this.cropVariantName,
    required this.cropName,
    required this.totalQuantity,
    required this.avgQuantity,
    required this.yieldCount,
  });

  factory VariantSummary.fromJson(Map<String, dynamic> json) {
    return VariantSummary(
      cropVariantName: json['crop_variant__crop_variant'] ?? '',
      cropName: json['crop_variant__crop__crop_name'] ?? '',
      totalQuantity:
          double.tryParse(json['total_quantity']?.toString() ?? '0') ?? 0.0,
      avgQuantity:
          double.tryParse(json['avg_quantity']?.toString() ?? '0') ?? 0.0,
      yieldCount: json['yield_count'] ?? 0,
    );
  }
}
