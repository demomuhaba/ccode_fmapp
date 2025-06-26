import '../../domain/entities/recurring_transaction.dart';

class RecurringTransactionModel extends RecurringTransaction {
  const RecurringTransactionModel({
    required super.id,
    required super.userId,
    required super.affectedAccountId,
    required super.templateName,
    required super.amount,
    required super.transactionType,
    required super.currency,
    super.descriptionNotes,
    super.payerSenderRaw,
    super.payeeReceiverRaw,
    super.referenceNumber,
    required super.isInternalTransfer,
    super.counterpartyAccountId,
    required super.frequency,
    required super.interval,
    required super.startDate,
    super.endDate,
    super.lastExecuted,
    super.nextExecution,
    required super.isActive,
    super.maxExecutions,
    required super.executionCount,
    super.dayOfMonth,
    super.dayOfWeek,
    super.tags,
  });

  factory RecurringTransactionModel.fromJson(Map<String, dynamic> json) {
    return RecurringTransactionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      affectedAccountId: json['affected_account_id'] as String,
      templateName: json['template_name'] as String,
      amount: (json['amount'] as num).toDouble(),
      transactionType: json['transaction_type'] as String,
      currency: json['currency'] as String,
      descriptionNotes: json['description_notes'] as String?,
      payerSenderRaw: json['payer_sender_raw'] as String?,
      payeeReceiverRaw: json['payee_receiver_raw'] as String?,
      referenceNumber: json['reference_number'] as String?,
      isInternalTransfer: json['is_internal_transfer'] as bool,
      counterpartyAccountId: json['counterparty_account_id'] as String?,
      frequency: json['frequency'] as String,
      interval: json['interval'] as int,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date'] as String) : null,
      lastExecuted: json['last_executed'] != null ? DateTime.parse(json['last_executed'] as String) : null,
      nextExecution: json['next_execution'] != null ? DateTime.parse(json['next_execution'] as String) : null,
      isActive: json['is_active'] as bool,
      maxExecutions: json['max_executions'] as int?,
      executionCount: json['execution_count'] as int,
      dayOfMonth: json['day_of_month'] as int?,
      dayOfWeek: json['day_of_week'] as int?,
      tags: json['tags'] != null ? List<String>.from(json['tags'] as List) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'affected_account_id': affectedAccountId,
      'template_name': templateName,
      'amount': amount,
      'transaction_type': transactionType,
      'currency': currency,
      'description_notes': descriptionNotes,
      'payer_sender_raw': payerSenderRaw,
      'payee_receiver_raw': payeeReceiverRaw,
      'reference_number': referenceNumber,
      'is_internal_transfer': isInternalTransfer,
      'counterparty_account_id': counterpartyAccountId,
      'frequency': frequency,
      'interval': interval,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'last_executed': lastExecuted?.toIso8601String(),
      'next_execution': nextExecution?.toIso8601String(),
      'is_active': isActive,
      'max_executions': maxExecutions,
      'execution_count': executionCount,
      'day_of_month': dayOfMonth,
      'day_of_week': dayOfWeek,
      'tags': tags,
    };
  }

  factory RecurringTransactionModel.fromEntity(RecurringTransaction entity) {
    return RecurringTransactionModel(
      id: entity.id,
      userId: entity.userId,
      affectedAccountId: entity.affectedAccountId,
      templateName: entity.templateName,
      amount: entity.amount,
      transactionType: entity.transactionType,
      currency: entity.currency,
      descriptionNotes: entity.descriptionNotes,
      payerSenderRaw: entity.payerSenderRaw,
      payeeReceiverRaw: entity.payeeReceiverRaw,
      referenceNumber: entity.referenceNumber,
      isInternalTransfer: entity.isInternalTransfer,
      counterpartyAccountId: entity.counterpartyAccountId,
      frequency: entity.frequency,
      interval: entity.interval,
      startDate: entity.startDate,
      endDate: entity.endDate,
      lastExecuted: entity.lastExecuted,
      nextExecution: entity.nextExecution,
      isActive: entity.isActive,
      maxExecutions: entity.maxExecutions,
      executionCount: entity.executionCount,
      dayOfMonth: entity.dayOfMonth,
      dayOfWeek: entity.dayOfWeek,
      tags: entity.tags,
    );
  }

  RecurringTransaction toEntity() {
    return RecurringTransaction(
      id: id,
      userId: userId,
      affectedAccountId: affectedAccountId,
      templateName: templateName,
      amount: amount,
      transactionType: transactionType,
      currency: currency,
      descriptionNotes: descriptionNotes,
      payerSenderRaw: payerSenderRaw,
      payeeReceiverRaw: payeeReceiverRaw,
      referenceNumber: referenceNumber,
      isInternalTransfer: isInternalTransfer,
      counterpartyAccountId: counterpartyAccountId,
      frequency: frequency,
      interval: interval,
      startDate: startDate,
      endDate: endDate,
      lastExecuted: lastExecuted,
      nextExecution: nextExecution,
      isActive: isActive,
      maxExecutions: maxExecutions,
      executionCount: executionCount,
      dayOfMonth: dayOfMonth,
      dayOfWeek: dayOfWeek,
      tags: tags,
    );
  }

  /// Validation method
  String? validate() {
    if (templateName.trim().isEmpty) {
      return 'Template name is required';
    }
    if (templateName.trim().length < 3) {
      return 'Template name must be at least 3 characters';
    }
    if (amount <= 0) {
      return 'Amount must be greater than 0';
    }
    if (amount > 999999999) {
      return 'Amount cannot exceed 999,999,999 ETB';
    }
    if (!['Income/Credit', 'Expense/Debit'].contains(transactionType)) {
      return 'Invalid transaction type';
    }
    if (!['daily', 'weekly', 'monthly', 'yearly'].contains(frequency.toLowerCase())) {
      return 'Invalid frequency';
    }
    if (interval < 1 || interval > 365) {
      return 'Interval must be between 1 and 365';
    }
    if (endDate != null && endDate!.isBefore(startDate)) {
      return 'End date cannot be before start date';
    }
    if (maxExecutions != null && maxExecutions! < 1) {
      return 'Max executions must be at least 1';
    }
    if (frequency.toLowerCase() == 'monthly' && dayOfMonth != null) {
      if (dayOfMonth! < 1 || dayOfMonth! > 31) {
        return 'Day of month must be between 1 and 31';
      }
    }
    if (frequency.toLowerCase() == 'weekly' && dayOfWeek != null) {
      if (dayOfWeek! < 1 || dayOfWeek! > 7) {
        return 'Day of week must be between 1 and 7';
      }
    }
    if (isInternalTransfer && counterpartyAccountId == null) {
      return 'Counterparty account is required for internal transfers';
    }
    if (isInternalTransfer && counterpartyAccountId == affectedAccountId) {
      return 'Source and destination accounts cannot be the same';
    }
    
    return null;
  }

  @override
  RecurringTransactionModel copyWith({
    String? id,
    String? userId,
    String? affectedAccountId,
    String? templateName,
    double? amount,
    String? transactionType,
    String? currency,
    String? descriptionNotes,
    String? payerSenderRaw,
    String? payeeReceiverRaw,
    String? referenceNumber,
    bool? isInternalTransfer,
    String? counterpartyAccountId,
    String? frequency,
    int? interval,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? lastExecuted,
    DateTime? nextExecution,
    bool? isActive,
    int? maxExecutions,
    int? executionCount,
    int? dayOfMonth,
    int? dayOfWeek,
    List<String>? tags,
  }) {
    return RecurringTransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      affectedAccountId: affectedAccountId ?? this.affectedAccountId,
      templateName: templateName ?? this.templateName,
      amount: amount ?? this.amount,
      transactionType: transactionType ?? this.transactionType,
      currency: currency ?? this.currency,
      descriptionNotes: descriptionNotes ?? this.descriptionNotes,
      payerSenderRaw: payerSenderRaw ?? this.payerSenderRaw,
      payeeReceiverRaw: payeeReceiverRaw ?? this.payeeReceiverRaw,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      isInternalTransfer: isInternalTransfer ?? this.isInternalTransfer,
      counterpartyAccountId: counterpartyAccountId ?? this.counterpartyAccountId,
      frequency: frequency ?? this.frequency,
      interval: interval ?? this.interval,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      lastExecuted: lastExecuted ?? this.lastExecuted,
      nextExecution: nextExecution ?? this.nextExecution,
      isActive: isActive ?? this.isActive,
      maxExecutions: maxExecutions ?? this.maxExecutions,
      executionCount: executionCount ?? this.executionCount,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      tags: tags ?? this.tags,
    );
  }
}