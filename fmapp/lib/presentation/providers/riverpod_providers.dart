import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/sim_card_record.dart';
import '../../domain/entities/financial_account_record.dart';
import '../../domain/entities/transaction_record.dart';
import '../../domain/entities/friend_record.dart';
import '../../domain/entities/loan_debt_item.dart';
import '../../domain/entities/recurring_transaction.dart';
import '../../domain/usecases/auth_usecases.dart';
import '../../domain/usecases/sim_card_usecases.dart';
import '../../domain/usecases/financial_account_usecases.dart';
import '../../domain/usecases/transaction_usecases.dart';
import '../../domain/usecases/friend_usecases.dart';
import '../../domain/usecases/loan_debt_usecases.dart';
import '../../domain/usecases/recurring_transaction_usecases.dart';
import '../../services/supabase_service.dart';
import '../../services/isar_service.dart';
import '../../services/ocr_service.dart';
import '../../services/security_service.dart';
import '../../data/repositories/user_profile_repository_impl.dart';
import '../../data/repositories/sim_card_repository_impl.dart';
import '../../data/repositories/financial_account_repository_hybrid.dart';
import '../../data/repositories/transaction_repository_hybrid.dart';
import '../../data/repositories/friend_repository_impl.dart';
import '../../data/repositories/loan_debt_repository_impl.dart';
import '../../data/repositories/recurring_transaction_repository_impl.dart';
import './recurring_transaction_provider.dart';

// Service Providers
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService.instance;
});

final isarServiceProvider = Provider<IsarService>((ref) {
  return IsarService.instance;
});

final ocrServiceProvider = Provider<OCRService>((ref) {
  return OCRService();
});

final securityServiceProvider = Provider<SecurityService>((ref) {
  return SecurityService();
});

// Repository Providers
final userProfileRepositoryProvider = Provider((ref) {
  final supabaseService = ref.read(supabaseServiceProvider);
  return UserProfileRepositoryImpl(supabaseService);
});

final simCardRepositoryProvider = Provider((ref) {
  final supabaseService = ref.read(supabaseServiceProvider);
  return SimCardRepositoryImpl(supabaseService);
});

final financialAccountRepositoryProvider = Provider((ref) {
  final supabaseService = ref.read(supabaseServiceProvider);
  final isarService = ref.read(isarServiceProvider);
  return FinancialAccountRepositoryHybrid(supabaseService, isarService);
});

final transactionRepositoryProvider = Provider((ref) {
  final supabaseService = ref.read(supabaseServiceProvider);
  final isarService = ref.read(isarServiceProvider);
  return TransactionRepositoryHybrid(supabaseService, isarService);
});

final friendRepositoryProvider = Provider((ref) {
  final supabaseService = ref.read(supabaseServiceProvider);
  return FriendRepositoryImpl(supabaseService);
});

final loanDebtRepositoryProvider = Provider((ref) {
  final supabaseService = ref.read(supabaseServiceProvider);
  return LoanDebtRepositoryImpl(supabaseService);
});

final recurringTransactionRepositoryProvider = Provider((ref) {
  final supabaseService = ref.read(supabaseServiceProvider);
  return RecurringTransactionRepositoryImpl(supabaseService);
});

// Use Case Providers
final authUseCasesProvider = Provider((ref) {
  final supabaseService = ref.read(supabaseServiceProvider);
  final userProfileRepository = ref.read(userProfileRepositoryProvider);
  return AuthUseCases(supabaseService, userProfileRepository);
});

final simCardUseCasesProvider = Provider((ref) {
  final simCardRepository = ref.read(simCardRepositoryProvider);
  final accountRepository = ref.read(financialAccountRepositoryProvider);
  return SimCardUseCases(simCardRepository, accountRepository);
});

final financialAccountUseCasesProvider = Provider((ref) {
  final accountRepository = ref.read(financialAccountRepositoryProvider);
  final simCardRepository = ref.read(simCardRepositoryProvider);
  final transactionRepository = ref.read(transactionRepositoryProvider);
  return FinancialAccountUseCases(accountRepository, simCardRepository, transactionRepository);
});

final transactionUseCasesProvider = Provider((ref) {
  final transactionRepository = ref.read(transactionRepositoryProvider);
  final accountRepository = ref.read(financialAccountRepositoryProvider);
  return TransactionUseCases(transactionRepository, accountRepository);
});

