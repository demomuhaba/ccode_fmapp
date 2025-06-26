import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/riverpod_providers.dart' as providers;

class InternalTransferScreen extends ConsumerStatefulWidget {
  const InternalTransferScreen({super.key});

  @override
  ConsumerState<InternalTransferScreen> createState() => _InternalTransferScreenState();
}

class _InternalTransferScreenState extends ConsumerState<InternalTransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _referenceController = TextEditingController();
  
  String? _fromAccountId;
  String? _toAccountId;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _loadAccounts() async {
    final authState = ref.read(providers.authNotifierProvider);
    final userId = authState.userProfile?.userId;
    
    if (userId != null) {
      await ref.read(providers.financialAccountNotifierProvider.notifier).loadAccounts(userId);
      
      final accountState = ref.read(providers.financialAccountNotifierProvider);
      if (accountState.accounts.isNotEmpty) {
        _fromAccountId = accountState.accounts.first.id;
        if (accountState.accounts.length > 1) {
          _toAccountId = accountState.accounts[1].id;
        }
      }
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    
    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  void _swapAccounts() {
    setState(() {
      final temp = _fromAccountId;
      _fromAccountId = _toAccountId;
      _toAccountId = temp;
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final authState = ref.read(providers.authNotifierProvider);
    final userId = authState.userProfile?.userId;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not found. Please sign in again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_fromAccountId == null || _toAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both accounts'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_fromAccountId == _toAccountId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot transfer to the same account'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final transferDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final success = await ref.read(providers.transactionNotifierProvider.notifier).createTransaction(
      userId: userId,
      affectedAccountId: _fromAccountId!,
      transactionDate: transferDateTime,
      amount: double.parse(_amountController.text.trim()),
      transactionType: 'Internal Transfer',
      descriptionNotes: _descriptionController.text.trim(),
      isInternalTransfer: true,
      counterpartyAccountId: _toAccountId!,
      referenceNumber: _referenceController.text.trim().isEmpty ? null : _referenceController.text.trim(),
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Internal transfer completed successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        final transactionState = ref.read(providers.transactionNotifierProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(transactionState.error ?? 'Failed to complete transfer'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final accountState = ref.watch(providers.financialAccountNotifierProvider);
        if (accountState.accounts.length < 2) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.swap_horiz_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Need More Accounts',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'You need at least 2 financial accounts to make internal transfers',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Add More Accounts'),
                ),
              ],
            ),
          );
        }

        return Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Transfer Between Accounts',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            onPressed: _swapAccounts,
                            icon: const Icon(Icons.swap_vert),
                            tooltip: 'Swap accounts',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _fromAccountId,
                        decoration: const InputDecoration(
                          labelText: 'From Account *',
                          prefixIcon: Icon(Icons.call_made),
                        ),
                        items: accountState.accounts.map((account) {
                          final balance = ref.read(providers.financialAccountNotifierProvider.notifier).getAccountBalance(account.id);
                          return DropdownMenuItem(
                            value: account.id,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${account.accountName} (${account.accountType})'),
                                Text(
                                  'Balance: ETB ${balance.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: balance >= 0 ? Colors.green : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _fromAccountId = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select source account';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _toAccountId,
                        decoration: const InputDecoration(
                          labelText: 'To Account *',
                          prefixIcon: Icon(Icons.call_received),
                        ),
                        items: accountState.accounts.map((account) {
                          final balance = ref.read(providers.financialAccountNotifierProvider.notifier).getAccountBalance(account.id);
                          return DropdownMenuItem(
                            value: account.id,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${account.accountName} (${account.accountType})'),
                                Text(
                                  'Balance: ETB ${balance.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: balance >= 0 ? Colors.green : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _toAccountId = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select destination account';
                          }
                          if (value == _fromAccountId) {
                            return 'Destination must be different from source';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Transfer Amount (ETB) *',
                          hintText: '0.00',
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter transfer amount';
                          }
                          final amount = double.tryParse(value.trim());
                          if (amount == null || amount <= 0) {
                            return 'Please enter a valid positive amount';
                          }
                          
                          // Check if source account has sufficient balance
                          if (_fromAccountId != null) {
                            final balance = ref.read(providers.financialAccountNotifierProvider.notifier).getAccountBalance(_fromAccountId!);
                            if (amount > balance) {
                              return 'Insufficient balance in source account';
                            }
                          }
                          
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Transfer Description *',
                          hintText: 'What is this transfer for?',
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 2,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter transfer description';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_fromAccountId != null && _toAccountId != null) _buildBalanceInfo(),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Date & Time',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              title: const Text('Date'),
                              subtitle: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                              leading: const Icon(Icons.calendar_today),
                              onTap: _selectDate,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ListTile(
                              title: const Text('Time'),
                              subtitle: Text(_selectedTime.format(context)),
                              leading: const Icon(Icons.access_time),
                              onTap: _selectTime,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Additional Information (Optional)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _referenceController,
                        decoration: const InputDecoration(
                          labelText: 'Reference Number',
                          hintText: 'Transfer ID or reference',
                          prefixIcon: Icon(Icons.confirmation_number),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Consumer(
                builder: (context, ref, child) {
                  final transactionState = ref.watch(providers.transactionNotifierProvider);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (transactionState.error != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(
                            transactionState.error!,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                      ElevatedButton(
                        onPressed: transactionState.isLoading ? null : _handleSubmit,
                        child: transactionState.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Complete Transfer'),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBalanceInfo() {
    final accountNotifier = ref.read(providers.financialAccountNotifierProvider.notifier);
    final fromAccount = accountNotifier.getAccountById(_fromAccountId!);
    final toAccount = accountNotifier.getAccountById(_toAccountId!);
    final fromBalance = accountNotifier.getAccountBalance(_fromAccountId!);
    final toBalance = accountNotifier.getAccountBalance(_toAccountId!);
    
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Current Balances',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'From: ${fromAccount?.accountName}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        'ETB ${fromBalance.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: fromBalance >= 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward, color: Colors.grey),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'To: ${toAccount?.accountName}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        'ETB ${toBalance.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: toBalance >= 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}