// Copyright 2024 The Coagulate Authors. All rights reserved.
// SPDX-License-Identifier: MPL-2.0

import 'dart:math';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';

import '../../data/models/contact_location.dart';
import '../../data/repositories/contacts.dart';
import '../widgets/circles/widget.dart';
import 'check_in/widget.dart';
import 'cubit.dart';

class LocationForm extends StatefulWidget {
  LocationForm({super.key, Random? seed}) : seed = seed ?? Random();

  final Random seed;

  @override
  State<LocationForm> createState() => _LocationFormState();
}

class _LocationFormState extends State<LocationForm> {
  final _key = GlobalKey<FormState>();
  late LocationFormState _state;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  final _multiSelectKey = GlobalKey<FormFieldState>();

  void _onEmailChanged() {
    setState(() {
      _state = _state.copyWith(email: Email.dirty(_emailController.text));
    });
  }

  void _onPasswordChanged() {
    setState(() {
      _state = _state.copyWith(
        password: Password.dirty(_passwordController.text),
      );
    });
  }

  Future<void> _onSubmit() async {
    if (!_key.currentState!.validate()) return;

    setState(() {
      _state = _state.copyWith(status: FormzSubmissionStatus.inProgress);
    });

    try {
      await _submitForm();
      _state = _state.copyWith(status: FormzSubmissionStatus.success);
    } catch (_) {
      _state = _state.copyWith(status: FormzSubmissionStatus.failure);
    }

    if (!mounted) return;

    setState(() {});

    FocusScope.of(context)
      ..nextFocus()
      ..unfocus();

    const successSnackBar = SnackBar(
      content: Text('Submitted successfully! 🎉'),
    );
    const failureSnackBar = SnackBar(
      content: Text('Something went wrong... 🚨'),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        _state.status.isSuccess ? successSnackBar : failureSnackBar,
      );

    if (_state.status.isSuccess) _resetForm();
  }

  Future<void> _submitForm() async {
    await Future<void>.delayed(const Duration(seconds: 1));
    if (widget.seed.nextInt(2) == 0) throw Exception();
  }

  void _resetForm() {
    _key.currentState!.reset();
    _emailController.clear();
    _passwordController.clear();
    setState(() => _state = LocationFormState());
  }

  @override
  void initState() {
    super.initState();
    _state = LocationFormState();
    _emailController = TextEditingController(text: _state.email.value)
      ..addListener(_onEmailChanged);
    _passwordController = TextEditingController(text: _state.password.value)
      ..addListener(_onPasswordChanged);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _key,
        child: Column(
          children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.pin_drop),
              const SizedBox(width: 16),
              Expanded(
                  child: TextFormField(
                key: const Key('LocationForm_longitudeInput'),
                // controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Longitude',
                  hintText: '23.31142',
                ),
                validator: (value) =>
                    _state.email.validator(value ?? '')?.text(),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
              )),
              const SizedBox(width: 16),
              Expanded(
                  child: TextFormField(
                key: const Key('LocationForm_latitudeInput'),
                // controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Latitude',
                  hintText: '8.141221',
                ),
                validator: (value) =>
                    _state.email.validator(value ?? '')?.text(),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
              )),
            ]),
            TextFormField(
              key: const Key('LocationForm_startInput'),
              // controller: _emailController,
              decoration: const InputDecoration(
                icon: Icon(Icons.calendar_month),
                labelText: 'From',
                hintText: '2024-12-26 16:55 (time is optional)',
                helperText: 'From when are you going to be there?',
              ),
              validator: (value) => _state.email.validator(value ?? '')?.text(),
              keyboardType: TextInputType.datetime,
              textInputAction: TextInputAction.next,
            ),
            TextFormField(
              key: const Key('LocationForm_endInput'),
              // controller: _emailController,
              decoration: const InputDecoration(
                icon: Icon(Icons.calendar_month),
                labelText: 'Till',
                hintText: '2024-12-26 16:55 (time is optional)',
                helperText: 'Optionally: Until when are you going to be there?',
              ),
              validator: (value) => _state.email.validator(value ?? '')?.text(),
              keyboardType: TextInputType.datetime,
              textInputAction: TextInputAction.next,
            ),
            TextFormField(
              key: const Key('LocationForm_nameInput'),
              // controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Title',
                helperText: 'Short title describing your stay.',
              ),
              validator: (value) => _state.email.validator(value ?? '')?.text(),
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
            ),
            TextFormField(
              key: const Key('LocationForm_detailsInput'),
              // controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Details',
                helperText: 'Longer descriptions providing more details.',
              ),
              validator: (value) => _state.email.validator(value ?? '')?.text(),
              keyboardType: TextInputType.multiline,
              maxLines: 6,
              textInputAction: TextInputAction.next,
            ),
            CirclesForm(
                allowCreateNew: false,
                circles: context
                    .read<LocationsCubit>()
                    .contactsRepository
                    .circlesWithMembership(context
                        .read<LocationsCubit>()
                        .contactsRepository
                        .profileContactId!),
                // TODO: add callback
                callback: (circles) async => {throw Error()}),
            const SizedBox(height: 24),
            if (_state.status.isInProgress)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                key: const Key('LocationForm_submit'),
                onPressed: _onSubmit,
                child: const Text('Add'),
              ),
          ],
        ),
      ));
}

