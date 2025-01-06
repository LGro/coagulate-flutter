// Copyright 2024 The Coagulate Authors. All rights reserved.
// SPDX-License-Identifier: MPL-2.0

part of 'cubit.dart';

@JsonSerializable()
final class DummyState extends Equatable {
  const DummyState(this.status, this.key, this.writer, this.content);

  final int status;
  final String key;
  final String writer;
  final String content;

  factory DummyState.fromJson(Map<String, dynamic> json) =>
      _$DummyStateFromJson(json);

  Map<String, dynamic> toJson() => _$DummyStateToJson(this);

  @override
  List<Object?> get props => [status, key, writer, content];
}
