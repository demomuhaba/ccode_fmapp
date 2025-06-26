import 'package:flutter/foundation.dart';
import '../../domain/entities/transaction_record.dart';
import '../../domain/usecases/transaction_usecases.dart';

class TransactionProvider extends ChangeNotifier {
  final TransactionUseCases _transactionUseCases;

  TransactionProvider(this._transactionUseCases);

  List<TransactionRecord> _transactions = [];
  List<TransactionRecord> _recentTransactions = [];
  List<TransactionRecord> _internalTransfers = [];
  bool _isLoading = false;
  String? _error;

  List<TransactionRecord> get transactions => _transactions;
  List<TransactionRecord> get recentTransactions => _recentTransactions;
  List<TransactionRecord> get internalTransfers => _internalTransfers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double getTotalIncome() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    
    return _transactions.where((transaction) => 
      (transaction.transactionType.toLowerCase().contains('income') ||
       transaction.transactionType.toLowerCase().contains('credit')) &&
      transaction.transactionDate.isAfter(startOfMonth)
    ).fold(0.0, (sum, transaction) => sum + transaction.amount);
  }

  double getTotalExpenses() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    
    return _transactions.where((transaction) => 
      (transaction.transactionType.toLowerCase().contains('expense') ||
       transaction.transactionType.toLowerCase().contains('debit')) &&
      transaction.transactionDate.isAfter(startOfMonth)
    ).fold(0.0, (sum, transaction) => sum + transaction.amount);
  }

  Future<void> loadTransactions(String userId) async {
    _setLoading(true);
    try {
      _transactions = await _transactionUseCases.getAllTransactions(userId);
      _clearError();
    } catch (e) {
      _setError('Failed to load transactions: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadRecentTransactions(String userId, {int limit = 10}) async {
    try {
      _recentTransactions = await _transactionUseCases.getRecentTransactions(userId, limit: limit);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load recent transactions: $e');
    }
  }

  Future<void> loadInternalTransfers(String userId) async {
    try {
      _internalTransfers = await _transactionUseCases.getInternalTransfers(userId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load internal transfers: $e');
    }
  }

  Future<bool> createTransaction({
    required String userId,
    required String affectedAccountId,
    required DateTime transactionDate,
    required double amount,
    required String transactionType,
    required String descriptionNotes,
    String currency = 'ETB',
    String? payerSenderRaw,
    String? payeeReceiverRaw,
    String? referenceNumber,
    bool isInternalTransfer = false,
    String? counterpartyAccountId,
    String? receiptFileLink,
    String? ocrExtractedRawText,
  }) async {
    _setLoading(true);
    try {
      final newTransaction = await _transactionUseCases.createTransaction(
        userId: userId,
        affectedAccountId: affectedAccountId,
        transactionDate: transactionDate,
        amount: amount,
        transactionType: transactionType,
        descriptionNotes: descriptionNotes,
        currency: currency,
        payerSenderRaw: payerSenderRaw,
        payeeReceiverRaw: payeeReceiverRaw,
        referenceNumber: referenceNumber,
        isInternalTransfer: isInternalTransfer,
        counterpartyAccountId: counterpartyAccountId,
        receiptFileLink: receiptFileLink,
        ocrExtractedRawText: ocrExtractedRawText,
      );
      
      _transactions.insert(0, newTransaction);
      
      // Update recent transactions if it's not full or if this is more recent
      if (_recentTransactions.length < 10) {
        _recentTransactions.insert(0, newTransaction);
      } else if (_recentTransactions.isNotEmpty && 
                 newTransaction.transactionDate.isAfter(_recentTransactions.last.transactionDate)) {
        _recentTransactions.insert(0, newTransaction);
        _recentTransactions.removeLast();
      }
      
      if (isInternalTransfer) {
        _internalTransfers.insert(0, newTransaction);
      }
      
      _clearError();
      return true;
    } catch (e) {
      _setError('Failed to create transaction: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateTransaction(TransactionRecord transaction) async {
    _setLoading(true);
    try {
      final updatedTransaction = await _transactionUseCases.updateTransaction(transaction);
      
      final index = _transactions.indexWhere((t) => t.id == updatedTransaction.id);
      if (index != -1) {
        _transactions[index] = updatedTransaction;
      }
      
      final recentIndex = _recentTransactions.indexWhere((t) => t.id == updatedTransaction.id);
      if (recentIndex != -1) {
        _recentTransactions[recentIndex] = updatedTransaction;
      }
      
      final transferIndex = _internalTransfers.indexWhere((t) => t.id == updatedTransaction.id);
      if (transferIndex != -1) {
        _internalTransfers[transferIndex] = updatedTransaction;
      }
      
      _clearError();
      return true;
    } catch (e) {
      _setError('Failed to update transaction: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteTransaction(String id) async {
    _setLoading(true);
    try {
      await _transactionUseCases.deleteTransaction(id);
      
      _transactions.removeWhere((t) => t.id == id);
      _recentTransactions.removeWhere((t) => t.id == id);
      _internalTransfers.removeWhere((t) => t.id == id);
      
      _clearError();
      return true;
    } catch (e) {
      _setError('Failed to delete transaction: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createInternalTransfer({
    required String userId,
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    required DateTime transferDate,
    required String description,
    String? referenceNumber,
  }) async {
    _setLoading(true);
    try {
      final result = await _transactionUseCases.createInternalTransfer(
        userId: userId,
        fromAccountId: fromAccountId,
        toAccountId: toAccountId,
        amount: amount,
        transferDate: transferDate,
        description: description,
        referenceNumber: referenceNumber,
      );
      
      final debitTransaction = result['debitTransaction'] as TransactionRecord;
      final creditTransaction = result['creditTransaction'] as TransactionRecord;
      
      _transactions.insertAll(0, [debitTransaction, creditTransaction]);
      _internalTransfers.insertAll(0, [debitTransaction, creditTransaction]);
      
      // Update recent transactions
      if (_recentTransactions.length < 8) {
        _recentTransactions.insertAll(0, [debitTransaction, creditTransaction]);
      } else {
        _recentTransactions.insertAll(0, [debitTransaction, creditTransaction]);
        while (_recentTransactions.length > 10) {
          _recentTransactions.removeLast();
        }
      }
      
      _clearError();
      return true;
    } catch (e) {
      _setError('Failed to create internal transfer: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  List<TransactionRecord> getTransactionsByAccount(String accountId) {
    return _transactions.where((t) => t.affectedAccountId == accountId).toList();
  }

  List<TransactionRecord> getTransactionsByDateRange(DateTime startDate, DateTime endDate) {
    return _transactions.where((t) => 
      t.transactionDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
      t.transactionDate.isBefore(endDate.add(const Duration(days: 1)))
    ).toList();
  }

  TransactionRecord? getTransactionById(String id) {
    try {
      return _transactions.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, double>> getAccountTransactionSummary(
    String accountId,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    try {
      return await _transactionUseCases.getAccountTransactionSummary(accountId, startDate, endDate);
    } catch (e) {
      _setError('Failed to get transaction summary: $e');
      return {'totalIncome': 0.0, 'totalExpense': 0.0, 'netAmount': 0.0};
    }
  }

  List<String> getValidTransactionTypes() {
    return ['Income/Credit', 'Expense/Debit'];
  }

  Future<bool> validateTransactionData({
    required double amount,
    required String transactionType,
    required String description,
  }) async {
    return await _transactionUseCases.validateTransactionData(
      amount: amount,
      transactionType: transactionType,
      description: description,
    );
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }
}