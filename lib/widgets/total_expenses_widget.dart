import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_expense_tracker_bloc/blocs/expense_list/expense_list_bloc.dart';

// Helper function to truncate decimals to 2 digits without rounding.
String truncateTo2Decimals(double value) {
  double truncated = (value * 100).truncateToDouble() / 100;
  return truncated.toStringAsFixed(2);
}

class TotalExpensesWidget extends StatelessWidget {
  const TotalExpensesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final state = context.watch<ExpenseListBloc>().state;

    // Use our helper function to display total expenses without rounding.
    final totalExpenses = "€${truncateTo2Decimals(state.totalExpenses)}";

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Expenses',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
          Text(totalExpenses, style: textTheme.displaySmall),
        ],
      ),
    );
  }
}
