import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/riverpod_providers.dart' as providers;
import 'add_friend_screen.dart';
import 'edit_friend_screen.dart';
import '../loans/loan_debt_list_screen.dart';

class FriendListScreen extends ConsumerStatefulWidget {
  const FriendListScreen({super.key});

  @override
  ConsumerState<FriendListScreen> createState() => _FriendListScreenState();
}

class _FriendListScreenState extends ConsumerState<FriendListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFriends() async {
    final authState = ref.read(providers.authNotifierProvider);
    final userId = authState.userProfile?.userId;
    
    if (userId != null) {
      await ref.read(providers.friendNotifierProvider.notifier).loadFriends(userId);
    }
  }

  Future<void> _handleRefresh() async {
    await _loadFriends();
  }

  void _handleSearch(String searchTerm) {
    final authState = ref.read(providers.authNotifierProvider);
    final userId = authState.userProfile?.userId;
    
    if (userId != null) {
      ref.read(providers.friendNotifierProvider.notifier).searchFriends(userId, searchTerm);
    }
  }

  void _navigateToAddFriend() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AddFriendScreen()),
    );
    
    if (result == true) {
      await _handleRefresh();
    }
  }

  void _navigateToEditFriend(String friendId) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditFriendScreen(friendId: friendId),
      ),
    );
    
    if (result == true) {
      await _handleRefresh();
    }
  }

  void _navigateToFriendLoansDebts(String friendId, String friendName) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LoanDebtListScreen(friendId: friendId, friendName: friendName),
      ),
    );
  }

  void _confirmDeleteFriend(String friendId, String friendName) async {
    final friendNotifier = ref.read(providers.friendNotifierProvider.notifier);
    final canDelete = await friendNotifier.canDeleteFriend(friendId);
    
    if (!canDelete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete friend with active loans or debts'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Friend'),
          content: Text('Are you sure you want to delete "$friendName"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteFriend(friendId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _deleteFriend(String friendId) async {
    final friendNotifier = ref.read(providers.friendNotifierProvider.notifier);
    
    final success = await friendNotifier.deleteFriend(friendId);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Friend deleted successfully' : 'Failed to delete friend'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _handleRefresh,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search friends...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _handleSearch('');
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: _handleSearch,
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              child: Consumer(
                builder: (context, ref, child) {
                  final friendState = ref.watch(providers.friendNotifierProvider);
                  
                  if (friendState.error != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error: ${friendState.error}',
                            style: const TextStyle(fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              ref.read(providers.friendNotifierProvider.notifier).clearError();
                              _handleRefresh();
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (friendState.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final friends = friendState.friends;

                  if (friends.isEmpty && friendState.searchQuery.isEmpty) {
                    return _buildEmptyState();
                  }

                  if (friends.isEmpty && friendState.searchQuery.isNotEmpty) {
                    return _buildNoSearchResults(friendState.searchQuery);
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: friends.length,
                    itemBuilder: (context, index) {
                      final friend = friends[index];
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.withOpacity(0.1),
                            child: Text(
                              friend.initials,
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            friend.friendName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (friend.friendPhoneNumber != null)
                                Text(friend.friendPhoneNumber!),
                              if (friend.notes != null && friend.notes!.isNotEmpty)
                                Text(
                                  friend.notes!,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                _navigateToEditFriend(friend.id);
                              } else if (value == 'loans') {
                                _navigateToFriendLoansDebts(friend.id, friend.friendName);
                              } else if (value == 'delete') {
                                _confirmDeleteFriend(friend.id, friend.friendName);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: ListTile(
                                  leading: Icon(Icons.edit),
                                  title: Text('Edit'),
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'loans',
                                child: ListTile(
                                  leading: Icon(Icons.handshake),
                                  title: Text('Loans & Debts'),
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: ListTile(
                                  leading: Icon(Icons.delete, color: Colors.red),
                                  title: Text('Delete', style: TextStyle(color: Colors.red)),
                                ),
                              ),
                            ],
                          ),
                          isThreeLine: friend.notes != null && friend.notes!.isNotEmpty,
                          onTap: () => _navigateToFriendLoansDebts(friend.id, friend.friendName),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddFriend,
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          const Text(
            'No Friends Added',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add friends to track loans and debts',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _navigateToAddFriend,
            icon: const Icon(Icons.person_add),
            label: const Text('Add Friend'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSearchResults(String searchQuery) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          const Text(
            'No Friends Found',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No friends match "$searchQuery"',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  _searchController.clear();
                  _handleSearch('');
                },
                child: const Text('Clear Search'),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _navigateToAddFriend,
                icon: const Icon(Icons.person_add),
                label: const Text('Add Friend'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}