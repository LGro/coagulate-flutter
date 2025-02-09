// Copyright 2024 The Coagulate Authors. All rights reserved.
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../../data/models/coag_contact.dart';
import '../../data/repositories/contacts.dart';
import '../../ui/profile/cubit.dart';
import '../../utils.dart';
import '../contact_details/page.dart';
import '../create_new_contact/page.dart';
import '../receive_request/page.dart';
import '../widgets/avatar.dart';
import 'cubit.dart';

class ContactListPage extends StatefulWidget {
  const ContactListPage({super.key});

  @override
  _ContactListPageState createState() => _ContactListPageState();
}

class _ContactListPageState extends State<ContactListPage> {
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Contacts')),
      body: MultiBlocProvider(
          providers: [
            BlocProvider(
                create: (context) =>
                    ContactListCubit(context.read<ContactsRepository>())),
            BlocProvider(
                create: (context) =>
                    ProfileCubit(context.read<ContactsRepository>())),
          ],
          child: BlocConsumer<ContactListCubit, ContactListState>(
              listener: (context, state) async {},
              builder: (context, state) {
                switch (state.status) {
                  // TODO: This is barely ever shown, remove
                  case ContactListStatus.initial:
                    return const Center(child: CircularProgressIndicator());
                  // TODO: This is never shown; but we want to see it at least when e.g. the contact list is empty
                  case ContactListStatus.denied:
                    return const Center(
                        child: TextButton(
                            onPressed: FlutterContacts.requestPermission,
                            child: Text('Grant access to contacts')));
                  case ContactListStatus.success:
                    return BlocConsumer<ProfileCubit, ProfileState>(
                        listener: (_, __) async {},
                        builder: (_, profileContactState) => Container(
                            padding: const EdgeInsets.all(10),
                            child: Column(children: [
                              _searchBar(context, state),
                              const SizedBox(height: 10),
                              Expanded(
                                  child: _body(
                                      state.contacts
                                          .where((c) =>
                                              c.coagContactId !=
                                              profileContactState.profileContact
                                                  ?.coagContactId)
                                          .toList(),
                                      state.circleMemberships)),
                              Padding(
                                  padding: const EdgeInsets.only(
                                      top: 4, left: 4, right: 4),
                                  child: Row(children: [
                                    const Text('Create invite:'),
                                    TextButton(
                                        child: const Row(children: [
                                          Icon(Icons.person_add),
                                          SizedBox(width: 8),
                                          Text('invite someone')
                                        ]),
                                        onPressed: () async {
                                          await Navigator.push(
                                              context,
                                              MaterialPageRoute<
                                                      CreateNewContactPage>(
                                                  builder: (_) =>
                                                      const CreateNewContactPage()));
                                        }),
                                  ])),
                              Padding(
                                  padding:
                                      const EdgeInsets.only(left: 4, right: 4),
                                  child: Row(children: [
                                    const Text('Receive invite:'),
                                    TextButton(
                                        child: const Row(children: [
                                          Icon(Icons.qr_code_scanner),
                                          SizedBox(width: 8),
                                          Text('scan QR code')
                                        ]),
                                        onPressed: () async {
                                          await Navigator.push(
                                              context,
                                              MaterialPageRoute<
                                                      ReceiveRequestPage>(
                                                  builder: (_) =>
                                                      const ReceiveRequestPage()));
                                        }),
                                    // TODO: Add option to copy & paste link
                                    // TextButton(
                                    //     child: const Row(children: [
                                    //       Icon(Icons.add_link),
                                    //       SizedBox(width: 8),
                                    //       Text('paste link')
                                    //     ]),
                                    //     onPressed: () async {}),
                                  ])),
                            ])));
                }
              })));

  Widget _searchBar(BuildContext context, ContactListState state) =>
      Row(children: [
        Expanded(
            child: TextField(
          onChanged: context.read<ContactListCubit>().filter,
          autocorrect: false,
          decoration: InputDecoration(
              labelText: 'Search',
              prefixIcon: const Icon(Icons.search),
              // TODO: Clear the actual text as well
              suffixIcon: IconButton(
                onPressed: () async =>
                    context.read<ContactListCubit>().filter(''),
                icon: const Icon(Icons.clear),
              ),
              border: const OutlineInputBorder()),
        )),
        if (state.circleMemberships.values.expand((c) => c).isNotEmpty)
          if (state.selectedCircle != null)
            ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 100),
                child: TextButton(
                    onPressed: context.read<ContactListCubit>().unselectCircle,
                    child: Text(
                      'Circle: ${state.circles[state.selectedCircle]}',
                      overflow: TextOverflow.ellipsis,
                    )))
          else
            IconButton(
                onPressed: () async => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (modalContext) => Padding(
                        padding: EdgeInsets.only(
                            left: 24,
                            top: 24,
                            right: 24,
                            bottom: 16 +
                                MediaQuery.of(modalContext).viewInsets.bottom),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Only display contacts from circle:',
                                  textScaler: TextScaler.linear(1.2)),
                              const SizedBox(height: 16),
                              Wrap(spacing: 8, runSpacing: 6, children: [
                                for (final circle in state.circles.entries)
                                  if (state.circleMemberships.values
                                      .expand((c) => c)
                                      .contains(circle.key))
                                    OutlinedButton(
                                        onPressed: () {
                                          context
                                              .read<ContactListCubit>()
                                              .selectCircle(circle.key);
                                          Navigator.pop(context);
                                        },
                                        child: Text(
                                            '${circle.value} (${state.circleMemberships.values.where((ids) => ids.contains(circle.key)).length})'))
                              ])
                            ]))),
                icon: const Icon(Icons.circle_outlined))
      ]);

  Widget _body(List<CoagContact> contacts,
          Map<String, List<String>> circleMemberships) =>
      ListView.builder(
          itemCount: contacts.length,
          itemBuilder: (context, i) {
            final contact = contacts[i];
            return ListTile(
                leading: avatar(contact.systemContact, radius: 18),
                title: Text(displayName(contact) ?? 'unknown'),
                trailing: Text(contactSharingReceivingStatus(
                    contact,
                    circleMemberships[contact.coagContactId]?.isNotEmpty ??
                        false)),
                onTap: () =>
                    Navigator.of(context).push(ContactPage.route(contact)));
          });
}

String contactSharingReceivingStatus(
    CoagContact contact, bool isMemberAnyCircle) {
  var status = '';
  if (contact.dhtSettingsForSharing != null && isMemberAnyCircle) {
    status = 'S';
  }
  if (contact.details != null) {
    status = 'R$status';
  }
  return status;
}
