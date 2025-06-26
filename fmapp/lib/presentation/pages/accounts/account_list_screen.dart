import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/riverpod_providers.dart' as providers;
import 'add_account_screen.dart';
import 'edit_account_screen.dart';

class AccountListScreen extends ConsumerStatefulWidget {
  const AccountListScreen({super.key});

  @override
  ConsumerState<AccountListScreen> createState() => _AccountListScreenState();
}

class _AccountListScreenState extends ConsumerState<AccountListScreen> {
  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final authState = ref.read(providers.authNotifierProvider);
    final userId = authState.userProfile?.userId;
    
    if (userId != null) {
      await Future.wait([
        ref.read(providers.financialAccountNotifierProvider.notifier).loadAccounts(userId),
        ref.read(providers.simCardNotifierProvider.notifier).loadSimCards(userId),
      ]);
    }
  }

  Future<void> _handleRefresh() async {
    await _loadAccounts();
  }

  void _navigateToAddAccount() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AddAccountScreen()),
    );
    
    if (result == true) {
      await _handleRefresh();
    }
  }

  void _navigateToEditAccount(String accountId) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditAccountScreen(accountId: accountId),
      ),
    );
    
    if (result == true) {
      await _handleRefresh();
    }
  }

  void _confirmDeleteAccount(String accountId, String accountName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: Text('Are you sure you want to delete "$accountName"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteAccount(accountId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(String accountId) async {
    final success = await ref.read(providers.financialAccountNotifierProvider.notifier).deleteAccount(accountId);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Account deleted successfully' : 'Failed to delete account'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  IconData _getAccountIcon(String accountType) {
    switch (accountType.toLowerCase()) {
      case 'bank account':
        return Icons.account_balance;
      case 'mobile wallet':
        return Icons.wallet;
      case 'online money':
        return Icons.cloud;
      default:
        return Icons.account_balance_wallet;
    }
  }

  Color _getAccountColor(String accountType) {
    switch (accountType.toLowerCase()) {
      case 'bank account':
        return Colors.blue;
      case 'mobile wallet':
        return Colors.green;
      case 'online money':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Accounts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _handleRefresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: Consumer(
          builder: (context, ref, child) {
            final accountState = ref.watch(providers.financialAccountNotifierProvider);
            final simCardState = ref.watch(providers.simCardNotifierProvider);
            
            if (accountState.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${accountState.error}',
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.read(providers.financialAccountNotifierProvider.notifier).clearError();
                        _handleRefresh();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (accountState.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (accountState.accounts.isEmpty) {
              return _buildEmptyState();
            }

            return Column(
              children: [
                _buildTotalBalanceCard(),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: accountState.accounts.length,
                    itemBuilder: (context, index) {
                      final account = accountState.accounts[index];
                      final balance = ref.read(providers.financialAccountNotifierProvider.notifier).getAccountBalance(account.id);
                      final simCard = ref.read(providers.simCardNotifierProvider.notifier).getSimCardById(account.linkedSimId);
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: _getAccountColor(account.accountType).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _getAccountIcon(account.accountType),
                              color: _getAccountColor(account.accountType),
                            ),
                          ),
                          title: Text(
                            account.accountName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(account.accountIdentifier),
                              Text(
                                '${account.accountType} • ${simCard?.simNickname ?? 'Unknown SIM'}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'ETB ${balance.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: balance >= 0 ? Colors.green : Colors.red,
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _navigateToEditAccount(account.id);
                                  } else if (value == 'delete') {
                                    _confirmDeleteAccount(account.id, account.accountName);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: ListTile(
                                      leading: Icon(Icons.edit),
                                      title: Text('Edit'),
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: ListTile(
                                      leading: Icon(Icons.delete, color: Colors.red),
                                      title: Text('Delete', style: TextStyle(color: Colors.red)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddAccount,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTotalBalanceCard() {
    final totalBalance = ref.read(providers.financialAccountNotifierProvider.notifier).getTotalBalance();
    
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Balance',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'All Accounts',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              Text(
                'ETB ${totalBalance.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: totalBalance >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
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
            'No Accounts',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add your first financial account to get started',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _navigateToAddAccount,
            icon: const Icon(Icons.add),
            label: const Text('Add Account'),
          ),
        ],
      ),
    );
  }
}