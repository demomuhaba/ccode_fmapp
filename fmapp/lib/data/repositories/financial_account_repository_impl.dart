import '../../domain/entities/financial_account_record.dart';
import '../../domain/repositories/financial_account_repository.dart';
import '../../services/supabase_service.dart';
import '../models/financial_account_record_model.dart';

class FinancialAccountRepositoryImpl implements FinancialAccountRepository {
  final SupabaseService _supabaseService;

  FinancialAccountRepositoryImpl(this._supabaseService);

  @override
  Future<List<FinancialAccountRecord>> getAllAccounts(String userId) async {
    try {
      final data = await _supabaseService.getAllRecords(
        table: 'financial_account_records',
      );
      return data.map((json) => FinancialAccountRecordModel.fromJson(json).toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to get financial accounts: $e');
    }
  }

  @override
  Future<FinancialAccountRecord?> getAccountById(String id) async {
    try {
      final data = await _supabaseService.getRecordById(table: 'financial_account_records', id: id);
      if (data == null) return null;
      return FinancialAccountRecordModel.fromJson(data).toEntity();
    } catch (e) {
      throw Exception('Failed to get financial account: $e');
    }
  }

  @override
  Future<FinancialAccountRecord> createAccount(FinancialAccountRecord account) async {
    try {
      final model = FinancialAccountRecordModel.fromEntity(account);
      final data = await _supabaseService.createRecord(table: 'financial_account_records', data: model.toJsonForInsert());
      return FinancialAccountRecordModel.fromJson(data).toEntity();
    } catch (e) {
      throw Exception('Failed to create financial account: $e');
    }
  }

  @override
  Future<FinancialAccountRecord> updateAccount(FinancialAccountRecord account) async {
    try {
      final model = FinancialAccountRecordModel.fromEntity(account);
      final data = await _supabaseService.updateRecord(table: 'financial_account_records', id: model.id, data: model.toJsonForInsert());
      return FinancialAccountRecordModel.fromJson(data).toEntity();
    } catch (e) {
      throw Exception('Failed to update financial account: $e');
    }
  }

  @override
  Future<void> deleteAccount(String id) async {
    try {
      await _supabaseService.deleteRecord(table: 'financial_account_records', id: id);
    } catch (e) {
      throw Exception('Failed to delete financial account: $e');
    }
  }

  @override
  Future<List<FinancialAccountRecord>> getAccountsBySimId(String simId) async {
    try {
      final data = await _supabaseService.getRecordsByCondition(
        table: 'financial_account_records',
        conditions: {'linked_sim_id': simId},
      );
      return data.map((json) => FinancialAccountRecordModel.fromJson(json).toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to get accounts by SIM ID: $e');
    }
  }

  @override
  Future<double> calculateCurrentBalance(String accountId) async {
    try {
      return await _supabaseService.calculateAccountBalance(accountId);
    } catch (e) {
      throw Exception('Failed to calculate current balance: $e');
    }
  }

  @override
  Future<Map<String, double>> calculateAllBalances(String userId) async {
    try {
      return await _supabaseService.calculateAllAccountBalances();
    } catch (e) {
      throw Exception('Failed to calculate all balances: $e');
    }
  }

  @override
  Future<double> getSimTotalBalance(String simId) async {
    try {
      return await _supabaseService.calculateSimTotalBalance(simId);
    } catch (e) {
      throw Exception('Failed to get SIM total balance: $e');
    }
  }
}