import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/recurring_transaction.dart';
import '../../providers/riverpod_providers.dart';

class EditRecurringTransactionScreen extends ConsumerStatefulWidget {
  final RecurringTransaction recurringTransaction;

  const EditRecurringTransactionScreen({
    super.key,
    required this.recurringTransaction,
  });

  @override
  ConsumerState<EditRecurringTransactionScreen> createState() => _EditRecurringTransactionScreenState();
}

class _EditRecurringTransactionScreenState extends ConsumerState<EditRecurringTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _templateNameController;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late TextEditingController _payerSenderController;
  late TextEditingController _payeeReceiverController;
  late TextEditingController _referenceNumberController;
  late TextEditingController _intervalController;
  late TextEditingController _dayOfMonthController;
  late TextEditingController _maxExecutionsController;

  late String _selectedAccountId;
  late String _selectedTransactionType;
  late String _selectedCurrency;
  late String _selectedFrequency;
  late bool _isInternalTransfer;
  String? _selectedCounterpartyAccountId;
  late DateTime _selectedStartDate;
  DateTime? _selectedEndDate;
  int? _selectedDayOfWeek;
  late List<String> _tags;
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
    _initializeControllers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authNotifierProvider);
      if (authState.userProfile != null) {
        ref.read(financialAccountNotifierProvider.notifier)
            .loadAccounts(authState.userProfile!.id);
      }
    });
  }

  void _initializeControllers() {
    final rt = widget.recurringTransaction;
    
    _templateNameController = TextEditingController(text: rt.templateName);
    _amountController = TextEditingController(text: rt.amount.toString());
    _descriptionController = TextEditingController(text: rt.descriptionNotes ?? '');
    _payerSenderController = TextEditingController(text: rt.payerSenderRaw ?? '');
    _payeeReceiverController = TextEditingController(text: rt.payeeReceiverRaw ?? '');
    _referenceNumberController = TextEditingController(text: rt.referenceNumber ?? '');
    _intervalController = TextEditingController(text: rt.interval.toString());
    _dayOfMonthController = TextEditingController(text: rt.dayOfMonth?.toString() ?? '');
    _maxExecutionsController = TextEditingController(text: rt.maxExecutions?.toString() ?? '');

    _selectedAccountId = rt.affectedAccountId;
    _selectedTransactionType = rt.transactionType;
    _selectedCurrency = rt.currency;
    _selectedFrequency = rt.frequency;
    _isInternalTransfer = rt.isInternalTransfer;
    _selectedCounterpartyAccountId = rt.counterpartyAccountId;
    _selectedStartDate = rt.startDate;
    _selectedEndDate = rt.endDate;
    _selectedDayOfWeek = rt.dayOfWeek;
    _tags = List<String>.from(rt.tags ?? []);
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
        title: const Text('Edit Recurring Transaction'),
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
              onPressed: _saveChanges,
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
              _buildInfoCard(),
              const SizedBox(height: 16),
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

  Widget _buildInfoCard() {
    final rt = widget.recurringTransaction;
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'Current Status',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Executed: ${rt.executionCount} times'),
            if (rt.lastExecuted != null)
              Text('Last executed: ${_formatDate(rt.lastExecuted!)}'),
            if (rt.nextExecution != null)
              Text('Next execution: ${_formatDate(rt.nextExecution!)}'),
            Text('Status: ${rt.isActive ? 'Active' : 'Paused'}'),
            if (rt.hasEnded())
              const Text('This recurring transaction has ended', 
                  style: TextStyle(color: Colors.red)),
          ],
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
                        if (value != 'weekly') _selectedDayOfWeek = null;
                        if (value != 'monthly') _dayOfMonthController.clear();
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
                    value: entry.key + 1,
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
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
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

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedTransaction = widget.recurringTransaction.copyWith(
        templateName: _templateNameController.text.trim(),
        amount: double.parse(_amountController.text),
        transactionType: _selectedTransactionType,
        currency: _selectedCurrency,
        affectedAccountId: _selectedAccountId,
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

      final success = await ref.read(recurringTransactionNotifierProvider.notifier)
          .updateRecurringTransaction(updatedTransaction);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recurring transaction updated successfully')),
        );
        Navigator.pop(context);
      } else if (mounted) {
        final error = ref.read(recurringTransactionNotifierProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update recurring transaction: ${error ?? 'Unknown error'}')),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}