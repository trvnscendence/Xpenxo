import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_expense_tracker_bloc/blocs/expense_form/expense_form_bloc.dart';
import 'package:flutter_expense_tracker_bloc/blocs/expense_list/expense_list_bloc.dart';
import 'package:intl/intl.dart';

import '../models/category.dart';
import 'loading_widget.dart';
import 'text_form_field_widget.dart';
import 'split_calculator_widget.dart'; // Use the full split calculator

class AddExpenseSheetWidget extends StatelessWidget {
  const AddExpenseSheetWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<ExpenseFormBloc, ExpenseFormState>(
      listener: (context, state) {
        if (state.status == ExpenseFormStatus.success) {
          // Trigger the ExpenseListBloc to fetch updated expenses
          context.read<ExpenseListBloc>().add(const ExpenseListFetch());
          // Close the add expense sheet
          Navigator.pop(context);
        }
      },
      child: Padding(
        padding: MediaQuery.viewInsetsOf(context),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const TitleFieldWidget(),
              const SizedBox(height: 16),
              const AmountFieldWidget(),
              const SizedBox(height: 16),
              const DateFieldWidget(),
              const SizedBox(height: 24),
              const CategoryChoicesWidget(),
              const SizedBox(height: 16),
              BlocBuilder<ExpenseFormBloc, ExpenseFormState>(
                builder: (context, state) {
                  return state.amount != null && state.amount! > 0
                      ? const SplitCalculatorWidget()
                      : const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 30),
              const AddButtonWidget(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class AddButtonWidget extends StatelessWidget {
  const AddButtonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ExpenseFormBloc>().state;
    final isLoading = state.status == ExpenseFormStatus.loading;

    return FilledButton(
      onPressed: (isLoading || !state.isFormValid)
          ? null
          : () {
              // Trigger expense submission.
              context.read<ExpenseFormBloc>().add(const ExpenseSubmitted());
            },
      child: isLoading ? const LoadingWidget() : const Text('Add Expense'),
    );
  }
}

class DateFieldWidget extends StatelessWidget {
  const DateFieldWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final bloc = context.read<ExpenseFormBloc>();
    final state = context.watch<ExpenseFormBloc>().state;

    final formattedDate = DateFormat('dd/MM/yyyy').format(state.date);

    return GestureDetector(
      onTap: () async {
        final today = DateTime.now();
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: state.date,
          firstDate: DateTime(1900),
          lastDate: DateTime(today.year + 50),
        );
        if (selectedDate != null) {
          bloc.add(ExpenseDateChanged(selectedDate));
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Date',
            style: textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.4),
              height: 1,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 10),
          Text(formattedDate, style: textTheme.titleLarge),
        ],
      ),
    );
  }
}

class AmountFieldWidget extends StatelessWidget {
  const AmountFieldWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ExpenseFormBloc>().state;
    // Display amount with two decimal places if available.
    final initial = state.amount?.toStringAsFixed(2);

    return TextFormFieldWidget(
      label: 'Amount',
      hint: '0.00',
      prefixText: '€',
      enabled: !state.status.isLoading,
      initialValue: initial,
      onChanged: (value) {
        context.read<ExpenseFormBloc>().add(ExpenseAmountChanged(value));
      },
    );
  }
}

class TitleFieldWidget extends StatelessWidget {
  const TitleFieldWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final state = context.watch<ExpenseFormBloc>().state;

    return TextFormField(
      style: textTheme.displaySmall?.copyWith(fontSize: 30),
      onChanged: (value) {
        context.read<ExpenseFormBloc>().add(ExpenseTitleChanged(value));
      },
      initialValue: state.initialExpense?.title,
      decoration: InputDecoration(
        enabled: !state.status.isLoading,
        border: InputBorder.none,
        hintText: 'Title',
      ),
    );
  }
}

class CategoryChoicesWidget extends StatelessWidget {
  const CategoryChoicesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final bloc = context.read<ExpenseFormBloc>();
    final state = context.watch<ExpenseFormBloc>().state;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Select Category',
          style: textTheme.labelLarge?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.4),
            height: 1,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          children: Category.values
              .where((category) => category != Category.all)
              .map((currentCategory) => ChoiceChip(
                    label: Text(currentCategory.toName),
                    selected: currentCategory == state.category,
                    onSelected: (_) {
                      if (state.category == currentCategory) {
                        bloc.add(const ExpenseCategoryChanged(Category.all));
                      } else {
                        bloc.add(ExpenseCategoryChanged(currentCategory));
                      }
                    },
                  ))
              .toList(),
        ),
      ],
    );
  }
}
