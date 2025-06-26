import 'package:uuid/uuid.dart';
import '../entities/loan_debt_item.dart';
import '../entities/loan_debt_payment.dart';
import '../entities/transaction_record.dart';
import '../repositories/loan_debt_repository.dart';
import '../repositories/friend_repository.dart';
import '../repositories/financial_account_repository.dart';
import 'transaction_usecases.dart';

class LoanDebtUseCases {
  final LoanDebtRepository _loanDebtRepository;
  final FriendRepository _friendRepository;
  final FinancialAccountRepository _accountRepository;
  final TransactionUseCases _transactionUseCases;
  final Uuid _uuid = const Uuid();

  LoanDebtUseCases(
    this._loanDebtRepository,
    this._friendRepository,
    this._accountRepository,
    this._transactionUseCases,
  );

  Future<List<LoanDebtItem>> getAllLoanDebts(String userId) async {
    try {
      return await _loanDebtRepository.getAllLoanDebts(userId);
    } catch (e) {
      throw Exception('Failed to get loan/debt items: $e');
    }
  }

  Future<LoanDebtItem?> getLoanDebtById(String id) async {
    try {
      return await _loanDebtRepository.getLoanDebtById(id);
    } catch (e) {
      throw Exception('Failed to get loan/debt item: $e');
    }
  }

