// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$ProfileStore on _ProfileStore, Store {
  Computed<UserProfile?>? _$profileComputed;

  @override
  UserProfile? get profile => (_$profileComputed ??= Computed<UserProfile?>(
    () => super.profile,
    name: '_ProfileStore.profile',
  )).value;
  Computed<String>? _$nameComputed;

  @override
  String get name => (_$nameComputed ??= Computed<String>(
    () => super.name,
    name: '_ProfileStore.name',
  )).value;
  Computed<String>? _$emailComputed;

  @override
  String get email => (_$emailComputed ??= Computed<String>(
    () => super.email,
    name: '_ProfileStore.email',
  )).value;
  Computed<String>? _$initialComputed;

  @override
  String get initial => (_$initialComputed ??= Computed<String>(
    () => super.initial,
    name: '_ProfileStore.initial',
  )).value;
  Computed<String>? _$cityComputed;

  @override
  String get city => (_$cityComputed ??= Computed<String>(
    () => super.city,
    name: '_ProfileStore.city',
  )).value;
  Computed<int>? _$plantsKeptComputed;

  @override
  int get plantsKept => (_$plantsKeptComputed ??= Computed<int>(
    () => super.plantsKept,
    name: '_ProfileStore.plantsKept',
  )).value;
  Computed<int>? _$underActiveCareComputed;

  @override
  int get underActiveCare => (_$underActiveCareComputed ??= Computed<int>(
    () => super.underActiveCare,
    name: '_ProfileStore.underActiveCare',
  )).value;
  Computed<int>? _$averageHealthComputed;

  @override
  int get averageHealth => (_$averageHealthComputed ??= Computed<int>(
    () => super.averageHealth,
    name: '_ProfileStore.averageHealth',
  )).value;
  Computed<int>? _$careStreakWeeksComputed;

  @override
  int get careStreakWeeks => (_$careStreakWeeksComputed ??= Computed<int>(
    () => super.careStreakWeeks,
    name: '_ProfileStore.careStreakWeeks',
  )).value;
  Computed<String>? _$streakSinceComputed;

  @override
  String get streakSince => (_$streakSinceComputed ??= Computed<String>(
    () => super.streakSince,
    name: '_ProfileStore.streakSince',
  )).value;
  Computed<String>? _$reminderTimeComputed;

  @override
  String get reminderTime => (_$reminderTimeComputed ??= Computed<String>(
    () => super.reminderTime,
    name: '_ProfileStore.reminderTime',
  )).value;
  Computed<String>? _$unitsComputed;

  @override
  String get units => (_$unitsComputed ??= Computed<String>(
    () => super.units,
    name: '_ProfileStore.units',
  )).value;

  late final _$signOutAsyncAction = AsyncAction(
    '_ProfileStore.signOut',
    context: context,
  );

  @override
  Future<void> signOut() {
    return _$signOutAsyncAction.run(() => super.signOut());
  }

  @override
  String toString() {
    return '''
profile: ${profile},
name: ${name},
email: ${email},
initial: ${initial},
city: ${city},
plantsKept: ${plantsKept},
underActiveCare: ${underActiveCare},
averageHealth: ${averageHealth},
careStreakWeeks: ${careStreakWeeks},
streakSince: ${streakSince},
reminderTime: ${reminderTime},
units: ${units}
    ''';
  }
}
