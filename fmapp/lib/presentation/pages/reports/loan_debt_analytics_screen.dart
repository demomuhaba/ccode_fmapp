import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/riverpod_providers.dart' as providers;

class LoanDebtAnalyticsScreen extends ConsumerStatefulWidget {
  const LoanDebtAnalyticsScreen({super.key});

  @override
  ConsumerState<LoanDebtAnalyticsScreen> createState() => _LoanDebtAnalyticsScreenState();
}

class _LoanDebtAnalyticsScreenState extends ConsumerState<LoanDebtAnalyticsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loan & Debt Analytics'),
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final loanDebtState = ref.watch(providers.loanDebtNotifierProvider);
          final friendState = ref.watch(providers.friendNotifierProvider);
          
          if (loanDebtState.error != null) {
            return _buildErrorState(loanDebtState.error!);
          }
          
          if (loanDebtState.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (loanDebtState.loanDebts.isEmpty) {
            return _buildEmptyState();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOverallSummary(loanDebtState),
                const SizedBox(height: 24),
                _buildStatusBreakdown(loanDebtState),
                const SizedBox(height: 24),
                _buildFriendAnalysis(loanDebtState, friendState),
                const SizedBox(height: 24),
                _buildOverdueAnalysis(loanDebtState, friendState),
                const SizedBox(height: 24),
                _buildTrendAnalysis(loanDebtState),
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
            Icons.handshake_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          const Text(
            'No Loan/Debt Data',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start tracking loans and debts to see analytics',
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
              ref.read(providers.loanDebtNotifierProvider.notifier).clearError();
              // Reload data
              final authState = ref.read(providers.authNotifierProvider);
              final userId = authState.userProfile?.userId;
              if (userId != null) {
                ref.read(providers.loanDebtNotifierProvider.notifier).loadLoanDebts(userId);
              }
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallSummary(dynamic loanDebtState) {
    final loanDebtNotifier = ref.read(providers.loanDebtNotifierProvider.notifier);
    final totalLoansGiven = loanDebtNotifier.getTotalLoansGiven();
    final totalDebtsOwed = loanDebtNotifier.getTotalDebtsOwed();
    final netPosition = loanDebtNotifier.getNetPosition();
    final totalItems = loanDebtState.loanDebts.length;
    final activeItems = loanDebtState.loanDebts.where((item) => 
        item.status.toLowerCase() == 'active' || 
        item.status.toLowerCase() == 'partiallypaid').length;
    final overdueItems = loanDebtState.loanDebts.where((item) => 
        item.dueDate != null && 
        DateTime.now().isAfter(item.dueDate) && 
        item.status.toLowerCase() != 'paidoff').length;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Financial Position',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (netPosition >= 0 ? Colors.green : Colors.red).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: (netPosition >= 0 ? Colors.green : Colors.red).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    netPosition >= 0 ? Icons.trending_up : Icons.trending_down,
                    color: netPosition >= 0 ? Colors.green : Colors.red,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          netPosition >= 0 ? 'Net Positive' : 'Net Negative',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'ETB ${netPosition.abs().toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: netPosition >= 0 ? Colors.green : Colors.red,
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
                  child: _buildSummaryCard(
                    'Loans Given',
                    'ETB ${totalLoansGiven.toStringAsFixed(2)}',
                    Icons.call_made,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Debts Owed',
                    'ETB ${totalDebtsOwed.toStringAsFixed(2)}',
                    Icons.call_received,
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Total Items',
                    totalItems.toString(),
                    Icons.format_list_numbered,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Active',
                    activeItems.toString(),
                    Icons.access_time,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Overdue',
                    overdueItems.toString(),
                    Icons.warning,
                    Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
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

  Widget _buildStatusBreakdown(dynamic loanDebtState) {
    final statusBreakdown = <String, int>{};
    
    for (final item in loanDebtState.loanDebts) {
      statusBreakdown[item.status] = (statusBreakdown[item.status] ?? 0) + 1;
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status Breakdown',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...statusBreakdown.entries.map((entry) {
              final percentage = (entry.value / loanDebtState.loanDebts.length) * 100;
              return _buildBreakdownItem(
                entry.key,
                '${entry.value} item${entry.value != 1 ? 's' : ''}',
                percentage,
                _getStatusColor(entry.key),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendAnalysis(dynamic loanDebtState, dynamic friendState) {
    final friendBreakdown = <String, Map<String, dynamic>>{};
    
    for (final item in loanDebtState.loanDebts) {
      final friend = friendState.friends.where((f) => f.id == item.associatedFriendId).isNotEmpty
          ? friendState.friends.firstWhere((f) => f.id == item.associatedFriendId)
          : null;
      final friendName = friend?.friendName ?? 'Unknown Friend';
      
      if (!friendBreakdown.containsKey(friendName)) {
        friendBreakdown[friendName] = {
          'totalAmount': 0.0,
          'outstandingAmount': 0.0,
          'count': 0,
        };
      }
      
      friendBreakdown[friendName]!['totalAmount'] += item.initialAmount;
      friendBreakdown[friendName]!['outstandingAmount'] += item.outstandingAmount;
      friendBreakdown[friendName]!['count'] += 1;
    }
    
    final sortedFriends = friendBreakdown.entries.toList()
      ..sort((a, b) => (b.value['outstandingAmount'] as double).compareTo(a.value['outstandingAmount'] as double));
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Friends by Outstanding Amount',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...sortedFriends.take(5).map((entry) {
              final outstandingAmount = entry.value['outstandingAmount'] as double;
              final count = entry.value['count'] as int;
              
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
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      child: Text(
                        entry.key[0].toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
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
                            '$count item${count != 1 ? 's' : ''}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'ETB ${outstandingAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: outstandingAmount > 0 ? Colors.red : Colors.green,
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

  Widget _buildOverdueAnalysis(dynamic loanDebtState, dynamic friendState) {
    final overdueItems = loanDebtState.loanDebts.where((item) => 
        item.dueDate != null && 
        DateTime.now().isAfter(item.dueDate) && 
        item.status.toLowerCase() != 'paidoff').toList();
    
    if (overdueItems.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                Icons.check_circle,
                size: 48,
                color: Colors.green,
              ),
              const SizedBox(height: 8),
              const Text(
                'No Overdue Items',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Great job staying on top of your commitments!',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.red),
                const SizedBox(width: 8),
                const Text(
                  'Overdue Items',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...overdueItems.map((item) {
              final friend = friendState.friends.where((f) => f.id == item.associatedFriendId).isNotEmpty
                  ? friendState.friends.firstWhere((f) => f.id == item.associatedFriendId)
                  : null;
              final daysOverdue = DateTime.now().difference(item.dueDate!).inDays;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      item.type.toLowerCase() == 'loangiventofriend' ? Icons.call_made : Icons.call_received,
                      color: Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            friend?.friendName ?? 'Unknown Friend',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '$daysOverdue day${daysOverdue != 1 ? 's' : ''} overdue',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'ETB ${item.outstandingAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade700,
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

  Widget _buildTrendAnalysis(dynamic loanDebtState) {
    final monthlyData = <String, Map<String, double>>{};
    
    for (final item in loanDebtState.loanDebts) {
      final monthKey = '${item.dateInitiated.month}/${item.dateInitiated.year}';
      
      if (!monthlyData.containsKey(monthKey)) {
        monthlyData[monthKey] = {'loans': 0.0, 'debts': 0.0};
      }
      
      if (item.type.toLowerCase() == 'loangiventofriend') {
        monthlyData[monthKey]!['loans'] = monthlyData[monthKey]!['loans']! + item.initialAmount;
      } else {
        monthlyData[monthKey]!['debts'] = monthlyData[monthKey]!['debts']! + item.initialAmount;
      }
    }
    
    final sortedMonths = monthlyData.keys.toList()..sort();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Trends',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (sortedMonths.isNotEmpty) ...[
              SizedBox(
                height: 200,
                child: _buildSimpleTrendChart(monthlyData, sortedMonths.take(6).toList()),
              ),
            ] else ...[
              Center(
                child: Text(
                  'Not enough data for trend analysis',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleTrendChart(Map<String, Map<String, double>> monthlyData, List<String> months) {
    final maxValue = monthlyData.values
        .map((data) => data['loans']! + data['debts']!)
        .reduce((a, b) => a > b ? a : b);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Loan/Debt Activity by Month',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: months.map((month) {
              final data = monthlyData[month]!;
              final loansHeight = maxValue > 0 ? (data['loans']! / maxValue) * 120 : 0.0;
              final debtsHeight = maxValue > 0 ? (data['debts']! / maxValue) * 120 : 0.0;
              
              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (debtsHeight > 0)
                    Container(
                      width: 20,
                      height: debtsHeight.clamp(5.0, 120.0),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ),
                  if (loansHeight > 0)
                    Container(
                      width: 20,
                      height: loansHeight.clamp(5.0, 120.0),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: debtsHeight > 0 
                            ? BorderRadius.zero 
                            : const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    month,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem('Loans Given', Colors.green),
            const SizedBox(width: 16),
            _buildLegendItem('Debts Owed', Colors.red),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildBreakdownItem(String label, String value, double percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.orange;
      case 'paidoff':
        return Colors.green;
      case 'partiallypaid':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}