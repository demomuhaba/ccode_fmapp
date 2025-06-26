import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/riverpod_providers.dart' as providers;
import '../pages/loans/loan_debt_list_screen.dart';

class LoanDebtSummaryWidget extends ConsumerWidget {
  const LoanDebtSummaryWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Loans & Debts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const LoanDebtListScreen()),
              ),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Consumer(
          builder: (context, ref, child) {
            final loanDebtState = ref.watch(providers.loanDebtNotifierProvider);
            final loanDebtNotifier = ref.read(providers.loanDebtNotifierProvider.notifier);
            
            if (loanDebtState.isLoading) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            final totalLoansGiven = loanDebtNotifier.getTotalLoansGiven();
            final totalDebtsOwed = loanDebtNotifier.getTotalDebtsOwed();
            final netPosition = loanDebtNotifier.getNetPosition();
            final overdueLoanDebts = loanDebtNotifier.getOverdueLoanDebts();

            if (totalLoansGiven == 0 && totalDebtsOwed == 0) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.handshake_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No loans or debts',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Track money you lend to or borrow from friends',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
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
                  children: [
                    _buildSummaryRow(
                      'Money Lent',
                      totalLoansGiven,
                      Colors.green,
                      Icons.trending_up,
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryRow(
                      'Money Owed',
                      totalDebtsOwed,
                      Colors.red,
                      Icons.trending_down,
                    ),
                    const Divider(height: 24),
                    _buildSummaryRow(
                      'Net Position',
                      netPosition.abs(),
                      netPosition >= 0 ? Colors.green : Colors.red,
                      netPosition >= 0 ? Icons.thumb_up : Icons.thumb_down,
                      isNet: true,
                      isPositive: netPosition >= 0,
                    ),
                    if (overdueLoanDebts.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning,
                              color: Colors.orange.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${overdueLoanDebts.length} overdue item${overdueLoanDebts.length != 1 ? 's' : ''}',
                                style: TextStyle(
                                  color: Colors.orange.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
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
          },
        ),
      ],
    );
  }

  Widget _buildSummaryRow(
    String label,
    double amount,
    Color color,
    IconData icon, {
    bool isNet = false,
    bool isPositive = true,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
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
          '${isNet ? (isPositive ? '+' : '-') : ''}ETB ${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}