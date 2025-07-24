class ExpenseModel {
  final String id;
  final String expenseName;
  final DateTime date;
  final String category;
  final double amount;
  final String spentBy;
  final String modeOfPayment;
  final String description;
  final String imageUrl;

  ExpenseModel({
    required this.id,
    required this.expenseName,
    required this.date,
    required this.category,
    required this.amount,
    required this.spentBy,
    required this.modeOfPayment,
    required this.description,
    required this.imageUrl, required String expenseDate, required String expenseCategory, required expenseImageUrl,
  });
}