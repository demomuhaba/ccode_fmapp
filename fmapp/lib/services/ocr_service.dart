import 'dart:io';
import 'package:google_ml_kit/google_ml_kit.dart';
import '../core/constants/app_constants.dart';

class OCRService {
  static final OCRService _instance = OCRService._internal();
  factory OCRService() => _instance;
  OCRService._internal();

  final TextRecognizer _textRecognizer = GoogleMlKit.vision.textRecognizer();

  Future<Map<String, dynamic>> extractTransactionData(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      final extractedData = _parseTransactionText(recognizedText.text);
      
      return {
        'success': true,
        'rawText': recognizedText.text,
        'extractedData': extractedData,
        'confidence': _calculateConfidence(extractedData),
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'OCR processing failed: $e',
        'rawText': '',
        'extractedData': <String, dynamic>{},
        'confidence': 0.0,
      };
    }
  }

  Map<String, dynamic> _parseTransactionText(String text) {
    final extractedData = <String, dynamic>{};
    final lines = text.split('\n').map((line) => line.trim()).toList();
    
    // Extract transaction amount
    final amount = _extractAmount(text);
    if (amount != null) {
      extractedData['amount'] = amount;
    }

    // Extract transaction date and time
    final dateTime = _extractDateTime(text);
    if (dateTime != null) {
      extractedData['transactionDate'] = dateTime;
    }

    // Extract transaction reference/ID
    final reference = _extractReference(text);
    if (reference != null) {
      extractedData['referenceNumber'] = reference;
    }

    // Extract payer/sender information
    final payer = _extractPayerInfo(text);
    if (payer != null) {
      extractedData['payerSenderRaw'] = payer;
    }

    // Extract payee/receiver information
    final payee = _extractPayeeInfo(text);
    if (payee != null) {
      extractedData['payeeReceiverRaw'] = payee;
    }

    // Extract transaction type
    final transactionType = _extractTransactionType(text);
    if (transactionType != null) {
      extractedData['transactionType'] = transactionType;
    }

    // Extract remaining balance
    final balance = _extractBalance(text);
    if (balance != null) {
      extractedData['remainingBalance'] = balance;
    }

    // Extract service provider
    final provider = _extractServiceProvider(text);
    if (provider != null) {
      extractedData['serviceProvider'] = provider;
    }

    return extractedData;
  }

  double? _extractAmount(String text) {
    // Ethiopian financial patterns
    final amountPatterns = [
      RegExp(r'ETB\s*(\d+(?:,\d{3})*(?:\.\d{2})?)', caseSensitive: false),
      RegExp(r'Birr\s*(\d+(?:,\d{3})*(?:\.\d{2})?)', caseSensitive: false),
      RegExp(r'Amount[:\s]*ETB\s*(\d+(?:,\d{3})*(?:\.\d{2})?)', caseSensitive: false),
      RegExp(r'(\d+(?:,\d{3})*(?:\.\d{2})?)\s*ETB', caseSensitive: false),
      RegExp(r'(\d+(?:,\d{3})*(?:\.\d{2})?)\s*Birr', caseSensitive: false),
      RegExp(r'Transfer[:\s]*(\d+(?:,\d{3})*(?:\.\d{2})?)', caseSensitive: false),
      RegExp(r'Payment[:\s]*(\d+(?:,\d{3})*(?:\.\d{2})?)', caseSensitive: false),
    ];

    for (final pattern in amountPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final amountStr = match.group(1)?.replaceAll(',', '') ?? '';
        final amount = double.tryParse(amountStr);
        if (amount != null && amount > 0) {
          return amount;
        }
      }
    }

    return null;
  }

  DateTime? _extractDateTime(String text) {
    final dateTimePatterns = [
      // Ethiopian date formats
      RegExp(r'(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4})\s+(\d{1,2}):(\d{2})(?::(\d{2}))?', caseSensitive: false),
      RegExp(r'(\d{4})[\/\-](\d{1,2})[\/\-](\d{1,2})\s+(\d{1,2}):(\d{2})(?::(\d{2}))?', caseSensitive: false),
      RegExp(r'Date[:\s]*(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4})', caseSensitive: false),
      RegExp(r'Time[:\s]*(\d{1,2}):(\d{2})(?::(\d{2}))?', caseSensitive: false),
      RegExp(r'(\d{1,2})\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+(\d{4})', caseSensitive: false),
    ];

    for (final pattern in dateTimePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        try {
          // Try to parse the extracted date/time
          if (match.groupCount >= 6) {
            // Full date and time
            final day = int.parse(match.group(1) ?? '1');
            final month = int.parse(match.group(2) ?? '1');
            final year = int.parse(match.group(3) ?? '2024');
            final hour = int.parse(match.group(4) ?? '0');
            final minute = int.parse(match.group(5) ?? '0');
            final second = int.parse(match.group(6) ?? '0');
            
            return DateTime(year, month, day, hour, minute, second);
          } else if (match.groupCount >= 3) {
            // Date only
            final day = int.parse(match.group(1) ?? '1');
            final month = int.parse(match.group(2) ?? '1');
            final year = int.parse(match.group(3) ?? '2024');
            
            return DateTime(year, month, day);
          }
        } catch (e) {
          continue;
        }
      }
    }

    return null;
  }

  String? _extractReference(String text) {
    final referencePatterns = [
      RegExp(r'Ref[erence]*[:\s]*([A-Z0-9]{6,})', caseSensitive: false),
      RegExp(r'TXN[:\s]*([A-Z0-9]{6,})', caseSensitive: false),
      RegExp(r'Transaction[:\s]*([A-Z0-9]{6,})', caseSensitive: false),
      RegExp(r'ID[:\s]*([A-Z0-9]{6,})', caseSensitive: false),
      RegExp(r'([A-Z0-9]{8,15})', caseSensitive: false),
    ];

    for (final pattern in referencePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final ref = match.group(1);
        if (ref != null && ref.length >= 6) {
          return ref;
        }
      }
    }

    return null;
  }

  String? _extractPayerInfo(String text) {
    final payerPatterns = [
      RegExp(r'From[:\s]*([^\n\r]+)', caseSensitive: false),
      RegExp(r'Sender[:\s]*([^\n\r]+)', caseSensitive: false),
      RegExp(r'Payer[:\s]*([^\n\r]+)', caseSensitive: false),
      RegExp(r'Source[:\s]*([^\n\r]+)', caseSensitive: false),
    ];

    for (final pattern in payerPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final payer = match.group(1)?.trim();
        if (payer != null && payer.isNotEmpty) {
          return payer;
        }
      }
    }

    return null;
  }

  String? _extractPayeeInfo(String text) {
    final payeePatterns = [
      RegExp(r'To[:\s]*([^\n\r]+)', caseSensitive: false),
      RegExp(r'Receiver[:\s]*([^\n\r]+)', caseSensitive: false),
      RegExp(r'Payee[:\s]*([^\n\r]+)', caseSensitive: false),
      RegExp(r'Destination[:\s]*([^\n\r]+)', caseSensitive: false),
      RegExp(r'Merchant[:\s]*([^\n\r]+)', caseSensitive: false),
    ];

    for (final pattern in payeePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final payee = match.group(1)?.trim();
        if (payee != null && payee.isNotEmpty) {
          return payee;
        }
      }
    }

    return null;
  }

  String? _extractTransactionType(String text) {
    final lowerText = text.toLowerCase();
    
    if (lowerText.contains('transfer') || lowerText.contains('send')) {
      return 'Expense/Debit';
    } else if (lowerText.contains('receive') || lowerText.contains('deposit')) {
      return 'Income/Credit';
    } else if (lowerText.contains('withdraw') || lowerText.contains('cash out')) {
      return 'Expense/Debit';
    } else if (lowerText.contains('payment') && lowerText.contains('from')) {
      return 'Income/Credit';
    } else if (lowerText.contains('payment') && lowerText.contains('to')) {
      return 'Expense/Debit';
    }

    return null;
  }

  double? _extractBalance(String text) {
    final balancePatterns = [
      RegExp(r'Balance[:\s]*ETB\s*(\d+(?:,\d{3})*(?:\.\d{2})?)', caseSensitive: false),
      RegExp(r'Remaining[:\s]*ETB\s*(\d+(?:,\d{3})*(?:\.\d{2})?)', caseSensitive: false),
      RegExp(r'Available[:\s]*ETB\s*(\d+(?:,\d{3})*(?:\.\d{2})?)', caseSensitive: false),
      RegExp(r'New Balance[:\s]*(\d+(?:,\d{3})*(?:\.\d{2})?)', caseSensitive: false),
    ];

    for (final pattern in balancePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final balanceStr = match.group(1)?.replaceAll(',', '') ?? '';
        final balance = double.tryParse(balanceStr);
        if (balance != null && balance >= 0) {
          return balance;
        }
      }
    }

    return null;
  }

  String? _extractServiceProvider(String text) {
    final lowerText = text.toLowerCase();
    
    // Check for Ethiopian financial service providers
    for (final provider in AppConstants.ethiopianBanks) {
      if (lowerText.contains(provider.toLowerCase())) {
        return provider;
      }
    }

    for (final service in AppConstants.mobileMoneyServices) {
      if (lowerText.contains(service.toLowerCase())) {
        return service;
      }
    }

    // Check for telecom providers
    for (final telecom in AppConstants.telecomProviders) {
      if (lowerText.contains(telecom.toLowerCase())) {
        return telecom;
      }
    }

    return null;
  }

  double _calculateConfidence(Map<String, dynamic> extractedData) {
    int foundFields = 0;
    const totalImportantFields = 4; // amount, date, type, reference

    if (extractedData.containsKey('amount')) foundFields++;
    if (extractedData.containsKey('transactionDate')) foundFields++;
    if (extractedData.containsKey('transactionType')) foundFields++;
    if (extractedData.containsKey('referenceNumber')) foundFields++;

    return foundFields / totalImportantFields;
  }

  Future<bool> validateImageFile(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        return false;
      }

      final fileSize = await file.length();
      if (fileSize > 10 * 1024 * 1024) { // 10MB limit
        return false;
      }

      final extension = imagePath.toLowerCase().split('.').last;
      return ['jpg', 'jpeg', 'png', 'bmp', 'gif'].contains(extension);
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    _textRecognizer.close();
  }
}