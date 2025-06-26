// Domain entity for Loan/Debt Item
// Represents money lent to friends or borrowed from friends

import 'package:equatable/equatable.dart';
import '../../core/constants/app_constants.dart';

class LoanDebtItem extends Equatable {
  final String id;
  final String userId;
  final String associatedFriendId;
  final String type;
  final double initialAmount;
  final double outstandingAmount;
  final String currency;
  final DateTime dateInitiated;
  final DateTime? dueDate;
  final String? description;
  final String status;
  final String initialTransactionMethod;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LoanDebtItem({
    required this.id,
    required this.userId,
    required this.associatedFriendId,
    required this.type,
    required this.initialAmount,
    required this.outstandingAmount,
    this.currency = AppConstants.defaultCurrency,
    required this.dateInitiated,
    this.dueDate,
    this.description,
    this.status = AppConstants.loanStatusActive,
    required this.initialTransactionMethod,
    required this.createdAt,
    required this.updatedAt,
  });

  LoanDebtItem copyWith({
    String? id,
    String? userId,
    String? associatedFriendId,
    String? type,
    double? initialAmount,
    double? outstandingAmount,
    String? currency,
    DateTime? dateInitiated,
    DateTime? dueDate,
    String? description,
    String? status,
    String? initialTransactionMethod,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LoanDebtItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      associatedFriendId: associatedFriendId ?? this.associatedFriendId,
      type: type ?? this.type,
      initialAmount: initialAmount ?? this.initialAmount,
      outstandingAmount: outstandingAmount ?? this.outstandingAmount,
      currency: currency ?? this.currency,
      dateInitiated: dateInitiated ?? this.dateInitiated,
      dueDate: dueDate ?? this.dueDate,
      description: description ?? this.description,
      status: status ?? this.status,
      initialTransactionMethod: initialTransactionMethod ?? this.initialTransactionMethod,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Validates if the loan/debt type is supported
  bool get isValidType {
    return AppConstants.loanDebtTypes.contains(type);
  }

  /// Checks if this is a loan given to friend
  bool get isLoanGivenToFriend {
    return type == AppConstants.loanTypeLoanGiven;
  }

  /// Checks if this is a debt owed to friend
  bool get isDebtOwedToFriend {
    return type == AppConstants.loanTypeDebtOwed;
  }

  /// Validates if the status is supported
  bool get isValidStatus {
    return AppConstants.loanStatuses.contains(status);
  }

  /// Checks if the loan/debt is active
  bool get isActive {
    return status == AppConstants.loanStatusActive;
  }

  /// Checks if the loan/debt is partially paid
  bool get isPartiallyPaid {
    return status == AppConstants.loanStatusPartiallyPaid;
  }

  /// Checks if the loan/debt is fully paid off
  bool get isPaidOff {
    return status == AppConstants.loanStatusPaidOff;
  }

  /// Checks if the loan/debt is overdue
  bool get isOverdue {
    if (dueDate == null || isPaidOff) return false;
    return DateTime.now().isAfter(dueDate!) && outstandingAmount > 0;
  }

  /// Checks if initial transaction method was cash
  bool get wasInitialTransactionCash {
    return initialTransactionMethod == AppConstants.transactionMethodCash;
  }

  /// Checks if this loan/debt has a due date
  bool get hasDueDate {
    return dueDate != null;
  }

  /// Checks if this loan/debt has a description
  bool get hasDescription {
    return description != null && description!.isNotEmpty;
  }

  /// Returns formatted initial amount in ETB
  String get formattedInitialAmount {
    return '${AppConstants.currencySymbol} ${initialAmount.toStringAsFixed(2)}';
  }

  /// Returns formatted outstanding amount in ETB
  String get formattedOutstandingAmount {
    return '${AppConstants.currencySymbol} ${outstandingAmount.toStringAsFixed(2)}';
  }

  /// Returns formatted paid amount in ETB
  String get formattedPaidAmount {
    final paidAmount = initialAmount - outstandingAmount;
    return '${AppConstants.currencySymbol} ${paidAmount.toStringAsFixed(2)}';
  }

  /// Returns payment progress as percentage
  double get paymentProgressPercentage {
    if (initialAmount == 0) return 0.0;
    final paidAmount = initialAmount - outstandingAmount;
    return (paidAmount / initialAmount) * 100;
  }

  /// Returns type display name
  String get typeDisplayName {
    switch (type) {
      case AppConstants.loanTypeLoanGiven:
        return 'Loan Given';
      case AppConstants.loanTypeDebtOwed:
        return 'Debt Owed';
      default:
        return type;
    }
  }

  /// Returns status display name
  String get statusDisplayName {
    switch (status) {
      case AppConstants.loanStatusActive:
        return 'Active';
      case AppConstants.loanStatusPartiallyPaid:
        return 'Partially Paid';
      case AppConstants.loanStatusPaidOff:
        return 'Paid Off';
      default:
        return status;
    }
  }

  /// Returns description for display purposes
  String get displayDescription {
    if (hasDescription) {
      return description!;
    }
    return typeDisplayName;
  }

  /// Calculates days until due date (negative if overdue)
  int? get daysUntilDue {
    if (dueDate == null) return null;
    final now = DateTime.now();
    final difference = dueDate!.difference(DateTime(now.year, now.month, now.day));
    return difference.inDays;
  }

  /// Returns due date status text
  String? get dueDateStatusText {
    final days = daysUntilDue;
    if (days == null) return null;
    
    if (days < 0) {
      return 'Overdue by ${-days} ${-days == 1 ? 'day' : 'days'}';
    } else if (days == 0) {
      return 'Due today';
    } else if (days <= 7) {
      return 'Due in $days ${days == 1 ? 'day' : 'days'}';
    } else {
      return 'Due on ${dueDate!.day}/${dueDate!.month}/${dueDate!.year}';
    }
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        associatedFriendId,
        type,
        initialAmount,
        outstandingAmount,
        currency,
        dateInitiated,
        dueDate,
        description,
        status,
        initialTransactionMethod,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'LoanDebtItem(id: $id, type: $typeDisplayName, amount: $formattedInitialAmount, outstanding: $formattedOutstandingAmount, status: $statusDisplayName)';
  }
}