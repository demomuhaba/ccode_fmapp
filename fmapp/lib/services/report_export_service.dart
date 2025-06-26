import 'dart:io';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../domain/entities/transaction_record.dart';
import '../domain/entities/loan_debt_item.dart';
import '../domain/entities/financial_account_record.dart';
import '../domain/entities/sim_card_record.dart';

/// Service for exporting financial reports to CSV and PDF formats
class ReportExportService {
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_ET',
    symbol: 'ETB ',
    decimalDigits: 2,
  );

  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm');
  final DateFormat _shortDateFormat = DateFormat('MMM dd, yyyy');

  /// Export transactions to CSV
  Future<File> exportTransactionsToCSV({
    required List<TransactionRecord> transactions,
    required List<FinancialAccountRecord> accounts,
    String? title,
  }) async {
    try {
      final List<List<dynamic>> csvData = [];
      
      // Add header
      csvData.add([
        'Date',
        'Time',
        'Account',
        'Type',
        'Amount (ETB)',
        'Description',
        'Payer/Sender',
        'Payee/Receiver',
        'Reference',
        'Balance After',
      ]);

      // Add transaction data
      for (final transaction in transactions) {
        final account = accounts.firstWhere(
          (acc) => acc.id == transaction.affectedAccountId,
          orElse: () => FinancialAccountRecord(
            id: '',
            userId: '',
            accountName: 'Unknown Account',
            accountIdentifier: '',
            accountType: '',
            linkedSimId: '',
            initialBalance: 0,
            dateAdded: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        csvData.add([
          DateFormat('yyyy-MM-dd').format(transaction.transactionDate),
          DateFormat('HH:mm:ss').format(transaction.transactionDate),
          account.accountName,
          transaction.transactionType,
          transaction.amount,
          transaction.descriptionNotes ?? '',
          transaction.payerSenderRaw ?? '',
          transaction.payeeReceiverRaw ?? '',
          transaction.referenceNumber ?? '',
          '', // Balance after - would need to be calculated
        ]);
      }

      // Convert to CSV string
      final String csvString = const ListToCsvConverter().convert(csvData);

      // Write to file
      final directory = await getApplicationDocumentsDirectory();
      final fileName = title != null 
          ? 'fmapp_${title.replaceAll(' ', '_').toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}.csv'
          : 'fmapp_transactions_${DateTime.now().millisecondsSinceEpoch}.csv';
      
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(csvString);

      return file;
    } catch (e) {
      debugPrint('Error exporting transactions to CSV: $e');
      rethrow;
    }
  }

  /// Export loan/debt summary to CSV
  Future<File> exportLoansToCSV({
    required List<LoanDebtItem> loans,
    String? title,
  }) async {
    try {
      final List<List<dynamic>> csvData = [];
      
      // Add header
      csvData.add([
        'Date Created',
        'Friend',
        'Type',
        'Initial Amount (ETB)',
        'Outstanding Amount (ETB)',
        'Due Date',
        'Status',
        'Description',
      ]);

      // Add loan data
      for (final loan in loans) {
        csvData.add([
          _shortDateFormat.format(loan.dateInitiated),
          loan.associatedFriendId, // Would need friend name lookup
          loan.type,
          loan.initialAmount,
          loan.outstandingAmount,
          loan.dueDate != null ? _shortDateFormat.format(loan.dueDate!) : '',
          loan.status,
          loan.description ?? '',
        ]);
      }

      // Convert to CSV string
      final String csvString = const ListToCsvConverter().convert(csvData);

      // Write to file
      final directory = await getApplicationDocumentsDirectory();
      final fileName = title != null 
          ? 'fmapp_${title.replaceAll(' ', '_').toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}.csv'
          : 'fmapp_loans_${DateTime.now().millisecondsSinceEpoch}.csv';
      
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(csvString);

      return file;
    } catch (e) {
      debugPrint('Error exporting loans to CSV: $e');
      rethrow;
    }
  }

  /// Export account summary to CSV
  Future<File> exportAccountSummaryToCSV({
    required List<FinancialAccountRecord> accounts,
    required List<SimCardRecord> simCards,
    String? title,
  }) async {
    try {
      final List<List<dynamic>> csvData = [];
      
      // Add header
      csvData.add([
        'Account Name',
        'Account Type',
        'Account Identifier',
        'SIM Card',
        'Telecom Provider',
        'Initial Balance (ETB)',
        'Current Balance (ETB)',
        'Date Added',
      ]);

      // Add account data
      for (final account in accounts) {
        final simCard = simCards.firstWhere(
          (sim) => sim.id == account.linkedSimId,
          orElse: () => SimCardRecord(
            id: '',
            userId: '',
            phoneNumber: '',
            simNickname: 'Unknown SIM',
            telecomProvider: '',
            officialRegisteredName: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        csvData.add([
          account.accountName,
          account.accountType,
          account.accountIdentifier,
          simCard.simNickname,
          simCard.telecomProvider,
          account.initialBalance,
          account.initialBalance, // Would need current balance calculation
          _shortDateFormat.format(account.dateAdded),
        ]);
      }

      // Convert to CSV string
      final String csvString = const ListToCsvConverter().convert(csvData);

      // Write to file
      final directory = await getApplicationDocumentsDirectory();
      final fileName = title != null 
          ? 'fmapp_${title.replaceAll(' ', '_').toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}.csv'
          : 'fmapp_accounts_${DateTime.now().millisecondsSinceEpoch}.csv';
      
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(csvString);

      return file;
    } catch (e) {
      debugPrint('Error exporting account summary to CSV: $e');
      rethrow;
    }
  }

  /// Export transactions to PDF
  Future<Uint8List> exportTransactionsToPDF({
    required List<TransactionRecord> transactions,
    required List<FinancialAccountRecord> accounts,
    String? title,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final pdf = pw.Document();

      // Load font for better Ethiopian support
      final font = await PdfGoogleFonts.notoSansRegular();
      final boldFont = await PdfGoogleFonts.notoSansBold();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Header
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'fmapp - Financial Report',
                    style: pw.TextStyle(font: boldFont, fontSize: 24),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    title ?? 'Transaction Report',
                    style: pw.TextStyle(font: font, fontSize: 18),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Generated on: ${_dateFormat.format(DateTime.now())}',
                    style: pw.TextStyle(font: font, fontSize: 12, color: PdfColors.grey),
                  ),
                  if (startDate != null && endDate != null) ...[
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Period: ${_shortDateFormat.format(startDate)} - ${_shortDateFormat.format(endDate)}',
                      style: pw.TextStyle(font: font, fontSize: 12, color: PdfColors.grey),
                    ),
                  ],
                  pw.SizedBox(height: 20),
                ],
              ),

              // Summary
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Summary',
                      style: pw.TextStyle(font: boldFont, fontSize: 16),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Total Transactions:', style: pw.TextStyle(font: font)),
                        pw.Text('${transactions.length}', style: pw.TextStyle(font: boldFont)),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Total Income:', style: pw.TextStyle(font: font)),
                        pw.Text(
                          _currencyFormat.format(_calculateTotalIncome(transactions)),
                          style: pw.TextStyle(font: boldFont, color: PdfColors.green),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Total Expenses:', style: pw.TextStyle(font: font)),
                        pw.Text(
                          _currencyFormat.format(_calculateTotalExpenses(transactions)),
                          style: pw.TextStyle(font: boldFont, color: PdfColors.red),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Transaction table
              pw.Text(
                'Transaction Details',
                style: pw.TextStyle(font: boldFont, fontSize: 16),
              ),
              pw.SizedBox(height: 12),

              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FixedColumnWidth(80),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FixedColumnWidth(60),
                  3: const pw.FixedColumnWidth(80),
                  4: const pw.FlexColumnWidth(3),
                },
                children: [
                  // Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _buildTableCell('Date', font: boldFont),
                      _buildTableCell('Account', font: boldFont),
                      _buildTableCell('Type', font: boldFont),
                      _buildTableCell('Amount', font: boldFont),
                      _buildTableCell('Description', font: boldFont),
                    ],
                  ),
                  // Data rows
                  ...transactions.map((transaction) {
                    final account = accounts.firstWhere(
                      (acc) => acc.id == transaction.affectedAccountId,
                      orElse: () => FinancialAccountRecord(
                        id: '',
                        userId: '',
                        accountName: 'Unknown',
                        accountIdentifier: '',
                        accountType: '',
                        linkedSimId: '',
                        initialBalance: 0,
                        dateAdded: DateTime.now(),
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      ),
                    );

                    return pw.TableRow(
                      children: [
                        _buildTableCell(_shortDateFormat.format(transaction.transactionDate), font: font),
                        _buildTableCell(account.accountName, font: font),
                        _buildTableCell(transaction.transactionType, font: font),
                        _buildTableCell(
                          _currencyFormat.format(transaction.amount),
                          font: font,
                          color: transaction.transactionType.toLowerCase().contains('income') ||
                                 transaction.transactionType.toLowerCase().contains('credit')
                              ? PdfColors.green
                              : PdfColors.red,
                        ),
                        _buildTableCell(transaction.descriptionNotes ?? '', font: font),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ];
          },
        ),
      );

      return await pdf.save();
    } catch (e) {
      debugPrint('Error exporting transactions to PDF: $e');
      rethrow;
    }
  }

  /// Export loan/debt summary to PDF
  Future<Uint8List> exportLoansToPDF({
    required List<LoanDebtItem> loans,
    String? title,
  }) async {
    try {
      final pdf = pw.Document();
      
      final font = await PdfGoogleFonts.notoSansRegular();
      final boldFont = await PdfGoogleFonts.notoSansBold();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Header
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'fmapp - Loan & Debt Report',
                    style: pw.TextStyle(font: boldFont, fontSize: 24),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    title ?? 'Loan & Debt Summary',
                    style: pw.TextStyle(font: font, fontSize: 18),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Generated on: ${_dateFormat.format(DateTime.now())}',
                    style: pw.TextStyle(font: font, fontSize: 12, color: PdfColors.grey),
                  ),
                  pw.SizedBox(height: 20),
                ],
              ),

              // Summary
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Summary',
                      style: pw.TextStyle(font: boldFont, fontSize: 16),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Total Loans Given:', style: pw.TextStyle(font: font)),
                        pw.Text(
                          _currencyFormat.format(_calculateTotalLoansGiven(loans)),
                          style: pw.TextStyle(font: boldFont, color: PdfColors.green),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Total Debts Owed:', style: pw.TextStyle(font: font)),
                        pw.Text(
                          _currencyFormat.format(_calculateTotalDebtsOwed(loans)),
                          style: pw.TextStyle(font: boldFont, color: PdfColors.red),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Loan table
              pw.Text(
                'Loan & Debt Details',
                style: pw.TextStyle(font: boldFont, fontSize: 16),
              ),
              pw.SizedBox(height: 12),

              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FixedColumnWidth(80),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FixedColumnWidth(80),
                  3: const pw.FixedColumnWidth(80),
                  4: const pw.FixedColumnWidth(80),
                  5: const pw.FlexColumnWidth(1),
                },
                children: [
                  // Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _buildTableCell('Date', font: boldFont),
                      _buildTableCell('Friend', font: boldFont),
                      _buildTableCell('Type', font: boldFont),
                      _buildTableCell('Initial', font: boldFont),
                      _buildTableCell('Outstanding', font: boldFont),
                      _buildTableCell('Status', font: boldFont),
                    ],
                  ),
                  // Data rows
                  ...loans.map((loan) => pw.TableRow(
                    children: [
                      _buildTableCell(_shortDateFormat.format(loan.dateInitiated), font: font),
                      _buildTableCell(loan.associatedFriendId, font: font), // Would need friend name
                      _buildTableCell(loan.type, font: font),
                      _buildTableCell(_currencyFormat.format(loan.initialAmount), font: font),
                      _buildTableCell(_currencyFormat.format(loan.outstandingAmount), font: font),
                      _buildTableCell(loan.status, font: font),
                    ],
                  )).toList(),
                ],
              ),
            ];
          },
        ),
      );

      return await pdf.save();
    } catch (e) {
      debugPrint('Error exporting loans to PDF: $e');
      rethrow;
    }
  }

  /// Share exported file
  Future<void> shareFile(File file, {String? subject}) async {
    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: subject ?? 'fmapp Report Export',
      );
    } catch (e) {
      debugPrint('Error sharing file: $e');
      rethrow;
    }
  }

  /// Print PDF
  Future<void> printPDF(Uint8List pdfData, {String? jobName}) async {
    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfData,
        name: jobName ?? 'fmapp Report',
      );
    } catch (e) {
      debugPrint('Error printing PDF: $e');
      rethrow;
    }
  }

  // Helper methods
  pw.Widget _buildTableCell(String text, {
    required pw.Font font,
    PdfColor? color,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: font, fontSize: 10, color: color),
        overflow: pw.TextOverflow.clip,
      ),
    );
  }

  double _calculateTotalIncome(List<TransactionRecord> transactions) {
    return transactions
        .where((t) => t.transactionType.toLowerCase().contains('income') ||
                     t.transactionType.toLowerCase().contains('credit'))
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double _calculateTotalExpenses(List<TransactionRecord> transactions) {
    return transactions
        .where((t) => t.transactionType.toLowerCase().contains('expense') ||
                     t.transactionType.toLowerCase().contains('debit'))
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double _calculateTotalLoansGiven(List<LoanDebtItem> loans) {
    return loans
        .where((l) => l.type.toLowerCase().contains('loan'))
        .fold(0.0, (sum, l) => sum + l.outstandingAmount);
  }

  double _calculateTotalDebtsOwed(List<LoanDebtItem> loans) {
    return loans
        .where((l) => l.type.toLowerCase().contains('debt'))
        .fold(0.0, (sum, l) => sum + l.outstandingAmount);
  }
}