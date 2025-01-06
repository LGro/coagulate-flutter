// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cubit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DummyState _$DummyStateFromJson(Map<String, dynamic> json) => DummyState(
      (json['status'] as num).toInt(),
      json['key'] as String,
      json['writer'] as String,
      json['content'] as String,
    );

Map<String, dynamic> _$DummyStateToJson(DummyState instance) =>
    <String, dynamic>{
      'status': instance.status,
      'key': instance.key,
      'writer': instance.writer,
      'content': instance.content,
    };
