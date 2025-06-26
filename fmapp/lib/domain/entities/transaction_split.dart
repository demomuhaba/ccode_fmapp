import 'package:equatable/equatable.dart';

/// Entity for transaction splits - dividing a transaction into multiple categories or accounts
class TransactionSplit extends Equatable {
  final String id;
  final String parentTransactionId;
  final String userId;
  final String? categoryName;
  final String? description;
  final double amount;
  final double percentage;
  final String? notes;
  final String? assignedAccountId; // For splitting between accounts
  final String? assignedPersonId; // For splitting with friends/people
  final Map<String, dynamic>? metadata;

  const TransactionSplit({
    required this.id,
    required this.parentTransactionId,
    required this.userId,
    this.categoryName,
    this.description,
    required this.amount,
    required this.percentage,
    this.notes,
    this.assignedAccountId,
    this.assignedPersonId,
    this.metadata,
  });

  @override
  List<Object?> get props => [
        id,
        parentTransactionId,
        userId,
        categoryName,
        description,
        amount,
        percentage,
        notes,
        assignedAccountId,
        assignedPersonId,
        metadata,
      ];

  /// Check if this split is assigned to an account
  bool get isAccountSplit => assignedAccountId != null;

  /// Check if this split is assigned to a person
  bool get isPersonSplit => assignedPersonId != null;

  /// Check if this split is just a category split
  bool get isCategorySplit => !isAccountSplit && !isPersonSplit;

  /// Get display name for the split
  String get displayName {
    if (categoryName != null && categoryName!.isNotEmpty) {
      return categoryName!;
    }
    if (description != null && description!.isNotEmpty) {
      return description!;
    }
    if (isAccountSplit) {
      return 'Account Split';
    }
    if (isPersonSplit) {
      return 'Person Split';
    }
    return 'Split ${id.substring(0, 8)}';
  }

  /// Copy with new values
  TransactionSplit copyWith({
    String? id,
    String? parentTransactionId,
    String? userId,
    String? categoryName,
    String? description,
    double? amount,
    double? percentage,
    String? notes,
    String? assignedAccountId,
    String? assignedPersonId,
    Map<String, dynamic>? metadata,
  }) {
    return TransactionSplit(
      id: id ?? this.id,
      parentTransactionId: parentTransactionId ?? this.parentTransactionId,
      userId: userId ?? this.userId,
      categoryName: categoryName ?? this.categoryName,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      percentage: percentage ?? this.percentage,
      notes: notes ?? this.notes,
      assignedAccountId: assignedAccountId ?? this.assignedAccountId,
      assignedPersonId: assignedPersonId ?? this.assignedPersonId,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'TransactionSplit(id: $id, amount: $amount, percentage: $percentage, category: $categoryName)';
  }
}

/// Utility class for managing transaction splits
class TransactionSplitManager {
  
  /// Validate that splits add up to 100%
  static bool validateSplits(List<TransactionSplit> splits) {
    if (splits.isEmpty) return true;
    
    final totalPercentage = splits.fold<double>(
      0.0, 
      (sum, split) => sum + split.percentage,
    );
    
    // Allow for small floating point differences
    return (totalPercentage - 100.0).abs() < 0.01;
  }

  /// Validate that split amounts add up to total amount
  static bool validateSplitAmounts(List<TransactionSplit> splits, double totalAmount) {
    if (splits.isEmpty) return true;
    
    final totalSplitAmount = splits.fold<double>(
      0.0, 
      (sum, split) => sum + split.amount,
    );
    
    // Allow for small floating point differences
    return (totalSplitAmount - totalAmount).abs() < 0.01;
  }

