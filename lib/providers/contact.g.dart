// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$fetchContactListHash() => r'f75cb33fbc664404bba122f1e128e437e0f0b2da';

/// Get the active account contact list
///
/// Copied from [fetchContactList].
@ProviderFor(fetchContactList)
final fetchContactListProvider =
    AutoDisposeFutureProvider<IList<Contact>?>.internal(
  fetchContactList,
  name: r'fetchContactListProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$fetchContactListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef FetchContactListRef = AutoDisposeFutureProviderRef<IList<Contact>?>;
// ignore_for_file: unnecessary_raw_strings, subtype_of_sealed_class, invalid_use_of_internal_member, do_not_use_environment, prefer_const_constructors, public_member_api_docs, avoid_private_typedef_functions
