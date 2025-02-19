// ignore_for_file: must_be_immutable

import 'package:equatable/equatable.dart';

import 'category.dart';
import 'split_info.dart'; // Import the split info model

class Expense extends Equatable {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final Category category;
  final List<SplitInfo>? splitInfos; // NEW field

  const Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    this.splitInfos, // Accept splitInfos optionally
  });

  @override
  List<Object?> get props => [
        id,
        title,
        amount,
        date,
        category,
        splitInfos, // Include splitInfos in the props
      ];

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      title: json['title'],
      amount: double.tryParse(json['amount']) ?? 0.0,
      date: DateTime.fromMillisecondsSinceEpoch(json['date']),
      category: Category.fromJson(json['category']),
      splitInfos: json['splitInfos'] != null
          ? List<SplitInfo>.from((json['splitInfos'] as List)
              .map((item) => SplitInfo.fromJson(item)))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount.toString(),
      'date': date.millisecondsSinceEpoch,
      'category': category.toJson(),
      'splitInfos': splitInfos?.map((s) => s.toJson()).toList(),
    };
  }

  Expense copyWith({
    String? title,
    double? amount,
    DateTime? date,
    Category? category,
    List<SplitInfo>? splitInfos,
  }) {
    return Expense(
      id: id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      splitInfos: splitInfos ?? this.splitInfos,
    );
  }

  @override
  bool get stringify => true;
}
