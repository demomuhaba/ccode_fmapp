import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/riverpod_providers.dart';

class AddRecurringTransactionScreen extends ConsumerStatefulWidget {
  const AddRecurringTransactionScreen({super.key});

  @override
  ConsumerState<AddRecurringTransactionScreen> createState() => _AddRecurringTransactionScreenState();
}

class _AddRecurringTransactionScreenState extends ConsumerState<AddRecurringTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _templateNameController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _payerSenderController = TextEditingController();
  final _payeeReceiverController = TextEditingController();
  final _referenceNumberController = TextEditingController();
  final _intervalController = TextEditingController(text: '1');
  final _dayOfMonthController = TextEditingController();
  final _maxExecutionsController = TextEditingController();

  String _selectedAccountId = '';
  String _selectedTransactionType = 'Expense/Debit';
  String _selectedCurrency = 'ETB';
  String _selectedFrequency = 'monthly';
  bool _isInternalTransfer = false;
  String? _selectedCounterpartyAccountId;
  DateTime _selectedStartDate = DateTime.now();
  DateTime? _selectedEndDate;
  int? _selectedDayOfWeek;
  List<String> _tags = [];
  bool _isLoading = false;

  final List<String> _frequencies = ['daily', 'weekly', 'monthly', 'yearly'];
  final List<String> _transactionTypes = ['Income/Credit', 'Expense/Debit'];
  final List<String> _currencies = ['ETB', 'USD', 'EUR'];
  final List<String> _weekDays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authNotifierProvider);
      if (authState.userProfile != null) {
        ref.read(financialAccountNotifierProvider.notifier)
            .loadAccounts(authState.userProfile!.id);
      }
    });
  }

  @override
  void dispose() {
    _templateNameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _payerSenderController.dispose();
    _payeeReceiverController.dispose();
    _referenceNumberController.dispose();
    _intervalController.dispose();
    _dayOfMonthController.dispose();
    _maxExecutionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountState = ref.watch(financialAccountNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Recurring Transaction'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _saveRecurringTransaction,
              child: const Text('Save'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBasicInformationSection(),
              const SizedBox(height: 24),
              _buildTransactionDetailsSection(),
              const SizedBox(height: 24),
              _buildRecurrenceSettingsSection(),
              const SizedBox(height: 24),
              _buildSchedulingSection(),
              const SizedBox(height: 24),
              _buildOptionalFieldsSection(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInformationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Information',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _templateNameController,
              decoration: const InputDecoration(
                labelText: 'Template Name *',
                hintText: 'e.g., Monthly Rent, Weekly Groceries',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Template name is required';
                }
                if (value.trim().length < 3) {
                  return 'Template name must be at least 3 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      labelText: 'Amount *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Amount is required';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null || amount <= 0) {
                        return 'Enter a valid amount';
                      }
                      if (amount > 999999999) {
                        return 'Amount cannot exceed 999,999,999';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCurrency,
                    decoration: const InputDecoration(
                      labelText: 'Currency',
                      border: OutlineInputBorder(),
                    ),
                    items: _currencies.map((currency) {
                      return DropdownMenuItem(
                        value: currency,
                        child: Text(currency),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCurrency = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedTransactionType,
              decoration: const InputDecoration(
                labelText: 'Transaction Type *',
                border: OutlineInputBorder(),
              ),
              items: _transactionTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTransactionType = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionDetailsSection() {
    final accountState = ref.watch(financialAccountNotifierProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transaction Details',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedAccountId.isEmpty ? null : _selectedAccountId,
              decoration: const InputDecoration(
                labelText: 'Account *',
                border: OutlineInputBorder(),
              ),
              items: accountState.accounts.map((account) {
                return DropdownMenuItem(
                  value: account.id,
                  child: Text('${account.accountName} (${account.accountType})'),
                );
              }).toList(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select an account';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  _selectedAccountId = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Internal Transfer'),
              subtitle: const Text('Transfer between your own accounts'),
              value: _isInternalTransfer,
              onChanged: (value) {
                setState(() {
                  _isInternalTransfer = value;
                  if (!value) {
                    _selectedCounterpartyAccountId = null;
                  }
                });
              },
            ),
            if (_isInternalTransfer) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCounterpartyAccountId,
                decoration: const InputDecoration(
                  labelText: 'Destination Account *',
                  border: OutlineInputBorder(),
                ),
                items: accountState.accounts
                    .where((account) => account.id != _selectedAccountId)
                    .map((account) {
                  return DropdownMenuItem(
                    value: account.id,
                    child: Text('${account.accountName} (${account.accountType})'),
                  );
                }).toList(),
                validator: (value) {
                  if (_isInternalTransfer && (value == null || value.isEmpty)) {
                    return 'Please select a destination account';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _selectedCounterpartyAccountId = value;
                  });
                },
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Optional notes about this transaction',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecurrenceSettingsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recurrence Settings',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedFrequency,
                    decoration: const InputDecoration(
                      labelText: 'Frequency *',
                      border: OutlineInputBorder(),
                    ),
                    items: _frequencies.map((frequency) {
                      return DropdownMenuItem(
                        value: frequency,
                        child: Text(frequency.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedFrequency = value!;
                        _selectedDayOfWeek = null;
                        _dayOfMonthController.clear();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _intervalController,
                    decoration: const InputDecoration(
                      labelText: 'Every X',
                      hintText: '1',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Interval is required';
                      }
                      final interval = int.tryParse(value);
                      if (interval == null || interval < 1 || interval > 365) {
                        return 'Enter 1-365';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            if (_selectedFrequency == 'weekly') ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedDayOfWeek,
                decoration: const InputDecoration(
                  labelText: 'Day of Week',
                  border: OutlineInputBorder(),
                ),
                items: _weekDays.asMap().entries.map((entry) {
                  return DropdownMenuItem(
                    value: entry.key + 1, // 1-7 for Monday-Sunday
                    child: Text(entry.value),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDayOfWeek = value;
                  });
                },
              ),
            ],
            if (_selectedFrequency == 'monthly') ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _dayOfMonthController,
                decoration: const InputDecoration(
                  labelText: 'Day of Month (1-31)',
                  hintText: 'Leave empty for current day',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final day = int.tryParse(value);
                    if (day == null || day < 1 || day > 31) {
                      return 'Enter a day between 1-31';
                    }
                  }
                  return null;
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSchedulingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scheduling',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Start Date'),
              subtitle: Text('${_selectedStartDate.day}/${_selectedStartDate.month}/${_selectedStartDate.year}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedStartDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                );
                if (date != null) {
                  setState(() {
                    _selectedStartDate = date;
                  });
                }
              },
            ),
            ListTile(
              title: const Text('End Date (Optional)'),
              subtitle: Text(_selectedEndDate != null 
                  ? '${_selectedEndDate!.day}/${_selectedEndDate!.month}/${_selectedEndDate!.year}'
                  : 'No end date'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_selectedEndDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _selectedEndDate = null;
                        });
                      },
                    ),
                  const Icon(Icons.calendar_today),
                ],
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedEndDate ?? _selectedStartDate.add(const Duration(days: 365)),
                  firstDate: _selectedStartDate,
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                );
                if (date != null) {
                  setState(() {
                    _selectedEndDate = date;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _maxExecutionsController,
              decoration: const InputDecoration(
                labelText: 'Maximum Executions (Optional)',
                hintText: 'Leave empty for unlimited',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final max = int.tryParse(value);
                  if (max == null || max < 1) {
                    return 'Enter a number greater than 0';
                  }
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionalFieldsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Additional Details (Optional)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _payerSenderController,
              decoration: const InputDecoration(
                labelText: 'Payer/Sender',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _payeeReceiverController,
              decoration: const InputDecoration(
                labelText: 'Payee/Receiver',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _referenceNumberController,
              decoration: const InputDecoration(
                labelText: 'Reference Number',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveRecurringTransaction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authState = ref.read(authNotifierProvider);
      if (authState.userProfile == null) {
        throw Exception('User not authenticated');
      }

      final success = await ref.read(recurringTransactionNotifierProvider.notifier)
          .createRecurringTransaction(
        userId: authState.userProfile!.id,
        affectedAccountId: _selectedAccountId,
        templateName: _templateNameController.text.trim(),
        amount: double.parse(_amountController.text),
        transactionType: _selectedTransactionType,
        currency: _selectedCurrency,
        descriptionNotes: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        payerSenderRaw: _payerSenderController.text.trim().isEmpty 
            ? null 
            : _payerSenderController.text.trim(),
        payeeReceiverRaw: _payeeReceiverController.text.trim().isEmpty 
            ? null 
            : _payeeReceiverController.text.trim(),
        referenceNumber: _referenceNumberController.text.trim().isEmpty 
            ? null 
            : _referenceNumberController.text.trim(),
        isInternalTransfer: _isInternalTransfer,
        counterpartyAccountId: _selectedCounterpartyAccountId,
        frequency: _selectedFrequency,
        interval: int.parse(_intervalController.text),
        startDate: _selectedStartDate,
        endDate: _selectedEndDate,
        maxExecutions: _maxExecutionsController.text.trim().isEmpty 
            ? null 
            : int.parse(_maxExecutionsController.text),
        dayOfMonth: _dayOfMonthController.text.trim().isEmpty 
            ? null 
            : int.parse(_dayOfMonthController.text),
        dayOfWeek: _selectedDayOfWeek,
        tags: _tags,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recurring transaction created successfully')),
        );
        Navigator.pop(context);
      } else if (mounted) {
        final error = ref.read(recurringTransactionNotifierProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create recurring transaction: ${error ?? 'Unknown error'}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}