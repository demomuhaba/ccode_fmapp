import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/riverpod_providers.dart' as providers;
import '../../../core/constants/app_constants.dart';

class EditSimCardScreen extends ConsumerStatefulWidget {
  final String simCardId;

  const EditSimCardScreen({super.key, required this.simCardId});

  @override
  ConsumerState<EditSimCardScreen> createState() => _EditSimCardScreenState();
}

class _EditSimCardScreenState extends ConsumerState<EditSimCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _officialNameController = TextEditingController();
  
  String _selectedProvider = AppConstants.telecomProviders.first;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSimCardData();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nicknameController.dispose();
    _officialNameController.dispose();
    super.dispose();
  }

  void _loadSimCardData() {
    final simCard = ref.read(providers.simCardNotifierProvider.notifier).getSimCardById(widget.simCardId);
    
    if (simCard != null) {
      _phoneController.text = simCard.phoneNumber;
      _nicknameController.text = simCard.simNickname;
      _officialNameController.text = simCard.officialRegisteredName ?? '';
      _selectedProvider = simCard.telecomProvider;
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final simCard = ref.read(providers.simCardNotifierProvider.notifier).getSimCardById(widget.simCardId);
    
    if (simCard == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('SIM card not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final updatedSimCard = simCard.copyWith(
      phoneNumber: _phoneController.text.trim(),
      simNickname: _nicknameController.text.trim(),
      telecomProvider: _selectedProvider,
      officialRegisteredName: _officialNameController.text.trim().isEmpty 
          ? null 
          : _officialNameController.text.trim(),
    );

    final success = await ref.read(providers.simCardNotifierProvider.notifier).updateSimCard(updatedSimCard);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SIM card updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        final simCardState = ref.read(providers.simCardNotifierProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(simCardState.error ?? 'Failed to update SIM card'),
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
        appBar: AppBar(title: const Text('Edit SIM Card')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit SIM Card'),
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
                      'SIM Card Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number *',
                        hintText: '+251901234567 or 0901234567',
                        prefixIcon: Icon(Icons.phone),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter phone number';
                        }
                        
                        final ethiopianPhoneRegex = RegExp(r'^(\+251|0)[97]\d{8}$');
                        if (!ethiopianPhoneRegex.hasMatch(value.trim())) {
                          return 'Please enter a valid Ethiopian phone number';
                        }
                        
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nicknameController,
                      decoration: const InputDecoration(
                        labelText: 'Nickname *',
                        hintText: 'Personal SIM, Work SIM, etc.',
                        prefixIcon: Icon(Icons.label),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a nickname';
                        }
                        if (value.trim().length < 2) {
                          return 'Nickname must be at least 2 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedProvider,
                      decoration: const InputDecoration(
                        labelText: 'Telecom Provider *',
                        prefixIcon: Icon(Icons.cell_tower),
                      ),
                      items: AppConstants.telecomProviders.map((provider) {
                        return DropdownMenuItem(
                          value: provider,
                          child: Text(provider),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedProvider = value!;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a telecom provider';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _officialNameController,
                      decoration: const InputDecoration(
                        labelText: 'Official Registered Name',
                        hintText: 'Name registered with telecom provider (optional)',
                        prefixIcon: Icon(Icons.person),
                      ),
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
                final simCardState = ref.watch(providers.simCardNotifierProvider);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (simCardState.error != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          simCardState.error!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ElevatedButton(
                      onPressed: simCardState.isLoading ? null : _handleSubmit,
                      child: simCardState.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Update SIM Card'),
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