// Copyright 2024 The Coagulate Authors. All rights reserved.
// SPDX-License-Identifier: MPL-2.0

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';

import '../../../data/repositories/contacts.dart';
import 'cubit.dart';

// TODO: Display check in form with location (from gps, from map picker, from address, from coordinates) circles to share with, optional duration, optional move away to check out constraint
class MyForm extends StatefulWidget {
  const MyForm(
      {required this.callback,
      super.key,
      this.circles = const {},
      this.circleMemberships = const {}});

  final Future<void> Function({
    required String name,
    required String details,
    required List<String> circles,
    required DateTime end,
  }) callback;

  final Map<String, String> circles;
  final Map<String, List<String>> circleMemberships;

  @override
  State<MyForm> createState() => _MyFormState();
}

class _MyFormState extends State<MyForm> {
  final _key = GlobalKey<FormState>();
  late MyFormState _state;
  late final TextEditingController _titleController;
  late final TextEditingController _detailsController;

  void _onTitleChanged() {
    setState(() {
      _state = _state.copyWith(title: _titleController.text);
    });
  }

  void _onDetailsChanged() {
    setState(() {
      _state = _state.copyWith(details: _detailsController.text);
    });
  }

  void _onMinutesChanged(double value) {
    setState(() {
      _state = _state.copyWith(minutes: value.toInt());
    });
  }

  void _onHoursChanged(double value) {
    setState(() {
      _state = _state.copyWith(hours: value.toInt());
    });
  }

  void _updateCircleSelection(int i, bool selected) {
    final circles = List<(String, String, bool, int)>.from(_state.circles);
    circles[i] = (circles[i].$1, circles[i].$2, selected, circles[i].$4);
    setState(() {
      _state = _state.copyWith(circles: circles);
    });
  }

  Future<void> _onSubmit() async {
    if (!_key.currentState!.validate()) return;

    setState(() {
      _state = _state.copyWith(status: FormzSubmissionStatus.inProgress);
    });

    try {
      await widget.callback(
          name: (_state.title.isEmpty) ? 'Checked-in' : _state.title,
          details: _state.details,
          circles: _state.circles.where((c) => c.$3).map((c) => c.$1).toList(),
          end: DateTime.now()
              .add(Duration(hours: _state.hours, minutes: _state.minutes)));
      _state = _state.copyWith(status: FormzSubmissionStatus.success);
      // Navigator.pop(context);
    } catch (e) {
      _state = _state.copyWith(status: FormzSubmissionStatus.failure);
    }

    if (!mounted) return;

    setState(() {});

    FocusScope.of(context)
      ..nextFocus()
      ..unfocus();

    const failureSnackBar = SnackBar(
      content: Text('Something went wrong... 🚨'),
    );

    if (!_state.status.isSuccess) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          failureSnackBar,
        );
    } else {
      _resetForm();
    }
  }

  void _resetForm() {
    _key.currentState!.reset();
    _titleController.clear();
    _detailsController.clear();
    setState(() => _state = MyFormState());
  }

  @override
  void initState() {
    super.initState();
    _state = MyFormState(
        circles: widget.circles
            .map((id, label) => MapEntry(id, (
                  id,
                  label,
                  false,
                  widget.circleMemberships.values
                      .where((circles) => circles.contains(id))
                      .length
                )))
            .values
            .toList());
    _titleController = TextEditingController(text: _state.title)
      ..addListener(_onTitleChanged);
    _detailsController = TextEditingController(text: _state.details)
      ..addListener(_onDetailsChanged);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
      child: Form(
          key: _key,
          child: Column(children: [
            TextFormField(
              key: const Key('myForm_titleInput'),
              controller: _titleController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                helperMaxLines: 2,
                labelText: 'Title',
                errorMaxLines: 2,
              ),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: const Key('myForm_detailsInput'),
              controller: _detailsController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                helperMaxLines: 2,
                labelText: 'Details',
                errorMaxLines: 2,
              ),
              textInputAction: TextInputAction.done,
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            const Row(children: [
              Text('Circles to share with', textScaler: TextScaler.linear(1.1))
            ]),
            Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _state.circles
                    .asMap()
                    .map((i, c) => MapEntry(
                        i,
                        (c.$3)
                            ? FilledButton(
                                onPressed: () =>
                                    _updateCircleSelection(i, false),
                                child: Text('${c.$2} (${c.$4})'))
                            : OutlinedButton(
                                onPressed: () =>
                                    _updateCircleSelection(i, true),
                                child: Text('${c.$2} (${c.$4})'))))
                    .values
                    .toList()),
            const SizedBox(height: 16),
            Row(children: [
              const Text('Hours'),
              Expanded(
                  child: Slider(
                      value: _state.hours.toDouble(),
                      label: _state.hours.toString(),
                      max: 24,
                      divisions: 24,
                      onChanged: _onHoursChanged)),
            ]),
            Row(children: [
              const Text('Minutes'),
              Expanded(
                  child: Slider(
                      value: _state.minutes.toDouble(),
                      label: _state.minutes.toString(),
                      max: 55,
                      divisions: 11,
                      onChanged: _onMinutesChanged)),
            ]),
            const SizedBox(height: 8),
            if (_state.status.isInProgress)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                key: const Key('myForm_submit'),
                onPressed:
                    (_state.circles.firstWhereOrNull((c) => c.$3) != null &&
                            (_state.minutes > 0 || _state.hours > 0) &&
                            _state.title.isNotEmpty)
                        ? _onSubmit
                        : null,
                child: const Text('Share'),
              ),
            const SizedBox(height: 16),
          ])));
}

