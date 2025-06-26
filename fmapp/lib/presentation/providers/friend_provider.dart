import 'package:flutter/foundation.dart';
import '../../domain/entities/friend_record.dart';
import '../../domain/usecases/friend_usecases.dart';

class FriendProvider extends ChangeNotifier {
  final FriendUseCases _friendUseCases;

  FriendProvider(this._friendUseCases);

  List<FriendRecord> _friends = [];
  List<FriendRecord> _filteredFriends = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  List<FriendRecord> get friends => _searchQuery.isEmpty ? _friends : _filteredFriends;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  Future<void> loadFriends(String userId) async {
    _setLoading(true);
    try {
      _friends = await _friendUseCases.getAllFriends(userId);
      _filteredFriends = _friends;
      _clearError();
    } catch (e) {
      _setError('Failed to load friends: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createFriend({
    required String userId,
    required String friendName,
    String? friendPhoneNumber,
    String? notes,
  }) async {
    _setLoading(true);
    try {
      final newFriend = await _friendUseCases.createFriend(
        userId: userId,
        friendName: friendName,
        friendPhoneNumber: friendPhoneNumber,
        notes: notes,
      );
      
      _friends.add(newFriend);
      _friends.sort((a, b) => a.friendName.compareTo(b.friendName));
      
      if (_searchQuery.isEmpty) {
        _filteredFriends = _friends;
      } else {
        await searchFriends(userId, _searchQuery);
      }
      
      _clearError();
      return true;
    } catch (e) {
      _setError('Failed to create friend: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateFriend(FriendRecord friend) async {
    _setLoading(true);
    try {
      final updatedFriend = await _friendUseCases.updateFriend(friend);
      
      final index = _friends.indexWhere((f) => f.id == updatedFriend.id);
      if (index != -1) {
        _friends[index] = updatedFriend;
        _friends.sort((a, b) => a.friendName.compareTo(b.friendName));
      }
      
      if (_searchQuery.isNotEmpty) {
        final filteredIndex = _filteredFriends.indexWhere((f) => f.id == updatedFriend.id);
        if (filteredIndex != -1) {
          _filteredFriends[filteredIndex] = updatedFriend;
        }
      } else {
        _filteredFriends = _friends;
      }
      
      _clearError();
      return true;
    } catch (e) {
      _setError('Failed to update friend: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteFriend(String id) async {
    _setLoading(true);
    try {
      await _friendUseCases.deleteFriend(id);
      
      _friends.removeWhere((f) => f.id == id);
      _filteredFriends.removeWhere((f) => f.id == id);
      
      _clearError();
      return true;
    } catch (e) {
      _setError('Failed to delete friend: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> searchFriends(String userId, String searchTerm) async {
    _searchQuery = searchTerm;
    
    if (searchTerm.trim().isEmpty) {
      _filteredFriends = _friends;
    } else {
      try {
        _filteredFriends = await _friendUseCases.searchFriends(userId, searchTerm);
      } catch (e) {
        _setError('Failed to search friends: $e');
        _filteredFriends = [];
      }
    }
    
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _filteredFriends = _friends;
    notifyListeners();
  }

  FriendRecord? getFriendById(String id) {
    try {
      return _friends.firstWhere((f) => f.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> getFriendWithLoanDebtSummary(String friendId) async {
    try {
      return await _friendUseCases.getFriendWithLoanDebtSummary(friendId);
    } catch (e) {
      _setError('Failed to get friend summary: $e');
      return {};
    }
  }

  Future<bool> canDeleteFriend(String friendId) async {
    try {
      return await _friendUseCases.canDeleteFriend(friendId);
    } catch (e) {
      return false;
    }
  }

  Future<bool> validatePhoneNumber(String phoneNumber) async {
    return await _friendUseCases.validatePhoneNumber(phoneNumber);
  }

  Future<String> formatPhoneNumber(String phoneNumber) async {
    return await _friendUseCases.formatPhoneNumber(phoneNumber);
  }

  int get friendsCount => _friends.length;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }
}