import '../../domain/entities/transaction_record.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../services/supabase_service.dart';
import '../models/transaction_record_model.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final SupabaseService _supabaseService;

  TransactionRepositoryImpl(this._supabaseService);

  @override
  Future<List<TransactionRecord>> getAllTransactions(String userId) async {
    try {
      final data = await _supabaseService.getRecordsByCondition(
        table: 'transaction_records',
        conditions: {'user_id': userId},
      );
      return data.map((json) => TransactionRecordModel.fromJson(json).toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to get transactions: $e');
    }
  }

  @override
  Future<TransactionRecord?> getTransactionById(String id) async {
    try {
      final data = await _supabaseService.getRecordById(table: 'transaction_records', id: id);
      if (data == null) return null;
      return TransactionRecordModel.fromJson(data).toEntity();
    } catch (e) {
      throw Exception('Failed to get transaction: $e');
    }
  }

  @override
  Future<TransactionRecord> createTransaction(TransactionRecord transaction) async {
    try {
      final model = TransactionRecordModel.fromEntity(transaction);
      final data = await _supabaseService.createRecord(table: 'transaction_records', data: model.toJsonForInsert());
      return TransactionRecordModel.fromJson(data).toEntity();
    } catch (e) {
      throw Exception('Failed to create transaction: $e');
    }
  }

  @override
  Future<TransactionRecord> updateTransaction(TransactionRecord transaction) async {
    try {
      final model = TransactionRecordModel.fromEntity(transaction);
      final data = await _supabaseService.updateRecord(table: 'transaction_records', id: model.id, data: model.toJsonForInsert());
      return TransactionRecordModel.fromJson(data).toEntity();
    } catch (e) {
      throw Exception('Failed to update transaction: $e');
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    try {
      await _supabaseService.deleteRecord(table: 'transaction_records', id: id);
    } catch (e) {
      throw Exception('Failed to delete transaction: $e');
    }
  }

  @override
  Future<List<TransactionRecord>> getTransactionsByAccount(String accountId) async {
    try {
      final data = await _supabaseService.getRecordsByCondition(
        table: 'transaction_records',
        conditions: {'affected_account_id': accountId},
      );
      return data.map((json) => TransactionRecordModel.fromJson(json).toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to get transactions by account: $e');
    }
  }

  @override
  Future<List<TransactionRecord>> getTransactionsByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final data = await _supabaseService.getRecordsByCondition(
        table: 'transaction_records',
        conditions: {'user_id': userId},
      );
      // Filter by date range in the application layer
      final filteredData = data.where((item) {
        final transactionDate = DateTime.parse(item['transaction_date']);
        return transactionDate.isAfter(startDate.subtract(Duration(days: 1))) &&
               transactionDate.isBefore(endDate.add(Duration(days: 1)));
      }).toList();
      return filteredData.map((json) => TransactionRecordModel.fromJson(json).toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to get transactions by date range: $e');
    }
  }

  @override
  Future<List<TransactionRecord>> getRecentTransactions(String userId, {int limit = 10}) async {
    try {
      final data = await _supabaseService.getRecordsByCondition(
        table: 'transaction_records',
        conditions: {'user_id': userId},
      );
      // Sort and limit in the application layer
      data.sort((a, b) => DateTime.parse(b['transaction_date']).compareTo(DateTime.parse(a['transaction_date'])));
      final limitedData = data.take(limit).toList();
      return limitedData.map((json) => TransactionRecordModel.fromJson(json).toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to get recent transactions: $e');
    }
  }

  @override
  Future<List<TransactionRecord>> getInternalTransfers(String userId) async {
    try {
      final data = await _supabaseService.getRecordsByCondition(
        table: 'transaction_records',
        conditions: {'is_internal_transfer': true, 'user_id': userId},
      );
      return data.map((json) => TransactionRecordModel.fromJson(json).toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to get internal transfers: $e');
    }
  }

  @override
  Future<double> getTotalIncomeForAccount(
    String accountId,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    try {
      List<Map<String, dynamic>> data;
      
      if (startDate != null && endDate != null) {
        data = await _supabaseService.getRecordsByCondition(
          table: 'transaction_records',
          conditions: {'affected_account_id': accountId},
        );
        data = data.where((item) {
          final transactionDate = DateTime.parse(item['transaction_date']);
          return transactionDate.isAfter(startDate.subtract(Duration(days: 1))) &&
                 transactionDate.isBefore(endDate.add(Duration(days: 1)));
        }).toList();
      } else {
        data = await _supabaseService.getRecordsByCondition(
          table: 'transaction_records',
          conditions: {'affected_account_id': accountId},
        );
      }

      double total = 0.0;
      for (final item in data) {
        final transactionType = item['transaction_type'] as String;
        if (transactionType.toLowerCase().contains('income') || 
            transactionType.toLowerCase().contains('credit')) {
          total += (item['amount'] as num).toDouble();
        }
      }
      
      return total;
    } catch (e) {
      throw Exception('Failed to get total income: $e');
    }
  }

  @override
  Future<double> getTotalExpenseForAccount(
    String accountId,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    try {
      List<Map<String, dynamic>> data;
      
      if (startDate != null && endDate != null) {
        data = await _supabaseService.getRecordsByCondition(
          table: 'transaction_records',
          conditions: {'affected_account_id': accountId},
        );
        data = data.where((item) {
          final transactionDate = DateTime.parse(item['transaction_date']);
          return transactionDate.isAfter(startDate.subtract(Duration(days: 1))) &&
                 transactionDate.isBefore(endDate.add(Duration(days: 1)));
        }).toList();
      } else {
        data = await _supabaseService.getRecordsByCondition(
          table: 'transaction_records',
          conditions: {'affected_account_id': accountId},
        );
      }

      double total = 0.0;
      for (final item in data) {
        final transactionType = item['transaction_type'] as String;
        if (transactionType.toLowerCase().contains('expense') || 
            transactionType.toLowerCase().contains('debit')) {
          total += (item['amount'] as num).toDouble();
        }
      }
      
      return total;
    } catch (e) {
      throw Exception('Failed to get total expense: $e');
    }
  }
}