  Future<Map<String, dynamic>> createLoanDebt({
    required String userId,
    required String associatedFriendId,
    required String type,
    required double initialAmount,
    required DateTime dateInitiated,
    required String description,
    required String initialTransactionMethod,
    DateTime? dueDate,
  }) async {
    try {
      final friend = await _friendRepository.getFriendById(associatedFriendId);
      if (friend == null) {
        throw Exception('Friend not found');
      }

      if (friend.userId != userId) {
        throw Exception('Friend does not belong to user');
      }

      if (initialAmount <= 0) {
        throw Exception('Amount must be positive');
      }

      if (!['LoanGivenToFriend', 'DebtOwedToFriend'].contains(type)) {
        throw Exception('Invalid loan/debt type');
      }

      TransactionRecord? linkedTransaction;
      if (initialTransactionMethod.toLowerCase() != 'cash') {
        final account = await _accountRepository.getAccountById(initialTransactionMethod);
        if (account == null) {
          throw Exception('Account not found');
        }

        if (account.userId != userId) {
          throw Exception('Account does not belong to user');
        }

        if (type == 'LoanGivenToFriend') {
          final currentBalance = await _accountRepository.calculateCurrentBalance(account.id);
          if (currentBalance < initialAmount) {
            throw Exception('Insufficient balance in account');
          }
        }

        final transactionType = type == 'LoanGivenToFriend' ? 'Expense/Debit' : 'Income/Credit';
        final transactionDescription = type == 'LoanGivenToFriend' 
            ? 'Loan given to ${friend.friendName}: $description'
            : 'Debt from ${friend.friendName}: $description';

        linkedTransaction = await _transactionUseCases.createTransaction(
          userId: userId,
          affectedAccountId: account.id,
          transactionDate: dateInitiated,
          amount: initialAmount,
          transactionType: transactionType,
          descriptionNotes: transactionDescription,
        );
      }

      final loanDebt = LoanDebtItem(
        id: _uuid.v4(),
        userId: userId,
        associatedFriendId: associatedFriendId,
        type: type,
        initialAmount: initialAmount,
        outstandingAmount: initialAmount,
        currency: 'ETB',
        dateInitiated: dateInitiated,
        dueDate: dueDate,
        description: description,
        status: 'Active',
        initialTransactionMethod: initialTransactionMethod,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final createdLoanDebt = await _loanDebtRepository.createLoanDebt(loanDebt);

      return {
        'loanDebt': createdLoanDebt,
        'linkedTransaction': linkedTransaction,
        'friend': friend,
      };
    } catch (e) {
      throw Exception('Failed to create loan/debt: $e');
    }
  }

  Future<Map<String, dynamic>> recordPayment({
    required String userId,
    required String parentLoanDebtId,
    required double amountPaid,
    required DateTime paymentDate,
    required String paidBy,
    required String paymentTransactionMethod,
    String? notes,
  }) async {
    try {
      final loanDebt = await getLoanDebtById(parentLoanDebtId);
      if (loanDebt == null) {
        throw Exception('Loan/debt item not found');
      }

      if (loanDebt.userId != userId) {
        throw Exception('Loan/debt item does not belong to user');
      }

      if (amountPaid <= 0) {
        throw Exception('Payment amount must be positive');
      }

      if (amountPaid > loanDebt.outstandingAmount) {
        throw Exception('Payment amount exceeds outstanding balance');
      }

      if (!['UserToFriend', 'FriendToUser'].contains(paidBy)) {
        throw Exception('Invalid payment direction');
      }

      final friend = await _friendRepository.getFriendById(loanDebt.associatedFriendId);
      if (friend == null) {
        throw Exception('Associated friend not found');
      }

      TransactionRecord? linkedTransaction;
      if (paymentTransactionMethod.toLowerCase() != 'cash') {
        final account = await _accountRepository.getAccountById(paymentTransactionMethod);
        if (account == null) {
          throw Exception('Account not found');
        }

        if (account.userId != userId) {
          throw Exception('Account does not belong to user');
        }

        String transactionType;
        String transactionDescription;

        if (loanDebt.type == 'LoanGivenToFriend') {
          transactionType = paidBy == 'FriendToUser' ? 'Income/Credit' : 'Expense/Debit';
          transactionDescription = paidBy == 'FriendToUser' 
              ? 'Loan repayment from ${friend.friendName}'
              : 'Additional loan payment to ${friend.friendName}';
        } else {
          transactionType = paidBy == 'UserToFriend' ? 'Expense/Debit' : 'Income/Credit';
          transactionDescription = paidBy == 'UserToFriend' 
              ? 'Debt payment to ${friend.friendName}'
              : 'Debt relief from ${friend.friendName}';
        }

        if (transactionType == 'Expense/Debit') {
          final currentBalance = await _accountRepository.calculateCurrentBalance(account.id);
          if (currentBalance < amountPaid) {
            throw Exception('Insufficient balance in account');
          }
        }

        linkedTransaction = await _transactionUseCases.createTransaction(
          userId: userId,
          affectedAccountId: account.id,
          transactionDate: paymentDate,
          amount: amountPaid,
          transactionType: transactionType,
          descriptionNotes: transactionDescription,
        );
      }

      final payment = LoanDebtPayment(
        id: _uuid.v4(),
        userId: userId,
        parentLoanDebtId: parentLoanDebtId,
        paymentDate: paymentDate,
        amountPaid: amountPaid,
        paidBy: paidBy,
        notes: notes,
        paymentTransactionMethod: paymentTransactionMethod,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final createdPayment = await _loanDebtRepository.createPayment(payment);

      final newOutstandingAmount = loanDebt.outstandingAmount - amountPaid;
      String newStatus = 'Active';
      
      if (newOutstandingAmount == 0) {
        newStatus = 'PaidOff';
      } else if (newOutstandingAmount < loanDebt.initialAmount) {
        newStatus = 'PartiallyPaid';
      }

      final updatedLoanDebt = loanDebt.copyWith(
        outstandingAmount: newOutstandingAmount,
        status: newStatus,
        updatedAt: DateTime.now(),
      );

      final finalLoanDebt = await _loanDebtRepository.updateLoanDebt(updatedLoanDebt);

      return {
        'payment': createdPayment,
        'updatedLoanDebt': finalLoanDebt,
        'linkedTransaction': linkedTransaction,
        'friend': friend,
      };
    } catch (e) {
      throw Exception('Failed to record payment: $e');
    }
  }

  Future<List<LoanDebtPayment>> getPaymentsForLoanDebt(String loanDebtId) async {
    try {
      return await _loanDebtRepository.getPaymentsForLoanDebt(loanDebtId);
    } catch (e) {
      throw Exception('Failed to get payments: $e');
    }
  }

  Future<List<LoanDebtItem>> getActiveLoanDebts(String userId) async {
    try {
      return await _loanDebtRepository.getActiveLoanDebts(userId);
    } catch (e) {
      throw Exception('Failed to get active loan/debt items: $e');
    }
  }

  Future<List<LoanDebtItem>> getOverdueLoanDebts(String userId) async {
    try {
      return await _loanDebtRepository.getOverdueLoanDebts(userId);
    } catch (e) {
      throw Exception('Failed to get overdue loan/debt items: $e');
    }
  }

  Future<Map<String, double>> getLoanDebtSummary(String userId) async {
    try {
      return await _loanDebtRepository.getLoanDebtSummary(userId);
    } catch (e) {
      throw Exception('Failed to get loan/debt summary: $e');
    }
  }

  Future<Map<String, dynamic>> getDashboardSummary(String userId) async {
    try {
      final summary = await getLoanDebtSummary(userId);
      final activeLoanDebts = await getActiveLoanDebts(userId);
      final overdueLoanDebts = await getOverdueLoanDebts(userId);

      final activeLoans = activeLoanDebts.where((item) => 
        item.type.toLowerCase() == 'loangiventofriend'
      ).toList();

      final activeDebts = activeLoanDebts.where((item) => 
        item.type.toLowerCase() == 'debtowedtofriend'
      ).toList();

      return {
        'totalLoansGiven': summary['totalLoansGiven'] ?? 0.0,
        'totalDebtsOwed': summary['totalDebtsOwed'] ?? 0.0,
        'netPosition': summary['netPosition'] ?? 0.0,
        'activeLoansCount': activeLoans.length,
        'activeDebtsCount': activeDebts.length,
        'overdueItemsCount': overdueLoanDebts.length,
        'urgentItems': _getUrgentItems(activeLoanDebts),
      };
    } catch (e) {
      throw Exception('Failed to get dashboard summary: $e');
    }
  }

  List<LoanDebtItem> _getUrgentItems(List<LoanDebtItem> activeLoanDebts) {
    final now = DateTime.now();
    final urgentItems = <LoanDebtItem>[];

    for (final item in activeLoanDebts) {
      if (item.dueDate != null) {
        final daysUntilDue = item.dueDate!.difference(now).inDays;
        if (daysUntilDue <= 7 && daysUntilDue >= 0) {
          urgentItems.add(item);
        } else if (now.isAfter(item.dueDate!)) {
          urgentItems.add(item);
        }
      }
    }

    urgentItems.sort((a, b) {
      if (a.dueDate == null && b.dueDate == null) return 0;
      if (a.dueDate == null) return 1;
      if (b.dueDate == null) return -1;
      return a.dueDate!.compareTo(b.dueDate!);
    });

    return urgentItems.take(2).toList();
  }

  Future<void> deleteLoanDebt(String id) async {
    try {
      final payments = await getPaymentsForLoanDebt(id);
      if (payments.isNotEmpty) {
        throw Exception('Cannot delete loan/debt item with payment history');
      }

      await _loanDebtRepository.deleteLoanDebt(id);
    } catch (e) {
      throw Exception('Failed to delete loan/debt item: $e');
    }
  }

  Future<List<String>> getValidLoanDebtTypes() async {
    return ['LoanGivenToFriend', 'DebtOwedToFriend'];
  }

  Future<List<String>> getValidPaymentDirections() async {
    return ['UserToFriend', 'FriendToUser'];
  }
}