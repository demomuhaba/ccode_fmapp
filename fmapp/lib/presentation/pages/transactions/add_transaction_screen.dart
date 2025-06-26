import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/riverpod_providers.dart' as providers;
import 'ocr_transaction_screen.dart';
import 'internal_transfer_screen.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _payerSenderController = TextEditingController();
  final _payeeReceiverController = TextEditingController();
  final _referenceController = TextEditingController();
  
  String _selectedTransactionType = 'Income/Credit';
  String? _selectedAccountId;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAccounts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _payerSenderController.dispose();
    _payeeReceiverController.dispose();
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
        _selectedAccountId = accountState.accounts.first.id;
      }
    }
    
    setState(() {
      _isLoading = false;
    });
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

    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a financial account first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final transactionDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final success = await ref.read(providers.transactionNotifierProvider.notifier).createTransaction(
      userId: userId,
      affectedAccountId: _selectedAccountId!,
      transactionDate: transactionDateTime,
      amount: double.parse(_amountController.text.trim()),
      transactionType: _selectedTransactionType,
      descriptionNotes: _descriptionController.text.trim(),
      payerSenderRaw: _payerSenderController.text.trim().isEmpty ? null : _payerSenderController.text.trim(),
      payeeReceiverRaw: _payeeReceiverController.text.trim().isEmpty ? null : _payeeReceiverController.text.trim(),
      referenceNumber: _referenceController.text.trim().isEmpty ? null : _referenceController.text.trim(),
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction added successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        final transactionState = ref.read(providers.transactionNotifierProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(transactionState.error ?? 'Failed to add transaction'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Add Transaction')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Manual', icon: Icon(Icons.edit)),
            Tab(text: 'OCR Scan', icon: Icon(Icons.camera_alt)),
            Tab(text: 'Transfer', icon: Icon(Icons.swap_horiz)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildManualEntryTab(),
          const OCRTransactionScreen(),
          const InternalTransferScreen(),
        ],
      ),
    );
  }

  Widget _buildManualEntryTab() {
    return Consumer(
      builder: (context, ref, child) {
        final accountState = ref.watch(providers.financialAccountNotifierProvider);
        if (accountState.accounts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 24),
                const Text(
                  'No Accounts Found',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'You need to add at least one financial account before creating transactions',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Go Back'),
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
                      const Text(
                        'Transaction Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedAccountId,
                        decoration: const InputDecoration(
                          labelText: 'Account *',
                          prefixIcon: Icon(Icons.account_balance_wallet),
                        ),
                        items: accountState.accounts.map((account) {
                          return DropdownMenuItem(
                            value: account.id,
                            child: Text('${account.accountName} (${account.accountType})'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedAccountId = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select an account';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedTransactionType,
                        decoration: const InputDecoration(
                          labelText: 'Transaction Type *',
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: ['Income/Credit', 'Expense/Debit'].map((type) {
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
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select transaction type';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Amount (ETB) *',
                          hintText: '0.00',
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter amount';
                          }
                          final amount = double.tryParse(value.trim());
                          if (amount == null || amount <= 0) {
                            return 'Please enter a valid positive amount';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description *',
                          hintText: 'What is this transaction for?',
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 2,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter description';
                          }
                          return null;
                        },
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
                        controller: _payerSenderController,
                        decoration: const InputDecoration(
                          labelText: 'Payer/Sender',
                          hintText: 'Who sent the money?',
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _payeeReceiverController,
                        decoration: const InputDecoration(
                          labelText: 'Payee/Receiver',
                          hintText: 'Who received the money?',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _referenceController,
                        decoration: const InputDecoration(
                          labelText: 'Reference Number',
                          hintText: 'Transaction ID or reference',
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
                            : const Text('Add Transaction'),
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
}