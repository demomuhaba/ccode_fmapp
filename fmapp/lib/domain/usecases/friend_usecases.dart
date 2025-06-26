import 'package:uuid/uuid.dart';
import '../entities/friend_record.dart';
import '../repositories/friend_repository.dart';
import '../repositories/loan_debt_repository.dart';

class FriendUseCases {
  final FriendRepository _friendRepository;
  final LoanDebtRepository _loanDebtRepository;
  final Uuid _uuid = const Uuid();

  FriendUseCases(this._friendRepository, this._loanDebtRepository);

  Future<List<FriendRecord>> getAllFriends(String userId) async {
    try {
      return await _friendRepository.getAllFriends(userId);
    } catch (e) {
      throw Exception('Failed to get friends: $e');
    }
  }

  Future<FriendRecord?> getFriendById(String id) async {
    try {
      return await _friendRepository.getFriendById(id);
    } catch (e) {
      throw Exception('Failed to get friend: $e');
    }
  }

  Future<FriendRecord> createFriend({
    required String userId,
    required String friendName,
    String? friendPhoneNumber,
    String? notes,
  }) async {
    try {
      if (friendName.trim().isEmpty) {
        throw Exception('Friend name cannot be empty');
      }

      final existingFriend = await _friendRepository.getFriendByName(userId, friendName.trim());
      if (existingFriend != null) {
        throw Exception('Friend with this name already exists');
      }

      if (friendPhoneNumber != null && friendPhoneNumber.isNotEmpty) {
        final isValidPhone = await validatePhoneNumber(friendPhoneNumber);
        if (!isValidPhone) {
          throw Exception('Invalid phone number format');
        }
        friendPhoneNumber = await formatPhoneNumber(friendPhoneNumber);
      }

      final friend = FriendRecord(
        id: _uuid.v4(),
        userId: userId,
        friendName: friendName.trim(),
        friendPhoneNumber: friendPhoneNumber,
        notes: notes?.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return await _friendRepository.createFriend(friend);
    } catch (e) {
      throw Exception('Failed to create friend: $e');
    }
  }

  Future<FriendRecord> updateFriend(FriendRecord friend) async {
    try {
      if (friend.friendName.trim().isEmpty) {
        throw Exception('Friend name cannot be empty');
      }

      final existingFriend = await _friendRepository.getFriendByName(
        friend.userId,
        friend.friendName.trim(),
      );
      
      if (existingFriend != null && existingFriend.id != friend.id) {
        throw Exception('Friend with this name already exists');
      }

      String? validatedPhone = friend.friendPhoneNumber;
      if (validatedPhone != null && validatedPhone.isNotEmpty) {
        final isValidPhone = await validatePhoneNumber(validatedPhone);
        if (!isValidPhone) {
          throw Exception('Invalid phone number format');
        }
        validatedPhone = await formatPhoneNumber(validatedPhone);
      }

      final updatedFriend = friend.copyWith(
        friendName: friend.friendName.trim(),
        friendPhoneNumber: validatedPhone,
        notes: friend.notes?.trim(),
        updatedAt: DateTime.now(),
      );

      return await _friendRepository.updateFriend(updatedFriend);
    } catch (e) {
      throw Exception('Failed to update friend: $e');
    }
  }

  Future<void> deleteFriend(String id) async {
    try {
      final loanDebts = await _loanDebtRepository.getLoanDebtsByFriend(id);
      final activeItems = loanDebts.where((item) => 
        item.status.toLowerCase() == 'active' || 
        item.status.toLowerCase() == 'partiallypaid'
      ).toList();

      if (activeItems.isNotEmpty) {
        throw Exception('Cannot delete friend with active loans or debts');
      }

      await _friendRepository.deleteFriend(id);
    } catch (e) {
      throw Exception('Failed to delete friend: $e');
    }
  }

  Future<List<FriendRecord>> searchFriends(String userId, String searchTerm) async {
    try {
      if (searchTerm.trim().isEmpty) {
        return await getAllFriends(userId);
      }
      
      return await _friendRepository.searchFriendsByName(userId, searchTerm.trim());
    } catch (e) {
      throw Exception('Failed to search friends: $e');
    }
  }

  Future<Map<String, dynamic>> getFriendWithLoanDebtSummary(String friendId) async {
    try {
      final friend = await getFriendById(friendId);
      if (friend == null) {
        throw Exception('Friend not found');
      }

      final loanDebts = await _loanDebtRepository.getLoanDebtsByFriend(friendId);
      
      double totalLoansGiven = 0.0;
      double totalDebtsOwed = 0.0;
      int activeLoans = 0;
      int activeDebts = 0;

      for (final item in loanDebts) {
        if (item.status.toLowerCase() == 'active' || 
            item.status.toLowerCase() == 'partiallypaid') {
          if (item.type.toLowerCase() == 'loangiventofriend') {
            totalLoansGiven += item.outstandingAmount;
            activeLoans++;
          } else if (item.type.toLowerCase() == 'debtowedtofriend') {
            totalDebtsOwed += item.outstandingAmount;
            activeDebts++;
          }
        }
      }

      return {
        'friend': friend,
        'totalLoansGiven': totalLoansGiven,
        'totalDebtsOwed': totalDebtsOwed,
        'activeLoans': activeLoans,
        'activeDebts': activeDebts,
        'netPosition': totalLoansGiven - totalDebtsOwed,
        'allLoanDebts': loanDebts,
      };
    } catch (e) {
      throw Exception('Failed to get friend summary: $e');
    }
  }

  Future<bool> validatePhoneNumber(String phoneNumber) async {
    final ethiopianPhoneRegex = RegExp(r'^(\+251|0)[97]\d{8}$');
    return ethiopianPhoneRegex.hasMatch(phoneNumber);
  }

  Future<String> formatPhoneNumber(String phoneNumber) async {
    String formatted = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    if (formatted.startsWith('0')) {
      formatted = '+251${formatted.substring(1)}';
    } else if (formatted.startsWith('251')) {
      formatted = '+$formatted';
    } else if (!formatted.startsWith('+251')) {
      formatted = '+251$formatted';
    }
    
    return formatted;
  }

  Future<bool> canDeleteFriend(String friendId) async {
    try {
      final loanDebts = await _loanDebtRepository.getLoanDebtsByFriend(friendId);
      final activeItems = loanDebts.where((item) => 
        item.status.toLowerCase() == 'active' || 
        item.status.toLowerCase() == 'partiallypaid'
      ).toList();

      return activeItems.isEmpty;
    } catch (e) {
      return false;
    }
  }
}