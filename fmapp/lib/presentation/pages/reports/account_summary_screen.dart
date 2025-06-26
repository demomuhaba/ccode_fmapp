import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/riverpod_providers.dart' as providers;

class AccountSummaryScreen extends ConsumerStatefulWidget {
  const AccountSummaryScreen({super.key});

  @override
  ConsumerState<AccountSummaryScreen> createState() => _AccountSummaryScreenState();
}

class _AccountSummaryScreenState extends ConsumerState<AccountSummaryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Summary'),
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final accountState = ref.watch(providers.financialAccountNotifierProvider);
          final simCardState = ref.watch(providers.simCardNotifierProvider);
          final transactionState = ref.watch(providers.transactionNotifierProvider);
          
          if (accountState.error != null) {
            return _buildErrorState(accountState.error!);
          }
          
          if (accountState.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (accountState.accounts.isEmpty) {
            return _buildEmptyState();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOverallSummary(accountState),
                const SizedBox(height: 24),
                _buildAccountsByType(accountState, simCardState),
                const SizedBox(height: 24),
                _buildAccountsList(accountState, simCardState, transactionState),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_outlined,
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
            'Add your financial accounts to view the summary',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
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
            'Error: $error',
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.read(providers.financialAccountNotifierProvider.notifier).clearError();
              // Reload data
              final authState = ref.read(providers.authNotifierProvider);
              final userId = authState.userProfile?.userId;
              if (userId != null) {
                ref.read(providers.financialAccountNotifierProvider.notifier).loadAccounts(userId);
              }
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallSummary(dynamic accountState) {
    final totalBalance = ref.read(providers.financialAccountNotifierProvider.notifier).getTotalBalance();
    final positiveAccounts = accountState.accounts.where((acc) => acc.currentBalance > 0).length;
    final negativeAccounts = accountState.accounts.where((acc) => acc.currentBalance < 0).length;
    final zeroAccounts = accountState.accounts.where((acc) => acc.currentBalance == 0).length;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overall Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: totalBalance >= 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: totalBalance >= 0 ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    color: totalBalance >= 0 ? Colors.green : Colors.red,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Balance',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
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
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryMetric(
                    'Total Accounts',
                    accountState.accounts.length.toString(),
                    Icons.account_balance,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryMetric(
                    'Positive',
                    positiveAccounts.toString(),
                    Icons.trending_up,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryMetric(
                    'Negative',
                    negativeAccounts.toString(),
                    Icons.trending_down,
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryMetric(
                    'Zero',
                    zeroAccounts.toString(),
                    Icons.horizontal_rule,
                    Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryMetric(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountsByType(dynamic accountState, dynamic simCardState) {
    final typeBreakdown = <String, List<dynamic>>{};
    
    for (final account in accountState.accounts) {
      if (!typeBreakdown.containsKey(account.accountType)) {
        typeBreakdown[account.accountType] = [];
      }
      typeBreakdown[account.accountType]!.add(account);
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Accounts by Type',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...typeBreakdown.entries.map((entry) {
              final totalBalance = entry.value.fold(0.0, (sum, acc) => sum + acc.currentBalance);
              final count = entry.value.length;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getAccountTypeColor(entry.key).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getAccountTypeIcon(entry.key),
                        color: _getAccountTypeColor(entry.key),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '$count account${count != 1 ? 's' : ''}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'ETB ${totalBalance.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: totalBalance >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountsList(
    dynamic accountState,
    dynamic simCardState,
    dynamic transactionState,
  ) {
    final sortedAccounts = List.from(accountState.accounts)
      ..sort((a, b) => b.currentBalance.compareTo(a.currentBalance));
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'All Accounts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...sortedAccounts.map((account) {
              final simCard = simCardState.simCards.where((sim) => sim.id == account.linkedSimId).isNotEmpty
                  ? simCardState.simCards.firstWhere((sim) => sim.id == account.linkedSimId)
                  : null;
              final recentTransactionCount = transactionState.transactions
                  .where((t) => t.affectedAccountId == account.id)
                  .length;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _getAccountTypeColor(account.accountType).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getAccountTypeIcon(account.accountType),
                            color: _getAccountTypeColor(account.accountType),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                account.accountName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${account.accountType} • ${simCard?.simNickname ?? 'Unknown SIM'}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'ETB ${account.currentBalance.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: account.currentBalance >= 0 ? Colors.green : Colors.red,
                              ),
                            ),
                            if (account.currentBalance >= 0)
                              Icon(
                                Icons.trending_up,
                                color: Colors.green,
                                size: 16,
                              )
                            else
                              Icon(
                                Icons.trending_down,
                                color: Colors.red,
                                size: 16,
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildAccountStat(
                          'Account ID',
                          account.accountIdentifier ?? 'N/A',
                          Icons.numbers,
                        ),
                        const SizedBox(width: 16),
                        _buildAccountStat(
                          'Transactions',
                          recentTransactionCount.toString(),
                          Icons.receipt,
                        ),
                        const SizedBox(width: 16),
                        _buildAccountStat(
                          'Status',
                          account.currentBalance >= 0 ? 'Positive' : 'Negative',
                          account.currentBalance >= 0 ? Icons.check_circle : Icons.warning,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountStat(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.grey.shade600, size: 16),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getAccountTypeColor(String accountType) {
    switch (accountType.toLowerCase()) {
      case 'mobile money':
        return Colors.green;
      case 'bank account':
        return Colors.blue;
      case 'digital wallet':
        return Colors.purple;
      case 'telecom account':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getAccountTypeIcon(String accountType) {
    switch (accountType.toLowerCase()) {
      case 'mobile money':
        return Icons.phone_android;
      case 'bank account':
        return Icons.account_balance;
      case 'digital wallet':
        return Icons.wallet;
      case 'telecom account':
        return Icons.cell_tower;
      default:
        return Icons.account_balance_wallet;
    }
  }
}