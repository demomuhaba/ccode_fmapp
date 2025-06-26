import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/riverpod_providers.dart' as providers;

class LoanDebtDetailScreen extends ConsumerStatefulWidget {
  final String loanDebtId;

  const LoanDebtDetailScreen({super.key, required this.loanDebtId});

  @override
  ConsumerState<LoanDebtDetailScreen> createState() => _LoanDebtDetailScreenState();
}

class _LoanDebtDetailScreenState extends ConsumerState<LoanDebtDetailScreen> {
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final loanDebtNotifier = ref.read(providers.loanDebtNotifierProvider.notifier);
    final friendNotifier = ref.read(providers.friendNotifierProvider.notifier);
    final accountNotifier = ref.read(providers.financialAccountNotifierProvider.notifier);
    
    final loanDebt = loanDebtNotifier.getLoanDebtById(widget.loanDebtId);
    final userId = loanDebt?.userId ?? '';
    
    await Future.wait([
      loanDebtNotifier.loadLoanDebtPayments(widget.loanDebtId),
      friendNotifier.loadFriends(userId),
      accountNotifier.loadAccounts(userId),
    ]);
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _handleRefresh() async {
    await _loadData();
  }

  void _showPaymentDialog() {
    final loanDebtNotifier = ref.read(providers.loanDebtNotifierProvider.notifier);
    final loanDebt = loanDebtNotifier.getLoanDebtById(widget.loanDebtId);
    
    if (loanDebt == null) return;

    showDialog(
      context: context,
      builder: (context) => _PaymentDialog(
        loanDebt: loanDebt,
        onPaymentAdded: _handleRefresh,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loan/Debt Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loan/Debt Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _handleRefresh,
          ),
        ],
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final loanDebtState = ref.watch(providers.loanDebtNotifierProvider);
          final friendState = ref.watch(providers.friendNotifierProvider);
          final loanDebt = loanDebtState.loanDebts
              .where((item) => item.id == widget.loanDebtId)
              .firstOrNull;
          
          if (loanDebt == null) {
            return const Center(
              child: Text('Loan/debt record not found'),
            );
          }

          final friend = friendState.friends
              .where((f) => f.id == loanDebt.associatedFriendId)
              .firstOrNull;
          final isLoan = loanDebt.type.toLowerCase() == 'loangiventofriend';
          final isOverdue = loanDebt.dueDate != null && 
                           DateTime.now().isAfter(loanDebt.dueDate!) &&
                           loanDebt.status.toLowerCase() != 'paidoff';
          final isPaidOff = loanDebt.status.toLowerCase() == 'paidoff';

          return RefreshIndicator(
            onRefresh: _handleRefresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: (isLoan ? Colors.green : Colors.red).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                isLoan ? Icons.call_made : Icons.call_received,
                                color: isLoan ? Colors.green : Colors.red,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isLoan ? 'Loan Given' : 'Debt Owed',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    friend?.friendName ?? 'Unknown Friend',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isOverdue)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'OVERDUE',
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          loanDebt.description ?? 'No description provided',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Financial Summary',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSummaryRow('Initial Amount', 'ETB ${loanDebt.initialAmount.toStringAsFixed(2)}'),
                        _buildSummaryRow('Outstanding Amount', 'ETB ${loanDebt.outstandingAmount.toStringAsFixed(2)}', 
                            valueColor: isLoan ? Colors.green : Colors.red),
                        _buildSummaryRow('Paid Amount', 'ETB ${(loanDebt.initialAmount - loanDebt.outstandingAmount).toStringAsFixed(2)}'),
                        _buildSummaryRow('Status', loanDebt.status),
                        if (loanDebt.dueDate != null)
                          _buildSummaryRow('Due Date', _formatDate(loanDebt.dueDate!),
                              valueColor: isOverdue ? Colors.red : null),
                        _buildSummaryRow('Date Initiated', _formatDate(loanDebt.dateInitiated)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Payment History',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (!isPaidOff)
                              ElevatedButton.icon(
                                onPressed: _showPaymentDialog,
                                icon: const Icon(Icons.payment, size: 18),
                                label: const Text('Record Payment'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildPaymentHistory(loanDebtState.payments
                            .where((p) => p.loanDebtId == widget.loanDebtId)
                            .toList()),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistory(List<dynamic> payments) {
    if (payments.isEmpty) {
      return Center(
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              'No payments recorded yet',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: payments.map((payment) {
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
              Icon(
                Icons.payment,
                color: Colors.green,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ETB ${payment.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      _formatDate(payment.paymentDate),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (payment.notes != null && payment.notes!.isNotEmpty)
                Tooltip(
                  message: payment.notes!,
                  child: Icon(
                    Icons.note,
                    color: Colors.grey[400],
                    size: 16,
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _PaymentDialog extends ConsumerStatefulWidget {
  final dynamic loanDebt;
  final VoidCallback onPaymentAdded;

  const _PaymentDialog({
    required this.loanDebt,
    required this.onPaymentAdded,
  });

  @override
  ConsumerState<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends ConsumerState<_PaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedTransactionMethod = 'Cash';
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final loanDebtNotifier = ref.read(providers.loanDebtNotifierProvider.notifier);
    final amount = double.parse(_amountController.text.trim());

    if (amount > widget.loanDebt.outstandingAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment amount cannot exceed outstanding amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final success = await loanDebtNotifier.recordPayment(
      loanDebtId: widget.loanDebt.id,
      amount: amount,
      paymentDate: _selectedDate,
      transactionMethod: _selectedTransactionMethod,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment recorded successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
        widget.onPaymentAdded();
      } else {
        final loanDebtState = ref.read(providers.loanDebtNotifierProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loanDebtState.error ?? 'Failed to record payment'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Record Payment',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Outstanding: ETB ${widget.loanDebt.outstandingAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Payment Amount (ETB) *',
                    hintText: '0.00',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter payment amount';
                    }
                    final amount = double.tryParse(value.trim());
                    if (amount == null || amount <= 0) {
                      return 'Please enter a valid positive amount';
                    }
                    if (amount > widget.loanDebt.outstandingAmount) {
                      return 'Amount cannot exceed outstanding balance';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Consumer(
                  builder: (context, ref, child) {
                    final accountState = ref.watch(providers.financialAccountNotifierProvider);
                    return DropdownButtonFormField<String>(
                      value: _selectedTransactionMethod,
                      decoration: const InputDecoration(
                        labelText: 'Payment Method *',
                        prefixIcon: Icon(Icons.payment),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: 'Cash',
                          child: Text('Cash'),
                        ),
                        ...accountState.accounts.map((account) {
                          return DropdownMenuItem(
                            value: account.id,
                            child: Text('${account.accountName} (${account.accountType})'),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedTransactionMethod = value!;
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Payment Date *'),
                  subtitle: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                  leading: const Icon(Icons.calendar_today),
                  onTap: _selectDate,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    hintText: 'Optional notes about this payment',
                    prefixIcon: Icon(Icons.note),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                Consumer(
                  builder: (context, ref, child) {
                    final loanDebtState = ref.watch(providers.loanDebtNotifierProvider);
                    return Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: loanDebtState.isLoading ? null : () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: loanDebtState.isLoading ? null : _handleSubmit,
                            child: loanDebtState.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Record Payment'),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}