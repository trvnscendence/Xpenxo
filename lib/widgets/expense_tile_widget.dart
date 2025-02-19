import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_expense_tracker_bloc/blocs/expense_list/expense_list_bloc.dart';
import 'package:flutter_expense_tracker_bloc/extensions/extensions.dart';
import 'package:flutter_expense_tracker_bloc/models/expense.dart';
import 'package:intl/intl.dart';

// Helper function to truncate decimals to 2 digits without rounding.
String truncateTo2Decimals(double value) {
  double truncated = (value * 100).truncateToDouble() / 100;
  return truncated.toStringAsFixed(2);
}

class ExpenseTileWidget extends StatelessWidget {
  const ExpenseTileWidget({super.key, required this.expense});
  final Expense expense;

  void _deleteExpense(BuildContext context) {
    context
        .read<ExpenseListBloc>()
        .add(ExpenseListExpenseDeleted(expense: expense));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final formattedDate = DateFormat('dd/MM/yyyy').format(expense.date);
    // Use our helper to display amount with two decimal places (without rounding)
    final price = "€${truncateTo2Decimals(expense.amount)}";

    return Dismissible(
      key: ValueKey(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.all(16),
        color: colorScheme.error,
        child: Icon(
          Icons.delete,
          color: colorScheme.onError, // Consistent error color
        ),
      ),
      onDismissed: (direction) {
        _deleteExpense(context);
      },
      child: ListTile(
        onTap: () => context.showAddExpenseSheet(expense: expense),
        leading: Icon(Icons.car_repair, color: colorScheme.surfaceTint),
        title: Text(expense.title, style: textTheme.titleMedium),
        subtitle: Text(
          formattedDate,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('-$price', style: textTheme.titleLarge),
            IconButton(
              icon: Icon(
                Icons.delete,
                color: colorScheme.error, // Consistent delete icon color
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Expense'),
                    content: const Text(
                        'Are you sure you want to delete this expense?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _deleteExpense(context);
                        },
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
