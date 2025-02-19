import 'package:flutter_expense_tracker_bloc/models/split_info.dart';
import 'package:flutter_expense_tracker_bloc/models/category.dart'; 
import 'package:flutter_expense_tracker_bloc/models/expense.dart'; 
import 'package:equatable/equatable.dart'; 
part of 'expense_form_bloc.dart';

enum ExpenseFormStatus { initial, loading, success, failure }

extension ExpenseFormStatusX on ExpenseFormStatus {
  bool get isLoading => [
        ExpenseFormStatus.loading,
        ExpenseFormStatus.success,
      ].contains(this);
}

final class ExpenseFormState extends Equatable {
  const ExpenseFormState({
    this.title,
    this.amount,
    required this.date,
    this.category = Category.other,
    this.status = ExpenseFormStatus.initial,
    this.initialExpense,
    this.splitInfos = const [], // NEW: default empty list for split info
  });

  final String? title;
  final double? amount;
  final DateTime date;
  final Category category;
  final ExpenseFormStatus status;
  final Expense? initialExpense;
  final List<SplitInfo> splitInfos; // NEW field for split info

  ExpenseFormState copyWith({
    String? title,
    double? amount,
    DateTime? date,
    Category? category,
    ExpenseFormStatus? status,
    Expense? initialExpense,
    List<SplitInfo>? splitInfos, // NEW parameter
  }) {
    return ExpenseFormState(
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      status: status ?? this.status,
      initialExpense: initialExpense ?? this.initialExpense,
      splitInfos: splitInfos ?? this.splitInfos, // NEW: update splitInfos
    );
  }

  @override
  List<Object?> get props => [
        title,
        amount,
        date,
        category,
        status,
        initialExpense,
        splitInfos, // NEW: include splitInfos in props
      ];

  bool get isFormValid => title != null && amount != null;
}
