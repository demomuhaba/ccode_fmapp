import '../entities/recurring_transaction.dart';
import '../entities/transaction_record.dart';
import '../repositories/recurring_transaction_repository.dart';
import '../repositories/transaction_repository.dart';

class RecurringTransactionUsecases {
  final RecurringTransactionRepository _recurringTransactionRepository;
  final TransactionRepository _transactionRepository;

  RecurringTransactionUsecases(
    this._recurringTransactionRepository,
    this._transactionRepository,
  );

  /// Get all recurring transactions for a user
  Future<List<RecurringTransaction>> getRecurringTransactions(String userId) async {
    return await _recurringTransactionRepository.getRecurringTransactions(userId);
  }

  /// Get recurring transaction by ID
  Future<RecurringTransaction?> getRecurringTransactionById(String id) async {
    return await _recurringTransactionRepository.getRecurringTransactionById(id);
  }

  /// Create a new recurring transaction
  Future<String> createRecurringTransaction({
    required String userId,
    required String affectedAccountId,
    required String templateName,
    required double amount,
    required String transactionType,
    required String currency,
    String? descriptionNotes,
    String? payerSenderRaw,
    String? payeeReceiverRaw,
    String? referenceNumber,
    required bool isInternalTransfer,
    String? counterpartyAccountId,
    required String frequency,
    required int interval,
    required DateTime startDate,
    DateTime? endDate,
    int? maxExecutions,
    int? dayOfMonth,
    int? dayOfWeek,
    List<String>? tags,
  }) async {
    final recurringTransaction = RecurringTransaction(
      id: '', // Will be generated in repository
      userId: userId,
      affectedAccountId: affectedAccountId,
      templateName: templateName,
      amount: amount,
      transactionType: transactionType,
      currency: currency,
      descriptionNotes: descriptionNotes,
      payerSenderRaw: payerSenderRaw,
      payeeReceiverRaw: payeeReceiverRaw,
      referenceNumber: referenceNumber,
      isInternalTransfer: isInternalTransfer,
      counterpartyAccountId: counterpartyAccountId,
      frequency: frequency,
      interval: interval,
      startDate: startDate,
      endDate: endDate,
      lastExecuted: null,
      nextExecution: null, // Will be calculated in repository
      isActive: true,
      maxExecutions: maxExecutions,
      executionCount: 0,
      dayOfMonth: dayOfMonth,
      dayOfWeek: dayOfWeek,
      tags: tags,
    );

    return await _recurringTransactionRepository.createRecurringTransaction(recurringTransaction);
  }

  /// Update an existing recurring transaction
  Future<bool> updateRecurringTransaction(RecurringTransaction recurringTransaction) async {
    return await _recurringTransactionRepository.updateRecurringTransaction(recurringTransaction);
  }

  /// Delete a recurring transaction
  Future<bool> deleteRecurringTransaction(String id) async {
    return await _recurringTransactionRepository.deleteRecurringTransaction(id);
  }

  /// Pause or resume a recurring transaction
  Future<bool> toggleActiveStatus(String id, bool isActive) async {
    return await _recurringTransactionRepository.toggleActive(id, isActive);
  }

  /// Get recurring transactions that are due for execution
  Future<List<RecurringTransaction>> getDueRecurringTransactions(String userId, [DateTime? currentDate]) async {
    final date = currentDate ?? DateTime.now();
    return await _recurringTransactionRepository.getRecurringTransactionsDue(userId, date);
  }