class MyFormState with FormzMixin {
  MyFormState({
    this.hours = 0,
    this.minutes = 0,
    this.title = '',
    this.details = '',
    this.circles = const [],
    this.status = FormzSubmissionStatus.initial,
  });

  final FormzSubmissionStatus status;
  final String title;
  final String details;
  final int hours;
  final int minutes;
  final List<(String, String, bool, int)> circles;

  MyFormState copyWith({
    int? hours,
    int? minutes,
    String? title,
    String? details,
    List<(String, String, bool, int)>? circles,
    FormzSubmissionStatus? status,
  }) =>
      MyFormState(
        hours: hours ?? this.hours,
        minutes: minutes ?? this.minutes,
        title: title ?? this.title,
        details: details ?? this.details,
        circles: circles ?? this.circles,
        status: status ?? this.status,
      );

  @override
  List<FormzInput<dynamic, dynamic>> get inputs => [];
}

class CheckInWidget extends StatelessWidget {
  const CheckInWidget({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
      create: (context) => CheckInCubit(context.read<ContactsRepository>()),
      child: BlocConsumer<CheckInCubit, CheckInState>(
          listener: (context, state) async {},
          builder: (context, state) {
            if (state.status.isInitial) {
              return SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: 100,
                  child: const Center(child: CircularProgressIndicator()));
            }

            if (context
                        .read<CheckInCubit>()
                        .contactsRepository
                        .getProfileContact() ==
                    null ||
                state.circles.isEmpty) {
              return SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: const Padding(
                      padding: EdgeInsets.only(
                          left: 16, right: 16, bottom: 32, top: 8),
                      child: Text(
                          'Pick a profile and add (contacts to) circles first.')));
            }

            // TODO: Instead of these two error cases, just show manual location picker in form
            if (state.status.isLocationDenied ||
                state.status.isLocationDeniedPermanent) {
              return SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: const Padding(
                      padding: EdgeInsets.only(
                          left: 16, right: 16, bottom: 32, top: 8),
                      child: Text(
                          'Location permission denied. Please grant Coagulate location access.')));
            }
            if (state.status.isLocationDisabled) {
              return SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: const Padding(
                      padding: EdgeInsets.only(
                          left: 16, right: 16, bottom: 32, top: 8),
                      child: Text(
                          'Location services seem to be disabled, GPS based check-in is not possible.')));
            }
            if (state.status.isLocationTimeout) {
              // TODO: Display error and leave filled out form in place
              // optionally, switch form to manual location choice
              return SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: const Padding(
                      padding: EdgeInsets.only(
                          left: 16, right: 16, bottom: 32, top: 8),
                      child: Text(
                          'Could not determine GPS location, please try again.')));
            }

            // TODO: What to do on success?
            // Navigator.pop(context);

            return MyForm(
                circles: state.circles,
                circleMemberships: state.circleMemberships,
                callback: context.read<CheckInCubit>().checkIn);
          }));
}
