import '../../domain/entities/sim_card_record.dart';
import '../../domain/repositories/sim_card_repository.dart';
import '../../services/supabase_service.dart';
import '../models/sim_card_record_model.dart';

class SimCardRepositoryImpl implements SimCardRepository {
  final SupabaseService _supabaseService;

  SimCardRepositoryImpl(this._supabaseService);

  @override
  Future<List<SimCardRecord>> getAllSimCards(String userId) async {
    try {
      final data = await _supabaseService.getRecordsByCondition(
        table: 'sim_card_records',
        conditions: {'user_id': userId},
      );
      return data.map((json) => SimCardRecordModel.fromJson(json).toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to get SIM cards: $e');
    }
  }

  @override
  Future<SimCardRecord?> getSimCardById(String id) async {
    try {
      final data = await _supabaseService.getRecordById(table: 'sim_card_records', id: id);
      if (data == null) return null;
      return SimCardRecordModel.fromJson(data).toEntity();
    } catch (e) {
      throw Exception('Failed to get SIM card: $e');
    }
  }

  @override
  Future<SimCardRecord> createSimCard(SimCardRecord simCard) async {
    try {
      final model = SimCardRecordModel.fromEntity(simCard);
      final data = await _supabaseService.createRecord(table: 'sim_card_records', data: model.toJsonForInsert());
      return SimCardRecordModel.fromJson(data).toEntity();
    } catch (e) {
      throw Exception('Failed to create SIM card: $e');
    }
  }

  @override
  Future<SimCardRecord> updateSimCard(SimCardRecord simCard) async {
    try {
      final model = SimCardRecordModel.fromEntity(simCard);
      final data = await _supabaseService.updateRecord(table: 'sim_card_records', id: model.id, data: model.toJsonForInsert());
      return SimCardRecordModel.fromJson(data).toEntity();
    } catch (e) {
      throw Exception('Failed to update SIM card: $e');
    }
  }

  @override
  Future<void> deleteSimCard(String id) async {
    try {
      await _supabaseService.deleteRecord(table: 'sim_card_records', id: id);
    } catch (e) {
      throw Exception('Failed to delete SIM card: $e');
    }
  }

  @override
  Future<SimCardRecord?> getSimCardByPhoneNumber(String userId, String phoneNumber) async {
    try {
      final data = await _supabaseService.getRecordsByCondition(
        table: 'sim_card_records',
        conditions: {'phone_number': phoneNumber, 'user_id': userId},
      );
      if (data.isEmpty) return null;
      return SimCardRecordModel.fromJson(data.first).toEntity();
    } catch (e) {
      throw Exception('Failed to get SIM card by phone number: $e');
    }
  }

  @override
  Future<bool> isPhoneNumberTaken(String userId, String phoneNumber, {String? excludeId}) async {
    try {
      final data = await _supabaseService.getRecordsByCondition(
        table: 'sim_card_records',
        conditions: {'phone_number': phoneNumber, 'user_id': userId},
      );
      
      if (excludeId != null) {
        return data.any((item) => item['id'] != excludeId);
      }
      
      return data.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check phone number availability: $e');
    }
  }
}