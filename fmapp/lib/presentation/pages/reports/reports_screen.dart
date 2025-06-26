import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/riverpod_providers.dart' as providers;
import '../../widgets/dashboard_card.dart';
import 'transaction_analytics_screen.dart';
import 'account_summary_screen.dart';
import 'loan_debt_analytics_screen.dart';
import 'export_screen.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    final authState = ref.read(providers.authNotifierProvider);
    final userId = authState.userProfile?.userId;
    
    if (userId != null) {
      final transactionNotifier = ref.read(providers.transactionNotifierProvider.notifier);
      final accountNotifier = ref.read(providers.financialAccountNotifierProvider.notifier);
      final loanDebtNotifier = ref.read(providers.loanDebtNotifierProvider.notifier);

      await Future.wait([
        transactionNotifier.loadTransactions(userId),
        accountNotifier.loadAccounts(userId),
        loanDebtNotifier.loadLoanDebts(userId),
      ]);
    }
  }

  Future<void> _handleRefresh() async {
    await _loadReportData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _handleRefresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildQuickStats(),
              const SizedBox(height: 24),
              _buildReportCategories(),
              const SizedBox(height: 24),
              _buildRecentInsights(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Consumer(
      builder: (context, ref, child) {
        final transactionState = ref.watch(providers.transactionNotifierProvider);
        final accountState = ref.watch(providers.financialAccountNotifierProvider);
        final loanDebtState = ref.watch(providers.loanDebtNotifierProvider);
        final totalBalance = ref.read(providers.financialAccountNotifierProvider.notifier).getTotalBalance();
        final totalIncome = ref.read(providers.transactionNotifierProvider.notifier).getTotalIncome();
        final totalExpenses = ref.read(providers.transactionNotifierProvider.notifier).getTotalExpenses();
        final netLoanDebt = ref.read(providers.loanDebtNotifierProvider.notifier).getNetPosition();
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Financial Overview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 2.5,
                  children: [
                    _buildQuickStatItem(
                      'Total Balance',
                      'ETB ${totalBalance.toStringAsFixed(2)}',
                      totalBalance >= 0 ? Colors.green : Colors.red,
                      Icons.account_balance_wallet,
                    ),
                    _buildQuickStatItem(
                      'Monthly Income',
                      'ETB ${totalIncome.toStringAsFixed(2)}',
                      Colors.green,
                      Icons.trending_up,
                    ),
                    _buildQuickStatItem(
                      'Monthly Expenses',
                      'ETB ${totalExpenses.toStringAsFixed(2)}',
                      Colors.red,
                      Icons.trending_down,
                    ),
                    _buildQuickStatItem(
                      'Net Position',
                      'ETB ${netLoanDebt.abs().toStringAsFixed(2)}',
                      netLoanDebt >= 0 ? Colors.green : Colors.red,
                      netLoanDebt >= 0 ? Icons.thumb_up : Icons.thumb_down,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickStatItem(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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

  Widget _buildReportCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detailed Reports',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            DashboardCard(
              title: 'Transaction Analytics',
              icon: Icons.analytics,
              color: Colors.blue,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const TransactionAnalyticsScreen()),
              ),
            ),
            DashboardCard(
              title: 'Account Summary',
              icon: Icons.account_balance,
              color: Colors.green,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AccountSummaryScreen()),
              ),
            ),
            DashboardCard(
              title: 'Loan & Debt Analysis',
              icon: Icons.handshake,
              color: Colors.orange,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const LoanDebtAnalyticsScreen()),
              ),
            ),
            DashboardCard(
              title: 'Export Data',
              icon: Icons.file_download,
              color: Colors.purple,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ExportScreen()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentInsights() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Insights',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Consumer(
              builder: (context, ref, child) {
                final transactionState = ref.watch(providers.transactionNotifierProvider);
                final accountState = ref.watch(providers.financialAccountNotifierProvider);
                final loanDebtState = ref.watch(providers.loanDebtNotifierProvider);
                final insights = _generateInsights(ref);
                
                if (insights.isEmpty) {
                  return Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'No insights available yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }
                
                return Column(
                  children: insights.map((insight) => _buildInsightItem(insight)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem(Map<String, dynamic> insight) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (insight['color'] as Color).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: (insight['color'] as Color).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            insight['icon'] as IconData,
            color: insight['color'] as Color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              insight['message'] as String,
              style: TextStyle(
                color: insight['color'] as Color,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _generateInsights(WidgetRef ref) {
    final insights = <Map<String, dynamic>>[];
    
    final totalBalance = ref.read(providers.financialAccountNotifierProvider.notifier).getTotalBalance();
    final totalIncome = ref.read(providers.transactionNotifierProvider.notifier).getTotalIncome();
    final totalExpenses = ref.read(providers.transactionNotifierProvider.notifier).getTotalExpenses();
    final netPosition = ref.read(providers.loanDebtNotifierProvider.notifier).getNetPosition();
    final loanDebtState = ref.read(providers.loanDebtNotifierProvider);
    final overdueCount = loanDebtState.loanDebts.where((item) => 
        item.dueDate != null && DateTime.now().isAfter(item.dueDate!) &&
        item.status.toLowerCase() != 'paidoff').length;
    
    if (totalBalance < 0) {
      insights.add({
        'message': 'Your total account balance is negative. Consider reducing expenses.',
        'icon': Icons.warning,
        'color': Colors.red,
      });
    }
    
    if (totalExpenses > totalIncome && totalIncome > 0) {
      insights.add({
        'message': 'Your expenses exceed your income this month. Review your spending.',
        'icon': Icons.trending_down,
        'color': Colors.orange,
      });
    }
    
    if (netPosition < -1000) {
      insights.add({
        'message': 'You owe more than ETB 1,000 to friends. Consider making payments.',
        'icon': Icons.handshake,
        'color': Colors.red,
      });
    }
    
    if (overdueCount > 0) {
      insights.add({
        'message': 'You have $overdueCount overdue loan/debt item${overdueCount != 1 ? 's' : ''}.',
        'icon': Icons.schedule,
        'color': Colors.red,
      });
    }
    
    if (totalBalance > 5000 && netPosition > 0) {
      insights.add({
        'message': 'Great financial position! Consider investing your excess funds.',
        'icon': Icons.trending_up,
        'color': Colors.green,
      });
    }
    
    return insights;
  }
}