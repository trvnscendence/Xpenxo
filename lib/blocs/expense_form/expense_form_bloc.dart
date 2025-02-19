import 'package:equatable/equatable.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter_expense_tracker_bloc/models/category.dart';
import 'package:flutter_expense_tracker_bloc/models/expense.dart';
import 'package:flutter_expense_tracker_bloc/models/split_info.dart';
import 'package:flutter_expense_tracker_bloc/repositories/expense_repository.dart';
import 'package:uuid/uuid.dart';

part 'expense_form_event.dart';
part 'expense_form_state.dart';

class ExpenseFormBloc extends Bloc<ExpenseFormEvent, ExpenseFormState> {
  ExpenseFormBloc({
    required ExpenseRepository repository,
    Expense? initialExpense,
  })  : _repository = repository,
        super(ExpenseFormState(
          initialExpense: initialExpense,
          title: initialExpense?.title,
          amount: initialExpense?.amount,
          date: initialExpense?.date ?? DateTime.now(),
          category: initialExpense?.category ?? Category.other,
          splitInfos: initialExpense?.splitInfos ?? [],
        )) {
    on<ExpenseTitleChanged>(onTitleChanged);
    on<ExpenseAmountChanged>(onAmountChanged);
    on<ExpenseDateChanged>(onDateChanged);
    on<ExpenseCategoryChanged>(onCategoryChanged);
    on<ExpenseSplitInfoChanged>(onSplitInfoChanged);
    on<ExpenseSubmitted>(onSubmitted);
  }

  final ExpenseRepository _repository;

  void onTitleChanged(
    ExpenseTitleChanged event,
    Emitter<ExpenseFormState> emit,
  ) {
    emit(state.copyWith(title: event.title));
  }

  void onAmountChanged(
    ExpenseAmountChanged event,
    Emitter<ExpenseFormState> emit,
  ) {
    final amount = double.tryParse(event.amount) ?? 0.0;
    emit(state.copyWith(amount: amount));
    if (state.splitInfos.isNotEmpty) {
      _updateSplitInfos(emit, amount);
    }
  }

  void onDateChanged(
    ExpenseDateChanged event,
    Emitter<ExpenseFormState> emit,
  ) {
    emit(state.copyWith(date: event.date));
  }

  void onCategoryChanged(
    ExpenseCategoryChanged event,
    Emitter<ExpenseFormState> emit,
  ) {
    emit(state.copyWith(category: event.category));
  }

  void onSplitInfoChanged(
    ExpenseSplitInfoChanged event,
    Emitter<ExpenseFormState> emit,
  ) {
    final updatedSplitInfos =
        _validateAndAdjustSplitInfos(event.splitInfos, state.amount ?? 0.0);
    emit(state.copyWith(splitInfos: updatedSplitInfos));
  }

  /// Auto-adjusts split shares when the expense amount is updated.
  void _updateSplitInfos(Emitter<ExpenseFormState> emit, double newAmount) {
    if (state.splitInfos.isNotEmpty) {
      final updatedSplitInfos =
          _validateAndAdjustSplitInfos(state.splitInfos, newAmount);
      emit(state.copyWith(splitInfos: updatedSplitInfos));
    }
  }

  /// Ensures that the split shares sum to the total expense amount.
  /// If all shares are zero, it auto-splits equally.
  List<SplitInfo> _validateAndAdjustSplitInfos(
      List<SplitInfo> splitInfos, double totalAmount) {
    if (splitInfos.isEmpty) return [];
    double totalShare = splitInfos.fold(0.0, (sum, info) => sum + info.share);
    if (totalShare == 0) {
      // If shares are all 0, auto-split equally.
      double equalShare = totalAmount / splitInfos.length;
      return splitInfos
          .map((info) =>
              SplitInfo(personName: info.personName, share: equalShare))
          .toList();
    } else if (totalShare != totalAmount) {
      // Adjust shares proportionally so that they sum to totalAmount.
      double adjustmentFactor = totalAmount / totalShare;
      return splitInfos
          .map((info) => SplitInfo(
              personName: info.personName,
              share: (info.share * adjustmentFactor).clamp(0, totalAmount)))
          .toList();
    }
    return splitInfos;
  }

  /// Handles the expense submission.
  /// If no split info is provided, adds a default split for the full amount.
  Future<void> onSubmitted(
    ExpenseSubmitted event,
    Emitter<ExpenseFormState> emit,
  ) async {
    if (state.title == null || state.amount == null) {
      emit(state.copyWith(status: ExpenseFormStatus.failure));
      return;
    }

    List<SplitInfo> splits = state.splitInfos;

    // If no splits are provided, add a default split with the full expense amount.
    if (splits.isEmpty) {
      splits = [SplitInfo(personName: "Default", share: state.amount ?? 0.0)];
    }

    double totalSplit = splits.fold(0.0, (sum, p) => sum + p.share);
    if ((totalSplit - state.amount!).abs() > 0.001) {
      // The split amounts do not match the expense amount.
      emit(state.copyWith(status: ExpenseFormStatus.failure));
      return;
    }

    emit(state.copyWith(status: ExpenseFormStatus.loading));
    try {
      final expense = Expense(
        id: state.initialExpense?.id ?? const Uuid().v4(),
        title: state.title!,
        amount: state.amount!,
        date: state.date,
        category: state.category,
        splitInfos: splits,
      );
      if (state.initialExpense != null) {
        await _repository.updateExpense(expense);
      } else {
        await _repository.createExpense(expense);
      }

      emit(state.copyWith(status: ExpenseFormStatus.success));
      // Reset the form state after successful submission.
      emit(ExpenseFormState(
          initialExpense: null,
          title: null,
          amount: null,
          date: DateTime.now(),
          category: Category.other,
          splitInfos: const []));
    } catch (e) {
      emit(state.copyWith(status: ExpenseFormStatus.failure));
    }
  }
}
