import 'package:flutter/foundation.dart';
import '../../domain/entities/sim_card_record.dart';
import '../../domain/repositories/sim_card_repository.dart';
import '../../services/supabase_service.dart';
import '../../services/isar_service.dart';
import '../local/isar_schemas.dart';
import '../models/sim_card_record_model.dart';

class SimCardRepositoryHybrid implements SimCardRepository {
  final SupabaseService _supabaseService;
  final IsarService _isarService;

  SimCardRepositoryHybrid(this._supabaseService, this._isarService);

  @override
  Future<List<SimCardRecord>> getAllSimCards(String userId) async {
    // On web, use Supabase directly since Isar is not supported
    if (kIsWeb) {
      try {
        final remoteData = await _supabaseService.getRecordsByCondition(
          table: 'sim_card_records',
          conditions: {'user_id': userId},
        );
        
        return remoteData
            .map((data) => SimCardRecordModel.fromJson(data).toEntity())
            .toList();
      } catch (e) {
        return [];
      }
    }
    
    final isar = await _isarService.database;
    
    // Get from local database first
    final localSimCards = await _isarService.getAll(isar.isarSimCardRecords);
    
    // Convert Isar entities to domain entities
    final simCards = localSimCards
        .where((simCard) => simCard.userId == userId)
        .map((isarSimCard) => _fromIsarEntity(isarSimCard))
        .toList();

    // If online, try to sync from Supabase
    if (await _isarService.isOnline) {
      try {
        final remoteData = await _supabaseService.getRecordsByCondition(
          table: 'sim_card_records',
          conditions: {'user_id': userId},
        );
        
        // Update local database with remote data
        await isar.writeTxn(() async {
          for (final data in remoteData) {
            final isarSimCard = _toIsarEntity(
              SimCardRecordModel.fromJson(data).toEntity(),
            );
            await isar.isarSimCardRecords.put(isarSimCard);
          }
        });
        
        // Return updated local data
        final updatedSimCards = await _isarService.getAll(isar.isarSimCardRecords);
        return updatedSimCards
            .where((simCard) => simCard.userId == userId)
            .map((isarSimCard) => _fromIsarEntity(isarSimCard))
            .toList();
      } catch (e) {
        // Return local data if sync fails
        return simCards;
      }
    }
    
    return simCards;
  }

  @override
  Future<SimCardRecord?> getSimCardById(String id) async {
    final isar = await _isarService.database;
    
    final isarSimCard = await isar.isarSimCardRecords
        .where()
        .recordIdEqualTo(id)
        .findFirst();
    
    if (isarSimCard != null && !isarSimCard.pendingDelete) {
      return _fromIsarEntity(isarSimCard);
    }
    
    return null;
  }

  @override
  Future<SimCardRecord> createSimCard(SimCardRecord simCard) async {
    // On web, create directly in Supabase
    if (kIsWeb) {
      try {
        await _supabaseService.insertRecord(
          table: 'sim_card_records',
          data: _entityToJson(simCard),
        );
        return simCard;
      } catch (e) {
        throw Exception('Failed to create SIM card: $e');
      }
    }
    
    final isar = await _isarService.database;
    
    // Convert to Isar entity
    final isarSimCard = _toIsarEntity(simCard);
    isarSimCard.synced = false;
    
    // Write to local database first
    await isar.writeTxn(() async {
      await isar.isarSimCardRecords.put(isarSimCard);
    });
    
    // Queue for sync to Supabase
    await _isarService.create(
      isarSimCard,
      tableName: 'sim_card_records',
      getId: (entity) => entity.recordId,
      toJson: (entity) => _entityToJson(_fromIsarEntity(entity)),
    );
    
    return _fromIsarEntity(isarSimCard);
  }

  @override
  Future<SimCardRecord> updateSimCard(SimCardRecord simCard) async {
    final isar = await _isarService.database;
    
    // Convert to Isar entity
    final isarSimCard = _toIsarEntity(simCard);
    isarSimCard.synced = false;
    isarSimCard.updatedAt = DateTime.now();
    
    // Update local database first
    await isar.writeTxn(() async {
      await isar.isarSimCardRecords.put(isarSimCard);
    });
    
    // Queue for sync to Supabase
    await _isarService.update(
      isarSimCard,
      tableName: 'sim_card_records',
      getId: (entity) => entity.recordId,
      toJson: (entity) => _entityToJson(_fromIsarEntity(entity)),
    );
    
    return _fromIsarEntity(isarSimCard);
  }

  @override
  Future<void> deleteSimCard(String id) async {
    final isar = await _isarService.database;
    
    // Mark as pending delete in local database
    await _isarService.delete(
      id,
      tableName: 'sim_card_records',
      collection: isar.isarSimCardRecords,
    );
  }

  @override
  Future<bool> isPhoneNumberTaken(String phoneNumber, String userId) async {
    return await isPhoneNumberExists(phoneNumber, userId);
  }

  @override
  Future<bool> isPhoneNumberExists(String phoneNumber, String userId) async {
    final isar = await _isarService.database;
    
    final existingCard = await isar.isarSimCardRecords
        .where()
        .userIdEqualTo(userId)
        .and()
        .phoneNumberEqualTo(phoneNumber)
        .findFirst();
    
    return existingCard != null;
  }

  @override
  Future<SimCardRecord?> getSimCardByPhoneNumber(String phoneNumber, String userId) async {
    final isar = await _isarService.database;
    
    final isarSimCard = await isar.isarSimCardRecords
        .where()
        .userIdEqualTo(userId)
        .and()
        .phoneNumberEqualTo(phoneNumber)
        .findFirst();
    
    if (isarSimCard != null) {
      return _fromIsarEntity(isarSimCard);
    }
    
    return null;
  }

  // Helper methods to convert between domain entities and Isar entities
  IsarSimCardRecord _toIsarEntity(SimCardRecord domain) {
    return IsarSimCardRecord()
      ..recordId = domain.id
      ..userId = domain.userId
      ..phoneNumber = domain.phoneNumber
      ..simNickname = domain.simNickname
      ..telecomProvider = domain.telecomProvider
      ..officialRegisteredName = domain.officialRegisteredName ?? ''
      ..createdAt = domain.createdAt
      ..updatedAt = domain.updatedAt;
  }

  SimCardRecord _fromIsarEntity(IsarSimCardRecord isar) {
    return SimCardRecord(
      id: isar.recordId,
      userId: isar.userId,
      phoneNumber: isar.phoneNumber,
      simNickname: isar.simNickname,
      telecomProvider: isar.telecomProvider,
      officialRegisteredName: isar.officialRegisteredName.isEmpty ? null : isar.officialRegisteredName,
      createdAt: isar.createdAt ?? DateTime.now(),
      updatedAt: isar.updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> _entityToJson(SimCardRecord entity) {
    return SimCardRecordModel.fromEntity(entity).toJsonForInsert();
  }
}