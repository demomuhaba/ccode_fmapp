import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/riverpod_providers.dart' as providers;
import 'add_sim_card_screen.dart';
import 'edit_sim_card_screen.dart';

class SimCardListScreen extends ConsumerStatefulWidget {
  const SimCardListScreen({super.key});

  @override
  ConsumerState<SimCardListScreen> createState() => _SimCardListScreenState();
}

class _SimCardListScreenState extends ConsumerState<SimCardListScreen> {
  @override
  void initState() {
    super.initState();
    _loadSimCards();
  }

  Future<void> _loadSimCards() async {
    final authState = ref.read(providers.authNotifierProvider);
    final userId = authState.userProfile?.userId;
    
    if (userId != null) {
      await ref.read(providers.simCardNotifierProvider.notifier).loadSimCards(userId);
    }
  }

  Future<void> _handleRefresh() async {
    await _loadSimCards();
  }

  void _navigateToAddSimCard() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AddSimCardScreen()),
    );
    
    if (result == true) {
      await _handleRefresh();
    }
  }

  void _navigateToEditSimCard(String simCardId) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditSimCardScreen(simCardId: simCardId),
      ),
    );
    
    if (result == true) {
      await _handleRefresh();
    }
  }

  void _confirmDeleteSimCard(String simCardId, String nickname) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete SIM Card'),
        content: Text('Are you sure you want to delete "$nickname"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteSimCard(simCardId);
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

  Future<void> _deleteSimCard(String simCardId) async {
    final success = await ref.read(providers.simCardNotifierProvider.notifier).deleteSimCard(simCardId);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'SIM card deleted successfully' : 'Failed to delete SIM card'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SIM Cards'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _handleRefresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: Consumer(
          builder: (context, ref, child) {
            final simCardState = ref.watch(providers.simCardNotifierProvider);
            
            if (simCardState.error != null) {
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
                      'Error: ${simCardState.error}',
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.read(providers.simCardNotifierProvider.notifier).clearError();
                        _handleRefresh();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (simCardState.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (simCardState.simCards.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: simCardState.simCards.length,
              itemBuilder: (context, index) {
                final simCard = simCardState.simCards[index];
                final balance = ref.read(providers.simCardNotifierProvider.notifier).getSimCardBalance(simCard.id);
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.sim_card,
                        color: Colors.blue,
                      ),
                    ),
                    title: Text(
                      simCard.simNickname,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(simCard.phoneNumber),
                        Text(
                          simCard.telecomProvider,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'ETB ${balance.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: balance >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _navigateToEditSimCard(simCard.id);
                            } else if (value == 'delete') {
                              _confirmDeleteSimCard(simCard.id, simCard.simNickname);
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
                              value: 'delete',
                              child: ListTile(
                                leading: Icon(Icons.delete, color: Colors.red),
                                title: Text('Delete', style: TextStyle(color: Colors.red)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddSimCard,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sim_card_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          const Text(
            'No SIM Cards',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add your first SIM card to get started',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _navigateToAddSimCard,
            icon: const Icon(Icons.add),
            label: const Text('Add SIM Card'),
          ),
        ],
      ),
    );
  }
}