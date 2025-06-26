import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/riverpod_providers.dart' as providers;
import 'add_transaction_screen.dart';
import 'edit_transaction_screen.dart';
import 'transaction_split_screen.dart';

class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({super.key});

  @override
  ConsumerState<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen> {
  String _filter = 'All';
  final List<String> _filterOptions = ['All', 'Income', 'Expense', 'Internal Transfer'];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final authState = ref.read(providers.authNotifierProvider);
    final userId = authState.userProfile?.userId;
    
    if (userId != null) {
      await Future.wait([
        ref.read(providers.transactionNotifierProvider.notifier).loadTransactions(userId),
        ref.read(providers.financialAccountNotifierProvider.notifier).loadAccounts(userId),
      ]);
    }
  }

  Future<void> _handleRefresh() async {
    await _loadTransactions();
  }

  void _navigateToAddTransaction() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
    );
    
    if (result == true) {
      await _handleRefresh();
    }
  }

  void _navigateToEditTransaction(String transactionId) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditTransactionScreen(transactionId: transactionId),
      ),
    );
    
    if (result == true) {
      await _handleRefresh();
    }
  }

  void _navigateToSplitTransaction(String transactionId, double amount) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TransactionSplitScreen(
          transactionId: transactionId,
          totalAmount: amount,
        ),
      ),
    );
    
    if (result == true) {
      await _handleRefresh();
    }
  }

  void _confirmDeleteTransaction(String transactionId, String description) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text('Are you sure you want to delete "$description"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteTransaction(transactionId);
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

  Future<void> _deleteTransaction(String transactionId) async {
    final success = await ref.read(providers.transactionNotifierProvider.notifier).deleteTransaction(transactionId);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Transaction deleted successfully' : 'Failed to delete transaction'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  List<dynamic> _getFilteredTransactions(List<dynamic> transactions) {
    switch (_filter) {
      case 'Income':
        return transactions.where((t) => 
          t.transactionType.toLowerCase().contains('income') || 
          t.transactionType.toLowerCase().contains('credit')
        ).toList();
      case 'Expense':
        return transactions.where((t) => 
          t.transactionType.toLowerCase().contains('expense') || 
          t.transactionType.toLowerCase().contains('debit')
        ).toList();
      case 'Internal Transfer':
        return transactions.where((t) => t.isInternalTransfer).toList();
      default:
        return transactions;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _filter = value;
              });
            },
            itemBuilder: (context) => _filterOptions.map((filter) {
              return PopupMenuItem(
                value: filter,
                child: Row(
                  children: [
                    if (_filter == filter) 
                      const Icon(Icons.check, size: 16)
                    else 
                      const SizedBox(width: 16),
                    const SizedBox(width: 8),
                    Text(filter),
                  ],
                ),
              );
            }).toList(),
          ),
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
            final transactionState = ref.watch(providers.transactionNotifierProvider);
            final accountState = ref.watch(providers.financialAccountNotifierProvider);
            
            if (transactionState.error != null) {
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
                      'Error: ${transactionState.error}',
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.read(providers.transactionNotifierProvider.notifier).clearError();
                        _handleRefresh();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (transactionState.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final allTransactions = transactionState.transactions;
            final filteredTransactions = _getFilteredTransactions(allTransactions);

            if (allTransactions.isEmpty) {
              return _buildEmptyState();
            }

            if (filteredTransactions.isEmpty) {
              return _buildNoFilterResults();
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredTransactions.length,
              itemBuilder: (context, index) {
                final transaction = filteredTransactions[index];
                final account = ref.read(providers.financialAccountNotifierProvider.notifier).getAccountById(transaction.affectedAccountId);
                final isIncome = transaction.transactionType.toLowerCase().contains('income') ||
                                transaction.transactionType.toLowerCase().contains('credit');
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: (isIncome ? Colors.green : Colors.red).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        transaction.isInternalTransfer 
                            ? Icons.swap_horiz
                            : (isIncome ? Icons.arrow_downward : Icons.arrow_upward),
                        color: transaction.isInternalTransfer 
                            ? Colors.blue 
                            : (isIncome ? Colors.green : Colors.red),
                      ),
                    ),
                    title: Text(
                      transaction.descriptionNotes,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(account?.accountName ?? 'Unknown Account'),
                        Text(
                          '${_formatDate(transaction.transactionDate)} • ${transaction.transactionType}',
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
                          '${isIncome ? '+' : '-'}ETB ${transaction.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: transaction.isInternalTransfer 
                                ? Colors.blue 
                                : (isIncome ? Colors.green : Colors.red),
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _navigateToEditTransaction(transaction.id);
                            } else if (value == 'split') {
                              _navigateToSplitTransaction(transaction.id, transaction.amount);
                            } else if (value == 'delete') {
                              _confirmDeleteTransaction(transaction.id, transaction.descriptionNotes);
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
                            if (!transaction.isInternalTransfer)
                              const PopupMenuItem(
                                value: 'split',
                                child: ListTile(
                                  leading: Icon(Icons.call_split),
                                  title: Text('Split'),
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
                    onTap: () => _navigateToEditTransaction(transaction.id),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddTransaction,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          const Text(
            'No Transactions',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add your first transaction to get started',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _navigateToAddTransaction,
            icon: const Icon(Icons.add),
            label: const Text('Add Transaction'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoFilterResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.filter_list_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'No $_filter Transactions',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try changing the filter or add new transactions',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _filter = 'All';
              });
            },
            child: const Text('Show All Transactions'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}