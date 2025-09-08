class Merchant {
  final String id;
  final String name;
  final String address;
  final String paymentTerms;
  final String contact;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Merchant({
    required this.id,
    required this.name,
    required this.address,
    required this.paymentTerms,
    required this.contact,
    this.createdAt,
    this.updatedAt,
  });

  factory Merchant.fromJson(Map<String, dynamic> json) {
    return Merchant(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      paymentTerms: json['payment_terms'] ?? '',
      contact: json['contact'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'payment_terms': paymentTerms,
      'contact': contact,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}