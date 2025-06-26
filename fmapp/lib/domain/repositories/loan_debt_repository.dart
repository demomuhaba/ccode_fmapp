import '../entities/loan_debt_item.dart';
import '../entities/loan_debt_payment.dart';

abstract class LoanDebtRepository {
  Future<List<LoanDebtItem>> getAllLoanDebts(String userId);
  Future<LoanDebtItem?> getLoanDebtById(String id);
  Future<LoanDebtItem> createLoanDebt(LoanDebtItem loanDebt);
  Future<LoanDebtItem> updateLoanDebt(LoanDebtItem loanDebt);
  Future<void> deleteLoanDebt(String id);
  Future<List<LoanDebtItem>> getLoanDebtsByFriend(String friendId);
  Future<List<LoanDebtItem>> getActiveLoanDebts(String userId);
  Future<List<LoanDebtItem>> getOverdueLoanDebts(String userId);
  
  Future<List<LoanDebtPayment>> getPaymentsForLoanDebt(String loanDebtId);
  Future<LoanDebtPayment> createPayment(LoanDebtPayment payment);
  Future<LoanDebtPayment> updatePayment(LoanDebtPayment payment);
  Future<void> deletePayment(String id);
  
  Future<double> getTotalOutstandingLoansGiven(String userId);
  Future<double> getTotalOutstandingDebtsOwed(String userId);
  Future<Map<String, double>> getLoanDebtSummary(String userId);
}