import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/riverpod_providers.dart' as providers;

class EditFriendScreen extends ConsumerStatefulWidget {
  final String friendId;

  const EditFriendScreen({super.key, required this.friendId});

  @override
  ConsumerState<EditFriendScreen> createState() => _EditFriendScreenState();
}

class _EditFriendScreenState extends ConsumerState<EditFriendScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFriendData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _loadFriendData() {
    final friendNotifier = ref.read(providers.friendNotifierProvider.notifier);
    final friend = friendNotifier.getFriendById(widget.friendId);
    
    if (friend != null) {
      _nameController.text = friend.friendName;
      _phoneController.text = friend.friendPhoneNumber ?? '';
      _notesController.text = friend.notes ?? '';
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final friendNotifier = ref.read(providers.friendNotifierProvider.notifier);
    final friend = friendNotifier.getFriendById(widget.friendId);
    
    if (friend == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Friend not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final updatedFriend = friend.copyWith(
      friendName: _nameController.text.trim(),
      friendPhoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    final success = await friendNotifier.updateFriend(updatedFriend);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Friend updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ref.read(providers.friendNotifierProvider).error ?? 'Failed to update friend'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Friend')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Friend'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Friend Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                        hintText: 'Enter friend\'s name',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter friend\'s name';
                        }
                        if (value.trim().length < 2) {
                          return 'Name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        hintText: '+251901234567 or 0901234567',
                        prefixIcon: Icon(Icons.phone),
                      ),
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          final ethiopianPhoneRegex = RegExp(r'^(\+251|0)[97]\d{8}$');
                          if (!ethiopianPhoneRegex.hasMatch(value.trim())) {
                            return 'Please enter a valid Ethiopian phone number';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        hintText: 'Any additional notes about this friend',
                        prefixIcon: Icon(Icons.note),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '* Required fields',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Consumer(
              builder: (context, ref, child) {
                final friendState = ref.watch(providers.friendNotifierProvider);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (friendState.error != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          friendState.error!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ElevatedButton(
                      onPressed: friendState.isLoading ? null : _handleSubmit,
                      child: friendState.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Update Friend'),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}