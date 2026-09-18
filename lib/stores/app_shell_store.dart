import 'package:mobx/mobx.dart';

import '../key.dart';
import '../storage_manager.dart';

part 'app_shell_store.g.dart';

class AppShellStore = _AppShellStore with _$AppShellStore;

/// Which of the five bottom-navigation destinations is showing.
///
/// Index 2 is the scan action: it opens a full-screen route rather than a tab,
/// so the shell never settles on it.
abstract class _AppShellStore with Store {
  _AppShellStore(this._storage);

  final StorageManager _storage;

  static const int scanIndex = 2;

  @observable
  int currentIndex = 0;

  /// The index the body shows — the scan slot maps back to the last real tab.
  @computed
  int get bodyIndex => currentIndex > scanIndex ? currentIndex - 1 : currentIndex;

  @action
  void select(int index) {
    if (index == scanIndex) return;
    currentIndex = index;
    _storage.setInt(StorageKeys.lastTab, index);
  }

  @action
  void restore() {
    final saved = _storage.getInt(StorageKeys.lastTab);
    if (saved != scanIndex && saved >= 0 && saved <= 4) currentIndex = saved;
  }
}
