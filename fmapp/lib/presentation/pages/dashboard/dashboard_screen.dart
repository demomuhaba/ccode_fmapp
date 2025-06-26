import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/riverpod_providers.dart' as providers;
import '../sim_cards/sim_card_list_screen.dart';
import '../accounts/account_list_screen.dart';
import '../transactions/transaction_list_screen.dart';
import '../friends/friend_list_screen.dart';
import '../loans/loan_debt_list_screen.dart';
import '../auth/login_screen.dart';
import '../reports/reports_screen.dart';
import '../recurring_transactions/recurring_transaction_list_screen.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/recent_transactions_widget.dart';
import '../../widgets/sim_balance_widget.dart';
import '../../widgets/loan_debt_summary_widget.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final authState = ref.read(providers.authNotifierProvider);
    final userId = authState.userProfile?.userId;
    
    if (userId != null) {
      await Future.wait([
        ref.read(providers.simCardNotifierProvider.notifier).loadSimCards(userId),
        ref.read(providers.financialAccountNotifierProvider.notifier).loadAccounts(userId),
        ref.read(providers.transactionNotifierProvider.notifier).loadRecentTransactions(userId, limit: 5),
        ref.read(providers.loanDebtNotifierProvider.notifier).loadLoanDebts(userId),
        ref.read(providers.recurringTransactionNotifierProvider.notifier).loadRecurringTransactions(userId),
      ]);
    }
  }

  Future<void> _handleRefresh() async {
    await _loadDashboardData();
  }

  void _handleSignOut() async {
    await ref.read(providers.authNotifierProvider.notifier).signOut();
    
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _handleRefresh,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _handleSignOut();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Sign Out'),
                ),
              ),
            ],
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
              _buildWelcomeSection(),
              const SizedBox(height: 24),
              _buildQuickActions(),
              const SizedBox(height: 24),
              const SimBalanceWidget(),
              const SizedBox(height: 24),
              const LoanDebtSummaryWidget(),
              const SizedBox(height: 24),
              const RecentTransactionsWidget(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Consumer(
      builder: (context, ref, child) {
        final authState = ref.watch(providers.authNotifierProvider);
        final userProfile = authState.userProfile;
        final firstName = userProfile?.fullName?.split(' ').first ?? 'User';
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    firstName[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back, $firstName!',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Manage your finances across all your accounts',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
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
              title: 'SIM Cards',
              icon: Icons.sim_card,
              color: Colors.blue,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SimCardListScreen()),
              ),
            ),
            DashboardCard(
              title: 'Accounts',
              icon: Icons.account_balance,
              color: Colors.green,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AccountListScreen()),
              ),
            ),
            DashboardCard(
              title: 'Transactions',
              icon: Icons.receipt_long,
              color: Colors.orange,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const TransactionListScreen()),
              ),
            ),
            DashboardCard(
              title: 'Friends',
              icon: Icons.people,
              color: Colors.purple,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const FriendListScreen()),
              ),
            ),
            DashboardCard(
              title: 'Loans & Debts',
              icon: Icons.handshake,
              color: Colors.red,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const LoanDebtListScreen()),
              ),
            ),
            DashboardCard(
              title: 'Reports',
              icon: Icons.analytics,
              color: Colors.teal,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ReportsScreen()),
              ),
            ),
            DashboardCard(
              title: 'Recurring',
              icon: Icons.repeat,
              color: Colors.indigo,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const RecurringTransactionListScreen()),
              ),
            ),
          ],
        ),
      ],
    );
  }
}