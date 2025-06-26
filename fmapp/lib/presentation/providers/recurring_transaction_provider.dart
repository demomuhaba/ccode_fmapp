import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/recurring_transaction.dart';
import '../../domain/usecases/recurring_transaction_usecases.dart';

class RecurringTransactionState {
  final List<RecurringTransaction> recurringTransactions;
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? stats;

  const RecurringTransactionState({
    this.recurringTransactions = const [],
    this.isLoading = false,
    this.error,
    this.stats,
  });

  RecurringTransactionState copyWith({
    List<RecurringTransaction>? recurringTransactions,
    bool? isLoading,
    String? error,
    Map<String, dynamic>? stats,
  }) {
    return RecurringTransactionState(
      recurringTransactions: recurringTransactions ?? this.recurringTransactions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      stats: stats ?? this.stats,
    );
  }
}

class RecurringTransactionNotifier extends StateNotifier<RecurringTransactionState> {
  final RecurringTransactionUsecases _usecases;

  RecurringTransactionNotifier(this._usecases) : super(const RecurringTransactionState());

  /// Load all recurring transactions for a user
  Future<void> loadRecurringTransactions(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final recurringTransactions = await _usecases.getRecurringTransactions(userId);
      final stats = await _usecases.getRecurringTransactionStats(userId);
      
      state = state.copyWith(
        recurringTransactions: recurringTransactions,
        stats: stats,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Create a new recurring transaction
  Future<bool> createRecurringTransaction({
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
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Validate the data first
      final validationError = _usecases.validateRecurringTransactionData(
        templateName: templateName,
        amount: amount,
        transactionType: transactionType,
        frequency: frequency,
        interval: interval,
        startDate: startDate,
        endDate: endDate,
        maxExecutions: maxExecutions,
        dayOfMonth: dayOfMonth,
        dayOfWeek: dayOfWeek,
        isInternalTransfer: isInternalTransfer,
        counterpartyAccountId: counterpartyAccountId,
      );

      if (validationError != null) {
        state = state.copyWith(isLoading: false, error: validationError);
        return false;
      }

      final id = await _usecases.createRecurringTransaction(
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
        maxExecutions: maxExecutions,
        dayOfMonth: dayOfMonth,
        dayOfWeek: dayOfWeek,
        tags: tags,
      );

      if (id.isNotEmpty) {
        // Reload the list to include the new recurring transaction
        await loadRecurringTransactions(userId);
        return true;
      } else {
        state = state.copyWith(isLoading: false, error: 'Failed to create recurring transaction');
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Update an existing recurring transaction
  Future<bool> updateRecurringTransaction(RecurringTransaction recurringTransaction) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final success = await _usecases.updateRecurringTransaction(recurringTransaction);
      
      if (success) {
        // Update the local state
        final updatedList = state.recurringTransactions.map((rt) {
          return rt.id == recurringTransaction.id ? recurringTransaction : rt;
        }).toList();
        
        state = state.copyWith(
          recurringTransactions: updatedList,
          isLoading: false,
        );
        
        return true;
      } else {
        state = state.copyWith(isLoading: false, error: 'Failed to update recurring transaction');
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Delete a recurring transaction
  Future<bool> deleteRecurringTransaction(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final success = await _usecases.deleteRecurringTransaction(id);
      
      if (success) {
        // Remove from local state
        final updatedList = state.recurringTransactions.where((rt) => rt.id != id).toList();
        state = state.copyWith(
          recurringTransactions: updatedList,
          isLoading: false,
        );
        
        return true;
      } else {
        state = state.copyWith(isLoading: false, error: 'Failed to delete recurring transaction');
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Toggle active status of a recurring transaction
  Future<bool> toggleActiveStatus(String id, bool isActive) async {
    try {
      final success = await _usecases.toggleActiveStatus(id, isActive);
      
      if (success) {
        // Update local state
        final updatedList = state.recurringTransactions.map((rt) {
          return rt.id == id ? rt.copyWith(isActive: isActive) : rt;
        }).toList();
        
        state = state.copyWith(recurringTransactions: updatedList);
        return true;
      }
      
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Execute a specific recurring transaction
  Future<bool> executeRecurringTransaction(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final success = await _usecases.executeRecurringTransaction(id);
      
      if (success) {
        // Update the execution count and last executed date in local state
        final updatedList = state.recurringTransactions.map((rt) {
          if (rt.id == id) {
            final now = DateTime.now();
            return rt.copyWith(
              lastExecuted: now,
              nextExecution: rt.calculateNextExecution(now),
              executionCount: rt.executionCount + 1,
            );
          }
          return rt;
        }).toList();
        
        state = state.copyWith(
          recurringTransactions: updatedList,
          isLoading: false,
        );
        
        return true;
      } else {
        state = state.copyWith(isLoading: false, error: 'Failed to execute recurring transaction');
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Execute all due recurring transactions
  Future<Map<String, dynamic>> executeAllDueRecurringTransactions(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final result = await _usecases.executeAllDueRecurringTransactions(userId);
      
      // Reload the recurring transactions to get updated execution counts
      await loadRecurringTransactions(userId);
      
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return {
        'total_due': 0,
        'success_count': 0,
        'failure_count': 1,
        'failed_transactions': [e.toString()],
      };
    }
  }

  /// Get due recurring transactions
  List<RecurringTransaction> getDueRecurringTransactions() {
    return state.recurringTransactions.where((rt) => rt.shouldExecute()).toList();
  }

  /// Get active recurring transactions
  List<RecurringTransaction> getActiveRecurringTransactions() {
    return state.recurringTransactions.where((rt) => rt.isActive && !rt.hasEnded()).toList();
  }

  /// Get paused recurring transactions
  List<RecurringTransaction> getPausedRecurringTransactions() {
    return state.recurringTransactions.where((rt) => !rt.isActive).toList();
  }

  /// Get ended recurring transactions
  List<RecurringTransaction> getEndedRecurringTransactions() {
    return state.recurringTransactions.where((rt) => rt.hasEnded()).toList();
  }

  /// Preview next execution dates
  List<DateTime> previewNextExecutions(String id, int count) {
    final recurringTransaction = state.recurringTransactions.firstWhere((rt) => rt.id == id);
    return _usecases.previewNextExecutions(recurringTransaction, count);
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Search recurring transactions by name
  List<RecurringTransaction> searchRecurringTransactions(String query) {
    if (query.trim().isEmpty) {
      return state.recurringTransactions;
    }
    
    final lowerQuery = query.toLowerCase();
    return state.recurringTransactions.where((rt) {
      return rt.templateName.toLowerCase().contains(lowerQuery) ||
             (rt.descriptionNotes?.toLowerCase().contains(lowerQuery) ?? false) ||
             rt.frequency.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Filter recurring transactions by frequency
  List<RecurringTransaction> filterByFrequency(String frequency) {
    return state.recurringTransactions.where((rt) => rt.frequency.toLowerCase() == frequency.toLowerCase()).toList();
  }

  /// Filter recurring transactions by account
  List<RecurringTransaction> filterByAccount(String accountId) {
    return state.recurringTransactions.where((rt) => rt.affectedAccountId == accountId).toList();
  }
}