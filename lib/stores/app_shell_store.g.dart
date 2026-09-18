// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_shell_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$AppShellStore on _AppShellStore, Store {
  Computed<int>? _$bodyIndexComputed;

  @override
  int get bodyIndex => (_$bodyIndexComputed ??= Computed<int>(
    () => super.bodyIndex,
    name: '_AppShellStore.bodyIndex',
  )).value;

  late final _$currentIndexAtom = Atom(
    name: '_AppShellStore.currentIndex',
    context: context,
  );

  @override
  int get currentIndex {
    _$currentIndexAtom.reportRead();
    return super.currentIndex;
  }

  @override
  set currentIndex(int value) {
    _$currentIndexAtom.reportWrite(value, super.currentIndex, () {
      super.currentIndex = value;
    });
  }

  late final _$_AppShellStoreActionController = ActionController(
    name: '_AppShellStore',
    context: context,
  );

  @override
  void select(int index) {
    final _$actionInfo = _$_AppShellStoreActionController.startAction(
      name: '_AppShellStore.select',
    );
    try {
      return super.select(index);
    } finally {
      _$_AppShellStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void restore() {
    final _$actionInfo = _$_AppShellStoreActionController.startAction(
      name: '_AppShellStore.restore',
    );
    try {
      return super.restore();
    } finally {
      _$_AppShellStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
currentIndex: ${currentIndex},
bodyIndex: ${bodyIndex}
    ''';
  }
}
