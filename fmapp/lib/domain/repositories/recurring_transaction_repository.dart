import '../entities/recurring_transaction.dart';

abstract class RecurringTransactionRepository {
  /// Get all recurring transactions for a user
  Future<List<RecurringTransaction>> getRecurringTransactions(String userId);

  /// Get recurring transaction by ID
  Future<RecurringTransaction?> getRecurringTransactionById(String id);

  /// Get active recurring transactions that need execution
  Future<List<RecurringTransaction>> getRecurringTransactionsDue(String userId, DateTime currentDate);

  /// Create a new recurring transaction
  Future<String> createRecurringTransaction(RecurringTransaction recurringTransaction);

  /// Update an existing recurring transaction
  Future<bool> updateRecurringTransaction(RecurringTransaction recurringTransaction);

  /// Delete a recurring transaction
  Future<bool> deleteRecurringTransaction(String id);

  /// Mark a recurring transaction as executed
  Future<bool> markAsExecuted(String id, DateTime executionDate);

  /// Pause/resume a recurring transaction
  Future<bool> toggleActive(String id, bool isActive);

  /// Get recurring transactions by frequency
  Future<List<RecurringTransaction>> getRecurringTransactionsByFrequency(String userId, String frequency);

  /// Get recurring transactions by account
  Future<List<RecurringTransaction>> getRecurringTransactionsByAccount(String userId, String accountId);

  /// Get recurring transaction statistics
  Future<Map<String, dynamic>> getRecurringTransactionStats(String userId);
}