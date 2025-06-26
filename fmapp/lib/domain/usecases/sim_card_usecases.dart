import 'package:uuid/uuid.dart';
import '../entities/sim_card_record.dart';
import '../repositories/sim_card_repository.dart';
import '../repositories/financial_account_repository.dart';

class SimCardUseCases {
  final SimCardRepository _simCardRepository;
  final FinancialAccountRepository _accountRepository;
  final Uuid _uuid = const Uuid();

  SimCardUseCases(this._simCardRepository, this._accountRepository);

  Future<List<SimCardRecord>> getAllSimCards(String userId) async {
    try {
      return await _simCardRepository.getAllSimCards(userId);
    } catch (e) {
      throw Exception('Failed to get SIM cards: $e');
    }
  }

  Future<SimCardRecord?> getSimCardById(String id) async {
    try {
      return await _simCardRepository.getSimCardById(id);
    } catch (e) {
      throw Exception('Failed to get SIM card: $e');
    }
  }

  Future<SimCardRecord> createSimCard({
    required String userId,
    required String phoneNumber,
    required String simNickname,
    required String telecomProvider,
    String? officialRegisteredName,
  }) async {
    try {
      final isPhoneTaken = await _simCardRepository.isPhoneNumberTaken(userId, phoneNumber);
      if (isPhoneTaken) {
        throw Exception('Phone number is already registered');
      }

      final simCard = SimCardRecord(
        id: _uuid.v4(),
        userId: userId,
        phoneNumber: phoneNumber,
        simNickname: simNickname,
        telecomProvider: telecomProvider,
        officialRegisteredName: officialRegisteredName,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return await _simCardRepository.createSimCard(simCard);
    } catch (e) {
      throw Exception('Failed to create SIM card: $e');
    }
  }

  Future<SimCardRecord> updateSimCard(SimCardRecord simCard) async {
    try {
      final isPhoneTaken = await _simCardRepository.isPhoneNumberTaken(
        simCard.userId,
        simCard.phoneNumber,
        excludeId: simCard.id,
      );
      
      if (isPhoneTaken) {
        throw Exception('Phone number is already registered');
      }

      final updatedSimCard = simCard.copyWith(updatedAt: DateTime.now());
      return await _simCardRepository.updateSimCard(updatedSimCard);
    } catch (e) {
      throw Exception('Failed to update SIM card: $e');
    }
  }

  Future<void> deleteSimCard(String id) async {
    try {
      final accounts = await _accountRepository.getAccountsBySimId(id);
      if (accounts.isNotEmpty) {
        throw Exception('Cannot delete SIM card with associated financial accounts');
      }

      await _simCardRepository.deleteSimCard(id);
    } catch (e) {
      throw Exception('Failed to delete SIM card: $e');
    }
  }

  Future<Map<String, double>> getSimCardBalances(String userId) async {
    try {
      final simCards = await getAllSimCards(userId);
      final balances = <String, double>{};

      for (final simCard in simCards) {
        final balance = await _accountRepository.getSimTotalBalance(simCard.id);
        balances[simCard.id] = balance;
      }

      return balances;
    } catch (e) {
      throw Exception('Failed to get SIM card balances: $e');
    }
  }

  Future<bool> validatePhoneNumber(String phoneNumber) async {
    final ethiopianPhoneRegex = RegExp(r'^(\+251|0)[97]\d{8}$');
    return ethiopianPhoneRegex.hasMatch(phoneNumber);
  }

  Future<String> formatPhoneNumber(String phoneNumber) async {
    String formatted = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    if (formatted.startsWith('0')) {
      formatted = '+251${formatted.substring(1)}';
    } else if (formatted.startsWith('251')) {
      formatted = '+$formatted';
    } else if (!formatted.startsWith('+251')) {
      formatted = '+251$formatted';
    }
    
    return formatted;
  }
}