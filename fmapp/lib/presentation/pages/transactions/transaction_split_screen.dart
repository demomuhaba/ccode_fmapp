import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/riverpod_providers.dart' as providers;
import '../../../domain/entities/transaction_split.dart';

class TransactionSplitScreen extends ConsumerStatefulWidget {
  final String transactionId;
  final double totalAmount;

  const TransactionSplitScreen({
    super.key,
    required this.transactionId,
    required this.totalAmount,
  });

  @override
  ConsumerState<TransactionSplitScreen> createState() => _TransactionSplitScreenState();
}

class _TransactionSplitScreenState extends ConsumerState<TransactionSplitScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<TransactionSplit> _splits = [];
  double _allocatedAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _addSplit();
  }

  void _addSplit() {
    setState(() {
      _splits.add(
        TransactionSplit(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          transactionId: widget.transactionId,
          category: '',
          description: '',
          amount: 0.0,
          percentage: 0.0,
        ),
      );
    });
  }

  void _removeSplit(int index) {
    if (_splits.length > 1) {
      setState(() {
        _splits.removeAt(index);
        _updateAllocatedAmount();
      });
    }
  }

  void _updateAllocatedAmount() {
    _allocatedAmount = _splits.fold(0.0, (sum, split) => sum + split.amount);
  }

  void _updateSplitAmount(int index, double amount) {
    setState(() {
      _splits[index] = _splits[index].copyWith(amount: amount);
      _updateAllocatedAmount();
      
      // Update percentages
      if (widget.totalAmount > 0) {
        for (int i = 0; i < _splits.length; i++) {
          _splits[i] = _splits[i].copyWith(
            percentage: (_splits[i].amount / widget.totalAmount) * 100,
          );
        }
      }
    });
  }

  void _updateSplitCategory(int index, String category) {
    setState(() {
      _splits[index] = _splits[index].copyWith(category: category);
    });
  }

  void _updateSplitDescription(int index, String description) {
    setState(() {
      _splits[index] = _splits[index].copyWith(description: description);
    });
  }

  void _distributeEvenly() {
    if (_splits.isNotEmpty) {
      final evenAmount = widget.totalAmount / _splits.length;
      setState(() {
        for (int i = 0; i < _splits.length; i++) {
          _splits[i] = _splits[i].copyWith(
            amount: evenAmount,
            percentage: 100.0 / _splits.length,
          );
        }
        _updateAllocatedAmount();
      });
    }
  }

  void _distributeByPercentage() {
    showDialog(
      context: context,
      builder: (context) => _PercentageDistributionDialog(
        splits: _splits,
        totalAmount: widget.totalAmount,
        onUpdate: (updatedSplits) {
          setState(() {
            _splits.clear();
            _splits.addAll(updatedSplits);
            _updateAllocatedAmount();
          });
        },
      ),
    );
  }

  Future<void> _saveSplits() async {
    if (!_formKey.currentState!.validate()) return;

    final unallocated = widget.totalAmount - _allocatedAmount;
    if (unallocated.abs() > 0.01) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Total splits must equal transaction amount. '
            'Unallocated: ETB ${unallocated.toStringAsFixed(2)}',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Here you would typically save the splits to your backend
    // For now, we'll just show a success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Transaction splits saved successfully'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final unallocated = widget.totalAmount - _allocatedAmount;
    final isBalanced = unallocated.abs() <= 0.01;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Split Transaction'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'even':
                  _distributeEvenly();
                  break;
                case 'percentage':
                  _distributeByPercentage();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'even',
                child: ListTile(
                  leading: Icon(Icons.pie_chart),
                  title: Text('Distribute Evenly'),
                ),
              ),
              const PopupMenuItem(
                value: 'percentage',
                child: ListTile(
                  leading: Icon(Icons.percent),
                  title: Text('By Percentage'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildSummaryCard(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _splits.length,
                itemBuilder: (context, index) {
                  return _buildSplitCard(index);
                },
              ),
            ),
            _buildActionButtons(isBalanced),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final unallocated = widget.totalAmount - _allocatedAmount;
    final isBalanced = unallocated.abs() <= 0.01;

    return Card(
      margin: const EdgeInsets.all(16),
      color: isBalanced ? Colors.green.shade50 : Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Transaction Total:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                Text(
                  'ETB ${widget.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Allocated:',
                  style: TextStyle(fontSize: 14),
                ),
                Text(
                  'ETB ${_allocatedAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Remaining:',
                  style: TextStyle(fontSize: 14),
                ),
                Text(
                  'ETB ${unallocated.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isBalanced 
                        ? Colors.green 
                        : (unallocated > 0 ? Colors.orange : Colors.red),
                  ),
                ),
              ],
            ),
            if (!isBalanced) ...[
              const SizedBox(height: 8),
              Text(
                isBalanced 
                    ? 'Perfectly balanced!' 
                    : unallocated > 0 
                        ? 'Need to allocate more' 
                        : 'Over-allocated',
                style: TextStyle(
                  fontSize: 12,
                  color: isBalanced 
                      ? Colors.green 
                      : (unallocated > 0 ? Colors.orange : Colors.red),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSplitCard(int index) {
    final split = _splits[index];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Split ${index + 1}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_splits.length > 1)
                  IconButton(
                    onPressed: () => _removeSplit(index),
                    icon: const Icon(Icons.close),
                    iconSize: 20,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    initialValue: split.category,
                    decoration: const InputDecoration(
                      labelText: 'Category *',
                      hintText: 'e.g., Food, Transport',
                      prefixIcon: Icon(Icons.category),
                    ),
                    onChanged: (value) => _updateSplitCategory(index, value),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Category required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: split.amount > 0 ? split.amount.toString() : '',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      hintText: '0.00',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    onChanged: (value) {
                      final amount = double.tryParse(value) ?? 0.0;
                      _updateSplitAmount(index, amount);
                    },
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      final amount = double.tryParse(value.trim());
                      if (amount == null || amount <= 0) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: split.description,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Optional details about this split',
                prefixIcon: Icon(Icons.description),
              ),
              onChanged: (value) => _updateSplitDescription(index, value),
            ),
            if (split.percentage > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${split.percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool isBalanced) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _addSplit,
              icon: const Icon(Icons.add),
              label: const Text('Add Split'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: isBalanced ? _saveSplits : null,
              child: const Text('Save Splits'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PercentageDistributionDialog extends StatefulWidget {
  final List<TransactionSplit> splits;
  final double totalAmount;
  final Function(List<TransactionSplit>) onUpdate;

  const _PercentageDistributionDialog({
    required this.splits,
    required this.totalAmount,
    required this.onUpdate,
  });

  @override
  State<_PercentageDistributionDialog> createState() => _PercentageDistributionDialogState();
}

class _PercentageDistributionDialogState extends State<_PercentageDistributionDialog> {
  late List<TextEditingController> _controllers;
  late List<TransactionSplit> _workingSplits;

  @override
  void initState() {
    super.initState();
    _workingSplits = widget.splits.map((split) => split.copyWith()).toList();
    _controllers = _workingSplits.map((split) => 
        TextEditingController(text: split.percentage.toStringAsFixed(1))
    ).toList();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updatePercentages() {
    double totalPercentage = 0.0;
    
    for (int i = 0; i < _controllers.length; i++) {
      final percentage = double.tryParse(_controllers[i].text) ?? 0.0;
      totalPercentage += percentage;
      
      final amount = (percentage / 100) * widget.totalAmount;
      _workingSplits[i] = _workingSplits[i].copyWith(
        percentage: percentage,
        amount: amount,
      );
    }

    setState(() {});
  }

  void _distributeRemaining() {
    double totalPercentage = 0.0;
    for (var controller in _controllers) {
      totalPercentage += double.tryParse(controller.text) ?? 0.0;
    }
    
    final remaining = 100.0 - totalPercentage;
    if (remaining > 0 && _controllers.isNotEmpty) {
      final additionalPerSplit = remaining / _controllers.length;
      
      for (int i = 0; i < _controllers.length; i++) {
        final currentPercentage = double.tryParse(_controllers[i].text) ?? 0.0;
        _controllers[i].text = (currentPercentage + additionalPerSplit).toStringAsFixed(1);
      }
      
      _updatePercentages();
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalPercentage = 0.0;
    for (var controller in _controllers) {
      totalPercentage += double.tryParse(controller.text) ?? 0.0;
    }
    
    final isValid = (totalPercentage - 100.0).abs() <= 0.1;

    return AlertDialog(
      title: const Text('Distribute by Percentage'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Total: ${totalPercentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isValid ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(_controllers.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text('Split ${index + 1}:'),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _controllers[index],
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          suffixText: '%',
                          isDense: true,
                        ),
                        onChanged: (_) => _updatePercentages(),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _distributeRemaining,
              child: const Text('Distribute Remaining'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isValid ? () {
            widget.onUpdate(_workingSplits);
            Navigator.of(context).pop();
          } : null,
          child: const Text('Apply'),
        ),
      ],
    );
  }
}