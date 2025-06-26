import '../entities/transaction_record.dart';

abstract class TransactionRepository {
  Future<List<TransactionRecord>> getAllTransactions(String userId);
  Future<TransactionRecord?> getTransactionById(String id);
  Future<TransactionRecord> createTransaction(TransactionRecord transaction);
  Future<TransactionRecord> updateTransaction(TransactionRecord transaction);
  Future<void> deleteTransaction(String id);
  Future<List<TransactionRecord>> getTransactionsByAccount(String accountId);
  Future<List<TransactionRecord>> getTransactionsByDateRange(String userId, DateTime startDate, DateTime endDate);
  Future<List<TransactionRecord>> getRecentTransactions(String userId, {int limit = 10});
  Future<List<TransactionRecord>> getInternalTransfers(String userId);
  Future<double> getTotalIncomeForAccount(String accountId, DateTime? startDate, DateTime? endDate);
  Future<double> getTotalExpenseForAccount(String accountId, DateTime? startDate, DateTime? endDate);
}