// Domain entity for Financial Account Record
// Represents user's financial accounts (bank, mobile wallet, online money)

import 'package:equatable/equatable.dart';
import '../../core/constants/app_constants.dart';

class FinancialAccountRecord extends Equatable {
  final String id;
  final String userId;
  final String accountName;
  final String accountIdentifier;
  final String accountType;
  final String linkedSimId;
  final double initialBalance;
  final DateTime dateAdded;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FinancialAccountRecord({
    required this.id,
    required this.userId,
    required this.accountName,
    required this.accountIdentifier,
    required this.accountType,
    required this.linkedSimId,
    required this.initialBalance,
    required this.dateAdded,
    required this.createdAt,
    required this.updatedAt,
  });

  FinancialAccountRecord copyWith({
    String? id,
    String? userId,
    String? accountName,
    String? accountIdentifier,
    String? accountType,
    String? linkedSimId,
    double? initialBalance,
    DateTime? dateAdded,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FinancialAccountRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      accountName: accountName ?? this.accountName,
      accountIdentifier: accountIdentifier ?? this.accountIdentifier,
      accountType: accountType ?? this.accountType,
      linkedSimId: linkedSimId ?? this.linkedSimId,
      initialBalance: initialBalance ?? this.initialBalance,
      dateAdded: dateAdded ?? this.dateAdded,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Validates if the account type is supported
  bool get isValidAccountType {
    return AppConstants.accountTypes.contains(accountType);
  }

  /// Checks if this is a bank account
  bool get isBankAccount {
    return accountType == AppConstants.accountTypeBankAccount;
  }

  /// Checks if this is a mobile wallet
  bool get isMobileWallet {
    return accountType == AppConstants.accountTypeMobileWallet;
  }

  /// Checks if this is an online money account
  bool get isOnlineMoneyAccount {
    return accountType == AppConstants.accountTypeOnlineMoney;
  }

  /// Returns formatted initial balance in ETB
  String get formattedInitialBalance {
    return '${AppConstants.currencySymbol} ${initialBalance.toStringAsFixed(2)}';
  }

  /// Returns account type display name
  String get accountTypeDisplayName {
    switch (accountType) {
      case AppConstants.accountTypeBankAccount:
        return 'Bank Account';
      case AppConstants.accountTypeMobileWallet:
        return 'Mobile Wallet';
      case AppConstants.accountTypeOnlineMoney:
        return 'Online Money';
      default:
        return accountType;
    }
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        accountName,
        accountIdentifier,
        accountType,
        linkedSimId,
        initialBalance,
        dateAdded,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'FinancialAccountRecord(id: $id, name: $accountName, type: $accountType, balance: $formattedInitialBalance)';
  }
}