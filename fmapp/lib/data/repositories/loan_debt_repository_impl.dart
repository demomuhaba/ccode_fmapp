import '../../domain/entities/loan_debt_item.dart';
import '../../domain/entities/loan_debt_payment.dart';
import '../../domain/repositories/loan_debt_repository.dart';
import '../../services/supabase_service.dart';
import '../models/loan_debt_item_model.dart';
import '../models/loan_debt_payment_model.dart';

class LoanDebtRepositoryImpl implements LoanDebtRepository {
  final SupabaseService _supabaseService;

  LoanDebtRepositoryImpl(this._supabaseService);

  @override
  Future<List<LoanDebtItem>> getAllLoanDebts(String userId) async {
    try {
      final data = await _supabaseService.getRecordsByCondition(
        table: 'loan_debt_items',
        conditions: {'user_id': userId},
      );
      return data.map((json) => LoanDebtItemModel.fromJson(json).toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to get loan/debt items: $e');
    }
  }

  @override
  Future<LoanDebtItem?> getLoanDebtById(String id) async {
    try {
      final data = await _supabaseService.getRecordById(table: 'loan_debt_items', id: id);
      if (data == null) return null;
      return LoanDebtItemModel.fromJson(data).toEntity();
    } catch (e) {
      throw Exception('Failed to get loan/debt item: $e');
    }
  }

  @override
  Future<LoanDebtItem> createLoanDebt(LoanDebtItem loanDebt) async {
    try {
      final model = LoanDebtItemModel.fromEntity(loanDebt);
      final data = await _supabaseService.createRecord(table: 'loan_debt_items', data: model.toJsonForInsert());
      return LoanDebtItemModel.fromJson(data).toEntity();
    } catch (e) {
      throw Exception('Failed to create loan/debt item: $e');
    }
  }

  @override
  Future<LoanDebtItem> updateLoanDebt(LoanDebtItem loanDebt) async {
    try {
      final model = LoanDebtItemModel.fromEntity(loanDebt);
      final data = await _supabaseService.updateRecord(table: 'loan_debt_items', id: model.id, data: model.toJsonForInsert());
      return LoanDebtItemModel.fromJson(data).toEntity();
    } catch (e) {
      throw Exception('Failed to update loan/debt item: $e');
    }
  }

  @override
  Future<void> deleteLoanDebt(String id) async {
    try {
      await _supabaseService.deleteRecord(table: 'loan_debt_items', id: id);
    } catch (e) {
      throw Exception('Failed to delete loan/debt item: $e');
    }
  }

  @override
  Future<List<LoanDebtItem>> getLoanDebtsByFriend(String friendId) async {
    try {
      final data = await _supabaseService.getRecordsByCondition(
        table: 'loan_debt_items',
        conditions: {'associated_friend_id': friendId},
      );
      return data.map((json) => LoanDebtItemModel.fromJson(json).toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to get loan/debt items by friend: $e');
    }
  }

  @override
  Future<List<LoanDebtItem>> getActiveLoanDebts(String userId) async {
    try {
      final allItems = await getAllLoanDebts(userId);
      return allItems.where((item) => 
        item.status.toLowerCase() == 'active' || 
        item.status.toLowerCase() == 'partiallypaid'
      ).toList();
    } catch (e) {
      throw Exception('Failed to get active loan/debt items: $e');
    }
  }

  @override
  Future<List<LoanDebtItem>> getOverdueLoanDebts(String userId) async {
    try {
      final activeItems = await getActiveLoanDebts(userId);
      final now = DateTime.now();
      
      return activeItems.where((item) => 
        item.dueDate != null && now.isAfter(item.dueDate!)
      ).toList();
    } catch (e) {
      throw Exception('Failed to get overdue loan/debt items: $e');
    }
  }

  @override
  Future<List<LoanDebtPayment>> getPaymentsForLoanDebt(String loanDebtId) async {
    try {
      final data = await _supabaseService.getRecordsByCondition(
        table: 'loan_debt_payments',
        conditions: {'parent_loan_debt_id': loanDebtId},
      );
      return data.map((json) => LoanDebtPaymentModel.fromJson(json).toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to get payments for loan/debt: $e');
    }
  }

  @override
  Future<LoanDebtPayment> createPayment(LoanDebtPayment payment) async {
    try {
      final model = LoanDebtPaymentModel.fromEntity(payment);
      final data = await _supabaseService.createRecord(table: 'loan_debt_payments', data: model.toJsonForInsert());
      return LoanDebtPaymentModel.fromJson(data).toEntity();
    } catch (e) {
      throw Exception('Failed to create payment: $e');
    }
  }

  @override
  Future<LoanDebtPayment> updatePayment(LoanDebtPayment payment) async {
    try {
      final model = LoanDebtPaymentModel.fromEntity(payment);
      final data = await _supabaseService.updateRecord(table: 'loan_debt_payments', id: model.id, data: model.toJsonForInsert());
      return LoanDebtPaymentModel.fromJson(data).toEntity();
    } catch (e) {
      throw Exception('Failed to update payment: $e');
    }
  }

  @override
  Future<void> deletePayment(String id) async {
    try {
      await _supabaseService.deleteRecord(table: 'loan_debt_payments', id: id);
    } catch (e) {
      throw Exception('Failed to delete payment: $e');
    }
  }

  @override
  Future<double> getTotalOutstandingLoansGiven(String userId) async {
    try {
      final loans = await getAllLoanDebts(userId);
      final loansGiven = loans.where((item) => 
        item.type.toLowerCase() == 'loangiventofriend' &&
        (item.status.toLowerCase() == 'active' || item.status.toLowerCase() == 'partiallypaid')
      );
      
      return loansGiven.fold<double>(0.0, (sum, loan) => sum + loan.outstandingAmount);
    } catch (e) {
      throw Exception('Failed to get total outstanding loans given: $e');
    }
  }

  @override
  Future<double> getTotalOutstandingDebtsOwed(String userId) async {
    try {
      final debts = await getAllLoanDebts(userId);
      final debtsOwed = debts.where((item) => 
        item.type.toLowerCase() == 'debtowedtofriend' &&
        (item.status.toLowerCase() == 'active' || item.status.toLowerCase() == 'partiallypaid')
      );
      
      return debtsOwed.fold<double>(0.0, (sum, debt) => sum + debt.outstandingAmount);
    } catch (e) {
      throw Exception('Failed to get total outstanding debts owed: $e');
    }
  }

  @override
  Future<Map<String, double>> getLoanDebtSummary(String userId) async {
    try {
      final totalLoansGiven = await getTotalOutstandingLoansGiven(userId);
      final totalDebtsOwed = await getTotalOutstandingDebtsOwed(userId);
      
      return {
        'totalLoansGiven': totalLoansGiven,
        'totalDebtsOwed': totalDebtsOwed,
        'netPosition': totalLoansGiven - totalDebtsOwed,
      };
    } catch (e) {
      throw Exception('Failed to get loan/debt summary: $e');
    }
  }
}