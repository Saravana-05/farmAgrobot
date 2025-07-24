import '../../../config/api.dart';

class ExpenseModel {
  final int? id;
  final String expenseName;
  final String expenseDate;
  final String expenseCategory;
  final String description;
  final double amount;
  final String spentBy;
  final String modeOfPayment;
  final String? expenseImageUrl;

  ExpenseModel({
    this.id,
    required this.expenseName,
    required this.expenseDate,
    required this.expenseCategory,
    required this.description,
    required this.amount,
    required this.spentBy,
    required this.modeOfPayment,
    this.expenseImageUrl,
  });

  // Add a getter to return the complete image URL
  String? get fullImageUrl {
    if (expenseImageUrl == null || expenseImageUrl!.isEmpty) {
      return null;
    }

    // If the URL already starts with http, return as is
    if (expenseImageUrl!.startsWith('http')) {
      return expenseImageUrl;
    }

    // If it starts with /, combine with base URL
    if (expenseImageUrl!.startsWith('/')) {
      return '$baseImgUrl$expenseImageUrl';
    }

    // Otherwise, add both / and base URL
    return '$baseImgUrl/$expenseImageUrl';
  }

  Map<String, dynamic> toJson() {
    return {
      'expense_name': expenseName,
      'date': expenseDate,
      'category': expenseCategory,
      'description': description,
      'amount': amount,
      'spent_by': spentBy,
      'mode_of_payment': modeOfPayment,
    };
  }

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'],
      expenseName: json['expense_name'] ?? '',
      expenseDate: json['date'] ?? '',
      expenseCategory: json['category'] ?? '',
      description: json['description'] ?? '',
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      spentBy: json['spent_by'] ?? '',
      modeOfPayment: json['mode_of_payment'] ?? '',
      expenseImageUrl: json['expense_image_url'],
    );
  }
}
