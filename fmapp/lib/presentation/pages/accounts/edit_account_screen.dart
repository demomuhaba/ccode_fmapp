import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/riverpod_providers.dart' as providers;

class EditAccountScreen extends ConsumerStatefulWidget {
  final String accountId;

  const EditAccountScreen({super.key, required this.accountId});

  @override
  ConsumerState<EditAccountScreen> createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends ConsumerState<EditAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _accountNameController = TextEditingController();
  final _accountIdentifierController = TextEditingController();
  final _initialBalanceController = TextEditingController();
  
  String _selectedAccountType = 'Bank Account';
  String? _selectedSimId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccountData();
  }

  @override
  void dispose() {
    _accountNameController.dispose();
    _accountIdentifierController.dispose();
    _initialBalanceController.dispose();
    super.dispose();
  }

  void _loadAccountData() {
    final accountNotifier = ref.read(providers.financialAccountNotifierProvider.notifier);
    final account = accountNotifier.getAccountById(widget.accountId);
    
    if (account != null) {
      _accountNameController.text = account.accountName;
      _accountIdentifierController.text = account.accountIdentifier;
      _initialBalanceController.text = account.initialBalance.toString();
      _selectedAccountType = account.accountType;
      _selectedSimId = account.linkedSimId;
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final accountNotifier = ref.read(providers.financialAccountNotifierProvider.notifier);
    final account = accountNotifier.getAccountById(widget.accountId);
    
    if (account == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedSimId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a SIM card'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final updatedAccount = account.copyWith(
      accountName: _accountNameController.text.trim(),
      accountIdentifier: _accountIdentifierController.text.trim(),
      accountType: _selectedAccountType,
      linkedSimId: _selectedSimId!,
      initialBalance: double.tryParse(_initialBalanceController.text.trim()) ?? 0.0,
    );

    final success = await accountNotifier.updateAccount(updatedAccount);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ref.read(providers.financialAccountNotifierProvider).error ?? 'Failed to update account'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getIdentifierHint(String accountType) {
    switch (accountType.toLowerCase()) {
      case 'bank account':
        return 'Bank account number';
      case 'mobile wallet':
        return 'Mobile wallet phone number';
      case 'online money':
        return 'Custom identifier (e.g., "Online Pool 1")';
      default:
        return 'Account identifier';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Account')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Account'),
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final simCardState = ref.watch(providers.simCardNotifierProvider);
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
                          'Account Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _accountNameController,
                          decoration: const InputDecoration(
                            labelText: 'Account Name *',
                            hintText: 'My Main Bank, Work Card, etc.',
                            prefixIcon: Icon(Icons.label),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter account name';
                            }
                            if (value.trim().length < 2) {
                              return 'Account name must be at least 2 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedAccountType,
                          decoration: const InputDecoration(
                            labelText: 'Account Type *',
                            prefixIcon: Icon(Icons.category),
                          ),
                          items: ['Bank Account', 'Mobile Wallet', 'Online Money'].map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedAccountType = value!;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select an account type';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _accountIdentifierController,
                          decoration: InputDecoration(
                            labelText: 'Account Identifier *',
                            hintText: _getIdentifierHint(_selectedAccountType),
                            prefixIcon: const Icon(Icons.numbers),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter account identifier';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedSimId,
                          decoration: const InputDecoration(
                            labelText: 'Linked SIM Card *',
                            prefixIcon: Icon(Icons.sim_card),
                          ),
                          items: simCardState.simCards.map((simCard) {
                            return DropdownMenuItem(
                              value: simCard.id,
                              child: Text('${simCard.simNickname} (${simCard.phoneNumber})'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedSimId = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Please select a SIM card';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _initialBalanceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Initial Balance (ETB) *',
                            hintText: '0.00',
                            prefixIcon: Icon(Icons.attach_money),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter initial balance';
                            }
                            final balance = double.tryParse(value.trim());
                            if (balance == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '* Required fields',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_selectedAccountType == 'Online Money') ...[
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
                                'About Online Money Accounts',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Online Money accounts are virtual pools for tracking internal transfers between your other accounts. Use them to organize funds before actual transfers.',
                            style: TextStyle(color: Colors.blue.shade700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Consumer(
                  builder: (context, ref, child) {
                    final accountState = ref.watch(providers.financialAccountNotifierProvider);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (accountState.error != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Text(
                              accountState.error!,
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ),
                        ElevatedButton(
                          onPressed: accountState.isLoading ? null : _handleSubmit,
                          child: accountState.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Update Account'),
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