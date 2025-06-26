import 'package:equatable/equatable.dart';
import '../../domain/entities/friend_record.dart';

class FriendRecordModel extends Equatable {
  final String id;
  final String userId;
  final String friendName;
  final String? friendPhoneNumber;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FriendRecordModel({
    required this.id,
    required this.userId,
    required this.friendName,
    this.friendPhoneNumber,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FriendRecordModel.fromEntity(FriendRecord entity) {
    return FriendRecordModel(
      id: entity.id,
      userId: entity.userId,
      friendName: entity.friendName,
      friendPhoneNumber: entity.friendPhoneNumber,
      notes: entity.notes,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  FriendRecord toEntity() {
    return FriendRecord(
      id: id,
      userId: userId,
      friendName: friendName,
      friendPhoneNumber: friendPhoneNumber,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory FriendRecordModel.fromJson(Map<String, dynamic> json) {
    return FriendRecordModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      friendName: json['friend_name'] as String,
      friendPhoneNumber: json['friend_phone_number'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'friend_name': friendName,
      'friend_phone_number': friendPhoneNumber,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toJsonForInsert() {
    final json = toJson();
    json.remove('id');
    json.remove('created_at');
    json.remove('updated_at');
    return json;
  }

  FriendRecordModel copyWith({
    String? id,
    String? userId,
    String? friendName,
    String? friendPhoneNumber,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FriendRecordModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      friendName: friendName ?? this.friendName,
      friendPhoneNumber: friendPhoneNumber ?? this.friendPhoneNumber,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get displayName {
    return friendName;
  }

  String get contactInfo {
    if (friendPhoneNumber != null && friendPhoneNumber!.isNotEmpty) {
      return '$friendName ($friendPhoneNumber)';
    }
    return friendName;
  }

  bool get hasPhoneNumber {
    return friendPhoneNumber != null && friendPhoneNumber!.isNotEmpty;
  }

  String get initials {
    final nameParts = friendName.trim().split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts.first[0]}${nameParts.last[0]}'.toUpperCase();
    } else if (nameParts.isNotEmpty) {
      return nameParts.first.substring(0, 1).toUpperCase();
    }
    return 'F';
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        friendName,
        friendPhoneNumber,
        notes,
        createdAt,
        updatedAt,
      ];
}