import 'package:equatable/equatable.dart';

/// Entity representing the result of OCR processing
class OCRResult extends Equatable {
  final bool success;
  final String rawText;
  final TransactionData? extractedData;
  final double confidence;
  final String? errorMessage;
  final String? errorCode;
  final List<String> warnings;
  final ProcessingMetadata metadata;

  const OCRResult({
    required this.success,
    required this.rawText,
    this.extractedData,
    required this.confidence,
    this.errorMessage,
    this.errorCode,
    this.warnings = const [],
    required this.metadata,
  });

  /// Factory constructor for successful OCR result
  factory OCRResult.success({
    required String rawText,
    required TransactionData extractedData,
    required double confidence,
    List<String> warnings = const [],
    required ProcessingMetadata metadata,
  }) {
    return OCRResult(
      success: true,
      rawText: rawText,
      extractedData: extractedData,
      confidence: confidence,
      warnings: warnings,
      metadata: metadata,
    );
  }

  /// Factory constructor for failed OCR result
  factory OCRResult.failure({
    required String errorMessage,
    String? errorCode,
    String rawText = '',
    double confidence = 0.0,
    List<String> warnings = const [],
    required ProcessingMetadata metadata,
  }) {
    return OCRResult(
      success: false,
      rawText: rawText,
      confidence: confidence,
      errorMessage: errorMessage,
      errorCode: errorCode,
      warnings: warnings,
      metadata: metadata,
    );
  }

  /// Check if the result has high confidence
  bool get hasHighConfidence => confidence >= 0.8;

  /// Check if the result has medium confidence
  bool get hasMediumConfidence => confidence >= 0.5 && confidence < 0.8;

  /// Check if the result has low confidence
  bool get hasLowConfidence => confidence < 0.5;

  /// Get confidence level as string
  String get confidenceLevel {
    if (hasHighConfidence) return 'High';
    if (hasMediumConfidence) return 'Medium';
    return 'Low';
  }

  /// Check if result is usable (successful with reasonable confidence)
  bool get isUsable => success && confidence >= 0.3;

  @override
  List<Object?> get props => [
        success,
        rawText,
        extractedData,
        confidence,
        errorMessage,
        errorCode,
        warnings,
        metadata,
      ];

  @override
  String toString() {
    return 'OCRResult(success: $success, confidence: $confidence, errorMessage: $errorMessage)';
  }
}

/// Entity representing extracted transaction data
class TransactionData extends Equatable {
  final double? amount;
  final DateTime? transactionDate;
  final String? transactionType;
  final String? referenceNumber;
  final String? payerSenderRaw;
  final String? payeeReceiverRaw;
  final double? remainingBalance;
  final String? serviceProvider;
  final String? description;
  final String? currency;
  final Map<String, dynamic> additionalFields;

  const TransactionData({
    this.amount,
    this.transactionDate,
    this.transactionType,
    this.referenceNumber,
    this.payerSenderRaw,
    this.payeeReceiverRaw,
    this.remainingBalance,
    this.serviceProvider,
    this.description,
    this.currency,
    this.additionalFields = const {},
  });

  /// Check if transaction data has minimum required fields
  bool get hasMinimumData => amount != null || transactionDate != null || referenceNumber != null;

  /// Get completeness score (0.0 to 1.0)
  double get completenessScore {
    int filledFields = 0;
    const totalFields = 8; // Core fields count

    if (amount != null) filledFields++;
    if (transactionDate != null) filledFields++;
    if (transactionType != null) filledFields++;
    if (referenceNumber != null) filledFields++;
    if (payerSenderRaw != null) filledFields++;
    if (payeeReceiverRaw != null) filledFields++;
    if (serviceProvider != null) filledFields++;
    if (description != null) filledFields++;

    return filledFields / totalFields;
  }

  /// Convert to map for serialization
  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'transactionDate': transactionDate?.toIso8601String(),
      'transactionType': transactionType,
      'referenceNumber': referenceNumber,
      'payerSenderRaw': payerSenderRaw,
      'payeeReceiverRaw': payeeReceiverRaw,
      'remainingBalance': remainingBalance,
      'serviceProvider': serviceProvider,
      'description': description,
      'currency': currency ?? 'ETB',
      'additionalFields': additionalFields,
    };
  }

  /// Create from map
  factory TransactionData.fromMap(Map<String, dynamic> map) {
    return TransactionData(
      amount: map['amount']?.toDouble(),
      transactionDate: map['transactionDate'] != null 
          ? DateTime.tryParse(map['transactionDate']) 
          : null,
      transactionType: map['transactionType'],
      referenceNumber: map['referenceNumber'],
      payerSenderRaw: map['payerSenderRaw'],
      payeeReceiverRaw: map['payeeReceiverRaw'],
      remainingBalance: map['remainingBalance']?.toDouble(),
      serviceProvider: map['serviceProvider'],
      description: map['description'],
      currency: map['currency'] ?? 'ETB',
      additionalFields: Map<String, dynamic>.from(map['additionalFields'] ?? {}),
    );
  }

  @override
  List<Object?> get props => [
        amount,
        transactionDate,
        transactionType,
        referenceNumber,
        payerSenderRaw,
        payeeReceiverRaw,
        remainingBalance,
        serviceProvider,
        description,
        currency,
        additionalFields,
      ];

  @override
  String toString() {
    return 'TransactionData(amount: $amount, type: $transactionType, ref: $referenceNumber)';
  }
}

/// Metadata about OCR processing
class ProcessingMetadata extends Equatable {
  final DateTime processedAt;
  final Duration processingTime;
  final String imageFormat;
  final int? imageSize;
  final String? mlKitVersion;
  final bool isOfflineProcessing;
  final Map<String, dynamic> debugInfo;

  const ProcessingMetadata({
    required this.processedAt,
    required this.processingTime,
    required this.imageFormat,
    this.imageSize,
    this.mlKitVersion,
    required this.isOfflineProcessing,
    this.debugInfo = const {},
  });

  @override
  List<Object?> get props => [
        processedAt,
        processingTime,
        imageFormat,
        imageSize,
        mlKitVersion,
        isOfflineProcessing,
        debugInfo,
      ];

  @override
  String toString() {
    return 'ProcessingMetadata(time: ${processingTime.inMilliseconds}ms, offline: $isOfflineProcessing)';
  }
}