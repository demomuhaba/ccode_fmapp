import 'package:uuid/uuid.dart';
import '../entities/transaction_record.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/financial_account_repository.dart';

class TransactionUseCases {
  final TransactionRepository _transactionRepository;
  final FinancialAccountRepository _accountRepository;
  final Uuid _uuid = const Uuid();

  TransactionUseCases(this._transactionRepository, this._accountRepository);

  Future<List<TransactionRecord>> getAllTransactions(String userId) async {
    try {
      return await _transactionRepository.getAllTransactions(userId);
    } catch (e) {
      throw Exception('Failed to get transactions: $e');
    }
  }

  Future<TransactionRecord?> getTransactionById(String id) async {
    try {
      return await _transactionRepository.getTransactionById(id);
    } catch (e) {
      throw Exception('Failed to get transaction: $e');
    }
  }

  Future<TransactionRecord> createTransaction({
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
    try {
      final account = await _accountRepository.getAccountById(affectedAccountId);
      if (account == null) {
        throw Exception('Account not found');
      }

      if (account.userId != userId) {
        throw Exception('Account does not belong to user');
      }

      if (amount <= 0) {
        throw Exception('Transaction amount must be positive');
      }

      final transaction = TransactionRecord(
        id: _uuid.v4(),
        userId: userId,
        affectedAccountId: affectedAccountId,
        transactionDate: transactionDate,
        amount: amount,
        transactionType: transactionType,
        currency: currency,
        descriptionNotes: descriptionNotes,
        payerSenderRaw: payerSenderRaw,
        payeeReceiverRaw: payeeReceiverRaw,
        referenceNumber: referenceNumber,
        isInternalTransfer: isInternalTransfer,
        counterpartyAccountId: counterpartyAccountId,
        receiptFileLink: receiptFileLink,
        ocrExtractedRawText: ocrExtractedRawText,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return await _transactionRepository.createTransaction(transaction);
    } catch (e) {
      throw Exception('Failed to create transaction: $e');
    }
  }

  Future<TransactionRecord> updateTransaction(TransactionRecord transaction) async {
    try {
      final updatedTransaction = transaction.copyWith(updatedAt: DateTime.now());
      return await _transactionRepository.updateTransaction(updatedTransaction);
    } catch (e) {
      throw Exception('Failed to update transaction: $e');
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      await _transactionRepository.deleteTransaction(id);
    } catch (e) {
      throw Exception('Failed to delete transaction: $e');
    }
  }

  Future<List<TransactionRecord>> getTransactionsByAccount(String accountId) async {
    try {
      return await _transactionRepository.getTransactionsByAccount(accountId);
    } catch (e) {
      throw Exception('Failed to get transactions by account: $e');
    }
  }

  Future<List<TransactionRecord>> getRecentTransactions(String userId, {int limit = 10}) async {
    try {
      return await _transactionRepository.getRecentTransactions(userId, limit: limit);
    } catch (e) {
      throw Exception('Failed to get recent transactions: $e');
    }
  }

  Future<List<TransactionRecord>> getTransactionsByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      return await _transactionRepository.getTransactionsByDateRange(userId, startDate, endDate);
    } catch (e) {
      throw Exception('Failed to get transactions by date range: $e');
    }
  }

  Future<List<TransactionRecord>> getInternalTransfers(String userId) async {
    try {
      return await _transactionRepository.getInternalTransfers(userId);
    } catch (e) {
      throw Exception('Failed to get internal transfers: $e');
    }
  }

  Future<Map<String, double>> getAccountTransactionSummary(
    String accountId,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    try {
      final totalIncome = await _transactionRepository.getTotalIncomeForAccount(
        accountId,
        startDate,
        endDate,
      );
      final totalExpense = await _transactionRepository.getTotalExpenseForAccount(
        accountId,
        startDate,
        endDate,
      );

      return {
        'totalIncome': totalIncome,
        'totalExpense': totalExpense,
        'netAmount': totalIncome - totalExpense,
      };
    } catch (e) {
      throw Exception('Failed to get account transaction summary: $e');
    }
  }

  Future<Map<String, Object>> createInternalTransfer({
    required String userId,
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    required DateTime transferDate,
    required String description,
    String? referenceNumber,
  }) async {
    try {
      if (fromAccountId == toAccountId) {
        throw Exception('Cannot transfer to the same account');
      }

      final fromAccount = await _accountRepository.getAccountById(fromAccountId);
      final toAccount = await _accountRepository.getAccountById(toAccountId);

      if (fromAccount == null || toAccount == null) {
        throw Exception('One or both accounts not found');
      }

      if (fromAccount.userId != userId || toAccount.userId != userId) {
        throw Exception('Accounts do not belong to user');
      }

      if (amount <= 0) {
        throw Exception('Transfer amount must be positive');
      }

      final currentBalance = await _accountRepository.calculateCurrentBalance(fromAccountId);
      if (currentBalance < amount) {
        throw Exception('Insufficient balance for transfer');
      }

      final debitTransaction = await createTransaction(
        userId: userId,
        affectedAccountId: fromAccountId,
        transactionDate: transferDate,
        amount: amount,
        transactionType: 'Expense/Debit',
        descriptionNotes: 'Internal Transfer: $description',
        isInternalTransfer: true,
        counterpartyAccountId: toAccountId,
        referenceNumber: referenceNumber,
      );

      final creditTransaction = await createTransaction(
        userId: userId,
        affectedAccountId: toAccountId,
        transactionDate: transferDate,
        amount: amount,
        transactionType: 'Income/Credit',
        descriptionNotes: 'Internal Transfer: $description',
        isInternalTransfer: true,
        counterpartyAccountId: fromAccountId,
        referenceNumber: referenceNumber,
      );

      return {
        'debitTransaction': debitTransaction,
        'creditTransaction': creditTransaction,
        'transferAmount': amount,
        'fromAccount': fromAccount,
        'toAccount': toAccount,
      };
    } catch (e) {
      throw Exception('Failed to create internal transfer: $e');
    }
  }

  Future<List<String>> getValidTransactionTypes() async {
    return ['Income/Credit', 'Expense/Debit'];
  }

  Future<bool> validateTransactionData({
    required double amount,
    required String transactionType,
    required String description,
  }) async {
    if (amount <= 0) return false;
    if (transactionType.trim().isEmpty) return false;
    if (description.trim().isEmpty) return false;
    
    final validTypes = await getValidTransactionTypes();
    return validTypes.contains(transactionType);
  }
}