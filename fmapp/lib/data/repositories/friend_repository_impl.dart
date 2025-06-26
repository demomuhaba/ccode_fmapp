import '../../domain/entities/friend_record.dart';
import '../../domain/repositories/friend_repository.dart';
import '../../services/supabase_service.dart';
import '../models/friend_record_model.dart';

class FriendRepositoryImpl implements FriendRepository {
  final SupabaseService _supabaseService;

  FriendRepositoryImpl(this._supabaseService);

  @override
  Future<List<FriendRecord>> getAllFriends(String userId) async {
    try {
      final data = await _supabaseService.getRecordsByCondition(
        table: 'friend_records',
        conditions: {'user_id': userId},
      );
      return data.map((json) => FriendRecordModel.fromJson(json).toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to get friends: $e');
    }
  }

  @override
  Future<FriendRecord?> getFriendById(String id) async {
    try {
      final data = await _supabaseService.getRecordById(table: 'friend_records', id: id);
      if (data == null) return null;
      return FriendRecordModel.fromJson(data).toEntity();
    } catch (e) {
      throw Exception('Failed to get friend: $e');
    }
  }

  @override
  Future<FriendRecord> createFriend(FriendRecord friend) async {
    try {
      final model = FriendRecordModel.fromEntity(friend);
      final data = await _supabaseService.createRecord(table: 'friend_records', data: model.toJsonForInsert());
      return FriendRecordModel.fromJson(data).toEntity();
    } catch (e) {
      throw Exception('Failed to create friend: $e');
    }
  }

  @override
  Future<FriendRecord> updateFriend(FriendRecord friend) async {
    try {
      final model = FriendRecordModel.fromEntity(friend);
      final data = await _supabaseService.updateRecord(table: 'friend_records', id: model.id, data: model.toJsonForInsert());
      return FriendRecordModel.fromJson(data).toEntity();
    } catch (e) {
      throw Exception('Failed to update friend: $e');
    }
  }

  @override
  Future<void> deleteFriend(String id) async {
    try {
      await _supabaseService.deleteRecord(table: 'friend_records', id: id);
    } catch (e) {
      throw Exception('Failed to delete friend: $e');
    }
  }

  @override
  Future<FriendRecord?> getFriendByName(String userId, String friendName) async {
    try {
      final data = await _supabaseService.getRecordsByCondition(
        table: 'friend_records',
        conditions: {'friend_name': friendName, 'user_id': userId},
      );
      if (data.isEmpty) return null;
      return FriendRecordModel.fromJson(data.first).toEntity();
    } catch (e) {
      throw Exception('Failed to get friend by name: $e');
    }
  }

  @override
  Future<List<FriendRecord>> searchFriendsByName(String userId, String searchTerm) async {
    try {
      final allFriends = await getAllFriends(userId);
      final searchTermLower = searchTerm.toLowerCase();
      
      return allFriends.where((friend) {
        return friend.friendName.toLowerCase().contains(searchTermLower) ||
               (friend.friendPhoneNumber?.toLowerCase().contains(searchTermLower) ?? false);
      }).toList();
    } catch (e) {
      throw Exception('Failed to search friends: $e');
    }
  }
}