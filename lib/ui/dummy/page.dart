// Copyright 2024 The Coagulate Authors. All rights reserved.
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/contacts.dart';
import '../../veilid_processor/views/signal_strength_meter.dart';
import '../contact_details/page.dart';
import 'cubit.dart';

class DummyPage extends StatelessWidget {
  const DummyPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: const Text('Dummy'),
      ),
      body: BlocProvider(
          create: (context) =>
              DummyCubit(context.read<ContactsRepository>().distributedStorage),
          child: BlocConsumer<DummyCubit, DummyState>(
              listener: (context, state) => {},
              builder: (context, state) => ListView(children: [
                    const ListTile(
                        title: Text('Network status'),
                        trailing: Padding(
                            padding: EdgeInsets.only(right: 20),
                            child: SignalStrengthMeterWidget())),
                    Text('Status: ${state.status}'),
                    const SizedBox(height: 8),
                    Text(state.key),
                    const SizedBox(height: 8),
                    Text(state.writer),
                    const SizedBox(height: 8),
                    Text('Content: ${state.content}'),
                    const SizedBox(height: 8),
                    if (state.status > 0)
                      qrCodeButton(context,
                          buttonText: "QR",
                          alertTitle: "QR",
                          qrCodeData:
                              'https://coagulate.social/${state.key}___${state.writer}'),
                    const SizedBox(height: 8),
                    if (state.status > 0)
                      TextButton(
                          onPressed: context.read<DummyCubit>().updateRecord,
                          child: Text('Update')),
                    const SizedBox(height: 8),
                    TextButton(
                        onPressed: context.read<DummyCubit>().reset,
                        child: Text('Reset')),
                  ]))));
}
