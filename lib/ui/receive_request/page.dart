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
                appBar: AppBar(title: const Text('Accept personal invite')),
                body: Padding(
                    padding: EdgeInsets.only(
                        top: 16,
                        left: MediaQuery.sizeOf(context).width * 0.1,
                        right: MediaQuery.sizeOf(context).width * 0.1),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // TODO: Instructions / re-request access if denied previously
                          const Text('Scan QR code:'),
                          const SizedBox(height: 8),
                          Align(
                              alignment: Alignment.center,
                              child: SizedBox.square(
                                  dimension:
                                      MediaQuery.sizeOf(context).width * 0.8,
                                  child: BarcodeScannerPageView(
                                      onDetectCallback: context
                                          .read<ReceiveRequestCubit>()
                                          .qrCodeCaptured))),
                          const SizedBox(height: 8),
                          const Text(
                              'Scan only QR codes that were specifically generated for you.'),
                          const SizedBox(height: 32),
                          const Text(
                              'Or if you have copied an invite to your clipboard:'),
                          const SizedBox(height: 8),
                          FilledButton(
                              onPressed: context
                                  .read<ReceiveRequestCubit>()
                                  .pasteInvite,
                              child: const Text('Paste invite')),
                          const SizedBox(height: 8),
                          const Text(
                              'Only paste invites that were specifically generated for you.'),
                        ])));

          case ReceiveRequestStatus.receivedRequest:
            return Scaffold(
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
                              (state.profile?.details?.names.isEmpty ?? true)
                                  ? null
                                  : context
                                      .read<ReceiveRequestCubit>()
                                      .createNewContact,
                          child: const Text(
                              'Create new contact & start sharing with them')),
                      if (state.contactProposalsForLinking.isNotEmpty)
                        const Center(
                            child: Text(
                                'or pick an existing contact to start sharing with')),
                      const SizedBox(height: 12),
                      if (state.contactProposalsForLinking.isNotEmpty)
                        Expanded(
                            child: pickExistingContact(
                                state.contactProposalsForLinking,
                                context
                                    .read<ReceiveRequestCubit>()
                                    .linkExistingContact)),
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
                appBar: appBar,
                body: SingleChildScrollView(
                    child: SizedBox(
                        height: MediaQuery.of(context).size.height -
                            appBar.preferredSize.height -
                            MediaQuery.of(context).padding.top -
                            kBottomNavigationBarHeight,
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 8),
                            if (state.profile?.details != null)
                              Expanded(
                                  child: ListView(children: [
                                ...contactDetailsAndLocations(
                                    context, state.profile!)
                              ])),
                            FilledButton(
                                onPressed: context
                                    .read<ReceiveRequestCubit>()
                                    .createNewContact,
                                child: const Text('Create new contact')),
                            if (state.contactProposalsForLinking.isNotEmpty)
                              const Center(
                                  child:
                                      Text('or link to an existing contact')),
                            if (state.contactProposalsForLinking.isNotEmpty)
                              Expanded(
                                  child: pickExistingContact(
                                      state.contactProposalsForLinking,
                                      context
                                          .read<ReceiveRequestCubit>()
                                          .linkExistingContact)),
                            FilledButton(
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

Widget pickExistingContact(Iterable<CoagContact> contactProporsalsForLinking,
        Future<void> Function(String coagContactId) linkExistingCallback) =>
    ListView(
      children: contactProporsalsForLinking
          // TODO: Filter out the profile contact
          .where((c) => c.details != null || c.systemContact != null)
          .map((c) => ListTile(
              leading: avatar(c.systemContact, radius: 18),
              title: Text(c.details?.names.values.join(', ') ??
                  c.systemContact?.displayName ??
                  '???'),
              //trailing: Text(_contactSyncStatus(c)),
              onTap: () => unawaited(linkExistingCallback(c.coagContactId))))
          .toList(),
    );
