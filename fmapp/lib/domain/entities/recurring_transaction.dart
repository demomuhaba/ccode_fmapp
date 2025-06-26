import 'package:equatable/equatable.dart';

/// Entity for recurring transaction templates
class RecurringTransaction extends Equatable {
  final String id;
  final String userId;
  final String affectedAccountId;
  final String templateName;
  final double amount;
  final String transactionType; // "Income/Credit" or "Expense/Debit"
  final String currency;
  final String? descriptionNotes;
  final String? payerSenderRaw;
  final String? payeeReceiverRaw;
  final String? referenceNumber;
  final bool isInternalTransfer;
  final String? counterpartyAccountId;
  
  // Recurring specific fields
  final String frequency; // "daily", "weekly", "monthly", "yearly"
  final int interval; // Every X days/weeks/months/years
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? lastExecuted;
  final DateTime? nextExecution;
  final bool isActive;
  final int? maxExecutions;
  final int executionCount;
  
  // Optional scheduling
  final int? dayOfMonth; // For monthly: 1-31
  final int? dayOfWeek; // For weekly: 1-7 (Monday-Sunday)
  final List<String>? tags;

  const RecurringTransaction({
    required this.id,
    required this.userId,
    required this.affectedAccountId,
    required this.templateName,
    required this.amount,
    required this.transactionType,
    required this.currency,
    this.descriptionNotes,
    this.payerSenderRaw,
    this.payeeReceiverRaw,
    this.referenceNumber,
    required this.isInternalTransfer,
    this.counterpartyAccountId,
    required this.frequency,
    required this.interval,
    required this.startDate,
    this.endDate,
    this.lastExecuted,
    this.nextExecution,
    required this.isActive,
    this.maxExecutions,
    required this.executionCount,
    this.dayOfMonth,
    this.dayOfWeek,
    this.tags,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        affectedAccountId,
        templateName,
        amount,
        transactionType,
        currency,
        descriptionNotes,
        payerSenderRaw,
        payeeReceiverRaw,
        referenceNumber,
        isInternalTransfer,
        counterpartyAccountId,
        frequency,
        interval,
        startDate,
        endDate,
        lastExecuted,
        nextExecution,
        isActive,
        maxExecutions,
        executionCount,
        dayOfMonth,
        dayOfWeek,
        tags,
      ];

  /// Calculate next execution date based on frequency and interval
  DateTime calculateNextExecution([DateTime? fromDate]) {
    final baseDate = fromDate ?? lastExecuted ?? startDate;
    
    switch (frequency.toLowerCase()) {
      case 'daily':
        return baseDate.add(Duration(days: interval));
      case 'weekly':
        return baseDate.add(Duration(days: interval * 7));
      case 'monthly':
        return DateTime(baseDate.year, baseDate.month + interval, dayOfMonth ?? baseDate.day);
      case 'yearly':
        return DateTime(baseDate.year + interval, baseDate.month, baseDate.day);
      default:
        return baseDate.add(Duration(days: interval));
    }
  }

  /// Check if the recurring transaction should be executed
  bool shouldExecute([DateTime? currentDate]) {
    final now = currentDate ?? DateTime.now();
    
    if (!isActive) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    if (maxExecutions != null && executionCount >= maxExecutions!) return false;
    if (nextExecution != null && now.isBefore(nextExecution!)) return false;
    
    return true;
  }

  /// Check if the recurring transaction has ended
  bool hasEnded([DateTime? currentDate]) {
    final now = currentDate ?? DateTime.now();
    
    if (!isActive) return true;
    if (endDate != null && now.isAfter(endDate!)) return true;
    if (maxExecutions != null && executionCount >= maxExecutions!) return true;
    
    return false;
  }

  /// Get frequency display name
  String get frequencyDisplayName {
    final intervalText = interval == 1 ? '' : ' $interval';
    switch (frequency.toLowerCase()) {
      case 'daily':
        return interval == 1 ? 'Daily' : 'Every $interval days';
      case 'weekly':
        return interval == 1 ? 'Weekly' : 'Every $interval weeks';
      case 'monthly':
        return interval == 1 ? 'Monthly' : 'Every $interval months';
      case 'yearly':
        return interval == 1 ? 'Yearly' : 'Every $interval years';
      default:
        return 'Custom${intervalText}';
    }
  }

  /// Get status display string
  String get statusDisplayName {
    if (!isActive) return 'Paused';
    if (hasEnded()) return 'Ended';
    return 'Active';
  }

  /// Copy with new values
  RecurringTransaction copyWith({
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
    return RecurringTransaction(
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

  @override
  String toString() {
    return 'RecurringTransaction(id: $id, templateName: $templateName, amount: $amount, frequency: $frequency, isActive: $isActive)';
  }
}