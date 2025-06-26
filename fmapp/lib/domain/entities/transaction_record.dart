// Domain entity for Transaction Record
// Represents all financial transactions for user's accounts

import 'package:equatable/equatable.dart';
import '../../core/constants/app_constants.dart';

class TransactionRecord extends Equatable {
  final String id;
  final String userId;
  final String affectedAccountId;
  final DateTime transactionDate;
  final double amount;
  final String transactionType;
  final String currency;
  final String? descriptionNotes;
  final String? payerSenderRaw;
  final String? payeeReceiverRaw;
  final String? referenceNumber;
  final bool isInternalTransfer;
  final String? counterpartyAccountId;
  final String? receiptFileLink;
  final String? ocrExtractedRawText;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TransactionRecord({
    required this.id,
    required this.userId,
    required this.affectedAccountId,
    required this.transactionDate,
    required this.amount,
    required this.transactionType,
    this.currency = AppConstants.defaultCurrency,
    this.descriptionNotes,
    this.payerSenderRaw,
    this.payeeReceiverRaw,
    this.referenceNumber,
    this.isInternalTransfer = false,
    this.counterpartyAccountId,
    this.receiptFileLink,
    this.ocrExtractedRawText,
    required this.createdAt,
    required this.updatedAt,
  });

  TransactionRecord copyWith({
    String? id,
    String? userId,
    String? affectedAccountId,
    DateTime? transactionDate,
    double? amount,
    String? transactionType,
    String? currency,
    String? descriptionNotes,
    String? payerSenderRaw,
    String? payeeReceiverRaw,
    String? referenceNumber,
    bool? isInternalTransfer,
    String? counterpartyAccountId,
    String? receiptFileLink,
    String? ocrExtractedRawText,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TransactionRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      affectedAccountId: affectedAccountId ?? this.affectedAccountId,
      transactionDate: transactionDate ?? this.transactionDate,
      amount: amount ?? this.amount,
      transactionType: transactionType ?? this.transactionType,
      currency: currency ?? this.currency,
      descriptionNotes: descriptionNotes ?? this.descriptionNotes,
      payerSenderRaw: payerSenderRaw ?? this.payerSenderRaw,
      payeeReceiverRaw: payeeReceiverRaw ?? this.payeeReceiverRaw,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      isInternalTransfer: isInternalTransfer ?? this.isInternalTransfer,
      counterpartyAccountId: counterpartyAccountId ?? this.counterpartyAccountId,
      receiptFileLink: receiptFileLink ?? this.receiptFileLink,
      ocrExtractedRawText: ocrExtractedRawText ?? this.ocrExtractedRawText,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Validates if the transaction type is supported
  bool get isValidTransactionType {
    return AppConstants.transactionTypes.contains(transactionType);
  }

  /// Checks if this is a credit transaction (income)
  bool get isCredit {
    return transactionType == AppConstants.transactionTypeCredit;
  }

  /// Checks if this is a debit transaction (expense)
  bool get isDebit {
    return transactionType == AppConstants.transactionTypeDebit;
  }

  /// Returns the amount with proper sign for balance calculations
  /// Credit transactions are positive, debit transactions are negative
  double get signedAmount {
    return isCredit ? amount : -amount;
  }

  /// Returns formatted amount in ETB with proper sign
  String get formattedAmount {
    final sign = isCredit ? '+' : '-';
    return '$sign${AppConstants.currencySymbol} ${amount.toStringAsFixed(2)}';
  }

  /// Returns formatted amount without sign
  String get formattedAmountWithoutSign {
    return '${AppConstants.currencySymbol} ${amount.toStringAsFixed(2)}';
  }

  /// Returns transaction type display name
  String get transactionTypeDisplayName {
    switch (transactionType) {
      case AppConstants.transactionTypeCredit:
        return 'Income';
      case AppConstants.transactionTypeDebit:
        return 'Expense';
      default:
        return transactionType;
    }
  }

  /// Checks if this transaction has OCR data
  bool get hasOcrData {
    return ocrExtractedRawText != null && ocrExtractedRawText!.isNotEmpty;
  }

  /// Checks if this transaction has receipt file
  bool get hasReceiptFile {
    return receiptFileLink != null && receiptFileLink!.isNotEmpty;
  }

  /// Returns a description for display purposes
  String get displayDescription {
    if (descriptionNotes != null && descriptionNotes!.isNotEmpty) {
      return descriptionNotes!;
    }
    if (isInternalTransfer) {
      return 'Internal Transfer';
    }
    if (payeeReceiverRaw != null && payeeReceiverRaw!.isNotEmpty) {
      return isCredit ? 'From: $payeeReceiverRaw' : 'To: $payeeReceiverRaw';
    }
    if (payerSenderRaw != null && payerSenderRaw!.isNotEmpty) {
      return isCredit ? 'From: $payerSenderRaw' : 'To: $payerSenderRaw';
    }
    return transactionTypeDisplayName;
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        affectedAccountId,
        transactionDate,
        amount,
        transactionType,
        currency,
        descriptionNotes,
        payerSenderRaw,
        payeeReceiverRaw,
        referenceNumber,
        isInternalTransfer,
        counterpartyAccountId,
        receiptFileLink,
        ocrExtractedRawText,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'TransactionRecord(id: $id, amount: $formattedAmount, type: $transactionTypeDisplayName, date: $transactionDate)';
  }
}