// Domain entity for Loan/Debt Payment
// Represents payments made against loan/debt items

import 'package:equatable/equatable.dart';
import '../../core/constants/app_constants.dart';

class LoanDebtPayment extends Equatable {
  final String id;
  final String userId;
  final String parentLoanDebtId;
  final DateTime paymentDate;
  final double amountPaid;
  final String paidBy;
  final String? notes;
  final String paymentTransactionMethod;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LoanDebtPayment({
    required this.id,
    required this.userId,
    required this.parentLoanDebtId,
    required this.paymentDate,
    required this.amountPaid,
    required this.paidBy,
    this.notes,
    required this.paymentTransactionMethod,
    required this.createdAt,
    required this.updatedAt,
  });

  LoanDebtPayment copyWith({
    String? id,
    String? userId,
    String? parentLoanDebtId,
    DateTime? paymentDate,
    double? amountPaid,
    String? paidBy,
    String? notes,
    String? paymentTransactionMethod,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LoanDebtPayment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      parentLoanDebtId: parentLoanDebtId ?? this.parentLoanDebtId,
      paymentDate: paymentDate ?? this.paymentDate,
      amountPaid: amountPaid ?? this.amountPaid,
      paidBy: paidBy ?? this.paidBy,
      notes: notes ?? this.notes,
      paymentTransactionMethod: paymentTransactionMethod ?? this.paymentTransactionMethod,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Validates if the payment type is supported
  bool get isValidPaymentType {
    return AppConstants.paymentTypes.contains(paidBy);
  }

  /// Checks if payment was made by user to friend
  bool get isPaidByUserToFriend {
    return paidBy == AppConstants.paymentTypeUserToFriend;
  }

  /// Checks if payment was made by friend to user
  bool get isPaidByFriendToUser {
    return paidBy == AppConstants.paymentTypeFriendToUser;
  }

  /// Checks if payment transaction method was cash
  bool get wasPaymentTransactionCash {
    return paymentTransactionMethod == AppConstants.transactionMethodCash;
  }

  /// Checks if this payment has notes
  bool get hasNotes {
    return notes != null && notes!.isNotEmpty;
  }

  /// Returns formatted amount paid in ETB
  String get formattedAmountPaid {
    return '${AppConstants.currencySymbol} ${amountPaid.toStringAsFixed(2)}';
  }

  /// Returns payment type display name
  String get paidByDisplayName {
    switch (paidBy) {
      case AppConstants.paymentTypeUserToFriend:
        return 'You paid friend';
      case AppConstants.paymentTypeFriendToUser:
        return 'Friend paid you';
      default:
        return paidBy;
    }
  }

  /// Returns payment method display name
  String get paymentMethodDisplayName {
    if (wasPaymentTransactionCash) {
      return 'Cash';
    }
    return 'Account Transfer';
  }

  /// Returns description for display purposes
  String get displayDescription {
    if (hasNotes) {
      return notes!;
    }
    return 'Payment of $formattedAmountPaid';
  }

  /// Returns payment direction icon/symbol
  String get paymentDirectionSymbol {
    return isPaidByUserToFriend ? '→' : '←';
  }

  /// Returns payment summary text
  String get paymentSummaryText {
    final direction = isPaidByUserToFriend ? 'to friend' : 'from friend';
    return '$formattedAmountPaid $direction via $paymentMethodDisplayName';
  }

  /// Checks if this payment was made today
  bool get isMadeToday {
    final now = DateTime.now();
    return paymentDate.year == now.year &&
           paymentDate.month == now.month &&
           paymentDate.day == now.day;
  }

  /// Checks if this payment was made this week
  bool get isMadeThisWeek {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return paymentDate.isAfter(weekAgo);
  }

  /// Returns formatted payment date for display
  String get formattedPaymentDate {
    if (isMadeToday) {
      return 'Today';
    }
    
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    
    if (paymentDate.year == yesterday.year &&
        paymentDate.month == yesterday.month &&
        paymentDate.day == yesterday.day) {
      return 'Yesterday';
    }
    
    if (isMadeThisWeek) {
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[paymentDate.weekday - 1];
    }
    
    return '${paymentDate.day}/${paymentDate.month}/${paymentDate.year}';
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        parentLoanDebtId,
        paymentDate,
        amountPaid,
        paidBy,
        notes,
        paymentTransactionMethod,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'LoanDebtPayment(id: $id, amount: $formattedAmountPaid, paidBy: $paidByDisplayName, date: $formattedPaymentDate)';
  }
}