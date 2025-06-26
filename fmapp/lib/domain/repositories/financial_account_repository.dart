import '../entities/financial_account_record.dart';

abstract class FinancialAccountRepository {
  Future<List<FinancialAccountRecord>> getAllAccounts(String userId);
  Future<FinancialAccountRecord?> getAccountById(String id);
  Future<FinancialAccountRecord> createAccount(FinancialAccountRecord account);
  Future<FinancialAccountRecord> updateAccount(FinancialAccountRecord account);
  Future<void> deleteAccount(String id);
  Future<List<FinancialAccountRecord>> getAccountsBySimId(String simId);
  Future<double> calculateCurrentBalance(String accountId);
  Future<Map<String, double>> calculateAllBalances(String userId);
  Future<double> getSimTotalBalance(String simId);
}