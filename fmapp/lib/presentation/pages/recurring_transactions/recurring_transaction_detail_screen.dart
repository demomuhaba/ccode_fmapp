import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/recurring_transaction.dart';
import '../../providers/riverpod_providers.dart';
import 'edit_recurring_transaction_screen.dart';

class RecurringTransactionDetailScreen extends ConsumerStatefulWidget {
  final RecurringTransaction recurringTransaction;

  const RecurringTransactionDetailScreen({
    super.key,
    required this.recurringTransaction,
  });

  @override
  ConsumerState<RecurringTransactionDetailScreen> createState() => _RecurringTransactionDetailScreenState();
}

class _RecurringTransactionDetailScreenState extends ConsumerState<RecurringTransactionDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final recurringTransactionState = ref.watch(recurringTransactionNotifierProvider);
    
    // Find the updated transaction from state, fallback to widget parameter
    final transaction = recurringTransactionState.recurringTransactions
        .where((rt) => rt.id == widget.recurringTransaction.id)
        .firstOrNull ?? widget.recurringTransaction;

    return Scaffold(
      appBar: AppBar(
        title: Text(transaction.templateName),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(value, transaction),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(
                value: transaction.isActive ? 'pause' : 'resume',
                child: Text(transaction.isActive ? 'Pause' : 'Resume'),
              ),
              if (transaction.shouldExecute())
                const PopupMenuItem(value: 'execute', child: Text('Execute Now')),
              const PopupMenuItem(value: 'preview', child: Text('Preview Next Executions')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(transaction),
            const SizedBox(height: 16),
            _buildDetailsCard(transaction),
            const SizedBox(height: 16),
            _buildScheduleCard(transaction),
            const SizedBox(height: 16),
            _buildExecutionHistoryCard(transaction),
            const SizedBox(height: 16),
            _buildPreviewCard(transaction),
          ],
        ),
      ),
      floatingActionButton: transaction.shouldExecute()
          ? FloatingActionButton.extended(
              onPressed: () => _executeTransaction(transaction),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Execute Now'),
            )
          : null,
    );
  }

  Widget _buildStatusCard(RecurringTransaction transaction) {
    final isDue = transaction.shouldExecute();
    final isOverdue = transaction.nextExecution != null && 
                      transaction.nextExecution!.isBefore(DateTime.now());

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.templateName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
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
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${transaction.amount.toStringAsFixed(2)} ${transaction.currency}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: transaction.transactionType.toLowerCase().contains('income')
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(transaction),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(transaction),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (isDue) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isOverdue ? Colors.red[50] : Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isOverdue ? Colors.red[300]! : Colors.orange[300]!,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isOverdue ? Icons.warning : Icons.schedule,
                      color: isOverdue ? Colors.red[700] : Colors.orange[700],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isOverdue 
                          ? 'This transaction is overdue!'
                          : 'This transaction is due for execution',
                      style: TextStyle(
                        color: isOverdue ? Colors.red[700] : Colors.orange[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(RecurringTransaction transaction) {
    final accountState = ref.watch(financialAccountNotifierProvider);
    final account = accountState.accounts
        .where((acc) => acc.id == transaction.affectedAccountId)
        .firstOrNull;
    final counterpartyAccount = transaction.counterpartyAccountId != null
        ? accountState.accounts
            .where((acc) => acc.id == transaction.counterpartyAccountId)
            .firstOrNull
        : null;

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
            _buildDetailRow('Type', transaction.transactionType),
            _buildDetailRow('Amount', '${transaction.amount.toStringAsFixed(2)} ${transaction.currency}'),
            _buildDetailRow('Account', account?.accountName ?? 'Unknown Account'),
            if (transaction.isInternalTransfer && counterpartyAccount != null)
              _buildDetailRow('Destination', counterpartyAccount.accountName),
            if (transaction.descriptionNotes?.isNotEmpty == true)
              _buildDetailRow('Description', transaction.descriptionNotes!),
            if (transaction.payerSenderRaw?.isNotEmpty == true)
              _buildDetailRow('Payer/Sender', transaction.payerSenderRaw!),
            if (transaction.payeeReceiverRaw?.isNotEmpty == true)
              _buildDetailRow('Payee/Receiver', transaction.payeeReceiverRaw!),
            if (transaction.referenceNumber?.isNotEmpty == true)
              _buildDetailRow('Reference', transaction.referenceNumber!),
            if (transaction.tags?.isNotEmpty == true)
              _buildDetailRow('Tags', transaction.tags!.join(', ')),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleCard(RecurringTransaction transaction) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Schedule Information',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Frequency', transaction.frequencyDisplayName),
            _buildDetailRow('Interval', 'Every ${transaction.interval} ${transaction.frequency}'),
            _buildDetailRow('Start Date', _formatDate(transaction.startDate)),
            if (transaction.endDate != null)
              _buildDetailRow('End Date', _formatDate(transaction.endDate!)),
            if (transaction.maxExecutions != null)
              _buildDetailRow('Max Executions', transaction.maxExecutions.toString()),
            if (transaction.dayOfMonth != null)
              _buildDetailRow('Day of Month', transaction.dayOfMonth.toString()),
            if (transaction.dayOfWeek != null)
              _buildDetailRow('Day of Week', _getWeekDayName(transaction.dayOfWeek!)),
            _buildDetailRow('Active', transaction.isActive ? 'Yes' : 'No'),
            if (transaction.hasEnded())
              _buildDetailRow('Status', 'Ended', valueColor: Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildExecutionHistoryCard(RecurringTransaction transaction) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Execution History',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Total Executions', transaction.executionCount.toString()),
            if (transaction.lastExecuted != null)
              _buildDetailRow('Last Executed', _formatDateTime(transaction.lastExecuted!)),
            if (transaction.nextExecution != null)
              _buildDetailRow(
                'Next Execution', 
                _formatDateTime(transaction.nextExecution!),
                valueColor: transaction.shouldExecute() ? Colors.orange : null,
              ),
            _buildDetailRow(
              'Total Amount Processed', 
              '${(transaction.amount * transaction.executionCount).toStringAsFixed(2)} ${transaction.currency}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard(RecurringTransaction transaction) {
    if (transaction.hasEnded()) return const SizedBox.shrink();

    final notifier = ref.read(recurringTransactionNotifierProvider.notifier);
    final nextExecutions = notifier.previewNextExecutions(transaction.id, 5);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Upcoming Executions',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _showFullPreview(transaction),
                  child: const Text('View More'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (nextExecutions.isEmpty)
              const Text('No upcoming executions scheduled')
            else
              ...nextExecutions.take(3).map((date) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(_formatDateTime(date)),
                    const Spacer(),
                    Text(
                      '${transaction.amount.toStringAsFixed(2)} ${transaction.currency}',
                      style: TextStyle(
                        color: transaction.transactionType.toLowerCase().contains('income')
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
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

  String _getWeekDayName(int dayOfWeek) {
    const weekDays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    return weekDays[dayOfWeek - 1];
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
        _executeTransaction(transaction);
        break;
      case 'preview':
        _showFullPreview(transaction);
        break;
      case 'delete':
        _showDeleteDialog(transaction);
        break;
    }
  }

  Future<void> _executeTransaction(RecurringTransaction transaction) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Execute Transaction'),
        content: Text(
          'Are you sure you want to execute "${transaction.templateName}" now?\n\n'
          'Amount: ${transaction.amount.toStringAsFixed(2)} ${transaction.currency}'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Execute'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ref.read(recurringTransactionNotifierProvider.notifier)
          .executeRecurringTransaction(transaction.id);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction executed successfully')),
        );
      } else if (mounted) {
        final error = ref.read(recurringTransactionNotifierProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to execute transaction: ${error ?? 'Unknown error'}')),
        );
      }
    }
  }

  void _showFullPreview(RecurringTransaction transaction) {
    final notifier = ref.read(recurringTransactionNotifierProvider.notifier);
    final nextExecutions = notifier.previewNextExecutions(transaction.id, 20);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Upcoming Executions - ${transaction.templateName}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: nextExecutions.isEmpty
              ? const Center(child: Text('No upcoming executions scheduled'))
              : ListView.builder(
                  itemCount: nextExecutions.length,
                  itemBuilder: (context, index) {
                    final date = nextExecutions[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue[100],
                        child: Text('${index + 1}'),
                      ),
                      title: Text(_formatDateTime(date)),
                      trailing: Text(
                        '${transaction.amount.toStringAsFixed(2)} ${transaction.currency}',
                        style: TextStyle(
                          color: transaction.transactionType.toLowerCase().contains('income')
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(RecurringTransaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recurring Transaction'),
        content: Text(
          'Are you sure you want to delete "${transaction.templateName}"?\n\n'
          'This action cannot be undone. All execution history will be preserved, '
          'but no future executions will occur.'
        ),
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
                Navigator.pop(context); // Go back to list
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}