import 'package:uuid/uuid.dart';
import '../../domain/entities/recurring_transaction.dart';
import '../../domain/repositories/recurring_transaction_repository.dart';
import '../models/recurring_transaction_model.dart';
import '../../services/supabase_service.dart';

class RecurringTransactionRepositoryImpl implements RecurringTransactionRepository {
  final SupabaseService _supabaseService;
  final String _tableName = 'recurring_transactions';

  RecurringTransactionRepositoryImpl(this._supabaseService);

  @override
  Future<List<RecurringTransaction>> getRecurringTransactions(String userId) async {
    try {
      final data = await _supabaseService.getAllRecords(
        table: _tableName,
        orderBy: 'created_at',
        ascending: false, // Latest first
      );

      return data.map((json) => RecurringTransactionModel.fromJson(json).toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to get recurring transactions: $e');
    }
  }

  @override
  Future<RecurringTransaction?> getRecurringTransactionById(String id) async {
    try {
      final data = await _supabaseService.getRecordById(
        table: _tableName,
        id: id,
      );
      if (data == null) return null;
      
      return RecurringTransactionModel.fromJson(data).toEntity();
    } catch (e) {
      throw Exception('Failed to get recurring transaction: $e');
    }
  }

  @override
  Future<List<RecurringTransaction>> getRecurringTransactionsDue(String userId, DateTime currentDate) async {
    try {
      final data = await _supabaseService.getRecordsByCondition(
        table: _tableName,
        conditions: {
          'is_active': true,
        },
      );

      final recurringTransactions = data
          .map((json) => RecurringTransactionModel.fromJson(json).toEntity())
          .where((rt) => rt.shouldExecute(currentDate))
          .toList();

      return recurringTransactions;
    } catch (e) {
      throw Exception('Failed to get due recurring transactions: $e');
    }
  }

  @override
  Future<String> createRecurringTransaction(RecurringTransaction recurringTransaction) async {
    try {
      final id = const Uuid().v4();
      final now = DateTime.now();
      
      final model = RecurringTransactionModel.fromEntity(recurringTransaction.copyWith(
        id: id,
        nextExecution: recurringTransaction.calculateNextExecution(),
      ));

      // Validate the model
      final validationError = model.validate();
      if (validationError != null) {
        throw Exception('Validation failed: $validationError');
      }

      final data = model.toJson()
        ..['created_at'] = now.toIso8601String()
        ..['updated_at'] = now.toIso8601String();

      await _supabaseService.createRecord(table: _tableName, data: data);
      return id;
    } catch (e) {
      throw Exception('Failed to create recurring transaction: $e');
    }
  }

  @override
  Future<bool> updateRecurringTransaction(RecurringTransaction recurringTransaction) async {
    try {
      final model = RecurringTransactionModel.fromEntity(recurringTransaction);
      
      // Validate the model
      final validationError = model.validate();
      if (validationError != null) {
        throw Exception('Validation failed: $validationError');
      }

      final data = model.toJson()
        ..['updated_at'] = DateTime.now().toIso8601String();

      await _supabaseService.updateRecord(table: _tableName, id: recurringTransaction.id, data: data);
      return true;
    } catch (e) {
      throw Exception('Failed to update recurring transaction: $e');
    }
  }

  @override
  Future<bool> deleteRecurringTransaction(String id) async {
    try {
      await _supabaseService.deleteRecord(table: _tableName, id: id);
      return true;
    } catch (e) {
      throw Exception('Failed to delete recurring transaction: $e');
    }
  }

  @override
  Future<bool> markAsExecuted(String id, DateTime executionDate) async {
    try {
      final recurringTransaction = await getRecurringTransactionById(id);
      if (recurringTransaction == null) {
        throw Exception('Recurring transaction not found');
      }

      final updatedTransaction = recurringTransaction.copyWith(
        lastExecuted: executionDate,
        nextExecution: recurringTransaction.calculateNextExecution(executionDate),
        executionCount: recurringTransaction.executionCount + 1,
      );

      return await updateRecurringTransaction(updatedTransaction);
    } catch (e) {
      throw Exception('Failed to mark recurring transaction as executed: $e');
    }
  }

  @override
  Future<bool> toggleActive(String id, bool isActive) async {
    try {
      final data = {
        'is_active': isActive,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabaseService.updateRecord(table: _tableName, id: id, data: data);
      return true;
    } catch (e) {
      throw Exception('Failed to toggle recurring transaction active status: $e');
    }
  }

  @override
  Future<List<RecurringTransaction>> getRecurringTransactionsByFrequency(String userId, String frequency) async {
    try {
      final data = await _supabaseService.getRecordsByCondition(
        table: _tableName,
        conditions: {
          'frequency': frequency.toLowerCase(),
        },
        orderBy: 'template_name',
        ascending: true,
      );

      return data.map((json) => RecurringTransactionModel.fromJson(json).toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to get recurring transactions by frequency: $e');
    }
  }

  @override
  Future<List<RecurringTransaction>> getRecurringTransactionsByAccount(String userId, String accountId) async {
    try {
      final data = await _supabaseService.getRecordsByCondition(
        table: _tableName,
        conditions: {
          'affected_account_id': accountId,
        },
        orderBy: 'template_name',
        ascending: true,
      );

      return data.map((json) => RecurringTransactionModel.fromJson(json).toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to get recurring transactions by account: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getRecurringTransactionStats(String userId) async {
    try {
      final data = await _supabaseService.getAllRecords(
        table: _tableName,
      );

      final recurringTransactions = data.map((json) => RecurringTransactionModel.fromJson(json).toEntity()).toList();
      
      final stats = {
        'total': recurringTransactions.length,
        'active': recurringTransactions.where((rt) => rt.isActive).length,
        'paused': recurringTransactions.where((rt) => !rt.isActive).length,
        'ended': recurringTransactions.where((rt) => rt.hasEnded()).length,
        'due_today': recurringTransactions.where((rt) => rt.shouldExecute()).length,
        'by_frequency': <String, int>{},
        'total_monthly_amount': 0.0,
      };

      // Calculate frequency breakdown
      for (final rt in recurringTransactions) {
        final freq = rt.frequencyDisplayName;
        stats['by_frequency'][freq] = (stats['by_frequency'][freq] ?? 0) + 1;
      }

      // Calculate estimated monthly amount
      double monthlyAmount = 0.0;
      for (final rt in recurringTransactions.where((rt) => rt.isActive && !rt.hasEnded())) {
        switch (rt.frequency.toLowerCase()) {
          case 'daily':
            monthlyAmount += rt.amount * 30 / rt.interval;
            break;
          case 'weekly':
            monthlyAmount += rt.amount * 4.3 / rt.interval; // 4.3 weeks per month
            break;
          case 'monthly':
            monthlyAmount += rt.amount / rt.interval;
            break;
          case 'yearly':
            monthlyAmount += rt.amount / (12 * rt.interval);
            break;
        }
      }
      stats['total_monthly_amount'] = monthlyAmount;

      return stats;
    } catch (e) {
      throw Exception('Failed to get recurring transaction stats: $e');
    }
  }
}