  /// Calculate splits by percentage
  static List<TransactionSplit> calculateSplitsByPercentage({
    required List<Map<String, dynamic>> splitData,
    required double totalAmount,
    required String parentTransactionId,
    required String userId,
  }) {
    final splits = <TransactionSplit>[];
    
    for (int i = 0; i < splitData.length; i++) {
      final data = splitData[i];
      final percentage = data['percentage'] as double;
      final amount = totalAmount * (percentage / 100);
      
      splits.add(TransactionSplit(
        id: data['id'] ?? 'split_${parentTransactionId}_$i',
        parentTransactionId: parentTransactionId,
        userId: userId,
        categoryName: data['categoryName'],
        description: data['description'],
        amount: amount,
        percentage: percentage,
        notes: data['notes'],
        assignedAccountId: data['assignedAccountId'],
        assignedPersonId: data['assignedPersonId'],
        metadata: data['metadata'],
      ));
    }
    
    return splits;
  }

  /// Calculate splits by amount
  static List<TransactionSplit> calculateSplitsByAmount({
    required List<Map<String, dynamic>> splitData,
    required double totalAmount,
    required String parentTransactionId,
    required String userId,
  }) {
    final splits = <TransactionSplit>[];
    
    for (int i = 0; i < splitData.length; i++) {
      final data = splitData[i];
      final amount = data['amount'] as double;
      final percentage = (amount / totalAmount) * 100;
      
      splits.add(TransactionSplit(
        id: data['id'] ?? 'split_${parentTransactionId}_$i',
        parentTransactionId: parentTransactionId,
        userId: userId,
        categoryName: data['categoryName'],
        description: data['description'],
        amount: amount,
        percentage: percentage,
        notes: data['notes'],
        assignedAccountId: data['assignedAccountId'],
        assignedPersonId: data['assignedPersonId'],
        metadata: data['metadata'],
      ));
    }
    
    return splits;
  }

  /// Auto-adjust last split to make total 100%
  static List<TransactionSplit> autoAdjustSplits(List<TransactionSplit> splits, double totalAmount) {
    if (splits.isEmpty) return splits;
    
    final adjustedSplits = List<TransactionSplit>.from(splits);
    final currentTotal = adjustedSplits.fold<double>(0.0, (sum, split) => sum + split.amount);
    final difference = totalAmount - currentTotal;
    
    if (difference.abs() > 0.01) {
      // Adjust the last split
      final lastSplit = adjustedSplits.last;
      final newAmount = lastSplit.amount + difference;
      final newPercentage = (newAmount / totalAmount) * 100;
      
      adjustedSplits[adjustedSplits.length - 1] = lastSplit.copyWith(
        amount: newAmount,
        percentage: newPercentage,
      );
    }
    
    return adjustedSplits;
  }

  /// Get common expense categories for splitting
  static List<String> getCommonExpenseCategories() {
    return [
      'Food & Dining',
      'Transportation',
      'Shopping',
      'Entertainment',
      'Bills & Utilities',
      'Healthcare',
      'Education',
      'Travel',
      'Insurance',
      'Savings',
      'Investments',
      'Donations',
      'Other',
    ];
  }

  /// Get common split templates
  static List<Map<String, dynamic>> getCommonSplitTemplates() {
    return [
      {
        'name': 'Equal Split (2 ways)',
        'splits': [
          {'percentage': 50.0, 'categoryName': 'Split 1'},
          {'percentage': 50.0, 'categoryName': 'Split 2'},
        ],
      },
      {
        'name': 'Equal Split (3 ways)',
        'splits': [
          {'percentage': 33.33, 'categoryName': 'Split 1'},
          {'percentage': 33.33, 'categoryName': 'Split 2'},
          {'percentage': 33.34, 'categoryName': 'Split 3'},
        ],
      },
      {
        'name': 'Rent Split (50/30/20)',
        'splits': [
          {'percentage': 50.0, 'categoryName': 'Housing'},
          {'percentage': 30.0, 'categoryName': 'Utilities'},
          {'percentage': 20.0, 'categoryName': 'Maintenance'},
        ],
      },
      {
        'name': 'Meal Split',
        'splits': [
          {'percentage': 60.0, 'categoryName': 'Main Course'},
          {'percentage': 25.0, 'categoryName': 'Drinks'},
          {'percentage': 15.0, 'categoryName': 'Tip'},
        ],
      },
    ];
  }
}