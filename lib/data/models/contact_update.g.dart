// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact_update.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContactUpdate _$ContactUpdateFromJson(Map<String, dynamic> json) =>
    ContactUpdate(
      oldContact:
          ContactDetails.fromJson(json['old_contact'] as Map<String, dynamic>),
      newContact:
          ContactDetails.fromJson(json['new_contact'] as Map<String, dynamic>),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$ContactUpdateToJson(ContactUpdate instance) =>
    <String, dynamic>{
      'old_contact': instance.oldContact.toJson(),
      'new_contact': instance.newContact.toJson(),
      'timestamp': instance.timestamp.toIso8601String(),
    };