final friendUseCasesProvider = Provider((ref) {
  final friendRepository = ref.read(friendRepositoryProvider);
  final loanDebtRepository = ref.read(loanDebtRepositoryProvider);
  return FriendUseCases(friendRepository, loanDebtRepository);
});

final loanDebtUseCasesProvider = Provider((ref) {
  final loanDebtRepository = ref.read(loanDebtRepositoryProvider);
  final friendRepository = ref.read(friendRepositoryProvider);
  final accountRepository = ref.read(financialAccountRepositoryProvider);
  final transactionUseCases = ref.read(transactionUseCasesProvider);
  return LoanDebtUseCases(loanDebtRepository, friendRepository, accountRepository, transactionUseCases);
});

final recurringTransactionUseCasesProvider = Provider((ref) {
  final recurringTransactionRepository = ref.read(recurringTransactionRepositoryProvider);
  final transactionRepository = ref.read(transactionRepositoryProvider);
  return RecurringTransactionUsecases(recurringTransactionRepository, transactionRepository);
});

// State Providers
class AuthState {
  final UserProfile? userProfile;
  final bool isLoading;
  final String? error;
  final bool isSignedIn;

  const AuthState({
    this.userProfile,
    this.isLoading = false,
    this.error,
    this.isSignedIn = false,
  });