class LocationFormState with FormzMixin {
  LocationFormState({
    Email? email,
    this.password = const Password.pure(),
    this.status = FormzSubmissionStatus.initial,
  }) : email = email ?? Email.pure();

  final Email email;
  final Password password;
  final FormzSubmissionStatus status;

  LocationFormState copyWith({
    Email? email,
    Password? password,
    FormzSubmissionStatus? status,
  }) =>
      LocationFormState(
        email: email ?? this.email,
        password: password ?? this.password,
        status: status ?? this.status,
      );

  @override
  List<FormzInput<dynamic, dynamic>> get inputs => [email, password];
}

enum EmailValidationError { invalid, empty }

class Email extends FormzInput<String, EmailValidationError>
    with FormzInputErrorCacheMixin {
  Email.pure([super.value = '']) : super.pure();

  Email.dirty([super.value = '']) : super.dirty();

  static final _emailRegExp = RegExp(
    r'^[a-zA-Z\d.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z\d-]+(?:\.[a-zA-Z\d-]+)*$',
  );

  @override
  EmailValidationError? validator(String value) {
    if (value.isEmpty) {
      return EmailValidationError.empty;
    } else if (!_emailRegExp.hasMatch(value)) {
      return EmailValidationError.invalid;
    }

    return null;
  }
}

enum PasswordValidationError { invalid, empty }

class Password extends FormzInput<String, PasswordValidationError> {
  const Password.pure([super.value = '']) : super.pure();

  const Password.dirty([super.value = '']) : super.dirty();

  static final _passwordRegex =
      RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$');

  @override
  PasswordValidationError? validator(String value) {
    if (value.isEmpty) {
      return PasswordValidationError.empty;
    } else if (!_passwordRegex.hasMatch(value)) {
      return PasswordValidationError.invalid;
    }

    return null;
  }
}

extension on EmailValidationError {
  String text() {
    switch (this) {
      case EmailValidationError.invalid:
        return 'Please ensure the email entered is valid';
      case EmailValidationError.empty:
        return 'Please enter an email';
    }
  }
}

extension on PasswordValidationError {
  String text() {
    switch (this) {
      case PasswordValidationError.invalid:
        return '''Password must be at least 8 characters and contain at least one letter and number''';
      case PasswordValidationError.empty:
        return 'Please enter a password';
    }
  }
}

// TODO: Display details as well?
// TODO: Indicate with how many contacts this location is shared
Widget locationTile(ContactTemporaryLocation location,
        {Future<void> Function()? onTap}) =>
    ListTile(
        title: Text(location.name),
        tileColor: Colors.white,
        onTap: onTap,
        subtitle: Text(
            'From: ${location.start} ${(location.end == location.start) ? "" : "\nTill: ${location.end}"}'
            '\nLon: ${location.longitude}, Lat: ${location.latitude}'),
        trailing:
            // TODO: Better icon to indicate checked in
            (location.checkedIn && DateTime.now().isBefore(location.end))
                ? const Icon(Icons.pin_drop_outlined)
                : null);

