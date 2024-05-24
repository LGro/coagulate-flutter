// Copyright 2024 The Coagulate Authors. All rights reserved.
// SPDX-License-Identifier: MPL-2.0

part of 'cubit.dart';

@JsonSerializable()
final class ScheduleState extends Equatable {
  const ScheduleState({required this.checkingIn, required this.circles});

  factory ScheduleState.fromJson(Map<String, dynamic> json) =>
      _$ScheduleStateFromJson(json);

  final bool checkingIn;
  final Map<String, String> circles;

  Map<String, dynamic> toJson() => _$ScheduleStateToJson(this);

  ScheduleState copyWith({bool? checkingIn, Map<String, String>? circles}) =>
      ScheduleState(
          checkingIn: checkingIn ?? this.checkingIn,
          circles: circles ?? this.circles);

  @override
  List<Object?> get props => [checkingIn, circles];
}
