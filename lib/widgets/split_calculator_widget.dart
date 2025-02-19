import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_expense_tracker_bloc/blocs/expense_form/expense_form_bloc.dart';
import 'package:flutter_expense_tracker_bloc/models/split_info.dart';

// Helper function to truncate decimals to 2 digits without rounding.
String truncateTo2Decimals(double value) {
  double truncated = (value * 100).truncateToDouble() / 100;
  return truncated.toStringAsFixed(2);
}

class SplitCalculatorWidget extends StatefulWidget {
  const SplitCalculatorWidget({super.key});

  @override
  State<SplitCalculatorWidget> createState() => _SplitCalculatorWidgetState();
}

class _SplitCalculatorWidgetState extends State<SplitCalculatorWidget> {
  final TextEditingController _nameController = TextEditingController();
  // The share controller is retained in case you want to restore it later.
  final TextEditingController _shareController = TextEditingController();
  final TextEditingController _totalAmountController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _shareController.dispose();
    _totalAmountController.dispose();
    super.dispose();
  }

  void _addParticipant() {
    final name = _nameController.text.trim();
    // Even though the share field is hidden, we preserve its logic.
    final shareText = _shareController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a name.")),
      );
      return;
    }

    // We still parse share if entered; if not, default to 0.
    final share = shareText.isEmpty ? null : double.tryParse(shareText);
    if (share != null && share <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid share amount.")),
      );
      return;
    }

    final bloc = context.read<ExpenseFormBloc>();
    final updatedSplits = List<SplitInfo>.from(bloc.state.splitInfos)
      ..add(SplitInfo(personName: name, share: share ?? 0));
    bloc.add(ExpenseSplitInfoChanged(updatedSplits));

    _nameController.clear();
    _shareController.clear();
  }

  void _removeParticipant(int index) {
    final bloc = context.read<ExpenseFormBloc>();
    final updatedSplits = List<SplitInfo>.from(bloc.state.splitInfos)
      ..removeAt(index);
    bloc.add(ExpenseSplitInfoChanged(updatedSplits));
  }

  void _updateTotalAmount() {
    final totalAmountText = _totalAmountController.text.trim();
    final totalAmount = double.tryParse(totalAmountText);

    if (totalAmount == null || totalAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid total amount.")),
      );
      return;
    }

    final bloc = context.read<ExpenseFormBloc>();
    bloc.add(ExpenseAmountChanged(totalAmountText));
  }

  void _splitEqually() {
    final bloc = context.read<ExpenseFormBloc>();
    final totalAmount = bloc.state.amount ?? 0.0;
    final participants = List<SplitInfo>.from(bloc.state.splitInfos);

    if (participants.isEmpty || totalAmount <= 0) return;

    final double equalShare = totalAmount / participants.length;
    final updatedSplits = participants
        .map((p) => SplitInfo(personName: p.personName, share: equalShare))
        .toList();
    bloc.add(ExpenseSplitInfoChanged(updatedSplits));
  }

  void _editParticipant(int index) {
    final participant = context.read<ExpenseFormBloc>().state.splitInfos[index];
    _nameController.text = participant.personName;
    _shareController.text = participant.share.toString();
    _removeParticipant(index);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExpenseFormBloc, ExpenseFormState>(
      builder: (context, state) {
        final totalAmount = state.amount ?? 0.0;
        final totalSplitAmount =
            state.splitInfos.fold(0.0, (sum, p) => sum + p.share);
        final bool isSplitCorrect = state.splitInfos.isEmpty ||
            (totalSplitAmount - totalAmount).abs() < 0.01;

        return Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Split Expense",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              // Moved Name text box (with add button) to appear first.
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: "Name",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _addParticipant,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Total Amount text box is now displayed after the Name field.
              TextField(
                controller: _totalAmountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Total Amount",
                  border: OutlineInputBorder(),
                ),
                onEditingComplete: _updateTotalAmount,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _splitEqually,
                child: const Text("Split Equally"),
              ),
              const SizedBox(height: 10),
              if (!isSplitCorrect)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    "⚠ The total split does not match the expense amount!",
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 10),
              if (state.splitInfos.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.splitInfos.length,
                  itemBuilder: (context, index) {
                    final participant = state.splitInfos[index];
                    return ListTile(
                      title: Text(participant.personName),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("€${truncateTo2Decimals(participant.share)}"),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _editParticipant(index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeParticipant(index),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
