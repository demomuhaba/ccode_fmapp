import 'package:equatable/equatable.dart';
import '../../domain/entities/loan_debt_item.dart';

class LoanDebtItemModel extends Equatable {
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

  const LoanDebtItemModel({
    required this.id,
    required this.userId,
    required this.associatedFriendId,
    required this.type,
    required this.initialAmount,
    required this.outstandingAmount,
    required this.currency,
    required this.dateInitiated,
    this.dueDate,
    this.description,
    required this.status,
    required this.initialTransactionMethod,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LoanDebtItemModel.fromEntity(LoanDebtItem entity) {
    return LoanDebtItemModel(
      id: entity.id,
      userId: entity.userId,
      associatedFriendId: entity.associatedFriendId,
      type: entity.type,
      initialAmount: entity.initialAmount,
      outstandingAmount: entity.outstandingAmount,
      currency: entity.currency,
      dateInitiated: entity.dateInitiated,
      dueDate: entity.dueDate,
      description: entity.description,
      status: entity.status,
      initialTransactionMethod: entity.initialTransactionMethod,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  LoanDebtItem toEntity() {
    return LoanDebtItem(
      id: id,
      userId: userId,
      associatedFriendId: associatedFriendId,
      type: type,
      initialAmount: initialAmount,
      outstandingAmount: outstandingAmount,
      currency: currency,
      dateInitiated: dateInitiated,
      dueDate: dueDate,
      description: description,
      status: status,
      initialTransactionMethod: initialTransactionMethod,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory LoanDebtItemModel.fromJson(Map<String, dynamic> json) {
    return LoanDebtItemModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      associatedFriendId: json['associated_friend_id'] as String,
      type: json['type'] as String,
      initialAmount: (json['initial_amount'] as num).toDouble(),
      outstandingAmount: (json['outstanding_amount'] as num).toDouble(),
      currency: json['currency'] as String,
      dateInitiated: DateTime.parse(json['date_initiated'] as String),
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date'] as String) : null,
      description: json['description'] as String,
      status: json['status'] as String,
      initialTransactionMethod: json['initial_transaction_method'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'associated_friend_id': associatedFriendId,
      'type': type,
      'initial_amount': initialAmount,
      'outstanding_amount': outstandingAmount,
      'currency': currency,
      'date_initiated': dateInitiated.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'description': description,
      'status': status,
      'initial_transaction_method': initialTransactionMethod,
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

  LoanDebtItemModel copyWith({
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
    return LoanDebtItemModel(
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

  String get formattedInitialAmount {
    return 'ETB ${initialAmount.toStringAsFixed(2)}';
  }

  String get formattedOutstandingAmount {
    return 'ETB ${outstandingAmount.toStringAsFixed(2)}';
  }

  String get formattedDateInitiated {
    return '${dateInitiated.day}/${dateInitiated.month}/${dateInitiated.year}';
  }

  String get formattedDueDate {
    if (dueDate == null) return 'No due date';
    return '${dueDate!.day}/${dueDate!.month}/${dueDate!.year}';
  }

  bool get isLoanGiven {
    return type.toLowerCase() == 'loangiventofriend';
  }

  bool get isDebtOwed {
    return type.toLowerCase() == 'debtowedtofriend';
  }

  bool get isActive {
    return status.toLowerCase() == 'active';
  }

  bool get isPartiallyPaid {
    return status.toLowerCase() == 'partiallypaid';
  }

  bool get isPaidOff {
    return status.toLowerCase() == 'paidoff';
  }

  bool get isOverdue {
    if (dueDate == null || isPaidOff) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  double get amountPaid {
    return initialAmount - outstandingAmount;
  }

  String get formattedAmountPaid {
    return 'ETB ${amountPaid.toStringAsFixed(2)}';
  }

  double get paymentProgress {
    if (initialAmount == 0) return 1.0;
    return amountPaid / initialAmount;
  }

  int get daysUntilDue {
    if (dueDate == null || isPaidOff) return 0;
    final now = DateTime.now();
    if (now.isAfter(dueDate!)) return 0;
    return dueDate!.difference(now).inDays;
  }

  bool get wasPaidWithAccount {
    return initialTransactionMethod.toLowerCase() != 'cash';
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
}