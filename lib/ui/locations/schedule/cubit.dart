// Copyright 2024 The Coagulate Authors. All rights reserved.
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:latlong2/latlong.dart';

import '../../../data/models/contact_location.dart';
import '../../../data/repositories/contacts.dart';

part 'cubit.g.dart';
part 'state.dart';

class ScheduleCubit extends Cubit<ScheduleState> {
  ScheduleCubit(this.contactsRepository)
      : super(ScheduleState(
            checkingIn: false,
            circles: contactsRepository.getCircles(),
            circleMemberships: contactsRepository.getCircleMemberships()));

  final ContactsRepository contactsRepository;

  Future<void> schedule({
    required String name,
    required String details,
    required DateTime start,
    required DateTime end,
    required LatLng coordinates,
    required List<String> circles,
  }) async {
    emit(state.copyWith(checkingIn: true));

    final profileContact = contactsRepository.getProfileContact();
    if (profileContact == null) {
      if (!isClosed) {
        //TODO: Emit failure state
        emit(state.copyWith(checkingIn: false));
      }
      return;
    }

    await contactsRepository
        .updateProfileContactData(profileContact.copyWith(temporaryLocations: [
      ...profileContact.temporaryLocations
          .map((l) => l.copyWith(checkedIn: false)),
      ContactTemporaryLocation(
          coagContactId: profileContact.coagContactId,
          longitude: coordinates.longitude,
          latitude: coordinates.latitude,
          start: start,
          name: name,
          details: details,
          end: end,
          circles: circles)
    ]));

    if (!isClosed) {
      emit(state.copyWith(checkingIn: false));
    }
  }
}
