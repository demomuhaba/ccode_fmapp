import '../entities/sim_card_record.dart';

abstract class SimCardRepository {
  Future<List<SimCardRecord>> getAllSimCards(String userId);
  Future<SimCardRecord?> getSimCardById(String id);
  Future<SimCardRecord> createSimCard(SimCardRecord simCard);
  Future<SimCardRecord> updateSimCard(SimCardRecord simCard);
  Future<void> deleteSimCard(String id);
  Future<SimCardRecord?> getSimCardByPhoneNumber(String userId, String phoneNumber);
  Future<bool> isPhoneNumberTaken(String userId, String phoneNumber, {String? excludeId});
}