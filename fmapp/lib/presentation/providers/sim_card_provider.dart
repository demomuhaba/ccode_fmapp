import 'package:flutter/foundation.dart';
import '../../domain/entities/sim_card_record.dart';
import '../../domain/usecases/sim_card_usecases.dart';

class SimCardProvider extends ChangeNotifier {
  final SimCardUseCases _simCardUseCases;

  SimCardProvider(this._simCardUseCases);

  List<SimCardRecord> _simCards = [];
  Map<String, double> _simCardBalances = {};
  bool _isLoading = false;
  String? _error;

  List<SimCardRecord> get simCards => _simCards;
  Map<String, double> get simCardBalances => _simCardBalances;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadSimCards(String userId) async {
    _setLoading(true);
    try {
      _simCards = await _simCardUseCases.getAllSimCards(userId);
      await loadSimCardBalances(userId);
      _clearError();
    } catch (e) {
      _setError('Failed to load SIM cards: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadSimCardBalances(String userId) async {
    try {
      _simCardBalances = await _simCardUseCases.getSimCardBalances(userId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load SIM card balances: $e');
    }
  }

  Future<bool> createSimCard({
    required String userId,
    required String phoneNumber,
    required String simNickname,
    required String telecomProvider,
    String? officialRegisteredName,
  }) async {
    _setLoading(true);
    try {
      final newSimCard = await _simCardUseCases.createSimCard(
        userId: userId,
        phoneNumber: phoneNumber,
        simNickname: simNickname,
        telecomProvider: telecomProvider,
        officialRegisteredName: officialRegisteredName,
      );
      
      _simCards.add(newSimCard);
      _simCardBalances[newSimCard.id] = 0.0;
      _clearError();
      return true;
    } catch (e) {
      _setError('Failed to create SIM card: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateSimCard(SimCardRecord simCard) async {
    _setLoading(true);
    try {
      final updatedSimCard = await _simCardUseCases.updateSimCard(simCard);
      
      final index = _simCards.indexWhere((s) => s.id == updatedSimCard.id);
      if (index != -1) {
        _simCards[index] = updatedSimCard;
      }
      
      _clearError();
      return true;
    } catch (e) {
      _setError('Failed to update SIM card: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteSimCard(String id) async {
    _setLoading(true);
    try {
      await _simCardUseCases.deleteSimCard(id);
      
      _simCards.removeWhere((s) => s.id == id);
      _simCardBalances.remove(id);
      
      _clearError();
      return true;
    } catch (e) {
      _setError('Failed to delete SIM card: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  SimCardRecord? getSimCardById(String id) {
    try {
      return _simCards.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  double getSimCardBalance(String simId) {
    return _simCardBalances[simId] ?? 0.0;
  }

  double getTotalBalance() {
    return _simCardBalances.values.fold(0.0, (sum, balance) => sum + balance);
  }

  Future<bool> validatePhoneNumber(String phoneNumber) async {
    return await _simCardUseCases.validatePhoneNumber(phoneNumber);
  }

  Future<String> formatPhoneNumber(String phoneNumber) async {
    return await _simCardUseCases.formatPhoneNumber(phoneNumber);
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }
}