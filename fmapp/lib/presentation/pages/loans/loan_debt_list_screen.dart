import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/riverpod_providers.dart' as providers;
import '../../providers/riverpod_providers.dart' show LoanDebtNotifier, FriendState;
import 'add_loan_debt_screen.dart';
import 'loan_debt_detail_screen.dart';

class LoanDebtListScreen extends ConsumerStatefulWidget {
  final String? friendId;
  final String? friendName;

  const LoanDebtListScreen({super.key, this.friendId, this.friendName});

  @override
  ConsumerState<LoanDebtListScreen> createState() => _LoanDebtListScreenState();
}

class _LoanDebtListScreenState extends ConsumerState<LoanDebtListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadLoanDebts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLoanDebts() async {
    final authState = ref.read(providers.authNotifierProvider);
    final loanDebtNotifier = ref.read(providers.loanDebtNotifierProvider.notifier);
    final friendNotifier = ref.read(providers.friendNotifierProvider.notifier);
    final userId = authState.userProfile?.userId;
    
    if (userId != null) {
      await Future.wait([
        loanDebtNotifier.loadLoanDebts(userId),
        friendNotifier.loadFriends(userId),
      ]);
    }
  }

  Future<void> _handleRefresh() async {
    await _loadLoanDebts();
  }

  void _navigateToAddLoanDebt() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddLoanDebtScreen(preselectedFriendId: widget.friendId),
      ),
    );
    
    if (result == true) {
      await _handleRefresh();
    }
  }

  void _navigateToLoanDebtDetail(String loanDebtId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LoanDebtDetailScreen(loanDebtId: loanDebtId),
      ),
    );
  }

  List<dynamic> _getFilteredLoanDebts(List<dynamic> loanDebts) {
    var filtered = loanDebts;

    // Filter by friend if specified
    if (widget.friendId != null) {
      filtered = filtered.where((item) => item.associatedFriendId == widget.friendId).toList();
    }

    // Filter by status
    switch (_filter) {
      case 'Active':
        filtered = filtered.where((item) => 
          item.status.toLowerCase() == 'active' || 
          item.status.toLowerCase() == 'partiallypaid'
        ).toList();
        break;
      case 'Completed':
        filtered = filtered.where((item) => item.status.toLowerCase() == 'paidoff').toList();
        break;
      case 'Overdue':
        final now = DateTime.now();
        filtered = filtered.where((item) => 
          item.dueDate != null && 
          now.isAfter(item.dueDate) && 
          item.status.toLowerCase() != 'paidoff'
        ).toList();
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.friendName != null 
        ? '${widget.friendName} - Loans & Debts'
        : 'Loans & Debts';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _filter = value;
              });
            },
            itemBuilder: (context) => ['All', 'Active', 'Completed', 'Overdue'].map((filter) {
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
        bottom: widget.friendId == null ? TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All', icon: Icon(Icons.list)),
            Tab(text: 'Loans Given', icon: Icon(Icons.call_made)),
            Tab(text: 'Debts Owed', icon: Icon(Icons.call_received)),
          ],
        ) : null,
      ),
      body: widget.friendId != null 
          ? _buildFriendLoanDebtList()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAllLoanDebtsList(),
                _buildLoansGivenList(),
                _buildDebtsOwedList(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddLoanDebt,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFriendLoanDebtList() {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: Consumer(
        builder: (context, ref, child) {
          final loanDebtState = ref.watch(providers.loanDebtNotifierProvider);
          final friendState = ref.watch(providers.friendNotifierProvider);
          if (loanDebtState.error != null) {
            return _buildErrorState(loanDebtState.error!, () => ref.read(providers.loanDebtNotifierProvider.notifier).clearError());
          }

          if (loanDebtState.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final filteredLoanDebts = _getFilteredLoanDebts(loanDebtState.loanDebts);

          if (filteredLoanDebts.isEmpty) {
            return _buildEmptyState('No loan/debt records found for ${widget.friendName}');
          }

          return _buildLoanDebtList(filteredLoanDebts, friendState);
        },
      ),
    );
  }

  Widget _buildAllLoanDebtsList() {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: Consumer(
        builder: (context, ref, child) {
          final loanDebtState = ref.watch(providers.loanDebtNotifierProvider);
          final friendState = ref.watch(providers.friendNotifierProvider);
          if (loanDebtState.error != null) {
            return _buildErrorState(loanDebtState.error!, () => ref.read(providers.loanDebtNotifierProvider.notifier).clearError());
          }

          if (loanDebtState.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final filteredLoanDebts = _getFilteredLoanDebts(loanDebtState.loanDebts);

          if (loanDebtState.loanDebts.isEmpty) {
            return _buildEmptyState('No loans or debts recorded yet');
          }

          if (filteredLoanDebts.isEmpty) {
            return _buildNoFilterResults();
          }

          return Column(
            children: [
              _buildSummaryCard(ref.read(providers.loanDebtNotifierProvider.notifier)),
              Expanded(child: _buildLoanDebtList(filteredLoanDebts, friendState)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoansGivenList() {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: Consumer(
        builder: (context, ref, child) {
          final loanDebtState = ref.watch(providers.loanDebtNotifierProvider);
          final loanDebtNotifier = ref.read(providers.loanDebtNotifierProvider.notifier);
          final friendState = ref.watch(providers.friendNotifierProvider);
          if (loanDebtState.error != null) {
            return _buildErrorState(loanDebtState.error!, () => loanDebtNotifier.clearError());
          }

          if (loanDebtState.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final loansGiven = loanDebtNotifier.getLoansGiven();
          final filteredLoans = _getFilteredLoanDebts(loansGiven);

          if (loansGiven.isEmpty) {
            return _buildEmptyState('No loans given yet');
          }

          if (filteredLoans.isEmpty) {
            return _buildNoFilterResults();
          }

          return _buildLoanDebtList(filteredLoans, friendState);
        },
      ),
    );
  }

  Widget _buildDebtsOwedList() {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: Consumer(
        builder: (context, ref, child) {
          final loanDebtState = ref.watch(providers.loanDebtNotifierProvider);
          final loanDebtNotifier = ref.read(providers.loanDebtNotifierProvider.notifier);
          final friendState = ref.watch(providers.friendNotifierProvider);
          if (loanDebtState.error != null) {
            return _buildErrorState(loanDebtState.error!, () => loanDebtNotifier.clearError());
          }

          if (loanDebtState.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final debtsOwed = loanDebtNotifier.getDebtsOwed();
          final filteredDebts = _getFilteredLoanDebts(debtsOwed);

          if (debtsOwed.isEmpty) {
            return _buildEmptyState('No debts owed yet');
          }

          if (filteredDebts.isEmpty) {
            return _buildNoFilterResults();
          }

          return _buildLoanDebtList(filteredDebts, friendState);
        },
      ),
    );
  }

  Widget _buildSummaryCard(LoanDebtNotifier loanDebtNotifier) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'ETB ${loanDebtNotifier.getTotalLoansGiven().toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const Text('Loans Given', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey.shade300,
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'ETB ${loanDebtNotifier.getTotalDebtsOwed().toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const Text('Debts Owed', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey.shade300,
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'ETB ${loanDebtNotifier.getNetPosition().abs().toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: loanDebtNotifier.getNetPosition() >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                    Text(
                      loanDebtNotifier.getNetPosition() >= 0 ? 'Net Positive' : 'Net Negative',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoanDebtList(List<dynamic> loanDebts, FriendState friendState) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: loanDebts.length,
      itemBuilder: (context, index) {
        final loanDebt = loanDebts[index];
        final friend = friendState.friends.where((f) => f.id == loanDebt.associatedFriendId).isNotEmpty ? friendState.friends.firstWhere((f) => f.id == loanDebt.associatedFriendId) : null;
        final isLoan = loanDebt.type.toLowerCase() == 'loangiventofriend';
        final isOverdue = loanDebt.dueDate != null && 
                         DateTime.now().isAfter(loanDebt.dueDate) &&
                         loanDebt.status.toLowerCase() != 'paidoff';
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (isLoan ? Colors.green : Colors.red).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isLoan ? Icons.call_made : Icons.call_received,
                color: isLoan ? Colors.green : Colors.red,
              ),
            ),
            title: Text(
              friend?.friendName ?? 'Unknown Friend',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loanDebt.description),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${_formatDate(loanDebt.dateInitiated)} • ${loanDebt.status}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    if (isOverdue) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'OVERDUE',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'ETB ${loanDebt.outstandingAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isLoan ? Colors.green : Colors.red,
                  ),
                ),
                Text(
                  'of ${loanDebt.initialAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            isThreeLine: true,
            onTap: () => _navigateToLoanDebtDetail(loanDebt.id),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(String error, VoidCallback onRetry) {
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
              onRetry();
              _handleRefresh();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
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
          Text(
            'No Records Found',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _navigateToAddLoanDebt,
            icon: const Icon(Icons.add),
            label: const Text('Add Loan/Debt'),
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
            'No $_filter Records',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try changing the filter or add new records',
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
            child: const Text('Show All Records'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}