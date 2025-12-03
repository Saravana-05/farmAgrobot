import 'package:flutter/material.dart';

class Employee {
  final String id;
  final String name;
  final String tamilName;
  final String empType;
  final String gender;
  final String contact;
  final DateTime joiningDate;
  final bool status;
  final String? imageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Employee({
    required this.id,
    required this.name,
    required this.tamilName,
    required this.empType,
    required this.gender,
    required this.contact,
    required this.joiningDate,
    required this.status,
    this.imageUrl,
    this.createdAt,
    this.updatedAt,
  });

  /// Create Employee from JSON (API response) with proper status conversion
  factory Employee.fromJson(Map<String, dynamic> json) {
    // Handle status conversion from backend (0/1) to boolean
    bool parseStatus(dynamic statusValue) {
      if (statusValue == null) return true; // Default to active
      
      if (statusValue is bool) {
        return statusValue;
      } else if (statusValue is int) {
        return statusValue == 1; // 1 = active, 0 = inactive
      } else if (statusValue is String) {
        // Handle string representations
        final lowerStatus = statusValue.toLowerCase();
        return lowerStatus == '1' || 
               lowerStatus == 'true' || 
               lowerStatus == 'active';
      }
      
      return true; // Default fallback
    }

    return Employee(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      tamilName: json['tamil_name'] ?? '',
      empType: json['emp_type'] ?? '',
      gender: json['gender'] ?? '',
      contact: json['contact'] ?? '',
      joiningDate: json['joining_date'] != null 
          ? DateTime.parse(json['joining_date']) 
          : DateTime.now(),
      status: parseStatus(json['status']),
      imageUrl: json['image_url'] ?? json['profile_image'], // Handle both field names
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  /// Convert Employee to JSON (for API requests)
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'tamil_name': tamilName,
      'emp_type': empType,
      'gender': gender,
      'contact': contact,
      'joining_date': joiningDate.toIso8601String().split('T')[0], // YYYY-MM-DD format
      'status': status ? 1 : 0, // Convert boolean to integer for backend
    };
  }

  /// Convert to JSON for status update API calls
  Map<String, dynamic> toStatusUpdateJson() {
    return {
      'status': status ? 1 : 0, // Send as integer to backend
    };
  }

  /// Create a copy of Employee with updated fields
  Employee copyWith({
    String? id,
    String? name,
    String? tamilName,
    String? empType,
    String? gender,
    String? contact,
    DateTime? joiningDate,
    bool? status,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      tamilName: tamilName ?? this.tamilName,
      empType: empType ?? this.empType,
      gender: gender ?? this.gender,
      contact: contact ?? this.contact,
      joiningDate: joiningDate ?? this.joiningDate,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get formatted joining date
  String get formattedJoiningDate {
    return '${joiningDate.day.toString().padLeft(2, '0')}/'
           '${joiningDate.month.toString().padLeft(2, '0')}'
           '${joiningDate.year}';
  }

  /// Get status text
  String get statusText {
    return status ? 'Active' : 'Inactive';
  }

  /// Get status color
  Color get statusColor {
    return status ? Colors.green : Colors.red;
  }

  /// Get status icon
  IconData get statusIcon {
    return status ? Icons.check_circle : Icons.cancel;
  }

  /// Get employee type display text
  String get empTypeDisplay {
    switch (empType.toLowerCase()) {
      case 'regular':
        return 'Regular';
      case 'contract':
        return 'Contract';
      case 'others':
        return 'Others';
      default:
        return empType;
    }
  }

  /// Get gender display text
  String get genderDisplay {
    switch (gender.toLowerCase()) {
      case 'male':
        return 'Male';
      case 'female':
        return 'Female';
      case 'other':
        return 'Other';
      default:
        return gender;
    }
  }

  /// Check if employee has image
  bool get hasImage {
    return imageUrl != null && imageUrl!.isNotEmpty;
  }

  /// Get display image URL or placeholder
  String get displayImageUrl {
    if (hasImage) {
      return imageUrl!;
    }
    return 'https://via.placeholder.com/150x150.png?text=No+Image';
  }

  /// Get employee initials for avatar
  String get initials {
    final nameParts = name.trim().split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else if (nameParts.isNotEmpty) {
      return nameParts[0][0].toUpperCase();
    }
    return 'E';
  }

  /// Get status as integer (for backend compatibility)
  int get statusAsInt {
    return status ? 1 : 0;
  }

  /// Check if employee is active
  bool get isActive {
    return status;
  }

  /// Check if employee is inactive
  bool get isInactive {
    return !status;
  }

  String get displayName {
  if (tamilName.isNotEmpty) {
    return '$name ($tamilName)';
  }
  return name;
}

  @override
  String toString() {
    return 'Employee{id: $id, name: $name, empType: $empType, status: $status}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Employee &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}