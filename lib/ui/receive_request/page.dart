// Copyright 2024 The Coagulate Authors. All rights reserved.
// SPDX-License-Identifier: MPL-2.0
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/coag_contact.dart';
import '../../data/repositories/contacts.dart';
import '../contact_details/page.dart';
import '../widgets/avatar.dart';
import '../widgets/scan_qr_code.dart';
import 'cubit.dart';

// TODO: Move cubit initialization outside to parent scope (potentially leaving the BlocConsumer inside) instead of passing initial state here?
class ReceiveRequestPage extends StatelessWidget {
  const ReceiveRequestPage({super.key, this.initialState});

  final ReceiveRequestState? initialState;

  @override
  Widget build(BuildContext _) => BlocProvider(
      create: (context) => ReceiveRequestCubit(
          context.read<ContactsRepository>(),
          initialState: initialState),
      child: BlocConsumer<ReceiveRequestCubit, ReceiveRequestState>(
          listener: (context, state) async {
        if (state.status.isSuccess) {
          context.goNamed('contactDetails',
              pathParameters: {'coagContactId': state.profile!.coagContactId});
        }
      }, builder: (context, state) {
        switch (state.status) {
          case ReceiveRequestStatus.processing:
            return Scaffold(
                appBar: AppBar(
                  title: const Text('Processing...'),
                  actions: [
                    IconButton(
                        onPressed:
                            context.read<ReceiveRequestCubit>().scanQrCode,
                        icon: const Icon(Icons.qr_code_scanner))
                  ],
                ),
                body: const Center(child: CircularProgressIndicator()));

          case ReceiveRequestStatus.qrcode:
            return Scaffold(
                appBar: AppBar(title: const Text('Scan QR Code')),
                body: BarcodeScannerPageView(
                    onDetectCallback:
                        context.read<ReceiveRequestCubit>().qrCodeCaptured));

          case ReceiveRequestStatus.receivedRequest:
            return Scaffold(
                // TODO: Theme
                backgroundColor: const Color.fromARGB(255, 244, 244, 244),
                appBar: AppBar(
                  title: const Text('Received Request'),
                  actions: [
                    IconButton(
                        onPressed:
                            context.read<ReceiveRequestCubit>().scanQrCode,
                        icon: const Icon(Icons.qr_code_scanner))
                  ],
                ),
                body: Center(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                      const Padding(
                          padding: EdgeInsets.only(left: 16, right: 16),
                          child: Text('Someone asks you to share your profile '
                              'with them. If you already have them in your '
                              'contacts, pick the matching one, or enter '
                              'their name to create a new contact.')),
                      Padding(
                          padding: const EdgeInsets.only(
                              left: 16, right: 16, top: 16),
                          child: TextFormField(
                              decoration: const InputDecoration(
                                  labelText: 'Their Name',
                                  border: OutlineInputBorder()),
                              onChanged: context
                                  .read<ReceiveRequestCubit>()
                                  .updateNewRequesterContact)),
                      TextButton(
                          onPressed:
                              (state.profile?.details?.displayName.isEmpty ??
                                      true)
                                  ? null
                                  : context
                                      .read<ReceiveRequestCubit>()
                                      .createNewContact,
                          child: const Text(
                              'Create new contact & start sharing with them')),
                      if (state.contactProporsalsForLinking.isNotEmpty)
                        const Center(
                            child: Text(
                                'or pick an existing contact to start sharing with')),
                      const SizedBox(height: 12),
                      if (state.contactProporsalsForLinking.isNotEmpty)
                        Expanded(
                            child: _pickExisting(
                                context,
                                state.contactProporsalsForLinking,
                                context
                                    .read<ReceiveRequestCubit>()
                                    .linkExistingContactRequested)),
                    ])));

          case ReceiveRequestStatus.receivedShare:
            final appBar = AppBar(
              title: const Text('Received Sharing Offer'),
              actions: [
                IconButton(
                    onPressed: context.read<ReceiveRequestCubit>().scanQrCode,
                    icon: const Icon(Icons.qr_code_scanner))
              ],
            );
            return Scaffold(
                // TODO: Theme
                backgroundColor: const Color.fromARGB(255, 244, 244, 244),
                appBar: appBar,
                body: SingleChildScrollView(
                    child: SizedBox(
                        height: MediaQuery.of(context).size.height -
                            appBar.preferredSize.height -
                            MediaQuery.of(context).padding.top -
                            kBottomNavigationBarHeight,
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 8),
                            if (state.profile?.details != null)
                              Expanded(
                                  child: ListView(children: [
                                ...displayDetails(state.profile!.details!)
                              ])),
                            TextButton(
                                onPressed: context
                                    .read<ReceiveRequestCubit>()
                                    .createNewContact,
                                child: const Text('Create new contact')),
                            if (state.contactProporsalsForLinking.isNotEmpty)
                              const Center(
                                  child:
                                      Text('or link to an existing contact')),
                            if (state.contactProporsalsForLinking.isNotEmpty)
                              Expanded(
                                  child: _pickExisting(
                                      context,
                                      state.contactProporsalsForLinking,
                                      context
                                          .read<ReceiveRequestCubit>()
                                          .linkExistingContactSharing)),
                            TextButton(
                                onPressed: context
                                    .read<ReceiveRequestCubit>()
                                    .scanQrCode,
                                child: const Text('Cancel')),
                          ],
                        ))));

          case ReceiveRequestStatus.success:
            return const Center(child: CircularProgressIndicator());

          case ReceiveRequestStatus.receivedUriFragment:
            return const Center(child: CircularProgressIndicator());
        }
      }));
}

Widget _pickExisting(
        BuildContext context,
        Iterable<CoagContact> contactProporsalsForLinking,
        Future<void> Function(CoagContact contact) linkExistingCallback) =>
    ListView(
      children: contactProporsalsForLinking
          // TODO: Filter out the profile contact
          .where((c) => c.details != null || c.systemContact != null)
          .map((c) => ListTile(
              leading: avatar(c.systemContact, radius: 18),
              title: Text(c.details?.displayName ??
                  c.systemContact?.displayName ??
                  '???'),
              //trailing: Text(_contactSyncStatus(c)),
              onTap: () => unawaited(linkExistingCallback(c))))
          .toList(),
    );