  AuthState copyWith({
    UserProfile? userProfile,
    bool? isLoading,
    String? error,
    bool? isSignedIn,
  }) {
    return AuthState(
      userProfile: userProfile ?? this.userProfile,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isSignedIn: isSignedIn ?? this.isSignedIn,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthUseCases _authUseCases;

  AuthNotifier(this._authUseCases) : super(const AuthState());

  Future<void> checkAuthStatus() async {
    state = state.copyWith(isLoading: true);
    try {
      final isSignedIn = await _authUseCases.isUserSignedIn();
      UserProfile? userProfile;
      if (isSignedIn) {
        userProfile = await _authUseCases.getCurrentUserProfile();
      }
      state = state.copyWith(
        isSignedIn: isSignedIn,
        userProfile: userProfile,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to check auth status: $e',
        isSignedIn: false,
        userProfile: null,
        isLoading: false,
      );
    }
  }

  Future<bool> signUp(String email, String password, String fullName) async {
    state = state.copyWith(isLoading: true);
    try {
      final result = await _authUseCases.signUp(email, password, fullName);
      
      if (result['user'] != null) {
        final userProfile = await _authUseCases.getCurrentUserProfile();
        state = state.copyWith(
          isSignedIn: true,
          userProfile: userProfile,
          error: null,
          isLoading: false,
        );
        return true;
      } else {
        state = state.copyWith(error: 'Sign up failed', isLoading: false);
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: 'Sign up failed: $e', isLoading: false);
      return false;
    }
  }

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true);
    try {
      final result = await _authUseCases.signIn(email, password);
      
      if (result['user'] != null) {
        final userProfile = await _authUseCases.getCurrentUserProfile();
        state = state.copyWith(
          isSignedIn: true,
          userProfile: userProfile,
          error: null,
          isLoading: false,
        );
        return true;
      } else {
        state = state.copyWith(error: 'Sign in failed', isLoading: false);
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: 'Sign in failed: $e', isLoading: false);
      return false;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    try {
      await _authUseCases.signOut();
      state = const AuthState();
    } catch (e) {
      state = state.copyWith(error: 'Sign out failed: $e', isLoading: false);
    }
  }

  Future<bool> resetPassword(String email) async {
    state = state.copyWith(isLoading: true);
    try {
      await _authUseCases.resetPassword(email);
      state = state.copyWith(error: null, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Password reset failed: $e', isLoading: false);
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authUseCases = ref.read(authUseCasesProvider);
  return AuthNotifier(authUseCases);
});

// SIM Card State
class SimCardState {
  final List<SimCardRecord> simCards;
  final bool isLoading;
  final String? error;

  const SimCardState({
    this.simCards = const [],
    this.isLoading = false,
    this.error,
  });

  SimCardState copyWith({
    List<SimCardRecord>? simCards,
    bool? isLoading,
    String? error,
  }) {
    return SimCardState(
      simCards: simCards ?? this.simCards,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class SimCardNotifier extends StateNotifier<SimCardState> {
  final SimCardUseCases _simCardUseCases;

  SimCardNotifier(this._simCardUseCases) : super(const SimCardState());

  Future<void> loadSimCards(String userId) async {
    state = state.copyWith(isLoading: true);
    try {
      final simCards = await _simCardUseCases.getAllSimCards(userId);
      state = state.copyWith(simCards: simCards, isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(error: 'Failed to load SIM cards: $e', isLoading: false);
    }
  }

  Future<bool> createSimCard(SimCardRecord simCard) async {
    state = state.copyWith(isLoading: true);
    try {
      final newSimCard = await _simCardUseCases.createSimCard(simCard);
      final updatedSimCards = [...state.simCards, newSimCard];
      state = state.copyWith(simCards: updatedSimCards, isLoading: false, error: null);
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to create SIM card: $e', isLoading: false);
      return false;
    }
  }

  Future<bool> updateSimCard(SimCardRecord simCard) async {
    state = state.copyWith(isLoading: true);
    try {
      final updatedSimCard = await _simCardUseCases.updateSimCard(simCard);
      final updatedSimCards = state.simCards.map((sc) => 
        sc.id == updatedSimCard.id ? updatedSimCard : sc
      ).toList();
      state = state.copyWith(simCards: updatedSimCards, isLoading: false, error: null);
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to update SIM card: $e', isLoading: false);
      return false;
    }
  }

  Future<bool> deleteSimCard(String id) async {
    state = state.copyWith(isLoading: true);
    try {
      await _simCardUseCases.deleteSimCard(id);
      final updatedSimCards = state.simCards.where((sc) => sc.id != id).toList();
      state = state.copyWith(simCards: updatedSimCards, isLoading: false, error: null);
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete SIM card: $e', isLoading: false);
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  // Additional utility methods for compatibility
  SimCardRecord? getSimCardById(String id) {
    try {
      return state.simCards.firstWhere((sc) => sc.id == id);
    } catch (e) {
      return null;
    }
  }

  double getSimCardBalance(String id) {
    // For now, return 0.0 - would need integration with account balance calculation
    return 0.0;
  }

  // Method signature compatible with old Provider pattern
  Future<bool> createSimCardWithParams({
    required String userId,
    required String phoneNumber,
    required String simNickname,
    required String telecomProvider,
    String? officialRegisteredName,
  }) async {
    final simCard = SimCardRecord(
      id: '', // Will be set by the service
      userId: userId,
      phoneNumber: phoneNumber,
      simNickname: simNickname,
      telecomProvider: telecomProvider,
      officialRegisteredName: officialRegisteredName,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return await createSimCard(simCard);
  }
}

final simCardNotifierProvider = StateNotifierProvider<SimCardNotifier, SimCardState>((ref) {
  final simCardUseCases = ref.read(simCardUseCasesProvider);
  return SimCardNotifier(simCardUseCases);
});

// Financial Account State
class FinancialAccountState {
  final List<FinancialAccountRecord> accounts;
  final bool isLoading;
  final String? error;

  const FinancialAccountState({
    this.accounts = const [],
    this.isLoading = false,
    this.error,
  });

  FinancialAccountState copyWith({
    List<FinancialAccountRecord>? accounts,
    bool? isLoading,
    String? error,
  }) {
    return FinancialAccountState(
      accounts: accounts ?? this.accounts,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class FinancialAccountNotifier extends StateNotifier<FinancialAccountState> {
  final FinancialAccountUseCases _accountUseCases;

  FinancialAccountNotifier(this._accountUseCases) : super(const FinancialAccountState());

  Future<void> loadAccounts(String userId) async {
    state = state.copyWith(isLoading: true);
    try {
      final accounts = await _accountUseCases.getAllAccounts(userId);
      state = state.copyWith(accounts: accounts, isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(error: 'Failed to load accounts: $e', isLoading: false);
    }
  }

  Future<bool> createAccount(FinancialAccountRecord account) async {
    state = state.copyWith(isLoading: true);
    try {
      final newAccount = await _accountUseCases.createAccount(account);
      final updatedAccounts = [...state.accounts, newAccount];
      state = state.copyWith(accounts: updatedAccounts, isLoading: false, error: null);
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to create account: $e', isLoading: false);
      return false;
    }
  }

  Future<bool> updateAccount(FinancialAccountRecord account) async {
    state = state.copyWith(isLoading: true);
    try {
      final updatedAccount = await _accountUseCases.updateAccount(account);
      final updatedAccounts = state.accounts.map((acc) => 
        acc.id == updatedAccount.id ? updatedAccount : acc
      ).toList();
      state = state.copyWith(accounts: updatedAccounts, isLoading: false, error: null);
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to update account: $e', isLoading: false);
      return false;
    }
  }

  Future<bool> deleteAccount(String id) async {
    state = state.copyWith(isLoading: true);
    try {
      await _accountUseCases.deleteAccount(id);
      final updatedAccounts = state.accounts.where((acc) => acc.id != id).toList();
      state = state.copyWith(accounts: updatedAccounts, isLoading: false, error: null);
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete account: $e', isLoading: false);
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  // Additional utility methods for compatibility
  FinancialAccountRecord? getAccountById(String id) {
    try {
      return state.accounts.firstWhere((acc) => acc.id == id);
    } catch (e) {
      return null;
    }
  }

  double getAccountBalance(String id) {
    // For now, return 0.0 - would need integration with transaction history
    return 0.0;
  }

  double getTotalBalance() {
    // Sum all account balances
    return state.accounts.fold(0.0, (sum, acc) => sum + getAccountBalance(acc.id));
  }

  // Method signature compatible with old Provider pattern
  Future<bool> createAccountWithParams({
    required String userId,
    required String accountName,
    required String accountIdentifier,
    required String accountType,
    required String linkedSimId,
    required double initialBalance,
  }) async {
    final account = FinancialAccountRecord(
      id: '', // Will be set by the service
      userId: userId,
      accountName: accountName,
      accountIdentifier: accountIdentifier,
      accountType: accountType,
      linkedSimId: linkedSimId,
      initialBalance: initialBalance,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return await createAccount(account);
  }
}

final financialAccountNotifierProvider = StateNotifierProvider<FinancialAccountNotifier, FinancialAccountState>((ref) {
  final accountUseCases = ref.read(financialAccountUseCasesProvider);
  return FinancialAccountNotifier(accountUseCases);
});

// Transaction State
class TransactionState {
  final List<TransactionRecord> transactions;
  final bool isLoading;
  final String? error;

  const TransactionState({
    this.transactions = const [],
    this.isLoading = false,
    this.error,
  });

  TransactionState copyWith({
    List<TransactionRecord>? transactions,
    bool? isLoading,
    String? error,
  }) {
    return TransactionState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class TransactionNotifier extends StateNotifier<TransactionState> {
  final TransactionUseCases _transactionUseCases;

  TransactionNotifier(this._transactionUseCases) : super(const TransactionState());

  Future<void> loadAllTransactions(String userId) async {
    state = state.copyWith(isLoading: true);
    try {
      final transactions = await _transactionUseCases.getAllTransactions(userId);
      state = state.copyWith(transactions: transactions, isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(error: 'Failed to load transactions: $e', isLoading: false);
    }
  }

  Future<void> loadRecentTransactions(String userId, {int limit = 10}) async {
    state = state.copyWith(isLoading: true);
    try {
      final transactions = await _transactionUseCases.getRecentTransactions(userId, limit: limit);
      state = state.copyWith(transactions: transactions, isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(error: 'Failed to load recent transactions: $e', isLoading: false);
    }
  }

  Future<bool> createTransaction({
    required String userId,
    required String affectedAccountId,
    required DateTime transactionDate,
    required double amount,
    required String transactionType,
    required String descriptionNotes,
    String currency = 'ETB',
    String? payerSenderRaw,
    String? payeeReceiverRaw,
    String? referenceNumber,
    bool isInternalTransfer = false,
    String? counterpartyAccountId,
    String? receiptFileLink,
    String? ocrExtractedRawText,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final newTransaction = await _transactionUseCases.createTransaction(
        userId: userId,
        affectedAccountId: affectedAccountId,
        transactionDate: transactionDate,
        amount: amount,
        transactionType: transactionType,
        descriptionNotes: descriptionNotes,
        currency: currency,
        payerSenderRaw: payerSenderRaw,
        payeeReceiverRaw: payeeReceiverRaw,
        referenceNumber: referenceNumber,
        isInternalTransfer: isInternalTransfer,
        counterpartyAccountId: counterpartyAccountId,
        receiptFileLink: receiptFileLink,
        ocrExtractedRawText: ocrExtractedRawText,
      );
      final updatedTransactions = [newTransaction, ...state.transactions];
      state = state.copyWith(transactions: updatedTransactions, isLoading: false, error: null);
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to create transaction: $e', isLoading: false);
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  // Additional utility methods for compatibility
  Future<void> loadTransactions(String userId) async {
    return await loadAllTransactions(userId);
  }

  Future<bool> deleteTransaction(String id) async {
    state = state.copyWith(isLoading: true);
    try {
      await _transactionUseCases.deleteTransaction(id);
      final updatedTransactions = state.transactions.where((t) => t.id != id).toList();
      state = state.copyWith(transactions: updatedTransactions, isLoading: false, error: null);
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete transaction: $e', isLoading: false);
      return false;
    }
  }

  TransactionRecord? getTransactionById(String id) {
    try {
      return state.transactions.firstWhere((txn) => txn.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateTransaction(TransactionRecord transaction) async {
    state = state.copyWith(isLoading: true);
    try {
      await _transactionUseCases.updateTransaction(transaction);
      final updatedTransactions = state.transactions.map((txn) => 
        txn.id == transaction.id ? transaction : txn
      ).toList();
      state = state.copyWith(transactions: updatedTransactions, isLoading: false, error: null);
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to update transaction: $e', isLoading: false);
      return false;
    }
  }

  double getTotalIncome() {
    return state.transactions
        .where((txn) => txn.transactionType.toLowerCase().contains('income') || 
                       txn.transactionType.toLowerCase().contains('credit'))
        .fold(0.0, (sum, txn) => sum + txn.amount);
  }

  double getTotalExpenses() {
    return state.transactions
        .where((txn) => txn.transactionType.toLowerCase().contains('expense') || 
                       txn.transactionType.toLowerCase().contains('debit'))
        .fold(0.0, (sum, txn) => sum + txn.amount);
  }
}

final transactionNotifierProvider = StateNotifierProvider<TransactionNotifier, TransactionState>((ref) {
  final transactionUseCases = ref.read(transactionUseCasesProvider);
  return TransactionNotifier(transactionUseCases);
});

// Friend State
class FriendState {
  final List<FriendRecord> friends;
  final String searchQuery;
  final bool isLoading;
  final String? error;

  const FriendState({
    this.friends = const [],
    this.searchQuery = '',
    this.isLoading = false,
    this.error,
  });

  FriendState copyWith({
    List<FriendRecord>? friends,
    String? searchQuery,
    bool? isLoading,
    String? error,
  }) {
    return FriendState(
      friends: friends ?? this.friends,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class FriendNotifier extends StateNotifier<FriendState> {
  final FriendUseCases _friendUseCases;

  FriendNotifier(this._friendUseCases) : super(const FriendState());

  Future<void> loadFriends(String userId) async {
    state = state.copyWith(isLoading: true);
    try {
      final friends = await _friendUseCases.getAllFriends(userId);
      state = state.copyWith(friends: friends, isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(error: 'Failed to load friends: $e', isLoading: false);
    }
  }

  Future<bool> createFriend(FriendRecord friend) async {
    state = state.copyWith(isLoading: true);
    try {
      final newFriend = await _friendUseCases.createFriend(friend);
      final updatedFriends = [...state.friends, newFriend];
      state = state.copyWith(friends: updatedFriends, isLoading: false, error: null);
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to create friend: $e', isLoading: false);
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  // Additional utility methods for compatibility
  FriendRecord? getFriendById(String id) {
    try {
      return state.friends.firstWhere((friend) => friend.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> searchFriends(String userId, String searchTerm) async {
    state = state.copyWith(searchQuery: searchTerm);
    // For now, just filter locally - could implement server-side search
    if (searchTerm.isEmpty) {
      await loadFriends(userId);
    } else {
      final filteredFriends = state.friends.where((friend) =>
        friend.friendName.toLowerCase().contains(searchTerm.toLowerCase()) ||
        (friend.friendPhoneNumber?.contains(searchTerm) ?? false)
      ).toList();
      state = state.copyWith(friends: filteredFriends);
    }
  }

  Future<bool> canDeleteFriend(String friendId) async {
    // For now, just return true - would need to check for active loans/debts
    return true;
  }

  Future<bool> deleteFriend(String friendId) async {
    state = state.copyWith(isLoading: true);
    try {
      await _friendUseCases.deleteFriend(friendId);
      final updatedFriends = state.friends.where((f) => f.id != friendId).toList();
      state = state.copyWith(friends: updatedFriends, isLoading: false, error: null);
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete friend: $e', isLoading: false);
      return false;
    }
  }

  Future<bool> updateFriend(FriendRecord friend) async {
    state = state.copyWith(isLoading: true);
    try {
      final updatedFriend = await _friendUseCases.updateFriend(friend);
      final updatedFriends = state.friends.map((f) => 
        f.id == updatedFriend.id ? updatedFriend : f
      ).toList();
      state = state.copyWith(friends: updatedFriends, isLoading: false, error: null);
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to update friend: $e', isLoading: false);
      return false;
    }
  }

  // Method signature compatible with old Provider pattern
  Future<bool> createFriendWithParams({
    required String userId,
    required String friendName,
    String? friendPhoneNumber,
    String? notes,
  }) async {
    final friend = FriendRecord(
      id: '', // Will be set by the service
      userId: userId,
      friendName: friendName,
      friendPhoneNumber: friendPhoneNumber,
      notes: notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return await createFriend(friend);
  }
}

final friendNotifierProvider = StateNotifierProvider<FriendNotifier, FriendState>((ref) {
  final friendUseCases = ref.read(friendUseCasesProvider);
  return FriendNotifier(friendUseCases);
});

// Loan Debt State
class LoanDebtState {
  final List<LoanDebtItem> loanDebts;
  final List<dynamic> payments; // Would need proper payment entity
  final bool isLoading;
  final String? error;

  const LoanDebtState({
    this.loanDebts = const [],
    this.payments = const [],
    this.isLoading = false,
    this.error,
  });

  LoanDebtState copyWith({
    List<LoanDebtItem>? loanDebts,
    List<dynamic>? payments,
    bool? isLoading,
    String? error,
  }) {
    return LoanDebtState(
      loanDebts: loanDebts ?? this.loanDebts,
      payments: payments ?? this.payments,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class LoanDebtNotifier extends StateNotifier<LoanDebtState> {
  final LoanDebtUseCases _loanDebtUseCases;

  LoanDebtNotifier(this._loanDebtUseCases) : super(const LoanDebtState());

  Future<void> loadLoanDebts(String userId) async {
    state = state.copyWith(isLoading: true);
    try {
      final loanDebts = await _loanDebtUseCases.getAllLoanDebts(userId);
      state = state.copyWith(loanDebts: loanDebts, isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(error: 'Failed to load loan/debts: $e', isLoading: false);
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  LoanDebtItem? getLoanDebtById(String id) {
    try {
      return state.loanDebts.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }


  Future<void> loadLoanDebtPayments(String loanDebtId) async {
    // For now, just a placeholder - would need to load payments
    // This would typically update a separate payments state
  }

  Future<bool> recordPayment({
    required String loanDebtId,
    required double amount,
    required DateTime paymentDate,
    required String transactionMethod,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      // This would typically call a use case to record the payment
      // For now, just return success
      state = state.copyWith(isLoading: false, error: null);
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to record payment: $e', isLoading: false);
      return false;
    }
  }

  // Additional utility methods for compatibility
  Future<bool> createLoanDebt({
    required String userId,
    required String associatedFriendId,
    required String type,
    required double initialAmount,
    required DateTime dateInitiated,
    required String description,
    required String initialTransactionMethod,
    DateTime? dueDate,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final loanDebt = await _loanDebtUseCases.createLoanDebt(
        userId: userId,
        associatedFriendId: associatedFriendId,
        type: type,
        initialAmount: initialAmount,
        dateInitiated: dateInitiated,
        description: description,
        initialTransactionMethod: initialTransactionMethod,
        dueDate: dueDate,
      );
      final updatedLoanDebts = [...state.loanDebts, loanDebt];
      state = state.copyWith(loanDebts: updatedLoanDebts, isLoading: false, error: null);
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to create loan/debt: $e', isLoading: false);
      return false;
    }
  }

  List<LoanDebtItem> getLoansGiven() {
    return state.loanDebts.where((item) => item.type.toLowerCase() == 'loangiventofriend').toList();
  }

  List<LoanDebtItem> getDebtsOwed() {
    return state.loanDebts.where((item) => item.type.toLowerCase() == 'debtowedtofriend').toList();
  }

  double getTotalLoansGiven() {
    return getLoansGiven().fold(0.0, (sum, item) => sum + item.outstandingAmount);
  }

  double getTotalDebtsOwed() {
    return getDebtsOwed().fold(0.0, (sum, item) => sum + item.outstandingAmount);
  }

  double getNetPosition() {
    return getTotalLoansGiven() - getTotalDebtsOwed();
  }
}

final loanDebtNotifierProvider = StateNotifierProvider<LoanDebtNotifier, LoanDebtState>((ref) {
  final loanDebtUseCases = ref.read(loanDebtUseCasesProvider);
  return LoanDebtNotifier(loanDebtUseCases);
});

// Theme State
enum ThemeMode { system, light, dark }

class ThemeState {
  final ThemeMode themeMode;

  const ThemeState({this.themeMode = ThemeMode.system});

  ThemeState copyWith({ThemeMode? themeMode}) {
    return ThemeState(themeMode: themeMode ?? this.themeMode);
  }
}

class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier() : super(const ThemeState()) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    // Load theme from SharedPreferences
    // Implementation here
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    // Save to SharedPreferences
    // Implementation here
  }
}

final themeNotifierProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
});

// Security State
class SecurityState {
  final bool isPinSetup;
  final bool isBiometricEnabled;
  final bool isBiometricAvailable;
  final bool isLoading;
  final String? error;

  const SecurityState({
    this.isPinSetup = false,
    this.isBiometricEnabled = false,
    this.isBiometricAvailable = false,
    this.isLoading = false,
    this.error,
  });

  SecurityState copyWith({
    bool? isPinSetup,
    bool? isBiometricEnabled,
    bool? isBiometricAvailable,
    bool? isLoading,
    String? error,
  }) {
    return SecurityState(
      isPinSetup: isPinSetup ?? this.isPinSetup,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      isBiometricAvailable: isBiometricAvailable ?? this.isBiometricAvailable,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class SecurityNotifier extends StateNotifier<SecurityState> {
  final SecurityService _securityService;

  SecurityNotifier(this._securityService) : super(const SecurityState()) {
    _loadSecurityStatus();
  }

  Future<void> _loadSecurityStatus() async {
    state = state.copyWith(isLoading: true);
    try {
      final isPinSetup = await _securityService.isPinSetup();
      final isBiometricEnabled = await _securityService.isBiometricEnabled();
      final isBiometricAvailable = await _securityService.isBiometricAvailable();
      
      state = state.copyWith(
        isPinSetup: isPinSetup,
        isBiometricEnabled: isBiometricEnabled,
        isBiometricAvailable: isBiometricAvailable,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to load security status: $e', isLoading: false);
    }
  }

  Future<bool> setPin(String pin) async {
    state = state.copyWith(isLoading: true);
    try {
      final success = await _securityService.setPin(pin);
      if (success) {
        state = state.copyWith(isPinSetup: true, isLoading: false, error: null);
      } else {
        state = state.copyWith(error: 'Failed to set PIN', isLoading: false);
      }
      return success;
    } catch (e) {
      state = state.copyWith(error: 'Failed to set PIN: $e', isLoading: false);
      return false;
    }
  }

  Future<bool> verifyPin(String pin) async {
    try {
      return await _securityService.verifyPin(pin);
    } catch (e) {
      state = state.copyWith(error: 'Failed to verify PIN: $e');
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final securityNotifierProvider = StateNotifierProvider<SecurityNotifier, SecurityState>((ref) {
  final securityService = ref.read(securityServiceProvider);
  return SecurityNotifier(securityService);
});

// Recurring Transaction State Provider
final recurringTransactionNotifierProvider = StateNotifierProvider<RecurringTransactionNotifier, RecurringTransactionState>((ref) {
  final recurringTransactionUseCases = ref.read(recurringTransactionUseCasesProvider);
  return RecurringTransactionNotifier(recurringTransactionUseCases);
});