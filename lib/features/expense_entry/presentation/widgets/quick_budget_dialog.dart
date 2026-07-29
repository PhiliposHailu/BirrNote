import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/utils/locale_provider.dart';

class QuickBudgetDialog extends ConsumerStatefulWidget {
  const QuickBudgetDialog({super.key});

  @override
  ConsumerState<QuickBudgetDialog> createState() => _QuickBudgetDialogState();
}

class _QuickBudgetDialogState extends ConsumerState<QuickBudgetDialog> {
  final _amountController = TextEditingController();
  String _selectedPeriod = 'Weekly';
  final List<String> _periods = ['Daily', 'Weekly', 'Monthly', 'Quarterly', 'Yearly'];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        ref.watch(trProvider('set_budget')),
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            ref.watch(trProvider('tap_to_set_budget')),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: _selectedPeriod,
            decoration: InputDecoration(
              labelText: ref.watch(trProvider('cycle')),
              border: const OutlineInputBorder(),
            ),
            items: _periods.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedPeriod = val);
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: ref.watch(trProvider('limit_amount')),
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            ref.watch(trProvider('cancel')),
            style: const TextStyle(color: Colors.red),
          ),
        ),
        FilledButton(
          onPressed: () async {
            final text = _amountController.text;
            final limit = double.tryParse(text);
            if (limit != null && limit > 0) {
              Navigator.pop(context);
              await ref.read(budgetDaoProvider).setBudget(limit, _selectedPeriod);
            }
          },
          child: Text(ref.watch(trProvider('save'))),
        ),
      ],
    );
  }
}