import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../providers/riverpod_providers.dart' as providers;
import '../../../services/report_export_service.dart';

class TransactionAnalyticsScreen extends ConsumerStatefulWidget {
  const TransactionAnalyticsScreen({super.key});

  @override
  ConsumerState<TransactionAnalyticsScreen> createState() => _TransactionAnalyticsScreenState();
}

class _TransactionAnalyticsScreenState extends ConsumerState<TransactionAnalyticsScreen> {
  String _selectedPeriod = 'This Month';
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Analytics'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.date_range),
            onSelected: (value) {
              setState(() {
                _selectedPeriod = value;
              });
            },
            itemBuilder: (context) => [
              'This Week',
              'This Month',
              'Last 3 Months',
              'This Year',
            ].map((period) {
              return PopupMenuItem(
                value: period,
                child: Row(
                  children: [
                    if (_selectedPeriod == period) 
                      const Icon(Icons.check, size: 16)
                    else 
                      const SizedBox(width: 16),
                    const SizedBox(width: 8),
                    Text(period),
                  ],
                ),
              );
            }).toList(),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.download),
            tooltip: 'Export Report',
            onSelected: (value) => _handleExport(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'csv',
                child: Row(
                  children: [
                    Icon(Icons.table_chart, size: 20),
                    SizedBox(width: 8),
                    Text('Export to CSV'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, size: 20),
                    SizedBox(width: 8),
                    Text('Export to PDF'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final transactionState = ref.watch(providers.transactionNotifierProvider);
          final accountState = ref.watch(providers.financialAccountNotifierProvider);
          
          if (transactionState.error != null) {
            return _buildErrorState(transactionState.error!);
          }
          
          if (transactionState.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final transactions = _getFilteredTransactions(transactionState.transactions);
          
          if (transactions.isEmpty) {
            return _buildEmptyState();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPeriodSummary(transactions),
                const SizedBox(height: 24),
                _buildTransactionTypeBreakdown(transactions),
                const SizedBox(height: 24),
                _buildAccountBreakdown(transactions, accountState),
                const SizedBox(height: 24),
                _buildTrendAnalysis(transactions),
                const SizedBox(height: 24),
                _buildTopTransactions(transactions),
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
            Icons.analytics_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          const Text(
            'No Transaction Data',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No transactions found for $_selectedPeriod',
            style: const TextStyle(
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
              ref.read(providers.transactionNotifierProvider.notifier).clearError();
              // Reload data
              final authState = ref.read(providers.authNotifierProvider);
              final userId = authState.userProfile?.userId;
              if (userId != null) {
                ref.read(providers.transactionNotifierProvider.notifier).loadTransactions(userId);
              }
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSummary(List<dynamic> transactions) {
    final income = transactions.where((t) => 
      t.transactionType.toLowerCase().contains('income') ||
      t.transactionType.toLowerCase().contains('credit')
    ).fold(0.0, (sum, t) => sum + t.amount);
    
    final expenses = transactions.where((t) => 
      t.transactionType.toLowerCase().contains('expense') ||
      t.transactionType.toLowerCase().contains('debit')
    ).fold(0.0, (sum, t) => sum + t.amount);
    
    final netFlow = income - expenses;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$_selectedPeriod Summary',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Total Income',
                    'ETB ${income.toStringAsFixed(2)}',
                    Colors.green,
                    Icons.trending_up,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryItem(
                    'Total Expenses',
                    'ETB ${expenses.toStringAsFixed(2)}',
                    Colors.red,
                    Icons.trending_down,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSummaryItem(
              'Net Cash Flow',
              '${netFlow >= 0 ? '+' : '-'}ETB ${netFlow.abs().toStringAsFixed(2)}',
              netFlow >= 0 ? Colors.green : Colors.red,
              netFlow >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
            ),
            const SizedBox(height: 16),
            Text(
              'Total Transactions: ${transactions.length}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTypeBreakdown(List<dynamic> transactions) {
    final typeBreakdown = <String, double>{};
    
    for (final transaction in transactions) {
      final type = transaction.transactionType;
      typeBreakdown[type] = (typeBreakdown[type] ?? 0) + transaction.amount;
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Transaction Types',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...typeBreakdown.entries.map((entry) {
              final percentage = (entry.value / transactions.fold(0.0, (sum, t) => sum + t.amount)) * 100;
              return _buildBreakdownItem(
                entry.key,
                'ETB ${entry.value.toStringAsFixed(2)}',
                percentage,
                _getTypeColor(entry.key),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountBreakdown(List<dynamic> transactions, dynamic accountState) {
    final accountBreakdown = <String, double>{};
    
    for (final transaction in transactions) {
      final accountId = transaction.affectedAccountId;
      final account = accountState.accounts.where((acc) => acc.id == accountId).isNotEmpty 
          ? accountState.accounts.firstWhere((acc) => acc.id == accountId)
          : null;
      final accountName = account?.accountName ?? 'Unknown Account';
      accountBreakdown[accountName] = (accountBreakdown[accountName] ?? 0) + transaction.amount;
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Activity by Account',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...accountBreakdown.entries.map((entry) {
              final percentage = (entry.value / transactions.fold(0.0, (sum, t) => sum + t.amount)) * 100;
              return _buildBreakdownItem(
                entry.key,
                'ETB ${entry.value.toStringAsFixed(2)}',
                percentage,
                Colors.blue,
              );
            }),
          ],
        ),
      ),
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

  Widget _buildTrendAnalysis(List<dynamic> transactions) {
    final dailyTotals = <String, double>{};
    
    for (final transaction in transactions) {
      final dateKey = '${transaction.transactionDate.day}/${transaction.transactionDate.month}';
      dailyTotals[dateKey] = (dailyTotals[dateKey] ?? 0) + transaction.amount;
    }
    
    final sortedDates = dailyTotals.keys.toList()..sort();
    final averageDaily = dailyTotals.values.fold(0.0, (sum, val) => sum + val) / dailyTotals.length;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Spending Trends',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTrendItem(
                    'Daily Average',
                    'ETB ${averageDaily.toStringAsFixed(2)}',
                    Icons.trending_neutral,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTrendItem(
                    'Most Active Day',
                    sortedDates.isNotEmpty ? sortedDates.last : 'N/A',
                    Icons.calendar_today,
                    Colors.green,
                  ),
                ),
              ],
            ),
            if (sortedDates.length >= 2) ...[
              const SizedBox(height: 16),
              _buildSimpleTrendChart(dailyTotals, sortedDates.take(7).toList()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTrendItem(String label, String value, IconData icon, Color color) {
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
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleTrendChart(Map<String, double> dailyTotals, List<String> dates) {
    final maxValue = dailyTotals.values.reduce((a, b) => a > b ? a : b);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: dates.map((date) {
              final value = dailyTotals[date] ?? 0;
              final height = maxValue > 0 ? (value / maxValue) * 80 : 0.0;
              
              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 20,
                    height: height.clamp(5.0, 80.0),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
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
      ],
    );
  }

  Widget _buildTopTransactions(List<dynamic> transactions) {
    final sortedTransactions = List.from(transactions)
      ..sort((a, b) => b.amount.compareTo(a.amount));
    
    final topTransactions = sortedTransactions.take(5).toList();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Transactions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...topTransactions.asMap().entries.map((entry) {
              final index = entry.key;
              final transaction = entry.value;
              final isIncome = transaction.transactionType.toLowerCase().contains('income') ||
                              transaction.transactionType.toLowerCase().contains('credit');
              
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontSize: 12,
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
                            transaction.descriptionNotes,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${transaction.transactionDate.day}/${transaction.transactionDate.month}/${transaction.transactionDate.year}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'ETB ${transaction.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isIncome ? Colors.green : Colors.red,
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

  List<dynamic> _getFilteredTransactions(List<dynamic> transactions) {
    final now = DateTime.now();
    DateTime startDate;
    
    switch (_selectedPeriod) {
      case 'This Week':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        break;
      case 'This Month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'Last 3 Months':
        startDate = DateTime(now.year, now.month - 3, 1);
        break;
      case 'This Year':
        startDate = DateTime(now.year, 1, 1);
        break;
      default:
        startDate = DateTime(now.year, now.month, 1);
    }
    
    return transactions.where((transaction) {
      return transaction.transactionDate.isAfter(startDate) ||
             transaction.transactionDate.isAtSameMomentAs(startDate);
    }).toList();
  }

  Color _getTypeColor(String type) {
    if (type.toLowerCase().contains('income') || type.toLowerCase().contains('credit')) {
      return Colors.green;
    } else if (type.toLowerCase().contains('expense') || type.toLowerCase().contains('debit')) {
      return Colors.red;
    } else {
      return Colors.blue;
    }
  }

  Future<void> _handleExport(String type) async {
    try {
      // Show loading indicator
      if (!mounted) return;
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Exporting report...'),
            ],
          ),
        ),
      );

      final transactionState = ref.read(providers.transactionNotifierProvider);
      final accountState = ref.read(providers.financialAccountNotifierProvider);
      final authState = ref.read(providers.authNotifierProvider);
      
      final transactions = _getFilteredTransactions(transactionState.transactions);
      final reportService = ReportExportService();
      
      if (type == 'csv') {
        // Export to CSV
        final file = await reportService.exportTransactionsToCSV(
          transactions: transactions.cast(),
          accounts: accountState.accounts,
          title: 'Transaction Analytics $_selectedPeriod',
        );
        
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          
          // Show success dialog with share option
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Export Successful'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Report exported successfully as CSV file.'),
                  const SizedBox(height: 8),
                  Text(
                    'File saved to: ${file.path}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await reportService.shareFile(
                      file,
                      subject: 'fmapp Transaction Analytics Report - $_selectedPeriod',
                    );
                  },
                  icon: const Icon(Icons.share, size: 16),
                  label: const Text('Share'),
                ),
              ],
            ),
          );
        }
      } else if (type == 'pdf') {
        // Export to PDF
        final startDate = _getPeriodStartDate();
        final endDate = DateTime.now();
        
        final pdfData = await reportService.exportTransactionsToPDF(
          transactions: transactions.cast(),
          accounts: accountState.accounts,
          title: 'Transaction Analytics Report - $_selectedPeriod',
          startDate: startDate,
          endDate: endDate,
        );
        
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          
          // Show success dialog with share and print options
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Export Successful'),
              content: const Text('PDF report generated successfully.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
                TextButton.icon(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await reportService.printPDF(
                      pdfData,
                      jobName: 'fmapp Transaction Analytics - $_selectedPeriod',
                    );
                  },
                  icon: const Icon(Icons.print, size: 16),
                  label: const Text('Print'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    // Save PDF to temporary file for sharing
                    final directory = await getApplicationDocumentsDirectory();
                    final fileName = 'fmapp_analytics_${DateTime.now().millisecondsSinceEpoch}.pdf';
                    final file = File('${directory.path}/$fileName');
                    await file.writeAsBytes(pdfData);
                    
                    await reportService.shareFile(
                      file,
                      subject: 'fmapp Transaction Analytics Report - $_selectedPeriod',
                    );
                  },
                  icon: const Icon(Icons.share, size: 16),
                  label: const Text('Share'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Export Failed'),
            content: Text('Failed to export report: ${e.toString()}'),
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

  DateTime _getPeriodStartDate() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'This Week':
        return now.subtract(Duration(days: now.weekday - 1));
      case 'This Month':
        return DateTime(now.year, now.month, 1);
      case 'Last 3 Months':
        return DateTime(now.year, now.month - 3, 1);
      case 'This Year':
        return DateTime(now.year, 1, 1);
      default:
        return DateTime(now.year, now.month, 1);
    }
  }
}