class LocationsPage extends StatelessWidget {
  const LocationsPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
      create: (context) => LocationsCubit(context.read<ContactsRepository>()),
      child: BlocConsumer<LocationsCubit, LocationsState>(
          listener: (context, state) async {},
          builder: (context, state) => Scaffold(
              appBar: AppBar(
                title: const Text('Locations'),
                actions: [
                  // TODO: Import from calendar
                  IconButton(
                      onPressed: () => ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(
                            content: Text(
                                'Importing new locations from the calendar will come soon'),
                          )),
                      icon: const Icon(Icons.calendar_month)),
                  // TODO: Add manually via form
                  IconButton(
                      onPressed:
                          context.read<LocationsCubit>().addRandomLocation,
                      icon: const Icon(Icons.add)),
                ],
              ),
              body: Column(children: [
                // SingleChildScrollView(child: LocationForm())
                Expanded(
                    child: ListView(children: [
                  // Future locations
                  ...state.temporaryLocations
                      .where((l) =>
                          !l.end.isBefore(DateTime.now()) &&
                          !l.start.isBefore(DateTime.now()))
                      .map((l) => Dismissible(
                          key: UniqueKey(),
                          onDismissed: (_) async =>
                              context.read<LocationsCubit>().removeLocation(l),
                          background: Container(color: Colors.red),
                          child: locationTile(l)))
                      .asList(),
                  // Current locations // TODO: maybe allow checking in 5-10min earlier?
                  ...state.temporaryLocations
                      .where((l) =>
                          !l.end.isBefore(DateTime.now()) &&
                          l.start.isBefore(DateTime.now()))
                      .map((l) => Dismissible(
                          key: UniqueKey(),
                          onDismissed: (_) async =>
                              context.read<LocationsCubit>().removeLocation(l),
                          background: Container(color: Colors.red),
                          child: locationTile(l,
                              onTap: () async => context
                                  .read<LocationsCubit>()
                                  .toggleCheckInExisting(l))))
                      .asList(),
                  // If no future locations
                  if (state.temporaryLocations
                      .where((l) => !l.end.isBefore(DateTime.now()))
                      .isEmpty)
                    const Padding(
                        padding: EdgeInsets.only(top: 16, bottom: 16),
                        child: Center(
                            child: Text(
                                'Nothing coming up, check-in now or plan a future stay.'))),
                  // Past locations
                  if (state.temporaryLocations
                      .where((l) => l.end.isBefore(DateTime.now()))
                      .isNotEmpty)
                    const Row(children: [
                      Expanded(child: Divider(indent: 8, endIndent: 8)),
                      Text('past locations'),
                      Expanded(child: Divider(indent: 8, endIndent: 8))
                    ]),
                  ...state.temporaryLocations
                      .where((l) => l.end.isBefore(DateTime.now()))
                      .map((l) => Dismissible(
                          key: UniqueKey(),
                          onDismissed: (_) async =>
                              context.read<LocationsCubit>().removeLocation(l),
                          background: Container(color: Colors.red),
                          child: locationTile(l)))
                      .asList(),
                ])),
                const SizedBox(height: 16),
                Row(children: [
                  const SizedBox(width: 16),
                  Expanded(
                      child: ElevatedButton(
                          // TODO: Display live location sharing dialog with selection of circles and optional duration
                          onPressed: () => ScaffoldMessenger.of(context)
                                  .showSnackBar(const SnackBar(
                                content: Text(
                                    'Live location sharing will come soon'),
                              )),
                          child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.route),
                                SizedBox(width: 8),
                                Text('share live')
                              ]))),
                  const SizedBox(width: 16),
                  const Expanded(child: CheckInWidget()),
                  const SizedBox(width: 16),
                ]),
                const SizedBox(height: 16),
              ]))));
}
