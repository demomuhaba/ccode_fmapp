import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/riverpod_providers.dart';
import '../../../domain/entities/recurring_transaction.dart';
import '../../../services/recurring_transaction_scheduler.dart';
import 'add_recurring_transaction_screen.dart';
import 'edit_recurring_transaction_screen.dart';
import 'recurring_transaction_detail_screen.dart';

class RecurringTransactionListScreen extends ConsumerStatefulWidget {
  const RecurringTransactionListScreen({super.key});

  @override
  ConsumerState<RecurringTransactionListScreen> createState() => _RecurringTransactionListScreenState();
}

class _RecurringTransactionListScreenState extends ConsumerState<RecurringTransactionListScreen> {
  String _selectedFilter = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authNotifierProvider);
      if (authState.userProfile != null) {
        ref.read(recurringTransactionNotifierProvider.notifier)
            .loadRecurringTransactions(authState.userProfile!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final recurringTransactionState = ref.watch(recurringTransactionNotifierProvider);

    if (authState.userProfile == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to view recurring transactions')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(recurringTransactionNotifierProvider.notifier)
                  .loadRecurringTransactions(authState.userProfile!.id);
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.schedule),
            tooltip: 'Scheduler Options',
            onSelected: _handleSchedulerAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'status',
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 20),
                    SizedBox(width: 8),
                    Text('Scheduler Status'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'check_now',
                child: Row(
                  children: [
                    Icon(Icons.play_arrow, size: 20),
                    SizedBox(width: 8),
                    Text('Check Now'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'upcoming',
                child: Row(
                  children: [
                    Icon(Icons.schedule, size: 20),
                    SizedBox(width: 8),
                    Text('Upcoming Executions'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (recurringTransactionState.stats != null) _buildStatsCard(recurringTransactionState.stats!),
          Expanded(
            child: _buildTransactionList(recurringTransactionState),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddRecurringTransactionScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatsCard(Map<String, dynamic> stats) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Overview', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total', stats['total'] ?? 0),
                _buildStatItem('Active', stats['active'] ?? 0),
                _buildStatItem('Paused', stats['paused'] ?? 0),
                _buildStatItem('Due Today', stats['due_today'] ?? 0),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Est. Monthly Impact: ${(stats['total_monthly_amount'] ?? 0.0).toStringAsFixed(2)} ETB',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int value) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildTransactionList(RecurringTransactionState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text('Error: ${state.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final authState = ref.read(authNotifierProvider);
                if (authState.userProfile != null) {
                  ref.read(recurringTransactionNotifierProvider.notifier)
                      .loadRecurringTransactions(authState.userProfile!.id);
                }
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final filteredTransactions = _getFilteredTransactions(state.recurringTransactions);

    if (filteredTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.repeat, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _selectedFilter == 'all' 
                  ? 'No recurring transactions yet'
                  : 'No $_selectedFilter recurring transactions',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddRecurringTransactionScreen(),
                  ),
                );
              },
              child: const Text('Add First Recurring Transaction'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredTransactions.length,
      itemBuilder: (context, index) {
        final transaction = filteredTransactions[index];
        return _buildTransactionCard(transaction);
      },
    );
  }

  Widget _buildTransactionCard(RecurringTransaction transaction) {
    final isDue = transaction.shouldExecute();
    final isOverdue = transaction.nextExecution != null && 
                      transaction.nextExecution!.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecurringTransactionDetailScreen(
                recurringTransaction: transaction,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      transaction.templateName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (isDue)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isOverdue ? Colors.red[100] : Colors.orange[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isOverdue ? 'Overdue' : 'Due',
                        style: TextStyle(
                          color: isOverdue ? Colors.red[800] : Colors.orange[800],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleMenuAction(value, transaction),
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(
                        value: transaction.isActive ? 'pause' : 'resume',
                        child: Text(transaction.isActive ? 'Pause' : 'Resume'),
                      ),
                      if (isDue)
                        const PopupMenuItem(value: 'execute', child: Text('Execute Now')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    transaction.transactionType.toLowerCase().contains('income') 
                        ? Icons.arrow_downward
                        : Icons.arrow_upward,
                    color: transaction.transactionType.toLowerCase().contains('income')
                        ? Colors.green
                        : Colors.red,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${transaction.amount.toStringAsFixed(2)} ${transaction.currency}',
                    style: TextStyle(
                      color: transaction.transactionType.toLowerCase().contains('income')
                          ? Colors.green
                          : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getStatusColor(transaction),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getStatusText(transaction),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${transaction.frequencyDisplayName} • ${transaction.executionCount} executions',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              if (transaction.nextExecution != null)
                Text(
                  'Next: ${_formatDate(transaction.nextExecution!)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              if (transaction.descriptionNotes?.isNotEmpty == true)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    transaction.descriptionNotes!,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(RecurringTransaction transaction) {
    if (transaction.hasEnded()) return Colors.grey;
    if (!transaction.isActive) return Colors.orange;
    if (transaction.shouldExecute()) return Colors.blue;
    return Colors.green;
  }

  String _getStatusText(RecurringTransaction transaction) {
    if (transaction.hasEnded()) return 'ENDED';
    if (!transaction.isActive) return 'PAUSED';
    if (transaction.shouldExecute()) return 'DUE';
    return 'ACTIVE';
  }

  List<RecurringTransaction> _getFilteredTransactions(List<RecurringTransaction> transactions) {
    var filtered = transactions;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = ref.read(recurringTransactionNotifierProvider.notifier)
          .searchRecurringTransactions(_searchQuery);
    }

    // Apply status filter
    switch (_selectedFilter) {
      case 'active':
        filtered = ref.read(recurringTransactionNotifierProvider.notifier)
            .getActiveRecurringTransactions();
        break;
      case 'paused':
        filtered = ref.read(recurringTransactionNotifierProvider.notifier)
            .getPausedRecurringTransactions();
        break;
      case 'ended':
        filtered = ref.read(recurringTransactionNotifierProvider.notifier)
            .getEndedRecurringTransactions();
        break;
      case 'due':
        filtered = ref.read(recurringTransactionNotifierProvider.notifier)
            .getDueRecurringTransactions();
        break;
    }

    return filtered;
  }

  void _handleMenuAction(String action, RecurringTransaction transaction) async {
    final notifier = ref.read(recurringTransactionNotifierProvider.notifier);

    switch (action) {
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditRecurringTransactionScreen(
              recurringTransaction: transaction,
            ),
          ),
        );
        break;
      case 'pause':
      case 'resume':
        final success = await notifier.toggleActiveStatus(transaction.id, !transaction.isActive);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                transaction.isActive 
                    ? 'Recurring transaction paused' 
                    : 'Recurring transaction resumed',
              ),
            ),
          );
        }
        break;
      case 'execute':
        final success = await notifier.executeRecurringTransaction(transaction.id);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction executed successfully')),
          );
        }
        break;
      case 'delete':
        _showDeleteDialog(transaction);
        break;
    }
  }

  void _showDeleteDialog(RecurringTransaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recurring Transaction'),
        content: Text('Are you sure you want to delete "${transaction.templateName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref.read(recurringTransactionNotifierProvider.notifier)
                  .deleteRecurringTransaction(transaction.id);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Recurring transaction deleted')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Recurring Transactions'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter search terms...',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            setState(() {
              _searchQuery = value;
            });
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
              });
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Transactions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('All'),
              value: 'all',
              groupValue: _selectedFilter,
              onChanged: (value) {
                setState(() {
                  _selectedFilter = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Active'),
              value: 'active',
              groupValue: _selectedFilter,
              onChanged: (value) {
                setState(() {
                  _selectedFilter = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Paused'),
              value: 'paused',
              groupValue: _selectedFilter,
              onChanged: (value) {
                setState(() {
                  _selectedFilter = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Ended'),
              value: 'ended',
              groupValue: _selectedFilter,
              onChanged: (value) {
                setState(() {
                  _selectedFilter = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Due Today'),
              value: 'due',
              groupValue: _selectedFilter,
              onChanged: (value) {
                setState(() {
                  _selectedFilter = value!;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _handleSchedulerAction(String action) async {
    final authState = ref.read(authNotifierProvider);
    if (authState.userProfile == null) return;

    switch (action) {
      case 'status':
        _showSchedulerStatusDialog();
        break;
      case 'check_now':
        _executeSchedulerCheckNow();
        break;
      case 'upcoming':
        _showUpcomingExecutionsDialog(authState.userProfile!.id);
        break;
    }
  }

  void _showSchedulerStatusDialog() {
    final status = RecurringTransactionScheduler.instance.getStatus();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.schedule, color: Colors.blue),
            SizedBox(width: 8),
            Text('Scheduler Status'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusRow('Initialized', status['is_initialized'] ? 'Yes' : 'No'),
            _buildStatusRow('Timer Active', status['foreground_timer_active'] ? 'Yes' : 'No'),
            _buildStatusRow('Last Check', DateTime.fromMillisecondsSinceEpoch(status['last_check']).toString()),
            const SizedBox(height: 16),
            const Text(
              'The scheduler automatically checks for due recurring transactions every 5 minutes when the app is active and every 15 minutes in the background.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }

  void _executeSchedulerCheckNow() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Checking recurring transactions...'),
          ],
        ),
      ),
    );

    try {
      final result = await RecurringTransactionScheduler.instance.checkNow();
      
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(result['success'] ? 'Check Complete' : 'Check Failed'),
            content: Text(
              result['success'] 
                  ? result['message'] 
                  : 'Error: ${result['error']}',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Refresh the recurring transactions list
                  final authState = ref.read(authNotifierProvider);
                  if (authState.userProfile != null) {
                    ref.read(recurringTransactionNotifierProvider.notifier)
                        .loadRecurringTransactions(authState.userProfile!.id);
                  }
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to check recurring transactions: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _showUpcomingExecutionsDialog(String userId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Loading upcoming executions...'),
          ],
        ),
      ),
    );

    try {
      final upcoming = await RecurringTransactionScheduler.instance.getUpcomingExecutions(userId);
      
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Upcoming Executions'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: upcoming.isEmpty
                  ? const Center(child: Text('No upcoming executions'))
                  : ListView.builder(
                      itemCount: upcoming.length,
                      itemBuilder: (context, index) {
                        final execution = upcoming[index];
                        final executionDate = DateTime.fromMillisecondsSinceEpoch(execution['execution_date']);
                        
                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 16,
                            child: Text('${execution['execution_order']}'),
                          ),
                          title: Text(execution['template_name']),
                          subtitle: Text('${execution['frequency']} • ETB ${execution['amount']}'),
                          trailing: Text(
                            _formatDate(executionDate),
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to load upcoming executions: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }
}