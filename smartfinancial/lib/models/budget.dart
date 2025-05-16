class Budget {
  final String id;
  final String category;
  final double amount;
  final double spent;

  Budget({
    required this.id,
    required this.category,
    required this.amount,
    this.spent = 0.0,
  });
}