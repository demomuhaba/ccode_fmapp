import 'package:flutter/foundation.dart';
import '../../domain/entities/loan_debt_item.dart';
import '../../domain/entities/loan_debt_payment.dart';
import '../../domain/usecases/loan_debt_usecases.dart';

class LoanDebtProvider extends ChangeNotifier {
  final LoanDebtUseCases _loanDebtUseCases;

  LoanDebtProvider(this._loanDebtUseCases);

  List<LoanDebtItem> _loanDebts = [];
  List<LoanDebtItem> _activeLoanDebts = [];
  List<LoanDebtItem> _overdueLoanDebts = [];
  Map<String, List<LoanDebtPayment>> _payments = {};
  Map<String, double> _summary = {};
  bool _isLoading = false;
  String? _error;

  List<LoanDebtItem> get loanDebts => _loanDebts;
  List<LoanDebtItem> get activeLoanDebts => _activeLoanDebts;
  List<LoanDebtItem> get overdueLoanDebts => _overdueLoanDebts;
  Map<String, double> get summary => _summary;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadLoanDebts(String userId) async {
    _setLoading(true);
    try {
      _loanDebts = await _loanDebtUseCases.getAllLoanDebts(userId);
      await loadActiveLoanDebts(userId);
      await loadOverdueLoanDebts(userId);
      await loadSummary(userId);
      _clearError();
    } catch (e) {
      _setError('Failed to load loan/debt items: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadActiveLoanDebts(String userId) async {
    try {
      _activeLoanDebts = await _loanDebtUseCases.getActiveLoanDebts(userId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load active loan/debt items: $e');
    }
  }

  Future<void> loadOverdueLoanDebts(String userId) async {
    try {
      _overdueLoanDebts = await _loanDebtUseCases.getOverdueLoanDebts(userId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load overdue loan/debt items: $e');
    }
  }

  Future<void> loadSummary(String userId) async {
    try {
      _summary = await _loanDebtUseCases.getLoanDebtSummary(userId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load loan/debt summary: $e');
    }
  }

  Future<void> loadLoanDebtPayments(String loanDebtId) async {
    try {
      _payments[loanDebtId] = await _loanDebtUseCases.getPaymentsForLoanDebt(loanDebtId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load payments: $e');
    }
  }

  Future<void> loadPaymentsForLoanDebt(String loanDebtId) async {
    await loadLoanDebtPayments(loanDebtId);
  }

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
    _setLoading(true);
    try {
      final result = await _loanDebtUseCases.createLoanDebt(
        userId: userId,
        associatedFriendId: associatedFriendId,
        type: type,
        initialAmount: initialAmount,
        dateInitiated: dateInitiated,
        description: description,
        initialTransactionMethod: initialTransactionMethod,
        dueDate: dueDate,
      );

      final newLoanDebt = result['loanDebt'] as LoanDebtItem;
      _loanDebts.insert(0, newLoanDebt);
      
      if (newLoanDebt.status.toLowerCase() == 'active') {
        _activeLoanDebts.insert(0, newLoanDebt);
      }

      await loadSummary(userId);
      _clearError();
      return true;
    } catch (e) {
      _setError('Failed to create loan/debt: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> recordPayment({
    required String loanDebtId,
    required double amount,
    required DateTime paymentDate,
    required String transactionMethod,
    String? notes,
  }) async {
    final userId = _loanDebts.firstWhere((item) => item.id == loanDebtId).userId;
    return recordPaymentForUser(
      userId: userId,
      parentLoanDebtId: loanDebtId,
      amountPaid: amount,
      paymentDate: paymentDate,
      paidBy: userId,
      paymentTransactionMethod: transactionMethod,
      notes: notes,
    );
  }

  Future<bool> recordPaymentForUser({
    required String userId,
    required String parentLoanDebtId,
    required double amountPaid,
    required DateTime paymentDate,
    required String paidBy,
    required String paymentTransactionMethod,
    String? notes,
  }) async {
    _setLoading(true);
    try {
      final result = await _loanDebtUseCases.recordPayment(
        userId: userId,
        parentLoanDebtId: parentLoanDebtId,
        amountPaid: amountPaid,
        paymentDate: paymentDate,
        paidBy: paidBy,
        paymentTransactionMethod: paymentTransactionMethod,
        notes: notes,
      );

      final updatedLoanDebt = result['updatedLoanDebt'] as LoanDebtItem;
      final payment = result['payment'] as LoanDebtPayment;

      // Update loan/debt item
      final index = _loanDebts.indexWhere((item) => item.id == updatedLoanDebt.id);
      if (index != -1) {
        _loanDebts[index] = updatedLoanDebt;
      }

      final activeIndex = _activeLoanDebts.indexWhere((item) => item.id == updatedLoanDebt.id);
      if (activeIndex != -1) {
        if (updatedLoanDebt.status.toLowerCase() == 'paidoff') {
          _activeLoanDebts.removeAt(activeIndex);
        } else {
          _activeLoanDebts[activeIndex] = updatedLoanDebt;
        }
      }

      // Add payment to cache
      if (_payments[parentLoanDebtId] != null) {
        _payments[parentLoanDebtId]!.insert(0, payment);
      } else {
        _payments[parentLoanDebtId] = [payment];
      }

      await loadSummary(userId);
      _clearError();
      return true;
    } catch (e) {
      _setError('Failed to record payment: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteLoanDebt(String id) async {
    _setLoading(true);
    try {
      await _loanDebtUseCases.deleteLoanDebt(id);
      
      _loanDebts.removeWhere((item) => item.id == id);
      _activeLoanDebts.removeWhere((item) => item.id == id);
      _overdueLoanDebts.removeWhere((item) => item.id == id);
      _payments.remove(id);
      
      _clearError();
      return true;
    } catch (e) {
      _setError('Failed to delete loan/debt: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  LoanDebtItem? getLoanDebtById(String id) {
    try {
      return _loanDebts.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  List<LoanDebtPayment> getPaymentsForLoanDebt(String loanDebtId) {
    return _payments[loanDebtId] ?? [];
  }

  List<LoanDebtPayment> getLoanDebtPayments(String loanDebtId) {
    return getPaymentsForLoanDebt(loanDebtId);
  }

  List<LoanDebtItem> getLoanDebtsByFriend(String friendId) {
    return _loanDebts.where((item) => item.associatedFriendId == friendId).toList();
  }

  List<LoanDebtItem> getLoansGiven() {
    return _loanDebts.where((item) => item.type.toLowerCase() == 'loangiventofriend').toList();
  }

  List<LoanDebtItem> getDebtsOwed() {
    return _loanDebts.where((item) => item.type.toLowerCase() == 'debtowedtofriend').toList();
  }

  double getTotalLoansGiven() {
    return _summary['totalLoansGiven'] ?? 0.0;
  }

  double getTotalDebtsOwed() {
    return _summary['totalDebtsOwed'] ?? 0.0;
  }

  double getNetPosition() {
    return _summary['netPosition'] ?? 0.0;
  }

  Future<Map<String, dynamic>> getDashboardSummary(String userId) async {
    try {
      return await _loanDebtUseCases.getDashboardSummary(userId);
    } catch (e) {
      _setError('Failed to get dashboard summary: $e');
      return {};
    }
  }

  List<String> getValidLoanDebtTypes() {
    return ['LoanGivenToFriend', 'DebtOwedToFriend'];
  }

  List<String> getValidPaymentDirections() {
    return ['UserToFriend', 'FriendToUser'];
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