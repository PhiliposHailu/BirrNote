import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/expense_providers.dart';
import '../../../settings/data/category_providers.dart';
import '../../../../core/utils/locale_provider.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';

class ManualEntrySheet extends ConsumerStatefulWidget {
  final DateTime? initialDate;
  final Expense? existingExpense;
  const ManualEntrySheet({super.key, this.initialDate, this.existingExpense});

  @override
  ConsumerState<ManualEntrySheet> createState() => _ManualEntrySheetState();
}

class _ManualEntrySheetState extends ConsumerState<ManualEntrySheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _customDaysController = TextEditingController();

  String? _selectedCategory;
  int _quantity = 1;
  bool _isAmortized = false;
  int _amortizeDays = 7;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onAmountChanged);

    if (widget.existingExpense != null) {
      final expense = widget.existingExpense!;
      _amountController.text = expense.amount.toString();
      _noteController.text = expense.rawNote;
      _selectedCategory = expense.category;
      _quantity = expense.quantity;
      _checkExistingAmortization();
    }
  }

  void _onAmountChanged() {
    if (_isAmortized) {
      setState(() {});
    }
  }

  Future<void> _checkExistingAmortization() async {
    if (widget.existingExpense != null) {
      final amort = await ref
          .read(amortizationDaoProvider)
          .getAmortizationForExpense(widget.existingExpense!.id);
      if (amort != null && mounted) {
        setState(() {
          _isAmortized = true;
          _amortizeDays = amort.durationDays;
          if (![7, 14, 30].contains(_amortizeDays)) {
            _customDaysController.text = _amortizeDays.toString();
          }
        });
      }
    }
  }

  void _submit() {
    final amountText = _amountController.text;
    if (amountText.isEmpty || _selectedCategory == null) return;

    final amount = double.tryParse(amountText) ?? 0.0;
    final amortizeDaysToPass = _isAmortized ? _amortizeDays : null;

    if (widget.existingExpense != null) {
      ref
          .read(expenseLogicProvider)
          .editExpense(
            id: widget.existingExpense!.id,
            amount: amount,
            category: _selectedCategory!,
            quantity: _quantity,
            note: _noteController.text,
            date: widget.existingExpense!.date,
            amortizeDays: amortizeDaysToPass,
          );
    } else {
      ref
          .read(expenseLogicProvider)
          .addManualExpense(
            amount: amount,
            category: _selectedCategory!,
            quantity: _quantity,
            note: _noteController.text,
            date: widget.initialDate,
            amortizeDays: amortizeDaysToPass,
          );
    }

    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    _noteController.dispose();
    _customDaysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final categoriesStream = ref.watch(categoryNamesStreamProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: bottomInset,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.existingExpense != null
                    ? "Edit Expense"
                    : ref.watch(trProvider('manual_entry')),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // AMOUNT INPUT
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: ref.watch(trProvider('amount_etb')),
                  prefixIcon: const Icon(Icons.attach_money),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // DYNAMIC CATEGORY DROPDOWN
              categoriesStream.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Text(
                  '${ref.watch(trProvider('error_loading_categories'))}$error',
                ),
                data: (categories) {
                  final List<String> availableCategories = List.from(
                    categories,
                  );
                  if (widget.existingExpense != null &&
                      !availableCategories.contains(
                        widget.existingExpense!.category,
                      )) {
                    availableCategories.add(widget.existingExpense!.category);
                  }

                  if (_selectedCategory == null ||
                      !availableCategories.contains(_selectedCategory)) {
                    _selectedCategory = availableCategories.isNotEmpty
                        ? availableCategories.first
                        : 'Others';
                  }

                  return DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: ref.watch(trProvider('category_label')),
                      border: const OutlineInputBorder(),
                    ),
                    items: availableCategories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedCategory = value);
                      }
                    },
                  );
                },
              ),
              const SizedBox(height: 16),

              // QUANTITY PICKER
              Row(
                children: [
                  Text(
                    ref.watch(trProvider('quantity_label')),
                    style: const TextStyle(fontSize: 16),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => setState(
                      () => _quantity = _quantity > 1 ? _quantity - 1 : 1,
                    ),
                  ),
                  Text(
                    '$_quantity',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => setState(() => _quantity++),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // OPTIONAL NOTE
              TextField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: ref.watch(trProvider('note_optional')),
                  hintText: ref.watch(trProvider('eg_lunch')),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // SPREAD COST (AMORTIZATION) SECTION
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isAmortized
                        ? Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.5)
                        : Theme.of(
                            context,
                          ).colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text(
                        ref.watch(trProvider('spread_cost')),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Text(
                        ref.watch(trProvider('spread_cost_desc')),
                        style: const TextStyle(fontSize: 12),
                      ),
                      value: _isAmortized,
                      onChanged: (val) => setState(() => _isAmortized = val),
                    ),
                    if (_isAmortized) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Divider(height: 1),
                            const SizedBox(height: 12),
                            // PRESET DURATION CHIPS
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ChoiceChip(
                                  label: Text(ref.watch(trProvider('days_7'))),
                                  selected: _amortizeDays == 7,
                                  onSelected: (sel) {
                                    if (sel) {
                                      setState(() => _amortizeDays = 7);
                                    }
                                  },
                                ),
                                ChoiceChip(
                                  label: Text(ref.watch(trProvider('days_14'))),
                                  selected: _amortizeDays == 14,
                                  onSelected: (sel) {
                                    if (sel) {
                                      setState(() => _amortizeDays = 14);
                                    }
                                  },
                                ),
                                ChoiceChip(
                                  label: Text(ref.watch(trProvider('days_30'))),
                                  selected: _amortizeDays == 30,
                                  onSelected: (sel) {
                                    if (sel) {
                                      setState(() => _amortizeDays = 30);
                                    }
                                  },
                                ),
                                ChoiceChip(
                                  label: Text(
                                    ref.watch(trProvider('custom_days')),
                                  ),
                                  selected: ![
                                    7,
                                    14,
                                    30,
                                  ].contains(_amortizeDays),
                                  onSelected: (sel) {
                                    if (sel) {
                                      setState(() {
                                        final customVal =
                                            int.tryParse(
                                              _customDaysController.text,
                                            ) ??
                                            5;
                                        _amortizeDays = customVal > 1
                                            ? customVal
                                            : 5;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                            if (![7, 14, 30].contains(_amortizeDays)) ...[
                              const SizedBox(height: 12),
                              TextField(
                                controller: _customDaysController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText:
                                      '${ref.watch(trProvider('custom_days'))} (${ref.watch(trProvider('days_suffix'))})',
                                  hintText: 'e.g. 5, 21...',
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                ),
                                onChanged: (val) {
                                  final parsed = int.tryParse(val);
                                  if (parsed != null && parsed > 1) {
                                    setState(() => _amortizeDays = parsed);
                                  }
                                },
                              ),
                            ],
                            const SizedBox(height: 12),
                            // LIVE PREVIEW BANNER
                            Builder(
                              builder: (context) {
                                final amt =
                                    double.tryParse(_amountController.text) ??
                                    0.0;
                                final burden = _amortizeDays > 0
                                    ? amt / _amortizeDays
                                    : 0.0;
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primaryContainer
                                        .withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today_rounded,
                                        size: 18,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '✦ ${burden.toStringAsFixed(2)} ETB ${ref.watch(trProvider('per_day'))} ${ref.watch(trProvider('for_duration'))} $_amortizeDays ${ref.watch(trProvider('days_suffix'))}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // SAVE BUTTON
              FilledButton(
                onPressed: _submit,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    ref.watch(trProvider('save_expense')),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
