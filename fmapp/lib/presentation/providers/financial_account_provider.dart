import 'package:flutter/foundation.dart';
import '../../domain/entities/financial_account_record.dart';
import '../../domain/usecases/financial_account_usecases.dart';

class FinancialAccountProvider extends ChangeNotifier {
  final FinancialAccountUseCases _accountUseCases;

  FinancialAccountProvider(this._accountUseCases);

  List<FinancialAccountRecord> _accounts = [];
  Map<String, double> _accountBalances = {};
  bool _isLoading = false;
  String? _error;

  List<FinancialAccountRecord> get accounts => _accounts;
  Map<String, double> get accountBalances => _accountBalances;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadAccounts(String userId) async {
    _setLoading(true);
    try {
      _accounts = await _accountUseCases.getAllAccounts(userId);
      _accountBalances = await _accountUseCases.getAllBalances(userId);
      _clearError();
    } catch (e) {
      _setError('Failed to load accounts: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshBalances(String userId) async {
    try {
      _accountBalances = await _accountUseCases.getAllBalances(userId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to refresh balances: $e');
    }
  }

  Future<bool> createAccount({
    required String userId,
    required String accountName,
    required String accountIdentifier,
    required String accountType,
    required String linkedSimId,
    required double initialBalance,
  }) async {
    _setLoading(true);
    try {
      final newAccount = await _accountUseCases.createAccount(
        userId: userId,
        accountName: accountName,
        accountIdentifier: accountIdentifier,
        accountType: accountType,
        linkedSimId: linkedSimId,
        initialBalance: initialBalance,
      );
      
      _accounts.add(newAccount);
      _accountBalances[newAccount.id] = initialBalance;
      _clearError();
      return true;
    } catch (e) {
      _setError('Failed to create account: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateAccount(FinancialAccountRecord account) async {
    _setLoading(true);
    try {
      final updatedAccount = await _accountUseCases.updateAccount(account);
      
      final index = _accounts.indexWhere((a) => a.id == updatedAccount.id);
      if (index != -1) {
        _accounts[index] = updatedAccount;
      }
      
      _clearError();
      return true;
    } catch (e) {
      _setError('Failed to update account: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteAccount(String id) async {
    _setLoading(true);
    try {
      await _accountUseCases.deleteAccount(id);
      
      _accounts.removeWhere((a) => a.id == id);
      _accountBalances.remove(id);
      
      _clearError();
      return true;
    } catch (e) {
      _setError('Failed to delete account: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  List<FinancialAccountRecord> getAccountsBySimId(String simId) {
    return _accounts.where((a) => a.linkedSimId == simId).toList();
  }

  FinancialAccountRecord? getAccountById(String id) {
    try {
      return _accounts.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  double getAccountBalance(String accountId) {
    return _accountBalances[accountId] ?? 0.0;
  }

  double getTotalBalance() {
    return _accountBalances.values.fold(0.0, (sum, balance) => sum + balance);
  }

  Future<Map<String, dynamic>> getAccountSummary(String userId) async {
    try {
      return await _accountUseCases.getAccountSummary(userId);
    } catch (e) {
      _setError('Failed to get account summary: $e');
      return {};
    }
  }

  List<FinancialAccountRecord> getAccountsByType(String accountType) {
    return _accounts.where((a) => a.accountType == accountType).toList();
  }

  List<String> getValidAccountTypes() {
    return ['Bank Account', 'Mobile Wallet', 'Online Money'];
  }

  bool isOnlineMoneyAccount(String accountId) {
    final account = getAccountById(accountId);
    return account?.accountType.toLowerCase() == 'online money';
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