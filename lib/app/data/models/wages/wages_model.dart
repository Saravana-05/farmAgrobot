import 'package:flutter/material.dart';

class Wage {
  final String id;
  final dynamic employeeId;
  final String employeeName;
  final DateTime effectiveFrom;
  final DateTime? effectiveTo;
  final double amount;
  final String? remarks;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Wage({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.effectiveFrom,
    this.effectiveTo,
    required this.amount,
    this.remarks,
    this.createdAt,
    this.updatedAt,
  });

  /// Create Wage from JSON (API response)
  factory Wage.fromJson(Map<String, dynamic> json) {
    return Wage(
      id: json['id']?.toString() ?? '',
      employeeId: json['employee_id'] ?? json['employee'] ?? '',
      employeeName: json['employee_name'] ?? '',
      effectiveFrom: json['effective_from'] != null
          ? DateTime.parse(json['effective_from'])
          : DateTime.now(),
      effectiveTo: json['effective_to'] != null
          ? DateTime.parse(json['effective_to'])
          : null,
      amount: _parseAmount(json['amount']),
      remarks: json['remarks'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  // Helper method to safely parse amount from different types
static dynamic _parseAmount(dynamic amount) {
  if (amount == null) return 0.0;
  
  if (amount is int) {
    return amount.toDouble();
  } else if (amount is double) {
    return amount;
  } else if (amount is String) {
    return double.tryParse(amount) ?? 0.0;
  } else if (amount is num) {
    return amount.toDouble();
  } else {
    // Fallback: try to parse as string
    return double.tryParse(amount.toString()) ?? 0.0;
  }
}

  /// Convert Wage to JSON (for API requests)
  Map<String, dynamic> toJson() {
    return {
      'employee_id': employeeId,
      'effective_from':
          effectiveFrom.toIso8601String().split('T')[0], // YYYY-MM-DD format
      'effective_to': effectiveTo?.toIso8601String().split('T')[0],
      'amount': amount,
      'remarks': remarks,
    };
  }

  /// Convert to JSON for update API calls
  Map<String, dynamic> toUpdateJson() {
    return {
      'effective_from': effectiveFrom.toIso8601String().split('T')[0],
      'effective_to': effectiveTo?.toIso8601String().split('T')[0],
      'amount': amount,
      'remarks': remarks,
    };
  }

  /// Create a copy of Wage with updated fields
  Wage copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    DateTime? effectiveFrom,
    DateTime? effectiveTo,
    double? amount,
    String? remarks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Wage(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      effectiveFrom: effectiveFrom ?? this.effectiveFrom,
      effectiveTo: effectiveTo ?? this.effectiveTo,
      amount: amount ?? this.amount,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get formatted effective from date
  String get formattedEffectiveFrom {
    return '${effectiveFrom.day.toString().padLeft(2, '0')}/'
        '${effectiveFrom.month.toString().padLeft(2, '0')}/'
        '${effectiveFrom.year}';
  }

  /// Get formatted effective to date
  String get formattedEffectiveTo {
    if (effectiveTo == null) return 'Ongoing';
    return '${effectiveTo!.day.toString().padLeft(2, '0')}/'
        '${effectiveTo!.month.toString().padLeft(2, '0')}/'
        '${effectiveTo!.year}';
  }

  /// Get formatted date range
  String get formattedDateRange {
    if (effectiveTo == null) {
      return '$formattedEffectiveFrom - Ongoing';
    }
    return '$formattedEffectiveFrom - $formattedEffectiveTo';
  }

  /// Get formatted amount with currency symbol
  String get formattedAmount {
    return '₹${amount.toStringAsFixed(2)}';
  }

  /// Get formatted amount without decimals if it's a whole number
  String get formattedAmountClean {
    if (amount == amount.roundToDouble()) {
      return '₹${amount.toInt()}';
    }
    return '₹${amount.toStringAsFixed(2)}';
  }

  /// Check if this wage record is currently active
  bool get isCurrent {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final effectiveFromDate =
        DateTime(effectiveFrom.year, effectiveFrom.month, effectiveFrom.day);

    if (effectiveTo != null) {
      final effectiveToDate =
          DateTime(effectiveTo!.year, effectiveTo!.month, effectiveTo!.day);
      return effectiveFromDate.isBefore(todayDate) ||
          effectiveFromDate.isAtSameMomentAs(todayDate) &&
              effectiveToDate.isAfter(todayDate) ||
          effectiveToDate.isAtSameMomentAs(todayDate);
    } else {
      return effectiveFromDate.isBefore(todayDate) ||
          effectiveFromDate.isAtSameMomentAs(todayDate);
    }
  }

  /// Check if this wage record is expired
  bool get isExpired {
    if (effectiveTo == null) return false;

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final effectiveToDate =
        DateTime(effectiveTo!.year, effectiveTo!.month, effectiveTo!.day);

    return effectiveToDate.isBefore(todayDate);
  }

  /// Check if this wage record is upcoming/future
  bool get isUpcoming {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final effectiveFromDate =
        DateTime(effectiveFrom.year, effectiveFrom.month, effectiveFrom.day);

    return effectiveFromDate.isAfter(todayDate);
  }

  /// Get status text based on current state
  String get statusText {
    if (isCurrent) return 'Current';
    if (isExpired) return 'Expired';
    if (isUpcoming) return 'Upcoming';
    return 'Unknown';
  }

  /// Get status color based on current state
  Color get statusColor {
    if (isCurrent) return Colors.green;
    if (isExpired) return Colors.red;
    if (isUpcoming) return Colors.orange;
    return Colors.grey;
  }

  /// Get status icon based on current state
  IconData get statusIcon {
    if (isCurrent) return Icons.check_circle;
    if (isExpired) return Icons.cancel;
    if (isUpcoming) return Icons.schedule;
    return Icons.help;
  }

  /// Check if wage has remarks
  bool get hasRemarks {
    return remarks != null && remarks!.isNotEmpty;
  }

  /// Get display remarks or default text
  String get displayRemarks {
    return hasRemarks ? remarks! : 'No remarks';
  }

  /// Validate wage data
  List<String> validate() {
    final errors = <String>[];

    if (employeeId.isEmpty) {
      errors.add('Employee ID is required');
    }

    if (amount <= 0) {
      errors.add('Amount must be greater than 0');
    }

    if (effectiveTo != null && effectiveTo!.isBefore(effectiveFrom)) {
      errors.add('Effective to date must be after effective from date');
    }

    return errors;
  }

  /// Check if wage data is valid
  bool get isValid {
    return validate().isEmpty;
  }

  /// Get duration in days (if effectiveTo is available)
  int? get durationInDays {
    if (effectiveTo == null) return null;
    return effectiveTo!.difference(effectiveFrom).inDays + 1;
  }

  /// Get duration text
  String get durationText {
    final days = durationInDays;
    if (days == null) return 'Ongoing';

    if (days == 1) return '1 day';
    if (days < 30) return '$days days';
    if (days < 365) {
      final months = (days / 30).round();
      return months == 1 ? '1 month' : '$months months';
    } else {
      final years = (days / 365).round();
      return years == 1 ? '1 year' : '$years years';
    }
  }

  @override
  String toString() {
    return 'Wage{id: $id, employeeId: $employeeId, amount: $amount, effectiveFrom: $effectiveFrom, isCurrent: $isCurrent}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Wage && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
