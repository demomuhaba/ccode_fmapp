import 'package:uuid/uuid.dart';
import '../entities/financial_account_record.dart';
import '../repositories/financial_account_repository.dart';
import '../repositories/sim_card_repository.dart';
import '../repositories/transaction_repository.dart';

class FinancialAccountUseCases {
  final FinancialAccountRepository _accountRepository;
  final SimCardRepository _simCardRepository;
  final TransactionRepository _transactionRepository;
  final Uuid _uuid = const Uuid();

  FinancialAccountUseCases(
    this._accountRepository,
    this._simCardRepository,
    this._transactionRepository,
  );

  Future<List<FinancialAccountRecord>> getAllAccounts(String userId) async {
    try {
      return await _accountRepository.getAllAccounts(userId);
    } catch (e) {
      throw Exception('Failed to get financial accounts: $e');
    }
  }

  Future<FinancialAccountRecord?> getAccountById(String id) async {
    try {
      return await _accountRepository.getAccountById(id);
    } catch (e) {
      throw Exception('Failed to get financial account: $e');
    }
  }

  Future<FinancialAccountRecord> createAccount({
    required String userId,
    required String accountName,
    required String accountIdentifier,
    required String accountType,
    required String linkedSimId,
    required double initialBalance,
  }) async {
    try {
      final simCard = await _simCardRepository.getSimCardById(linkedSimId);
      if (simCard == null) {
        throw Exception('SIM card not found');
      }

      if (simCard.userId != userId) {
        throw Exception('SIM card does not belong to user');
      }

      final account = FinancialAccountRecord(
        id: _uuid.v4(),
        userId: userId,
        accountName: accountName,
        accountIdentifier: accountIdentifier,
        accountType: accountType,
        linkedSimId: linkedSimId,
        initialBalance: initialBalance,
        dateAdded: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return await _accountRepository.createAccount(account);
    } catch (e) {
      throw Exception('Failed to create financial account: $e');
    }
  }

  Future<FinancialAccountRecord> updateAccount(FinancialAccountRecord account) async {
    try {
      final updatedAccount = account.copyWith(updatedAt: DateTime.now());
      return await _accountRepository.updateAccount(updatedAccount);
    } catch (e) {
      throw Exception('Failed to update financial account: $e');
    }
  }

  Future<void> deleteAccount(String id) async {
    try {
      final transactions = await _transactionRepository.getTransactionsByAccount(id);
      if (transactions.isNotEmpty) {
        throw Exception('Cannot delete account with transaction history');
      }

      await _accountRepository.deleteAccount(id);
    } catch (e) {
      throw Exception('Failed to delete financial account: $e');
    }
  }

  Future<List<FinancialAccountRecord>> getAccountsBySimId(String simId) async {
    try {
      return await _accountRepository.getAccountsBySimId(simId);
    } catch (e) {
      throw Exception('Failed to get accounts by SIM ID: $e');
    }
  }

  Future<double> getCurrentBalance(String accountId) async {
    try {
      return await _accountRepository.calculateCurrentBalance(accountId);
    } catch (e) {
      throw Exception('Failed to get current balance: $e');
    }
  }

  Future<Map<String, double>> getAllBalances(String userId) async {
    try {
      return await _accountRepository.calculateAllBalances(userId);
    } catch (e) {
      throw Exception('Failed to get all balances: $e');
    }
  }

  Future<double> getSimTotalBalance(String simId) async {
    try {
      return await _accountRepository.getSimTotalBalance(simId);
    } catch (e) {
      throw Exception('Failed to get SIM total balance: $e');
    }
  }

  Future<Map<String, dynamic>> getAccountSummary(String userId) async {
    try {
      final accounts = await getAllAccounts(userId);
      final balances = await getAllBalances(userId);
      
      double totalBalance = 0.0;
      final accountsByType = <String, List<FinancialAccountRecord>>{};
      
      for (final account in accounts) {
        final balance = balances[account.id] ?? 0.0;
        totalBalance += balance;
        
        if (!accountsByType.containsKey(account.accountType)) {
          accountsByType[account.accountType] = [];
        }
        accountsByType[account.accountType]!.add(account);
      }

      return {
        'totalAccounts': accounts.length,
        'totalBalance': totalBalance,
        'accountsByType': accountsByType,
        'balances': balances,
      };
    } catch (e) {
      throw Exception('Failed to get account summary: $e');
    }
  }

  Future<bool> isOnlineMoneyAccount(String accountId) async {
    try {
      final account = await getAccountById(accountId);
      return account?.accountType.toLowerCase() == 'online money';
    } catch (e) {
      return false;
    }
  }

  Future<List<String>> getValidAccountTypes() async {
    return ['Bank Account', 'Mobile Wallet', 'Online Money'];
  }
}