import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/riverpod_providers.dart' as providers;

class AddLoanDebtScreen extends ConsumerStatefulWidget {
  final String? preselectedFriendId;

  const AddLoanDebtScreen({super.key, this.preselectedFriendId});

  @override
  ConsumerState<AddLoanDebtScreen> createState() => _AddLoanDebtScreenState();
}

class _AddLoanDebtScreenState extends ConsumerState<AddLoanDebtScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedType = 'LoanGivenToFriend';
  String? _selectedFriendId;
  String _selectedTransactionMethod = 'Cash';
  DateTime _selectedDate = DateTime.now();
  DateTime? _selectedDueDate;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedFriendId = widget.preselectedFriendId;
    _loadData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final authState = ref.read(providers.authNotifierProvider);
    final friendNotifier = ref.read(providers.friendNotifierProvider.notifier);
    final accountNotifier = ref.read(providers.financialAccountNotifierProvider.notifier);
    final userId = authState.userProfile?.userId;
    
    if (userId != null) {
      await Future.wait([
        friendNotifier.loadFriends(userId),
        accountNotifier.loadAccounts(userId),
      ]);
      
      final friendState = ref.read(providers.friendNotifierProvider);
      if (_selectedFriendId == null && friendState.friends.isNotEmpty) {
        _selectedFriendId = friendState.friends.first.id;
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

  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    
    if (date != null) {
      setState(() {
        _selectedDueDate = date;
      });
    }
  }

  void _clearDueDate() {
    setState(() {
      _selectedDueDate = null;
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final authState = ref.read(providers.authNotifierProvider);
    final loanDebtNotifier = ref.read(providers.loanDebtNotifierProvider.notifier);
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

    if (_selectedFriendId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a friend first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final success = await loanDebtNotifier.createLoanDebt(
      userId: userId,
      associatedFriendId: _selectedFriendId!,
      type: _selectedType,
      initialAmount: double.parse(_amountController.text.trim()),
      dateInitiated: _selectedDate,
      description: _descriptionController.text.trim(),
      initialTransactionMethod: _selectedTransactionMethod,
      dueDate: _selectedDueDate,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Loan/debt record created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ref.read(providers.loanDebtNotifierProvider).error ?? 'Failed to create loan/debt record'),
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
        appBar: AppBar(title: const Text('Add Loan/Debt')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Loan/Debt'),
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final friendState = ref.watch(providers.friendNotifierProvider);
          final accountState = ref.watch(providers.financialAccountNotifierProvider);
          if (friendState.friends.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'No Friends Found',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You need to add at least one friend before creating loan/debt records',
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
                          'Loan/Debt Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedType,
                          decoration: const InputDecoration(
                            labelText: 'Type *',
                            prefixIcon: Icon(Icons.category),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'LoanGivenToFriend',
                              child: Text('Loan Given to Friend'),
                            ),
                            DropdownMenuItem(
                              value: 'DebtOwedToFriend',
                              child: Text('Debt Owed to Friend'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedType = value!;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select loan/debt type';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedFriendId,
                          decoration: const InputDecoration(
                            labelText: 'Friend *',
                            prefixIcon: Icon(Icons.person),
                          ),
                          items: friendState.friends.map((friend) {
                            return DropdownMenuItem(
                              value: friend.id,
                              child: Text(friend.friendName),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedFriendId = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Please select a friend';
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
                            hintText: 'What is this loan/debt for?',
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
                          'Transaction Method',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedTransactionMethod,
                          decoration: const InputDecoration(
                            labelText: 'How was this money transferred? *',
                            prefixIcon: Icon(Icons.payment),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: 'Cash',
                              child: Text('Cash'),
                            ),
                            ...accountState.accounts.map((account) {
                              return DropdownMenuItem(
                                value: account.id,
                                child: Text('${account.accountName} (${account.accountType})'),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedTransactionMethod = value!;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select transaction method';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _selectedTransactionMethod == 'Cash' 
                              ? 'This will not affect your account balances'
                              : 'This will automatically create a transaction in your selected account',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
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
                          'Dates',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          title: const Text('Date Initiated *'),
                          subtitle: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                          leading: const Icon(Icons.calendar_today),
                          onTap: _selectDate,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          title: const Text('Due Date (Optional)'),
                          subtitle: Text(_selectedDueDate != null 
                              ? '${_selectedDueDate!.day}/${_selectedDueDate!.month}/${_selectedDueDate!.year}'
                              : 'No due date set'),
                          leading: const Icon(Icons.event),
                          trailing: _selectedDueDate != null 
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: _clearDueDate,
                                )
                              : null,
                          onTap: _selectDueDate,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
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
                              'Important Notes',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _selectedType == 'LoanGivenToFriend'
                              ? 'You are recording money you lent to this friend. If you used an account, the money will be deducted from your balance.'
                              : 'You are recording money you borrowed from this friend. If you received it in an account, the money will be added to your balance.',
                          style: TextStyle(color: Colors.blue.shade700),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Consumer(
                  builder: (context, ref, child) {
                    final loanDebtState = ref.watch(providers.loanDebtNotifierProvider);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (loanDebtState.error != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Text(
                              loanDebtState.error!,
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ),
                        ElevatedButton(
                          onPressed: loanDebtState.isLoading ? null : _handleSubmit,
                          child: loanDebtState.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Create Loan/Debt Record'),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}