  /// Execute a recurring transaction (create actual transaction)
  Future<bool> executeRecurringTransaction(String recurringTransactionId) async {
    try {
      final recurringTransaction = await _recurringTransactionRepository.getRecurringTransactionById(recurringTransactionId);
      if (recurringTransaction == null) {
        throw Exception('Recurring transaction not found');
      }

      if (!recurringTransaction.shouldExecute()) {
        throw Exception('Recurring transaction should not be executed at this time');
      }

      // Create the actual transaction
      final transactionId = await _transactionRepository.createTransaction(
        TransactionRecord(
          id: '', // Will be generated
          userId: recurringTransaction.userId,
          affectedAccountId: recurringTransaction.affectedAccountId,
          transactionDate: DateTime.now(),
          amount: recurringTransaction.amount,
          transactionType: recurringTransaction.transactionType,
          currency: recurringTransaction.currency,
          descriptionNotes: '${recurringTransaction.descriptionNotes} (Auto-generated from ${recurringTransaction.templateName})',
          payerSenderRaw: recurringTransaction.payerSenderRaw,
          payeeReceiverRaw: recurringTransaction.payeeReceiverRaw,
          referenceNumber: '${recurringTransaction.referenceNumber ?? ''}_${DateTime.now().millisecondsSinceEpoch}',
          isInternalTransfer: recurringTransaction.isInternalTransfer,
          counterpartyAccountId: recurringTransaction.counterpartyAccountId,
          receiptFileLink: null,
          ocrExtractedRawText: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      // Mark the recurring transaction as executed
      if (transactionId.isNotEmpty) {
        await _recurringTransactionRepository.markAsExecuted(recurringTransactionId, DateTime.now());
        return true;
      }

      return false;
    } catch (e) {
      throw Exception('Failed to execute recurring transaction: $e');
    }
  }

  /// Execute all due recurring transactions for a user
  Future<Map<String, dynamic>> executeAllDueRecurringTransactions(String userId) async {
    try {
      final dueTransactions = await getDueRecurringTransactions(userId);
      
      int successCount = 0;
      int failureCount = 0;
      final List<String> failedTransactions = [];

      for (final recurringTransaction in dueTransactions) {
        try {
          final success = await executeRecurringTransaction(recurringTransaction.id);
          if (success) {
            successCount++;
          } else {
            failureCount++;
            failedTransactions.add(recurringTransaction.templateName);
          }
        } catch (e) {
          failureCount++;
          failedTransactions.add('${recurringTransaction.templateName}: $e');
        }
      }

      return {
        'total_due': dueTransactions.length,
        'success_count': successCount,
        'failure_count': failureCount,
        'failed_transactions': failedTransactions,
      };
    } catch (e) {
      throw Exception('Failed to execute due recurring transactions: $e');
    }
  }

  /// Get recurring transactions by frequency
  Future<List<RecurringTransaction>> getRecurringTransactionsByFrequency(String userId, String frequency) async {
    return await _recurringTransactionRepository.getRecurringTransactionsByFrequency(userId, frequency);
  }

  /// Get recurring transactions by account
  Future<List<RecurringTransaction>> getRecurringTransactionsByAccount(String userId, String accountId) async {
    return await _recurringTransactionRepository.getRecurringTransactionsByAccount(userId, accountId);
  }

  /// Get recurring transaction statistics
  Future<Map<String, dynamic>> getRecurringTransactionStats(String userId) async {
    return await _recurringTransactionRepository.getRecurringTransactionStats(userId);
  }

  /// Get active recurring transactions
  Future<List<RecurringTransaction>> getActiveRecurringTransactions(String userId) async {
    final allTransactions = await getRecurringTransactions(userId);
    return allTransactions.where((rt) => rt.isActive && !rt.hasEnded()).toList();
  }

  /// Get paused recurring transactions
  Future<List<RecurringTransaction>> getPausedRecurringTransactions(String userId) async {
    final allTransactions = await getRecurringTransactions(userId);
    return allTransactions.where((rt) => !rt.isActive).toList();
  }

  /// Get ended recurring transactions
  Future<List<RecurringTransaction>> getEndedRecurringTransactions(String userId) async {
    final allTransactions = await getRecurringTransactions(userId);
    return allTransactions.where((rt) => rt.hasEnded()).toList();
  }

  /// Preview next execution dates for a recurring transaction
  List<DateTime> previewNextExecutions(RecurringTransaction recurringTransaction, int count) {
    final dates = <DateTime>[];
    DateTime currentDate = recurringTransaction.nextExecution ?? 
                          recurringTransaction.calculateNextExecution();

    for (int i = 0; i < count; i++) {
      dates.add(currentDate);
      currentDate = recurringTransaction.calculateNextExecution(currentDate);
      
      // Stop if we've reached the end date or max executions
      if (recurringTransaction.endDate != null && currentDate.isAfter(recurringTransaction.endDate!)) {
        break;
      }
      if (recurringTransaction.maxExecutions != null && 
          recurringTransaction.executionCount + i + 1 >= recurringTransaction.maxExecutions!) {
        break;
      }
    }

    return dates;
  }

  /// Validate recurring transaction data
  String? validateRecurringTransactionData({
    required String templateName,
    required double amount,
    required String transactionType,
    required String frequency,
    required int interval,
    required DateTime startDate,
    DateTime? endDate,
    int? maxExecutions,
    int? dayOfMonth,
    int? dayOfWeek,
    bool isInternalTransfer = false,
    String? counterpartyAccountId,
  }) {
    if (templateName.trim().isEmpty) {
      return 'Template name is required';
    }
    if (templateName.trim().length < 3) {
      return 'Template name must be at least 3 characters';
    }
    if (amount <= 0) {
      return 'Amount must be greater than 0';
    }
    if (amount > 999999999) {
      return 'Amount cannot exceed 999,999,999 ETB';
    }
    if (!['Income/Credit', 'Expense/Debit'].contains(transactionType)) {
      return 'Invalid transaction type';
    }
    if (!['daily', 'weekly', 'monthly', 'yearly'].contains(frequency.toLowerCase())) {
      return 'Invalid frequency';
    }
    if (interval < 1 || interval > 365) {
      return 'Interval must be between 1 and 365';
    }
    if (endDate != null && endDate.isBefore(startDate)) {
      return 'End date cannot be before start date';
    }
    if (maxExecutions != null && maxExecutions < 1) {
      return 'Max executions must be at least 1';
    }
    if (frequency.toLowerCase() == 'monthly' && dayOfMonth != null) {
      if (dayOfMonth < 1 || dayOfMonth > 31) {
        return 'Day of month must be between 1 and 31';
      }
    }
    if (frequency.toLowerCase() == 'weekly' && dayOfWeek != null) {
      if (dayOfWeek < 1 || dayOfWeek > 7) {
        return 'Day of week must be between 1 and 7';
      }
    }
    if (isInternalTransfer && counterpartyAccountId == null) {
      return 'Destination account is required for internal transfers';
    }
    
    return null;
  }
}