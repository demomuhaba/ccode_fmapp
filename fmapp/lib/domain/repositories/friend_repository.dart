import '../entities/friend_record.dart';

abstract class FriendRepository {
  Future<List<FriendRecord>> getAllFriends(String userId);
  Future<FriendRecord?> getFriendById(String id);
  Future<FriendRecord> createFriend(FriendRecord friend);
  Future<FriendRecord> updateFriend(FriendRecord friend);
  Future<void> deleteFriend(String id);
  Future<FriendRecord?> getFriendByName(String userId, String friendName);
  Future<List<FriendRecord>> searchFriendsByName(String userId, String searchTerm);
}