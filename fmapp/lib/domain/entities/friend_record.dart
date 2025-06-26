// Domain entity for Friend Record
// Represents user's friends for loan/debt tracking

import 'package:equatable/equatable.dart';

class FriendRecord extends Equatable {
  final String id;
  final String userId;
  final String friendName;
  final String? friendPhoneNumber;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FriendRecord({
    required this.id,
    required this.userId,
    required this.friendName,
    this.friendPhoneNumber,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  FriendRecord copyWith({
    String? id,
    String? userId,
    String? friendName,
    String? friendPhoneNumber,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FriendRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      friendName: friendName ?? this.friendName,
      friendPhoneNumber: friendPhoneNumber ?? this.friendPhoneNumber,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Checks if friend has a phone number
  bool get hasPhoneNumber {
    return friendPhoneNumber != null && friendPhoneNumber!.isNotEmpty;
  }

  /// Validates if the phone number follows Ethiopian format (if provided)
  bool get isValidEthiopianPhoneNumber {
    if (!hasPhoneNumber) return true; // Valid if no phone number provided
    
    // Ethiopian phone numbers: +251XXXXXXXXX or 0XXXXXXXXX format
    final phoneRegex = RegExp(r'^(\+251|0)[79]\d{8}$');
    return phoneRegex.hasMatch(friendPhoneNumber!);
  }

  /// Returns formatted phone number for display (if available)
  String? get formattedPhoneNumber {
    if (!hasPhoneNumber) return null;
    
    final phone = friendPhoneNumber!;
    if (phone.startsWith('+251')) {
      return phone;
    } else if (phone.startsWith('0')) {
      return '+251${phone.substring(1)}';
    }
    return phone;
  }

  /// Returns display name with phone number if available
  String get displayNameWithPhone {
    if (hasPhoneNumber) {
      return '$friendName ($formattedPhoneNumber)';
    }
    return friendName;
  }

  /// Checks if friend has notes
  bool get hasNotes {
    return notes != null && notes!.isNotEmpty;
  }

  /// Returns initials for avatar display
  String get initials {
    final nameParts = friendName.trim().split(' ');
    if (nameParts.isEmpty) return 'F';
    
    if (nameParts.length == 1) {
      return nameParts[0].substring(0, 1).toUpperCase();
    }
    
    return '${nameParts[0].substring(0, 1)}${nameParts[1].substring(0, 1)}'.toUpperCase();
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        friendName,
        friendPhoneNumber,
        notes,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'FriendRecord(id: $id, name: $friendName, phone: $friendPhoneNumber)';
  }
}