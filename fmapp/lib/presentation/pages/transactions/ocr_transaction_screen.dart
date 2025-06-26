import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/riverpod_providers.dart' as providers;
import '../../../services/ocr_service.dart';

class OCRTransactionScreen extends ConsumerStatefulWidget {
  const OCRTransactionScreen({super.key});

  @override
  ConsumerState<OCRTransactionScreen> createState() => _OCRTransactionScreenState();
}

class _OCRTransactionScreenState extends ConsumerState<OCRTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _payerSenderController = TextEditingController();
  final _payeeReceiverController = TextEditingController();
  final _referenceController = TextEditingController();
  
  String _selectedTransactionType = 'Income/Credit';
  String? _selectedAccountId;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  File? _selectedFile;
  Map<String, dynamic>? _ocrResult;
  bool _isProcessing = false;
  String? _rawOcrText;

  final ImagePicker _imagePicker = ImagePicker();
  final OCRService _ocrService = OCRService();

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _payerSenderController.dispose();
    _payeeReceiverController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _loadAccounts() async {
    final authState = ref.read(providers.authNotifierProvider);
    final userId = authState.userProfile?.userId;
    
    if (userId != null) {
      await ref.read(providers.financialAccountNotifierProvider.notifier).loadAccounts(userId);
      
      final accountState = ref.read(providers.financialAccountNotifierProvider);
      if (accountState.accounts.isNotEmpty) {
        _selectedAccountId = accountState.accounts.first.id;
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedFile = File(image.path);
        });
        await _processOCR();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to capture image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedFile = File(image.path);
        });
        await _processOCR();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickPDFFile() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      
      if (result != null && result.files.single.path != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF OCR not yet supported. Please use image files.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _processOCR() async {
    if (_selectedFile == null) return;

    setState(() {
      _isProcessing = true;
      _ocrResult = null;
    });

    try {
      final result = await _ocrService.extractTransactionData(_selectedFile!.path);
      
      setState(() {
        _ocrResult = result;
        _rawOcrText = result['rawText'] as String?;
      });

      if (result['success'] == true) {
        _populateFieldsFromOCR(result['extractedData'] as Map<String, dynamic>);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OCR completed with ${(result['confidence'] * 100).toInt()}% confidence'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'OCR processing failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OCR error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _populateFieldsFromOCR(Map<String, dynamic> extractedData) {
    if (extractedData['amount'] != null) {
      _amountController.text = extractedData['amount'].toString();
    }
    
    if (extractedData['transactionDate'] != null) {
      final date = extractedData['transactionDate'] as DateTime;
      _selectedDate = DateTime(date.year, date.month, date.day);
      _selectedTime = TimeOfDay(hour: date.hour, minute: date.minute);
    }
    
    if (extractedData['transactionType'] != null) {
      _selectedTransactionType = extractedData['transactionType'] as String;
    }
    
    if (extractedData['referenceNumber'] != null) {
      _referenceController.text = extractedData['referenceNumber'] as String;
    }
    
    if (extractedData['payerSenderRaw'] != null) {
      _payerSenderController.text = extractedData['payerSenderRaw'] as String;
    }
    
    if (extractedData['payeeReceiverRaw'] != null) {
      _payeeReceiverController.text = extractedData['payeeReceiverRaw'] as String;
    }

    // Generate description from extracted data
    String description = 'Transaction';
    if (_payerSenderController.text.isNotEmpty && _payeeReceiverController.text.isNotEmpty) {
      description = 'From ${_payerSenderController.text} to ${_payeeReceiverController.text}';
    } else if (_payerSenderController.text.isNotEmpty) {
      description = 'From ${_payerSenderController.text}';
    } else if (_payeeReceiverController.text.isNotEmpty) {
      description = 'To ${_payeeReceiverController.text}';
    }
    _descriptionController.text = description;
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    
    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final authState = ref.read(providers.authNotifierProvider);
    final userId = authState.userProfile?.userId;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not found. Please sign in again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a financial account first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final transactionDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final success = await ref.read(providers.transactionNotifierProvider.notifier).createTransaction(
      userId: userId,
      affectedAccountId: _selectedAccountId!,
      transactionDate: transactionDateTime,
      amount: double.parse(_amountController.text.trim()),
      transactionType: _selectedTransactionType,
      descriptionNotes: _descriptionController.text.trim(),
      payerSenderRaw: _payerSenderController.text.trim().isEmpty ? null : _payerSenderController.text.trim(),
      payeeReceiverRaw: _payeeReceiverController.text.trim().isEmpty ? null : _payeeReceiverController.text.trim(),
      referenceNumber: _referenceController.text.trim().isEmpty ? null : _referenceController.text.trim(),
      ocrExtractedRawText: _rawOcrText,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction added successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        final transactionState = ref.read(providers.transactionNotifierProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(transactionState.error ?? 'Failed to add transaction'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final accountState = ref.watch(providers.financialAccountNotifierProvider);
        if (accountState.accounts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 24),
                const Text(
                  'No Accounts Found',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'You need to add at least one financial account before creating transactions',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_selectedFile == null) _buildFilePicker(),
              if (_selectedFile != null) _buildFilePreview(),
              if (_isProcessing) _buildProcessingIndicator(),
              if (_ocrResult != null) _buildOCRResults(),
              if (_selectedFile != null && !_isProcessing) _buildTransactionForm(accountState),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilePicker() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.camera_alt,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            const Text(
              'Capture or Upload Receipt',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Take a photo or upload an image of your transaction receipt for automatic data extraction',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickImageFromCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickImageFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickPDFFile,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('PDF'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePreview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Selected File',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedFile = null;
                      _ocrResult = null;
                      _rawOcrText = null;
                    });
                  },
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_selectedFile!.path.toLowerCase().endsWith('.pdf'))
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: Text(_selectedFile!.path.split('/').last),
                subtitle: const Text('PDF File'),
              )
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  _selectedFile!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingIndicator() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Processing OCR...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Extracting transaction data from your receipt',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOCRResults() {
    final result = _ocrResult!;
    final success = result['success'] as bool;
    final confidence = ((result['confidence'] as double) * 100).toInt();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  success ? Icons.check_circle : Icons.error,
                  color: success ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  success ? 'OCR Successful' : 'OCR Failed',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: success ? Colors.green : Colors.red,
                  ),
                ),
                const Spacer(),
                if (success)
                  Chip(
                    label: Text('$confidence% confidence'),
                    backgroundColor: confidence > 70 ? Colors.green.shade100 : Colors.orange.shade100,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              success 
                  ? 'Transaction data extracted successfully. Please review and edit the fields below.'
                  : result['error'] ?? 'Failed to extract transaction data from the image.',
              style: const TextStyle(color: Colors.grey),
            ),
            if (success && _rawOcrText != null) ...[
              const SizedBox(height: 16),
              ExpansionTile(
                title: const Text('Raw OCR Text'),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _rawOcrText!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
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

  Widget _buildTransactionForm(FinancialAccountState accountState) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Review & Edit Transaction Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedAccountId,
                  decoration: const InputDecoration(
                    labelText: 'Account *',
                    prefixIcon: Icon(Icons.account_balance_wallet),
                  ),
                  items: accountState.accounts.map((account) {
                    return DropdownMenuItem(
                      value: account.id,
                      child: Text('${account.accountName} (${account.accountType})'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedAccountId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select an account';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedTransactionType,
                  decoration: const InputDecoration(
                    labelText: 'Transaction Type *',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: ['Income/Credit', 'Expense/Debit'].map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedTransactionType = value!;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select transaction type';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Amount (ETB) *',
                    hintText: '0.00',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter amount';
                    }
                    final amount = double.tryParse(value.trim());
                    if (amount == null || amount <= 0) {
                      return 'Please enter a valid positive amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description *',
                    hintText: 'What is this transaction for?',
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter description';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Date & Time',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        title: const Text('Date'),
                        subtitle: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                        leading: const Icon(Icons.calendar_today),
                        onTap: _selectDate,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ListTile(
                        title: const Text('Time'),
                        subtitle: Text(_selectedTime.format(context)),
                        leading: const Icon(Icons.access_time),
                        onTap: _selectTime,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Additional Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _payerSenderController,
                  decoration: const InputDecoration(
                    labelText: 'Payer/Sender',
                    hintText: 'Who sent the money?',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _payeeReceiverController,
                  decoration: const InputDecoration(
                    labelText: 'Payee/Receiver',
                    hintText: 'Who received the money?',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _referenceController,
                  decoration: const InputDecoration(
                    labelText: 'Reference Number',
                    hintText: 'Transaction ID or reference',
                    prefixIcon: Icon(Icons.confirmation_number),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Consumer(
          builder: (context, ref, child) {
            final transactionState = ref.watch(providers.transactionNotifierProvider);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (transactionState.error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      transactionState.error!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ElevatedButton(
                  onPressed: transactionState.isLoading ? null : _handleSubmit,
                  child: transactionState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Add Transaction'),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}