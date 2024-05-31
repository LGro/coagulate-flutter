// Copyright 2024 The Coagulate Authors. All rights reserved.
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../../data/models/contact_location.dart';
import '../../../data/repositories/contacts.dart';

part 'cubit.g.dart';
part 'state.dart';

class CheckInCubit extends Cubit<CheckInState> {
  CheckInCubit(this.contactsRepository)
      : super(CheckInState(
            checkingIn: false, circles: contactsRepository.getCircles()));

  final ContactsRepository contactsRepository;

  Future<void> checkIn(
      {required String name,
      required String details,
      required List<String> circles,
      required DateTime end}) async {
    emit(state.copyWith(checkingIn: true));

    final profileContact = contactsRepository.getProfileContact();
    if (profileContact == null) {
      if (!isClosed) {
        //TODO: Emit failure state
        emit(state.copyWith(checkingIn: false));
      }
      return;
    }

    try {
      final location =
          await Geolocator.getCurrentPosition(timeLimit: Duration(seconds: 30));

      unawaited(contactsRepository
          .updateContact(profileContact.copyWith(temporaryLocations: [
            ...profileContact.temporaryLocations
                .map((l) => l.copyWith(checkedIn: false)),
            ContactTemporaryLocation(
                coagContactId: contactsRepository.profileContactId!,
                longitude: location.longitude,
                latitude: location.latitude,
                start: DateTime.now(),
                name: name,
                details: details,
                end: end,
                circles: circles,
                checkedIn: true)
          ]))
          // Make sure to regenerate the sharing profiles and update DHT sharing records
          .then((_) => contactsRepository
              .updateProfileContact(profileContact.coagContactId)));

      if (!isClosed) {
        emit(state.copyWith(checkingIn: false));
      }
    } on TimeoutException {
      if (!isClosed) {
        //TODO: Emit failure state
        emit(state.copyWith(checkingIn: false));
      }
      return;
    } on LocationServiceDisabledException {
      if (!isClosed) {
        //TODO: Emit failure state
        emit(state.copyWith(checkingIn: false));
      }
      return;
    }
  }
}
