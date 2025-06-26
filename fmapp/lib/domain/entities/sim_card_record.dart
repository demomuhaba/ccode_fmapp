// Domain entity for SIM Card Record
// Represents user's personal SIM cards with Ethiopian telecom providers

import 'package:equatable/equatable.dart';

class SimCardRecord extends Equatable {
  final String id;
  final String userId;
  final String phoneNumber;
  final String simNickname;
  final String telecomProvider;
  final String? officialRegisteredName;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SimCardRecord({
    required this.id,
    required this.userId,
    required this.phoneNumber,
    required this.simNickname,
    required this.telecomProvider,
    this.officialRegisteredName,
    required this.createdAt,
    required this.updatedAt,
  });

  SimCardRecord copyWith({
    String? id,
    String? userId,
    String? phoneNumber,
    String? simNickname,
    String? telecomProvider,
    String? officialRegisteredName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SimCardRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      simNickname: simNickname ?? this.simNickname,
      telecomProvider: telecomProvider ?? this.telecomProvider,
      officialRegisteredName: officialRegisteredName ?? this.officialRegisteredName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Validates if the phone number follows Ethiopian format
  bool get isValidEthiopianPhoneNumber {
    // Ethiopian phone numbers: +251XXXXXXXXX or 0XXXXXXXXX format
    final phoneRegex = RegExp(r'^(\+251|0)[79]\d{8}$');
    return phoneRegex.hasMatch(phoneNumber);
  }

  /// Returns formatted phone number for display
  String get formattedPhoneNumber {
    if (phoneNumber.startsWith('+251')) {
      return phoneNumber;
    } else if (phoneNumber.startsWith('0')) {
      return '+251${phoneNumber.substring(1)}';
    }
    return phoneNumber;
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        phoneNumber,
        simNickname,
        telecomProvider,
        officialRegisteredName,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'SimCardRecord(id: $id, phoneNumber: $phoneNumber, nickname: $simNickname, provider: $telecomProvider)';
  }
}