import 'package:flutter/material.dart';
import '../models/budget.dart';

class BudgetCard extends StatelessWidget {
  final Budget budget;

  const BudgetCard({super.key, required this.budget});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(budget.category),
        subtitle: Text('Budget: \$${budget.amount.toStringAsFixed(2)}'),
        trailing: Text('Spent: \$${budget.spent.toStringAsFixed(2)}'),
      ),
    );
  }
}