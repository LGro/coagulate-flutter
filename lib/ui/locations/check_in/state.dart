// Copyright 2024 The Coagulate Authors. All rights reserved.
// SPDX-License-Identifier: MPL-2.0

part of 'cubit.dart';

enum CheckInStatus {
  initial,
  locationDisabled,
  locationDenied,
  locationDeniedPermanent,
  locationTimeout,
  noProfile,
  readyForCheckIn,
  checkingIn
}

extension CheckInStatusX on CheckInStatus {
  bool get isInitial => this == CheckInStatus.initial;
  bool get isLocationDisabled => this == CheckInStatus.locationDisabled;
  bool get isLocationDenied => this == CheckInStatus.locationDenied;
  bool get isLocationDeniedPermanent =>
      this == CheckInStatus.locationDeniedPermanent;
  bool get isLocationTimeout => this == CheckInStatus.locationTimeout;
  bool get isNoProfile => this == CheckInStatus.noProfile;
  bool get isReadyForCheckIn => this == CheckInStatus.readyForCheckIn;
  bool get isCheckingIn => this == CheckInStatus.checkingIn;
}

@JsonSerializable()
final class CheckInState extends Equatable {
  const CheckInState({required this.status, required this.circles});

  factory CheckInState.fromJson(Map<String, dynamic> json) =>
      _$CheckInStateFromJson(json);

  final CheckInStatus status;
  final Map<String, String> circles;

  Map<String, dynamic> toJson() => _$CheckInStateToJson(this);

  CheckInState copyWith(
          {CheckInStatus? status, Map<String, String>? circles}) =>
      CheckInState(
          status: status ?? this.status, circles: circles ?? this.circles);

  @override
  List<Object?> get props => [status, circles];
}
