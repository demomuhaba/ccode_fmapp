import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/riverpod_providers.dart' as providers;
import '../../../services/report_export_service.dart';

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  final ReportExportService _exportService = ReportExportService();
  
  String _selectedExportType = 'transactions';
  String _selectedFormat = 'csv';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isExporting = false;
  String? _lastExportedFile;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authState = ref.read(providers.authNotifierProvider);
    final userId = authState.userProfile?.userId;
    
    if (userId != null) {
      await Future.wait([
        ref.read(providers.transactionNotifierProvider.notifier).loadTransactions(userId),
        ref.read(providers.financialAccountNotifierProvider.notifier).loadAccounts(userId),
        ref.read(providers.loanDebtNotifierProvider.notifier).loadLoanDebts(userId),
        ref.read(providers.friendNotifierProvider.notifier).loadFriends(userId),
        ref.read(providers.simCardNotifierProvider.notifier).loadSimCards(userId),
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Reports'),
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final transactionState = ref.watch(providers.transactionNotifierProvider);
          final accountState = ref.watch(providers.financialAccountNotifierProvider);
          final loanDebtState = ref.watch(providers.loanDebtNotifierProvider);
          final friendState = ref.watch(providers.friendNotifierProvider);
          final simCardState = ref.watch(providers.simCardNotifierProvider);

          if (transactionState.isLoading || accountState.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildExportTypeSection(),
                const SizedBox(height: 24),
                _buildFormatSection(),
                const SizedBox(height: 24),
                if (_selectedExportType == 'transactions') ...[
                  _buildDateRangeSection(),
                  const SizedBox(height: 24),
                ],
                _buildDataPreview(transactionState, accountState, loanDebtState, friendState, simCardState),
                const SizedBox(height: 24),
                _buildExportButton(),
                if (_lastExportedFile != null) ...[
                  const SizedBox(height: 16),
                  _buildLastExportInfo(),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildExportTypeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Export Type',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...['transactions', 'accounts', 'loans'].map((type) {
              return RadioListTile<String>(
                title: Text(_getExportTypeLabel(type)),
                subtitle: Text(_getExportTypeDescription(type)),
                value: type,
                groupValue: _selectedExportType,
                onChanged: (value) {
                  setState(() {
                    _selectedExportType = value!;
                  });
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Export Format',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('CSV'),
                    subtitle: const Text('Spreadsheet format'),
                    value: 'csv',
                    groupValue: _selectedFormat,
                    onChanged: (value) {
                      setState(() {
                        _selectedFormat = value!;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('PDF'),
                    subtitle: const Text('Document format'),
                    value: 'pdf',
                    groupValue: _selectedFormat,
                    onChanged: (value) {
                      setState(() {
                        _selectedFormat = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Date Range',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('Start Date'),
                    subtitle: Text(DateFormat('MMM dd, yyyy').format(_startDate)),
                    leading: const Icon(Icons.calendar_today),
                    onTap: () => _selectStartDate(),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ListTile(
                    title: const Text('End Date'),
                    subtitle: Text(DateFormat('MMM dd, yyyy').format(_endDate)),
                    leading: const Icon(Icons.event),
                    onTap: () => _selectEndDate(),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('Last Week'),
                  selected: false,
                  onSelected: (_) => _setDateRange(7),
                ),
                FilterChip(
                  label: const Text('Last Month'),
                  selected: false,
                  onSelected: (_) => _setDateRange(30),
                ),
                FilterChip(
                  label: const Text('Last 3 Months'),
                  selected: false,
                  onSelected: (_) => _setDateRange(90),
                ),
                FilterChip(
                  label: const Text('This Year'),
                  selected: false,
                  onSelected: (_) => _setDateRangeThisYear(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataPreview(dynamic transactionState, dynamic accountState, 
      dynamic loanDebtState, dynamic friendState, dynamic simCardState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Data Preview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildPreviewContent(transactionState, accountState, loanDebtState, friendState, simCardState),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewContent(dynamic transactionState, dynamic accountState, 
      dynamic loanDebtState, dynamic friendState, dynamic simCardState) {
    switch (_selectedExportType) {
      case 'transactions':
        final filteredTransactions = transactionState.transactions.where((t) =>
          t.transactionDate.isAfter(_startDate) && t.transactionDate.isBefore(_endDate.add(const Duration(days: 1)))
        ).toList();
        
        return Column(
          children: [
            _buildPreviewRow('Total Transactions', '${filteredTransactions.length}'),
            _buildPreviewRow('Date Range', '${DateFormat('MMM dd, yyyy').format(_startDate)} - ${DateFormat('MMM dd, yyyy').format(_endDate)}'),
            _buildPreviewRow('Accounts Included', '${accountState.accounts.length}'),
          ],
        );
      
      case 'accounts':
        return Column(
          children: [
            _buildPreviewRow('Total Accounts', '${accountState.accounts.length}'),
            _buildPreviewRow('SIM Cards', '${simCardState.simCards.length}'),
            _buildPreviewRow('Account Types', _getUniqueAccountTypes(accountState.accounts)),
          ],
        );
      
      case 'loans':
        return Column(
          children: [
            _buildPreviewRow('Total Loan/Debt Items', '${loanDebtState.loanDebts.length}'),
            _buildPreviewRow('Friends', '${friendState.friends.length}'),
            _buildPreviewRow('Active Items', '${loanDebtState.loanDebts.where((item) => item.status.toLowerCase() != 'paidoff').length}'),
          ],
        );
      
      default:
        return const Text('Select an export type to see preview');
    }
  }

  Widget _buildPreviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildExportButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isExporting ? null : _handleExport,
        icon: _isExporting 
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.file_download),
        label: Text(_isExporting ? 'Exporting...' : 'Export ${_selectedFormat.toUpperCase()}'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildLastExportInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Export Completed',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
                Text(
                  'File saved: $_lastExportedFile',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getExportTypeLabel(String type) {
    switch (type) {
      case 'transactions':
        return 'Transactions';
      case 'accounts':
        return 'Account Summary';
      case 'loans':
        return 'Loans & Debts';
      default:
        return type;
    }
  }

  String _getExportTypeDescription(String type) {
    switch (type) {
      case 'transactions':
        return 'Export all transaction records with account details';
      case 'accounts':
        return 'Export account balances and SIM card information';
      case 'loans':
        return 'Export loan and debt records with friend details';
      default:
        return '';
    }
  }

  String _getUniqueAccountTypes(List<dynamic> accounts) {
    final types = accounts.map((acc) => acc.accountType).toSet();
    return types.join(', ');
  }

  void _setDateRange(int days) {
    setState(() {
      _endDate = DateTime.now();
      _startDate = _endDate.subtract(Duration(days: days));
    });
  }

  void _setDateRangeThisYear() {
    final now = DateTime.now();
    setState(() {
      _startDate = DateTime(now.year, 1, 1);
      _endDate = now;
    });
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: _endDate,
    );
    
    if (date != null) {
      setState(() {
        _startDate = date;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now(),
    );
    
    if (date != null) {
      setState(() {
        _endDate = date;
      });
    }
  }

  Future<void> _handleExport() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final transactionState = ref.read(providers.transactionNotifierProvider);
      final accountState = ref.read(providers.financialAccountNotifierProvider);
      final loanDebtState = ref.read(providers.loanDebtNotifierProvider);
      final friendState = ref.read(providers.friendNotifierProvider);
      final simCardState = ref.read(providers.simCardNotifierProvider);

      switch (_selectedExportType) {
        case 'transactions':
          await _exportTransactions(transactionState, accountState);
          break;
        case 'accounts':
          await _exportAccounts(accountState, simCardState);
          break;
        case 'loans':
          await _exportLoans(loanDebtState, friendState);
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  Future<void> _exportTransactions(dynamic transactionState, dynamic accountState) async {
    final filteredTransactions = transactionState.transactions.where((t) =>
      t.transactionDate.isAfter(_startDate) && 
      t.transactionDate.isBefore(_endDate.add(const Duration(days: 1)))
    ).toList();

    final title = 'Transactions_${DateFormat('yyyy-MM-dd').format(_startDate)}_to_${DateFormat('yyyy-MM-dd').format(_endDate)}';

    if (_selectedFormat == 'csv') {
      final file = await _exportService.exportTransactionsToCSV(
        transactions: filteredTransactions,
        accounts: accountState.accounts,
        title: title,
      );
      setState(() {
        _lastExportedFile = file.path.split('/').last;
      });
      await _exportService.shareFile(file, subject: 'fmapp Transaction Report');
    } else {
      final pdfData = await _exportService.exportTransactionsToPDF(
        transactions: filteredTransactions,
        accounts: accountState.accounts,
        title: 'Transaction Report',
        startDate: _startDate,
        endDate: _endDate,
      );
      await _exportService.printPDF(pdfData, jobName: 'fmapp Transaction Report');
      setState(() {
        _lastExportedFile = 'Transaction_Report.pdf';
      });
    }
  }

  Future<void> _exportAccounts(dynamic accountState, dynamic simCardState) async {
    final title = 'Account_Summary_${DateFormat('yyyy-MM-dd').format(DateTime.now())}';

    if (_selectedFormat == 'csv') {
      final file = await _exportService.exportAccountSummaryToCSV(
        accounts: accountState.accounts,
        simCards: simCardState.simCards,
        title: title,
      );
      setState(() {
        _lastExportedFile = file.path.split('/').last;
      });
      await _exportService.shareFile(file, subject: 'fmapp Account Summary');
    } else {
      // PDF export for accounts would need to be implemented
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF export for accounts is not yet implemented. Please use CSV format.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _exportLoans(dynamic loanDebtState, dynamic friendState) async {
    final title = 'Loans_and_Debts_${DateFormat('yyyy-MM-dd').format(DateTime.now())}';

    if (_selectedFormat == 'csv') {
      final file = await _exportService.exportLoansToCSV(
        loans: loanDebtState.loanDebts,
        title: title,
      );
      setState(() {
        _lastExportedFile = file.path.split('/').last;
      });
      await _exportService.shareFile(file, subject: 'fmapp Loans & Debts Report');
    } else {
      final pdfData = await _exportService.exportLoansToPDF(
        loans: loanDebtState.loanDebts,
        title: 'Loans & Debts Report',
      );
      await _exportService.printPDF(pdfData, jobName: 'fmapp Loans & Debts Report');
      setState(() {
        _lastExportedFile = 'Loans_and_Debts_Report.pdf';
      });
    }
  }
}