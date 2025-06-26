import 'package:equatable/equatable.dart';
import '../../domain/entities/loan_debt_payment.dart';

class LoanDebtPaymentModel extends Equatable {
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

  const LoanDebtPaymentModel({
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

  factory LoanDebtPaymentModel.fromEntity(LoanDebtPayment entity) {
    return LoanDebtPaymentModel(
      id: entity.id,
      userId: entity.userId,
      parentLoanDebtId: entity.parentLoanDebtId,
      paymentDate: entity.paymentDate,
      amountPaid: entity.amountPaid,
      paidBy: entity.paidBy,
      notes: entity.notes,
      paymentTransactionMethod: entity.paymentTransactionMethod,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  LoanDebtPayment toEntity() {
    return LoanDebtPayment(
      id: id,
      userId: userId,
      parentLoanDebtId: parentLoanDebtId,
      paymentDate: paymentDate,
      amountPaid: amountPaid,
      paidBy: paidBy,
      notes: notes,
      paymentTransactionMethod: paymentTransactionMethod,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory LoanDebtPaymentModel.fromJson(Map<String, dynamic> json) {
    return LoanDebtPaymentModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      parentLoanDebtId: json['parent_loan_debt_id'] as String,
      paymentDate: DateTime.parse(json['payment_date'] as String),
      amountPaid: (json['amount_paid'] as num).toDouble(),
      paidBy: json['paid_by'] as String,
      notes: json['notes'] as String?,
      paymentTransactionMethod: json['payment_transaction_method'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'parent_loan_debt_id': parentLoanDebtId,
      'payment_date': paymentDate.toIso8601String(),
      'amount_paid': amountPaid,
      'paid_by': paidBy,
      'notes': notes,
      'payment_transaction_method': paymentTransactionMethod,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toJsonForInsert() {
    final json = toJson();
    json.remove('id');
    json.remove('created_at');
    json.remove('updated_at');
    return json;
  }

  LoanDebtPaymentModel copyWith({
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
    return LoanDebtPaymentModel(
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

  String get formattedAmount {
    return 'ETB ${amountPaid.toStringAsFixed(2)}';
  }

  String get formattedDate {
    return '${paymentDate.day}/${paymentDate.month}/${paymentDate.year}';
  }

  String get formattedDateTime {
    final date = formattedDate;
    final time = '${paymentDate.hour.toString().padLeft(2, '0')}:${paymentDate.minute.toString().padLeft(2, '0')}';
    return '$date at $time';
  }

  bool get isPaidByUser {
    return paidBy.toLowerCase() == 'usertofriend';
  }

  bool get isPaidByFriend {
    return paidBy.toLowerCase() == 'friendtouser';
  }

  bool get wasPaidWithAccount {
    return paymentTransactionMethod.toLowerCase() != 'cash';
  }

  String get paymentMethodDisplay {
    if (wasPaidWithAccount) {
      return 'Account Transfer';
    }
    return 'Cash';
  }

  String get paymentDirectionDisplay {
    if (isPaidByUser) {
      return 'You paid';
    } else if (isPaidByFriend) {
      return 'Friend paid';
    }
    return 'Payment';
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
}