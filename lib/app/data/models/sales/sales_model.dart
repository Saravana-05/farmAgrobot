import '../yield/yield_model.dart';

class SaleImage {
  final String id;
  final String saleId;
  final String imageUrl;
  final String? imageName;
  final String? description;
  final bool isPrimary;
  final DateTime? uploadedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SaleImage({
    required this.id,
    required this.saleId,
    required this.imageUrl,
    this.imageName,
    this.description,
    this.isPrimary = false,
    this.uploadedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory SaleImage.fromJson(Map<String, dynamic> json) {
    print('SaleImage.fromJson - Raw JSON: $json'); // Debug log

    // Handle different possible field names for sale ID
    String parsedSaleId = '';
    if (json['sale'] != null) {
      if (json['sale'] is Map) {
        parsedSaleId = json['sale']['id']?.toString() ?? '';
      } else {
        parsedSaleId = json['sale']?.toString() ?? '';
      }
    } else if (json['sale_id'] != null) {
      parsedSaleId = json['sale_id']?.toString() ?? '';
    }

    // Handle different possible field names for image URL
    String parsedImageUrl = '';
    if (json['image_url'] != null) {
      parsedImageUrl = json['image_url']?.toString() ?? '';
    } else if (json['image'] != null) {
      if (json['image'] is String) {
        parsedImageUrl = json['image'];
      } else if (json['image'] is Map && json['image']['url'] != null) {
        parsedImageUrl = json['image']['url'];
      }
    }

    // Parse dates safely
    DateTime? parseDate(dynamic dateValue) {
      if (dateValue == null) return null;
      try {
        if (dateValue is String && dateValue.isNotEmpty) {
          return DateTime.parse(dateValue);
        }
      } catch (e) {
        print('Error parsing date: $dateValue - $e');
      }
      return null;
    }

    return SaleImage(
      id: json['id']?.toString() ?? '',
      saleId: parsedSaleId,
      imageUrl: parsedImageUrl,
      imageName: json['image_name']?.toString(),
      description: json['description']?.toString(),
      isPrimary: json['is_primary'] ?? false,
      uploadedAt: parseDate(json['uploaded_at']),
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sale': saleId,
      'image_url': imageUrl,
      'image_name': imageName,
      'description': description,
      'is_primary': isPrimary,
      'uploaded_at': uploadedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // For creating image metadata when uploading
  Map<String, dynamic> toCreateJson() {
    return {
      'name': imageName ?? '',
      'description': description ?? '',
      'is_primary': isPrimary,
    };
  }

  String get filename => imageName ?? imageUrl.split('/').last;

  SaleImage copyWith({
    String? id,
    String? saleId,
    String? imageUrl,
    String? imageName,
    String? description,
    bool? isPrimary,
    DateTime? uploadedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SaleImage(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      imageUrl: imageUrl ?? this.imageUrl,
      imageName: imageName ?? this.imageName,
      description: description ?? this.description,
      isPrimary: isPrimary ?? this.isPrimary,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'SaleImage(id: $id, saleId: $saleId, filename: $filename, isPrimary: $isPrimary)';
  }
}

// Payment History Model
class PaymentHistory {
  final String id;
  final String saleId;
  final double paymentAmount;
  final DateTime paymentDate;
  final String paymentMethod;
  final String? paymentReference;
  final String? notes;
  final String? createdBy;

  PaymentHistory({
    required this.id,
    required this.saleId,
    required this.paymentAmount,
    required this.paymentDate,
    required this.paymentMethod,
    this.paymentReference,
    this.notes,
    this.createdBy,
  });

  factory PaymentHistory.fromJson(Map<String, dynamic> json) {
    return PaymentHistory(
      id: json['id']?.toString() ?? '',
      saleId: json['sale']?.toString() ?? '',
      paymentAmount:
          double.tryParse(json['payment_amount']?.toString() ?? '0') ?? 0.0,
      paymentDate: json['payment_date'] != null
          ? DateTime.parse(json['payment_date'])
          : DateTime.now(),
      paymentMethod: json['payment_method']?.toString() ?? '',
      paymentReference: json['payment_reference']?.toString(),
      notes: json['notes']?.toString(),
      createdBy: json['created_by']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sale': saleId,
      'payment_amount': paymentAmount,
      'payment_date': paymentDate.toIso8601String(),
      'payment_method': paymentMethod,
      'payment_reference': paymentReference,
      'notes': notes,
      'created_by': createdBy,
    };
  }

  // For creating new payments
  Map<String, dynamic> toCreateJson() {
    return {
      'payment_amount': paymentAmount,
      'payment_method': paymentMethod,
      if (paymentReference?.isNotEmpty == true)
        'payment_reference': paymentReference,
      if (notes?.isNotEmpty == true) 'notes': notes,
      if (createdBy?.isNotEmpty == true) 'created_by': createdBy,
    };
  }

  String get formattedAmount => '₹${paymentAmount.toStringAsFixed(2)}';
  String get formattedDate =>
      '${paymentDate.day}/${paymentDate.month}/${paymentDate.year}';

  PaymentHistory copyWith({
    String? id,
    String? saleId,
    double? paymentAmount,
    DateTime? paymentDate,
    String? paymentMethod,
    String? paymentReference,
    String? notes,
    String? createdBy,
  }) {
    return PaymentHistory(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      paymentAmount: paymentAmount ?? this.paymentAmount,
      paymentDate: paymentDate ?? this.paymentDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentReference: paymentReference ?? this.paymentReference,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  @override
  String toString() {
    return 'PaymentHistory(id: $id, amount: $formattedAmount, method: $paymentMethod, date: $formattedDate)';
  }
}

// Sale Variant Model
class SaleVariant {
  final String? id;
  final String saleId;
  final String cropVariantId;
  final String cropVariantName;
  final String cropName;
  final double quantity;
  final double amountPerUnit;
  final double totalAmount;
  final String unit;
  final DateTime? createdAt;

  SaleVariant({
    this.id,
    required this.saleId,
    required this.cropVariantId,
    required this.cropVariantName,
    required this.cropName,
    required this.quantity,
    required this.amountPerUnit,
    required this.totalAmount,
    required this.unit,
    this.createdAt,
  });

  factory SaleVariant.fromJson(Map<String, dynamic> json) {
    return SaleVariant(
      id: json['id']?.toString(),
      saleId: json['sale']?.toString() ?? '',
      cropVariantId: json['crop_variant']?.toString() ?? '',
      cropVariantName: json['crop_variant_name']?.toString() ?? '',
      cropName: json['crop_name']?.toString() ?? '',
      quantity: double.tryParse(json['quantity']?.toString() ?? '0') ?? 0.0,
      amountPerUnit:
          double.tryParse(json['amount_per_unit']?.toString() ?? '0') ?? 0.0,
      totalAmount:
          double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0.0,
      unit: json['unit']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sale': saleId,
      'crop_variant': cropVariantId,
      'crop_variant_name': cropVariantName,
      'crop_name': cropName,
      'quantity': quantity,
      'amount_per_unit': amountPerUnit,
      'total_amount': totalAmount,
      'unit': unit,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  // For creating new sale variants
  Map<String, dynamic> toCreateJson() {
    return {
      'crop_variant_id': cropVariantId,
      'quantity': quantity,
      'amount':
          amountPerUnit, // Note: backend expects 'amount' not 'amount_per_unit'
      'unit': unit,
    };
  }

  String get formattedQuantity => '$quantity $unit';
  String get formattedAmountPerUnit => '₹${amountPerUnit.toStringAsFixed(2)}';
  String get formattedTotalAmount => '₹${totalAmount.toStringAsFixed(2)}';
  String get displayText =>
      '$cropVariantName: $formattedQuantity @ $formattedAmountPerUnit = $formattedTotalAmount';

  SaleVariant copyWith({
    String? id,
    String? saleId,
    String? cropVariantId,
    String? cropVariantName,
    String? cropName,
    double? quantity,
    double? amountPerUnit,
    double? totalAmount,
    String? unit,
    DateTime? createdAt,
  }) {
    return SaleVariant(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      cropVariantId: cropVariantId ?? this.cropVariantId,
      cropVariantName: cropVariantName ?? this.cropVariantName,
      cropName: cropName ?? this.cropName,
      quantity: quantity ?? this.quantity,
      amountPerUnit: amountPerUnit ?? this.amountPerUnit,
      totalAmount: totalAmount ?? this.totalAmount,
      unit: unit ?? this.unit,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'SaleVariant(cropVariantName: $cropVariantName, quantity: $quantity, unit: $unit, totalAmount: $totalAmount)';
  }
}

// Main Sale Model
class SaleModel {
  final String id;
  final String merchantId;
  final String merchantName;
  final String? merchantContact;
  final String yieldRecordId;
  final String cropName;
  final String paymentMode;
  final DateTime harvestDate;
  final String? billUrl;

  // Financial fields
  final double totalAmount;
  final double commission;
  final double lorryRent;
  final double coolyCharges;
  final double totalDeductions;
  final double totalCalculatedAmount;
  final double finalAmount;
  final double paidAmount;
  final double pendingAmount;

  // Status fields
  final String paymentStatus;
  final String status;

  // Timestamps
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Related data
  final List<SaleVariant> saleVariants;
  final List<SaleImage> saleImages;
  final List<PaymentHistory> paymentHistory;

  SaleModel({
    required this.id,
    required this.merchantId,
    required this.merchantName,
    this.merchantContact,
    required this.yieldRecordId,
    required this.cropName,
    required this.paymentMode,
    required this.harvestDate,
    this.billUrl,
    required this.totalAmount,
    this.commission = 0.0,
    this.lorryRent = 0.0,
    this.coolyCharges = 0.0,
    this.totalDeductions = 0.0,
    required this.totalCalculatedAmount,
    required this.finalAmount,
    this.paidAmount = 0.0,
    this.pendingAmount = 0.0,
    this.paymentStatus = 'pending',
    this.status = 'pending',
    this.createdAt,
    this.updatedAt,
    this.saleVariants = const [],
    this.saleImages = const [],
    this.paymentHistory = const [],
  });

  factory SaleModel.fromJson(Map<String, dynamic> json) {
    print('\n=== SaleModel.fromJson DEBUG ===');
    print('Full JSON keys: ${json.keys.toList()}');

    // Debug image parsing specifically
    if (json.containsKey('sale_images')) {
      print('Found sale_images field: ${json['sale_images']}');
      print('sale_images type: ${json['sale_images'].runtimeType}');
      if (json['sale_images'] is List) {
        print('sale_images count: ${(json['sale_images'] as List).length}');
        for (int i = 0; i < (json['sale_images'] as List).length; i++) {
          print('Image $i: ${json['sale_images'][i]}');
        }
      }
    } else {
      print('sale_images field NOT FOUND');
      // Check for other possible field names
      List<String> possibleFields = [
        'images',
        'saleImages',
        'sale_image',
        'image_set'
      ];
      for (String field in possibleFields) {
        if (json.containsKey(field)) {
          print('Found alternative image field: $field = ${json[field]}');
        }
      }
    }

    // Parse dates safely
    DateTime parseDate(dynamic dateValue, DateTime fallback) {
      if (dateValue == null) return fallback;
      try {
        if (dateValue is String && dateValue.isNotEmpty) {
          return DateTime.parse(dateValue);
        }
      } catch (e) {
        print('Error parsing date: $dateValue - $e');
      }
      return fallback;
    }

    // Parse sale images with extensive debugging
    List<SaleImage> parsedSaleImages = [];
    try {
      var imageData = json['sale_images'];

      if (imageData != null && imageData is List) {
        print('Parsing ${imageData.length} images...');
        for (int i = 0; i < imageData.length; i++) {
          try {
            var imgJson = imageData[i];
            print('Parsing image $i: $imgJson');

            if (imgJson is Map<String, dynamic>) {
              var saleImage = SaleImage.fromJson(imgJson);
              parsedSaleImages.add(saleImage);
              print('Successfully parsed image $i: ${saleImage.toString()}');
            } else {
              print('Image $i is not a Map: ${imgJson.runtimeType}');
            }
          } catch (e, stackTrace) {
            print('Error parsing image $i: $e');
            print('Stack trace: $stackTrace');
          }
        }
      } else if (imageData != null) {
        print(
            'sale_images is not a List. Type: ${imageData.runtimeType}, Value: $imageData');
      }
    } catch (e, stackTrace) {
      print('Error parsing sale_images: $e');
      print('Stack trace: $stackTrace');
    }

    print('Final parsed images count: ${parsedSaleImages.length}');
    print('=== END SaleModel.fromJson DEBUG ===\n');

    return SaleModel(
      id: json['id']?.toString() ?? '',
      merchantId:
          json['merchant']?.toString() ?? json['merchant_id']?.toString() ?? '',
      merchantName: json['merchant_name']?.toString() ?? '',
      merchantContact: json['merchant_contact']?.toString(),
      yieldRecordId: json['yield_record']?.toString() ??
          json['yield_record_id']?.toString() ??
          '',
      cropName: json['crop_name']?.toString() ?? '',
      paymentMode: json['payment_mode']?.toString() ?? '',
      harvestDate: parseDate(json['harvest_date'], DateTime.now()),
      billUrl: json['bill_url']?.toString(),
      totalAmount:
          double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0.0,
      commission: double.tryParse(json['commission']?.toString() ?? '0') ?? 0.0,
      lorryRent: double.tryParse(json['lorry_rent']?.toString() ?? '0') ?? 0.0,
      coolyCharges:
          double.tryParse(json['cooly_charges']?.toString() ?? '0') ?? 0.0,
      totalDeductions:
          double.tryParse(json['total_deductions']?.toString() ?? '0') ?? 0.0,
      totalCalculatedAmount:
          double.tryParse(json['total_calculated_amount']?.toString() ?? '0') ??
              0.0,
      finalAmount:
          double.tryParse(json['final_amount']?.toString() ?? '0') ?? 0.0,
      paidAmount:
          double.tryParse(json['paid_amount']?.toString() ?? '0') ?? 0.0,
      pendingAmount:
          double.tryParse(json['pending_amount']?.toString() ?? '0') ?? 0.0,
      paymentStatus: json['payment_status']?.toString() ?? 'pending',
      status: json['status']?.toString() ?? 'pending',
      createdAt: parseDate(json['created_at'],DateTime.now()),
      updatedAt: parseDate(json['updated_at'], DateTime.now()),

      // Parse sale variants
      saleVariants:
          json['sale_variants'] != null && json['sale_variants'] is List
              ? (json['sale_variants'] as List)
                  .map((variant) => SaleVariant.fromJson(variant))
                  .toList()
              : [],

      // Use the parsed sale images
      saleImages: parsedSaleImages,

      // Parse payment history
      paymentHistory:
          json['payment_history'] != null && json['payment_history'] is List
              ? (json['payment_history'] as List)
                  .map((payment) => PaymentHistory.fromJson(payment))
                  .toList()
              : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'merchant': merchantId,
      'merchant_name': merchantName,
      'merchant_contact': merchantContact,
      'yield_record': yieldRecordId,
      'crop_name': cropName,
      'payment_mode': paymentMode,
      'harvest_date': harvestDate.toIso8601String(),
      'bill_url': billUrl,
      'total_amount': totalAmount,
      'commission': commission,
      'lorry_rent': lorryRent,
      'cooly_charges': coolyCharges,
      'total_deductions': totalDeductions,
      'total_calculated_amount': totalCalculatedAmount,
      'final_amount': finalAmount,
      'paid_amount': paidAmount,
      'pending_amount': pendingAmount,
      'payment_status': paymentStatus,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'sale_variants': saleVariants.map((v) => v.toJson()).toList(),
      'sale_images': saleImages.map((i) => i.toJson()).toList(),
      'payment_history': paymentHistory.map((p) => p.toJson()).toList(),
    };
  }

  // For creating new sales
  Map<String, dynamic> toCreateJson() {
    return {
      'merchant': merchantId,
      'yield_record': yieldRecordId,
      'payment_mode': paymentMode,
      'harvest_date': harvestDate.toIso8601String(),
      'total_amount': totalAmount,
      'commission': commission,
      'lorry_rent': lorryRent,
      'cooly_charges': coolyCharges,
      'total_calculated_amount': totalCalculatedAmount,
      'paid_amount': paidAmount,
      if (billUrl?.isNotEmpty == true) 'bill_url': billUrl,
      'variants': saleVariants.map((v) => v.toCreateJson()).toList(),
      if (saleImages.isNotEmpty)
        'image_metadata': saleImages.map((i) => i.toCreateJson()).toList(),
    };
  }

  // Convenience getters
  String get formattedTotalAmount => '₹${totalAmount.toStringAsFixed(2)}';
  String get formattedFinalAmount => '₹${finalAmount.toStringAsFixed(2)}';
  String get formattedPaidAmount => '₹${paidAmount.toStringAsFixed(2)}';
  String get formattedPendingAmount => '₹${pendingAmount.toStringAsFixed(2)}';
  String get formattedCommission => '₹${commission.toStringAsFixed(2)}';
  String get formattedTotalDeductions =>
      '₹${totalDeductions.toStringAsFixed(2)}';

  String get formattedHarvestDate =>
      '${harvestDate.day}/${harvestDate.month}/${harvestDate.year}';
  String get formattedCreatedDate => createdAt != null
      ? '${createdAt!.day}/${createdAt!.month}/${createdAt!.year}'
      : '';

  int get variantCount => saleVariants.length;
  int get imageCount => saleImages.length;
  int get paymentCount => paymentHistory.length;

  bool get hasImages => saleImages.isNotEmpty;
  bool get hasPayments => paymentHistory.isNotEmpty;
  bool get isPaid => paymentStatus == 'paid';
  bool get isPartiallyPaid => paymentStatus == 'partial';
  bool get isPending => paymentStatus == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCancelled => status == 'cancelled';

  SaleImage? get primaryImage =>
      saleImages.where((img) => img.isPrimary).isNotEmpty
          ? saleImages.firstWhere((img) => img.isPrimary)
          : (saleImages.isNotEmpty ? saleImages.first : null);

  String? get primaryImageUrl => primaryImage?.imageUrl;

  double get collectionRate =>
      finalAmount > 0 ? (paidAmount / finalAmount) * 100 : 0.0;
  String get formattedCollectionRate => '${collectionRate.toStringAsFixed(1)}%';

  // Calculate total quantity across all variants
  double get totalQuantity {
    return saleVariants.fold(0.0, (sum, variant) => sum + variant.quantity);
  }

  // Get all variant names
  List<String> get variantNames {
    return saleVariants.map((v) => v.cropVariantName).toList();
  }

  // Get payment method counts
  Map<String, int> get paymentMethodCounts {
    Map<String, int> counts = {};
    for (PaymentHistory payment in paymentHistory) {
      counts[payment.paymentMethod] = (counts[payment.paymentMethod] ?? 0) + 1;
    }
    return counts;
  }

  SaleModel copyWith({
    String? id,
    String? merchantId,
    String? merchantName,
    String? merchantContact,
    String? yieldRecordId,
    String? cropName,
    String? paymentMode,
    DateTime? harvestDate,
    String? billUrl,
    double? totalAmount,
    double? commission,
    double? lorryRent,
    double? coolyCharges,
    double? totalDeductions,
    double? totalCalculatedAmount,
    double? finalAmount,
    double? paidAmount,
    double? pendingAmount,
    String? paymentStatus,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<SaleVariant>? saleVariants,
    List<SaleImage>? saleImages,
    List<PaymentHistory>? paymentHistory,
  }) {
    return SaleModel(
      id: id ?? this.id,
      merchantId: merchantId ?? this.merchantId,
      merchantName: merchantName ?? this.merchantName,
      merchantContact: merchantContact ?? this.merchantContact,
      yieldRecordId: yieldRecordId ?? this.yieldRecordId,
      cropName: cropName ?? this.cropName,
      paymentMode: paymentMode ?? this.paymentMode,
      harvestDate: harvestDate ?? this.harvestDate,
      billUrl: billUrl ?? this.billUrl,
      totalAmount: totalAmount ?? this.totalAmount,
      commission: commission ?? this.commission,
      lorryRent: lorryRent ?? this.lorryRent,
      coolyCharges: coolyCharges ?? this.coolyCharges,
      totalDeductions: totalDeductions ?? this.totalDeductions,
      totalCalculatedAmount:
          totalCalculatedAmount ?? this.totalCalculatedAmount,
      finalAmount: finalAmount ?? this.finalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      pendingAmount: pendingAmount ?? this.pendingAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      saleVariants: saleVariants ?? this.saleVariants,
      saleImages: saleImages ?? this.saleImages,
      paymentHistory: paymentHistory ?? this.paymentHistory,
    );
  }

  @override
  String toString() {
    return 'SaleModel(id: $id, merchantName: $merchantName, cropName: $cropName, finalAmount: $formattedFinalAmount, status: $status, paymentStatus: $paymentStatus)';
  }
}

// Sale Summary Model (for list views)
class SaleSummary {
  final String id;
  final String merchantName;
  final String cropName;
  final String paymentMode;
  final DateTime harvestDate;
  final double finalAmount;
  final double paidAmount;
  final double pendingAmount;
  final String paymentStatus;
  final String status;
  final int variantCount;
  final int imageCount;
  final String? primaryImageUrl;
  final DateTime? createdAt;

  SaleSummary({
    required this.id,
    required this.merchantName,
    required this.cropName,
    required this.paymentMode,
    required this.harvestDate,
    required this.finalAmount,
    required this.paidAmount,
    required this.pendingAmount,
    required this.paymentStatus,
    required this.status,
    required this.variantCount,
    required this.imageCount,
    this.primaryImageUrl,
    this.createdAt,
  });

  factory SaleSummary.fromJson(Map<String, dynamic> json) {
    return SaleSummary(
      id: json['id']?.toString() ?? '',
      merchantName: json['merchant_name']?.toString() ?? '',
      cropName: json['crop_name']?.toString() ?? '',
      paymentMode: json['payment_mode']?.toString() ?? '',
      harvestDate: json['harvest_date'] != null
          ? DateTime.parse(json['harvest_date'])
          : DateTime.now(),
      finalAmount:
          double.tryParse(json['final_amount']?.toString() ?? '0') ?? 0.0,
      paidAmount:
          double.tryParse(json['paid_amount']?.toString() ?? '0') ?? 0.0,
      pendingAmount:
          double.tryParse(json['pending_amount']?.toString() ?? '0') ?? 0.0,
      paymentStatus: json['payment_status']?.toString() ?? 'pending',
      status: json['status']?.toString() ?? 'pending',
      variantCount: json['variant_count'] ?? 0,
      imageCount: json['image_count'] ?? 0,
      primaryImageUrl: json['primary_image']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  // Convert to full SaleModel (you'd typically fetch full data from API)
  SaleModel toSaleModel() {
    return SaleModel(
      id: id,
      merchantId: '',
      merchantName: merchantName,
      yieldRecordId: '',
      cropName: cropName,
      paymentMode: paymentMode,
      harvestDate: harvestDate,
      totalAmount: finalAmount,
      totalCalculatedAmount: finalAmount,
      finalAmount: finalAmount,
      paidAmount: paidAmount,
      pendingAmount: pendingAmount,
      paymentStatus: paymentStatus,
      status: status,
      createdAt: createdAt,
    );
  }

  String get formattedFinalAmount => '₹${finalAmount.toStringAsFixed(2)}';
  String get formattedPaidAmount => '₹${paidAmount.toStringAsFixed(2)}';
  String get formattedPendingAmount => '₹${pendingAmount.toStringAsFixed(2)}';
  String get formattedHarvestDate =>
      '${harvestDate.day}/${harvestDate.month}/${harvestDate.year}';

  double get collectionRate =>
      finalAmount > 0 ? (paidAmount / finalAmount) * 100 : 0.0;
  String get formattedCollectionRate => '${collectionRate.toStringAsFixed(1)}%';

  @override
  String toString() {
    return 'SaleSummary(id: $id, merchantName: $merchantName, finalAmount: $formattedFinalAmount, status: $status)';
  }
}

class AvailableYield {
  final String id;
  final String cropId;
  final String cropName;
  final DateTime harvestDate;
  final double totalQuantity; // This will now correctly parse from API
  final String farmLocation;
  final String variantsInfo;
  final int billCount;
  final bool hasBills;
  final DateTime? createdAt;
  final String displayText; // Use backend's display_text directly
  final String status;
  final List<String> farmSegments;
  final int variantsCount;

  // Keep these for backward compatibility if needed
  final List<YieldVariant> yieldVariants;
  final List<YieldFarmSegment> yieldFarmSegments;

  AvailableYield({
    required this.id,
    this.cropId = '',
    required this.cropName,
    required this.harvestDate,
    required this.totalQuantity,
    required this.farmLocation,
    required this.variantsInfo,
    required this.billCount,
    required this.hasBills,
    this.createdAt,
    required this.displayText,
    this.status = 'available',
    this.farmSegments = const [],
    this.variantsCount = 0,
    this.yieldVariants = const [],
    this.yieldFarmSegments = const [],
  });

  factory AvailableYield.fromJson(Map<String, dynamic> json) {
    try {
      // Parse harvest date
      DateTime parsedHarvestDate;
      final harvestDateStr = json['harvest_date'];
      if (harvestDateStr != null && harvestDateStr is String) {
        parsedHarvestDate = DateTime.parse(harvestDateStr);
      } else {
        parsedHarvestDate = DateTime.now();
      }

      // Parse created date
      DateTime? parsedCreatedAt;
      final createdAtStr = json['created_at'];
      if (createdAtStr != null && createdAtStr is String) {
        try {
          parsedCreatedAt = DateTime.parse(createdAtStr);
        } catch (e) {
          parsedCreatedAt = null;
        }
      }

      // Parse total quantity - THE KEY FIX
      double parsedQuantity = 0.0;
      final quantityValue = json['total_quantity'];
      if (quantityValue != null) {
        if (quantityValue is num) {
          parsedQuantity = quantityValue.toDouble();
        } else if (quantityValue is String) {
          parsedQuantity = double.tryParse(quantityValue) ?? 0.0;
        }
      }

      print('Parsing quantity: $quantityValue -> $parsedQuantity'); // Debug log

      // Parse farm segments if available
      List<String> parsedFarmSegments = [];
      if (json['farm_segments'] != null && json['farm_segments'] is List) {
        parsedFarmSegments = (json['farm_segments'] as List).cast<String>();
      }

      // Parse yield variants if available (for backward compatibility)
      List<YieldVariant> parsedYieldVariants = [];
      if (json['yield_variants'] != null && json['yield_variants'] is List) {
        parsedYieldVariants = (json['yield_variants'] as List)
            .map((variant) => YieldVariant.fromJson(variant))
            .toList();
      }

      // Parse farm segments if available (for backward compatibility)
      List<YieldFarmSegment> parsedYieldFarmSegments = [];
      if (json['yield_farm_segments'] != null &&
          json['yield_farm_segments'] is List) {
        parsedYieldFarmSegments = (json['yield_farm_segments'] as List)
            .map((segment) => YieldFarmSegment.fromJson(segment))
            .toList();
      }

      return AvailableYield(
        id: json['id']?.toString() ?? '',
        cropId: json['crop_id']?.toString() ?? json['crop']?.toString() ?? '',
        cropName: json['crop_name']?.toString() ?? 'Unknown Crop',
        harvestDate: parsedHarvestDate,
        totalQuantity: parsedQuantity, // Now correctly parsed
        farmLocation: json['farm_location']?.toString() ?? 'Unknown Location',
        variantsInfo: json['variants_info']?.toString() ?? 'No variants',
        billCount: json['bill_count'] as int? ?? 0,
        hasBills: json['has_bills'] as bool? ?? false,
        createdAt: parsedCreatedAt,
        displayText: json['display_text']?.toString() ??
            '${json['crop_name']} - ${_formatDate(parsedHarvestDate)}',
        status: json['status']?.toString() ?? 'available',
        farmSegments: parsedFarmSegments,
        variantsCount: json['variants_count'] as int? ?? 0,
        yieldVariants: parsedYieldVariants,
        yieldFarmSegments: parsedYieldFarmSegments,
      );
    } catch (e, stackTrace) {
      print('Error parsing AvailableYield from JSON: $e');
      print('JSON data: $json');
      print('Stack trace: $stackTrace');

      // Return a default object instead of throwing
      return AvailableYield(
        id: json['id']?.toString() ?? '0',
        cropName: json['crop_name']?.toString() ?? 'Unknown Crop',
        harvestDate: DateTime.now(),
        totalQuantity: 0.0,
        farmLocation: 'Unknown Location',
        variantsInfo: 'Error parsing',
        billCount: 0,
        hasBills: false,
        displayText: 'Error parsing yield data',
      );
    }
  }

  // Helper method to format date
  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'crop_id': cropId,
      'crop_name': cropName,
      'harvest_date': harvestDate.toIso8601String(),
      'total_quantity': totalQuantity,
      'farm_location': farmLocation,
      'variants_info': variantsInfo,
      'bill_count': billCount,
      'has_bills': hasBills,
      'created_at': createdAt?.toIso8601String(),
      'display_text': displayText,
      'status': status,
      'farm_segments': farmSegments,
      'variants_count': variantsCount,
      'yield_variants': yieldVariants.map((v) => v.toJson()).toList(),
      'yield_farm_segments': yieldFarmSegments.map((s) => s.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'AvailableYield(id: $id, cropName: $cropName, totalQuantity: $totalQuantity, displayText: $displayText, farmLocation: $farmLocation)';
  }

  // Utility getters - updated to use the correct totalQuantity
  String get formattedQuantity {
    if (totalQuantity <= 0) return 'No quantity available';
    return '${totalQuantity.toStringAsFixed(1)} units';
  }

  String get formattedHarvestDate {
    return _formatDate(harvestDate);
  }

  String get shortDisplayText {
    return '$cropName - ${formattedHarvestDate}';
  }

  bool get isAvailable => totalQuantity > 0 && status == 'available';

  String get quantityStatus {
    if (totalQuantity <= 0) return 'Out of Stock';
    if (totalQuantity < 1) return 'Low Stock';
    return 'In Stock';
  }

  String get location {
    if (farmSegments.isNotEmpty) {
      return farmSegments.join(', ');
    }
    return farmLocation;
  }

  List<String> get variantNames {
    if (yieldVariants.isNotEmpty) {
      return yieldVariants.map((v) => v.cropVariantName).toList();
    }
    // Parse from variants_info string if no variant objects
    if (variantsInfo.isNotEmpty && variantsInfo != 'No variants') {
      // Parse "large: 2.00 Pieces" format
      return variantsInfo
          .split(';')
          .map((v) => v.split(':').first.trim())
          .toList();
    }
    return [];
  }

  List<String> get farmSegmentNames {
    if (yieldFarmSegments.isNotEmpty) {
      return yieldFarmSegments.map((s) => s.farmSegmentName).toList();
    }
    return farmSegments;
  }

  bool get hasVariants => yieldVariants.isNotEmpty || variantsInfo.isNotEmpty;
  bool get hasFarmSegments =>
      yieldFarmSegments.isNotEmpty || farmSegments.isNotEmpty;

  // Create a copy with updated values
  AvailableYield copyWith({
    String? id,
    String? cropId,
    String? cropName,
    DateTime? harvestDate,
    double? totalQuantity,
    String? farmLocation,
    String? variantsInfo,
    int? billCount,
    bool? hasBills,
    DateTime? createdAt,
    String? displayText,
    String? status,
    List<String>? farmSegments,
    int? variantsCount,
    List<YieldVariant>? yieldVariants,
    List<YieldFarmSegment>? yieldFarmSegments,
  }) {
    return AvailableYield(
      id: id ?? this.id,
      cropId: cropId ?? this.cropId,
      cropName: cropName ?? this.cropName,
      harvestDate: harvestDate ?? this.harvestDate,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      farmLocation: farmLocation ?? this.farmLocation,
      variantsInfo: variantsInfo ?? this.variantsInfo,
      billCount: billCount ?? this.billCount,
      hasBills: hasBills ?? this.hasBills,
      createdAt: createdAt ?? this.createdAt,
      displayText: displayText ?? this.displayText,
      status: status ?? this.status,
      farmSegments: farmSegments ?? this.farmSegments,
      variantsCount: variantsCount ?? this.variantsCount,
      yieldVariants: yieldVariants ?? this.yieldVariants,
      yieldFarmSegments: yieldFarmSegments ?? this.yieldFarmSegments,
    );
  }
}

// Search Suggestion Model
class SearchSuggestion {
  final String id;
  final String name;

  SearchSuggestion({
    required this.id,
    required this.name,
  });

  factory SearchSuggestion.fromJson(Map<String, dynamic> json) {
    return SearchSuggestion(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }

  @override
  String toString() {
    return 'SearchSuggestion(id: $id, name: $name)';
  }
}

// Constants for dropdown values
class SaleConstants {
  static const List<String> paymentModes = ['Cash', 'Card', 'UPI', 'Online'];
  static const List<String> statusChoices = [
    'pending',
    'confirmed',
    'cancelled'
  ];
  static const List<String> paymentStatusChoices = [
    'pending',
    'paid',
    'partial'
  ];
  static const List<String> dateRanges = [
    'today',
    'yesterday',
    'week',
    'month',
    'quarter'
  ];
  static const List<String> searchTypes = ['merchant', 'crop', 'yield'];
}
