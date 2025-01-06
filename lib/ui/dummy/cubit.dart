// Copyright 2024 The Coagulate Authors. All rights reserved.
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/providers/distributed_storage/base.dart';

part 'cubit.g.dart';
part 'state.dart';

class DummyCubit extends Cubit<DummyState> {
  DummyCubit(this.ds) : super(const DummyState(0, '', '', '')) {
    unawaited(initialize());
  }

  final DistributedStorage ds;
  SharedPreferences? prefs;

  // VLD0:WU5YyGGrZ2i-7QSl1D4r-ecvyXxigFVqbOx-He6clGo

  Future<void> initialize() async {
    if (prefs == null) {
      prefs = await SharedPreferences.getInstance();
    }
    final storedRecord = prefs!.getString('debug_stored_record');
    if (storedRecord == null) {
      // final record = await ds.createDHTRecord();
      // await ds.updatePasswordEncryptedDHTRecord(
      //     recordKey: record.$1,
      //     recordWriter: record.$2,
      //     secret: 'Ld8bbs8Y0LTey_UPUZMQkCNwf-aNodnSXb84sQaD6Wc',
      //     content: 'INITIALIZED');

      final record = ('VLD0:WU5YyGGrZ2i-7QSl1D4r-ecvyXxigFVqbOx-He6clGo', '');
      await prefs!
          .setString('debug_stored_record', '${record.$1}|${record.$2}');
      emit(DummyState(1, record.$1, record.$2, state.content));
    } else {
      final record = storedRecord.split('|');
      emit(DummyState(2, record[0], record[1], state.content));
    }
  }

  Future<void> updateRecord() async {
    final record = await ds.readPasswordEncryptedDHTRecord(
        recordKey: state.key,
        secret: 'Ld8bbs8Y0LTey_UPUZMQkCNwf-aNodnSXb84sQaD6Wc');
    emit(DummyState(state.status, state.key, state.writer, record));
  }

  Future<void> reset() async {
    await prefs?.remove('debug_stored_record');
    return initialize();
  }
}
